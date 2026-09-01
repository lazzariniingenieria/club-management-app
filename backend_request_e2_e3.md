# Pedido al backend — Etapas 2 y 3

**De**: equipo frontend (`club-management-app`)
**Para**: equipo backend ([`club-management-api`](https://github.com/lazzariniingenieria/club-management-api))
**Fecha**: 2026-08-27 · **Revisado**: 2026-09-01

Este documento pide lo necesario para cerrar dos entregas del frontend:

- **E2 — Base de conexión + shell del administrador**: autenticación, sesión persistida, refresco de token y navegación por rol.
- **E3 — Inicio del Administrador**: tablero con contadores de socios activos y en mora.

Alcance y flujos completos en [app_flows.md](app_flows.md) (§8 entregas, §3.2 pantallas del admin).

**Fuera de alcance de este pedido**: canchas, turnos y agenda (el bloque "Próximos Turnos" del Inicio queda postergado), listado y ABM de socios, pagos, y el reporte de pagos. Van en pedidos posteriores.

**Nada de esto nos bloquea para empezar.** E2 incluye implementaciones *fake* de cada data source detrás de la misma interfaz de dominio, así que construimos y demostramos las pantallas sin la API y cambiamos a remoto con un solo `--dart-define`. Lo que sí necesitamos temprano es **el contrato**, para no escribir el mapeo dos veces.

---

## Punto de partida

> **Actualización 2026-09-01.** Cuando se escribió este pedido la API no tenía código, solo el `README` con el diseño previsto. Hoy `develop` de `club-management-api` ya tiene implementación, y varios puntos de este documento quedaron resueltos por el camino. Se marcan como **✅ Resuelto** en lugar de borrarse, para que quede el rastro de qué se acordó y contra qué se codea.
>
> Ya confirmado, no hace falta responderlo: el `role` del login devuelve el enum completo (§2.3); el DNI duplicado devuelve `409` con mensaje propio (§2.5); las bajas son lógicas con endpoint de reactivación; la API usa `GET` / `POST` / `PATCH`, sin `PUT` ni `DELETE`; y el **reset de contraseña es una acción manual de un ADMIN o SUPER_ADMIN**, nunca self-service por email (§2.7).

Dos puntos del diseño no están contemplados en el frontend y hay que resolverlos antes de escribir el mapeo:

1. **Multi-tenencia por `club_id` en todas las tablas.** La app hoy no tiene noción de club. Ver §2.4.
2. **`user_account.member_id` es nullable** — un admin puede o no ser socio. Nos sirve, y necesitamos ese dato en el login. Ver §2.3.

El login ya está implementado en la app contra el contrato que asumimos en el plan original. Si coincide, no tocamos nada; si cambia, preferimos saberlo ahora.

---

## Resumen de lo pedido

| # | Necesidad | Bloquea | Estado |
| :--- | :--- | :--- | :--- |
| 1 | URL del entorno remoto, prefijo de rutas y separación de ambientes | E2 | Abierto |
| 2.1 | `POST /auth/login` — confirmar contrato | E2 | Abierto |
| 2.2 | `POST /auth/refresh` | E2 | Abierto — **feature nueva de cero** |
| 2.3 | `SUPER_ADMIN` en el rol, y `memberId` en el usuario | E2 | ✅ Rol resuelto · `memberId` abierto |
| 2.4 | Multi-tenencia: cómo viaja el `clubId` | E2 | Abierto |
| 2.5 | Formato de error con código estable | E2 | Parcial — el 409 ya existe, falta el `code` |
| 2.6 | Tipo de los `id` en JSON | E2 | Abierto |
| 2.7 | Reset de contraseña por un administrador | E7 | ✅ Modelo definido · falta el endpoint |
| 3.1 | `GET /admin/summary` — contadores del Inicio | E3 | Abierto |
| 3.2 | Modelo de estado del socio (activo/inactivo y al día/en mora) | E3 | Abierto |

---

## 1. Entorno y despliegue — E2

El `README` menciona Render como hosting. Necesitamos:

- **URL base del entorno remoto** ya desplegado, o cuándo lo estará. La usamos como default de `API_BASE_URL`; hoy la app apunta a `localhost`, que no sirve como base de trabajo diaria.
- **Prefijo de las rutas**: la app asume `/api/v1`, pero los endpoints implementados que vimos son `/api/members`, `/api/admins`. **Confirmar cuál es**, porque hoy es la diferencia entre integrar y comer 404 en todas las llamadas. Los ejemplos de este documento usan `/api/v1` por consistencia con lo que la app tiene cableado; se ajustan en cuanto se confirme.
- **Si habrá más de un ambiente** (dev / prod) y sus URLs, para armar los flavors de una vez.
- **Credenciales de prueba** para cada rol (`MEMBER`, `ADMIN`, `SUPER_ADMIN`), o un seed de datos de ejemplo. Sin esto no podemos probar los guards de navegación por rol.

---

## 2. Autenticación — E2

### 2.1 Login — confirmar contrato

Este es el contrato que la app ya implementa:

```
POST /api/v1/auth/login
{ "email": "admin@club.com", "password": "..." }
```

```json
200 OK
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "user": {
    "id": "...",
    "email": "admin@club.com",
    "fullName": "Nombre Apellido",
    "role": "ADMIN"
  }
}
```

Necesitamos confirmar los nombres de campo y agregar dos: `clubId` y `memberId` (§2.3, §2.4).

Y definir el comportamiento de error: hoy la app mapea **401** a "credenciales inválidas". Si existen otros casos que el usuario deba distinguir — cuenta deshabilitada, socio sin cuenta activada — necesitamos un código propio para cada uno (§2.5), no un 401 genérico para todo.

### 2.2 Refresh de token

**Confirmado que hoy no existe ningún concepto de refresh en el backend, ni parcial**: es una feature nueva de cero, no la formalización de algo a medias. Del lado de la app ya está construido y testeado contra un mock, así que lo único que falta es el acuerdo de contrato.

Nos hace falta desde E2: el admin usa la app todos los días y no puede quedar deslogueado cada vez que expira el `accessToken`.

Propuesta:

```
POST /api/v1/auth/refresh
{ "refreshToken": "eyJ..." }
```

```json
200 OK
{ "accessToken": "eyJ...", "refreshToken": "eyJ...", "tokenType": "Bearer", "expiresIn": 86400 }
```

Preguntas concretas:

- ¿El refresco **rota** el `refreshToken` o devuelve el mismo? Cambia si tenemos que reescribir el storage seguro en cada refresco.
- **TTL** del `accessToken` y del `refreshToken`.
- **Qué status devuelve un `refreshToken` vencido o revocado**, y que sea distinguible del 401 del `accessToken`. Es la diferencia entre "refrescar y reintentar en silencio" y "cerrar sesión y mandar al login": si ambos son 401 sin código, entramos en un bucle de refresco.
- ¿Existe **logout con revocación** del lado servidor, o el logout es solo borrar tokens en el cliente?

### 2.3 Roles y vínculo con socio

**✅ Resuelto.** `LoginResponse.role` ya devuelve el enum completo:

| Valor | Significado |
| :--- | :--- |
| `MEMBER` | Socio |
| `ADMIN` | Administrador |
| `SUPER_ADMIN` | Administrador + gestión de administradores |

La app ya mapea los tres en E2. Queda registrado el riesgo que esto cerró: la app solo conocía `ADMIN` y `MEMBER` y cualquier otro valor caía a `MEMBER` por defecto, así que un super admin habría entrado con permisos de socio.

**Lo que sigue abierto**: aprovechando que `user_account.member_id` es nullable, pedimos **`user.memberId`** en la respuesta del login (`null` si la cuenta no tiene socio asociado). Nos sirve para dos cosas: saber si mostrar accesos de socio a un admin, y más adelante preseleccionar nada en el flujo de reserva pero validar que el admin tenga socio si reserva para sí mismo.

**Pregunta de diseño**: ¿el rol vive en `user_account` como columna, o hay una tabla de roles? Solo nos importa que el login devuelva un string estable; lo planteamos porque el `README` no menciona roles y conviene que quede decidido antes de escribir la entidad.

### 2.4 Multi-tenencia — cómo viaja el `clubId`

El `README` define `club_id` en todas las tablas tenant-scoped, pero la app no tiene noción de club. Hay que definir cuál de estas dos:

- **A (preferida)**: el `clubId` va dentro del JWT y el backend lo resuelve solo. La app no lo manda nunca y ningún endpoint lo recibe como parámetro. Es más difícil de romper: un bug del cliente no puede leer datos de otro club.
- **B**: la app lo manda en cada request (header o path). Requiere que el login lo devuelva y que lo persistamos junto al token.

En cualquiera de las dos, **pedimos `user.clubId` en la respuesta del login**, aunque sea solo informativo para mostrar el nombre del club en la interfaz.

Y una pregunta que conviene contestar ahora: ¿un `user_account` puede pertenecer a **más de un club**? Si es posible, la app necesita un selector de club post-login y eso cambia el flujo de arranque. Asumimos que no, salvo que digan lo contrario.

### 2.5 Formato de error con código estable

**Parcialmente resuelto.** El caso que más nos preocupaba ya está: el DNI duplicado devuelve **`409 Conflict`** con un mensaje propio, distinguible por status code de un 400 genérico. Con eso alcanza para mostrarlo en el campo.

Lo que sigue abierto es generalizarlo: un envelope de error consistente en toda la API, con un **código legible por máquina**. Hoy la app solo distingue por status code y para todo lo demás muestra un mensaje genérico.

Propuesta:

```json
{
  "status": 409,
  "code": "MEMBER_DNI_ALREADY_EXISTS",
  "message": "Ya existe un socio con ese DNI",
  "fieldErrors": [ { "field": "dni", "message": "Ya existe un socio con ese DNI" } ]
}
```

Lo importante es `code`: un string estable que no cambie al reescribir el `message`. Sin eso, la app tiene que hacer matching sobre el texto del mensaje, que se rompe la primera vez que alguien corrige una redacción. `fieldErrors` nos permite mostrar el error en el campo del formulario en lugar de un cartel flotante.

También necesitamos acordar el uso de **401 vs 403**: 401 para sesión inválida o vencida (la app refresca o desloguea), 403 para permiso insuficiente (la app muestra un mensaje sin tocar la sesión). Si un 403 llega como 401, deslogueamos al usuario por error.

### 2.6 Tipo de los `id` en JSON

La app hoy parsea `user.id` como **string**. Si las entidades usan `Long` o `UUID` y el JSON los serializa como número, el parseo falla en runtime.

Pedimos que **todos los `id` se serialicen como string** en el JSON, o que nos confirmen el tipo para ajustar el mapeo. Cualquiera de las dos sirve; lo que no queremos es descubrirlo en la primera integración.

### 2.7 Contraseñas — cambio propio y reset por un administrador

**Modelo ya definido del lado del backend, lo tomamos como dado**: el reset de contraseña es una **acción manual de un ADMIN o SUPER_ADMIN**, no un flujo self-service por email. No pedimos "recuperar contraseña por email" — la pantalla `/login/forgot` de la app se rediseña como pantalla informativa que dirige al usuario a contactar a un administrador del club.

Sobre eso necesitamos dos endpoints:

- **Cambio de contraseña propio**, para el usuario logueado: recibe la actual y la nueva. Bloquea E7 (Perfil del admin).
- **Reset de contraseña de un tercero**, restringido a `ADMIN` / `SUPER_ADMIN`: sobre qué cuenta opera, y si la contraseña nueva la define quien la resetea o la genera la API y se devuelve una vez.

Y una decisión de producto asociada: cuando un admin resetea la contraseña de alguien, **¿esa cuenta queda obligada a cambiarla en el próximo ingreso?** Si sí, el login necesita un flag en la respuesta y la app suma esa pantalla al flujo de primer ingreso.

---

## 3. Inicio del Administrador — E3

Pantalla de aterrizaje del admin. En esta etapa muestra dos contadores; el bloque de próximos turnos queda **fuera de alcance** hasta la entrega de canchas y agenda.

### 3.1 Endpoint de resumen

Preferimos **una sola llamada** en lugar de tres: es la primera pantalla después del login y define la percepción de velocidad de la app.

```
GET /api/v1/admin/summary
```

```json
200 OK
{
  "activeMembers": 230,
  "overdueMembers": 25
}
```

- Alcance del club resuelto por el token (§2.4).
- Restringido a `ADMIN` y `SUPER_ADMIN`; un `MEMBER` recibe 403.
- Si más adelante se suma el bloque de turnos, se agrega un campo a esta misma respuesta en vez de crear otro endpoint.

Si un endpoint agregado no es viable ahora, avisen: lo resolvemos con dos llamadas a los contadores del listado de socios, pero la pantalla pasa a tener dos estados de carga independientes.

### 3.2 Modelo de estado del socio

Los contadores dependen de esto, así que necesitamos cerrarlo en E3 aunque el listado completo venga en el pedido siguiente.

Del lado producto ya está definido que son **dos ejes independientes**:

| Eje | Valores | Significado |
| :--- | :--- | :--- |
| Condición de socio | `ACTIVE` / `INACTIVE` | Si la persona **sigue siendo socia** del club |
| Estado de cuota | `UP_TO_DATE` / `OVERDUE` | Si tiene la **cuota al día** |

Un socio puede estar **activo y en mora a la vez** — de hecho es el caso que el admin más necesita ver. Por eso no sirve un solo enum de estado combinado.

Lo que necesitamos definido:

1. **¿Existe una columna de condición de socio en `member`?** El `README` no la menciona. Si no está, hay que agregarla.
2. **El estado de cuota lo calcula el backend**, no el cliente. No queremos derivarlo de la tabla `payment` en la app: es lógica de negocio y se desincronizaría entre pantallas.
3. **Definición de "en mora"** — esta es una decisión de producto, no técnica, y conviene que quede escrita: ¿es "tiene al menos una cuota vencida y no paga"? ¿Hay días de gracia después del vencimiento? ¿Cuántos períodos sin pagar hacen que además pase a `INACTIVE`, si eso pasa automáticamente?
4. **`overdueMembers` cuenta solo socios activos, o también inactivos en mora?** Nuestra lectura es que el contador de mora debería contar solo activos — un socio que se fue no es deuda cobrable. Necesitamos que lo confirmen, porque define el número que el admin ve al abrir la app.

---

## Detalle a alinear para más adelante

En el `README` la tabla de reservas se llama **`booking`**, mientras que en nuestra documentación de flujos la venimos llamando `reservation`. No afecta a E2 ni E3, pero conviene unificar el nombre en el contrato de la API antes de la entrega de agenda para no terminar con dos vocabularios.
