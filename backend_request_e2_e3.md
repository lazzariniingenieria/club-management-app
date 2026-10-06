# Pedido al backend — Etapas 2 y 3

**De**: equipo frontend (`club-management-app`)
**Para**: equipo backend ([`club-management-api`](https://github.com/lazzariniingenieria/club-management-api))
**Fecha**: 2026-08-27 · **Revisado**: 2026-10-06

> **Este documento es histórico: registra qué se pidió y por qué.** Para saber **qué expone la API hoy**, leer [backend_api.md](backend_api.md) — ese es el contrato verificado contra `develop` y la única fuente de verdad. Acá se marca cada punto como resuelto o abierto, sin borrar el rastro de lo acordado.
>
> **Cerrado desde la revisión del 2026-09-01**: el refresco de token existe y está integrado (§2.2), `memberId` viene en el login (§2.3), la multi-tenencia quedó en la opción A — el `clubId` viaja en el JWT (§2.4), y los `id` se serializan como números (§2.6).
>
> **Sigue abierto**: las URLs de los dos entornos (§1), el `code` estable en el envelope de error (§2.5), los endpoints de contraseña (§2.7) y `GET /admin/summary` (§3.1, hoy innecesario).

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
> Ya confirmado, no hace falta responderlo: el `role` del login devuelve el enum completo (§2.3); el DNI duplicado devuelve `409` con mensaje propio (§2.5); las bajas son lógicas con endpoint de reactivación; la API usa `GET` / `POST` / `PATCH` y **un solo** `DELETE` (`/api/members/{id}/family-group`), sin `PUT` en ningún endpoint; y el **reset de contraseña es una acción manual de un ADMIN o SUPER_ADMIN**, nunca self-service por email (§2.7).

Los dos puntos del diseño que no estaban contemplados en el frontend quedaron resueltos:

1. **Multi-tenencia por `club_id`** — quedó la opción A: viaja en el JWT. Ver §2.4.
2. **`user_account.member_id` es nullable** y el login ya devuelve `memberId`. Ver §2.3.

---

## Resumen de lo pedido

| # | Necesidad | Bloquea | Estado |
| :--- | :--- | :--- | :--- |
| 1 | URL del entorno remoto, prefijo de rutas y separación de ambientes | E2 | **Abierto** — prefijo confirmado (`/api`, sin versión); faltan las URLs |
| 2.1 | `POST /auth/login` — confirmar contrato | E2 | ✅ Resuelto — la app se alineó al contrato real |
| 2.2 | `POST /auth/refresh` | E2 | ✅ **Implementado** (PR #16) e integrado |
| 2.3 | `SUPER_ADMIN` en el rol, y `memberId` en el usuario | E2 | ✅ Resuelto — los dos vienen en el login |
| 2.4 | Multi-tenencia: cómo viaja el `clubId` | E2 | ✅ Resuelto — **opción A**: viaja en el JWT. No vuelve en el login |
| 2.5 | Formato de error con código estable | E2 | **Parcial** — el 409 ya existe, el `code` no |
| 2.6 | Tipo de los `id` en JSON | E2 | ✅ Resuelto — **números**, y la app ya parsea así |
| 2.7 | Reset de contraseña por un administrador | E7 | Modelo definido · **falta el endpoint** |
| 3.1 | `GET /admin/summary` — contadores del Inicio | E3 | **No existe** — ya no hace falta, ver §3.1 |
| 3.2 | Modelo de estado del socio (activo/inactivo y al día/en mora) | E3 | ✅ Resuelto — dos ejes separados, mora calculada por el backend |

---

## 1. Entorno y despliegue — E2

El `README` menciona Render como hosting. Necesitamos:

- **URL base del entorno remoto** ya desplegado, o cuándo lo estará. **Sigue siendo el pedido abierto más concreto de esta sección**: las URLs son variables de Railway y no están en el repo del backend, así que no hay forma de deducirlas leyendo código.
- **Prefijo de las rutas**: ✅ **resuelto — es `/api`, sin segmento de versión.** `/api/v1` no existe y nunca existió. Los ejemplos de este documento que usan `/api/v1` quedaron escritos antes de confirmarlo y dan 404 contra la API real; el inventario correcto está en [backend_api.md](backend_api.md) §6.
- **Si habrá más de un ambiente** (dev / prod) y sus URLs, para armar los flavors de una vez. Confirmado que son **dos**: producción desde `main` y test desde `develop`, cada uno con su Postgres. Faltan las URLs.
- **Credenciales de prueba** para cada rol (`MEMBER`, `ADMIN`, `SUPER_ADMIN`), o un seed de datos de ejemplo. Sin esto no podemos probar los guards de navegación por rol.

---

## 2. Autenticación — E2

### 2.1 Login — resuelto, la app se alineó al contrato real

**Cerrado.** El contrato que esta sección asumía (`email` + `password`, prefijo `/api/v1`, respuesta con objeto
`user` anidado más `tokenType`) **no era el de la API**. El backend lo corrigió y la app ya se adaptó.

Contrato vigente, verificado contra `develop` — detalle completo en [backend_api.md](backend_api.md) §3.1:

```
POST /api/auth/login
{ "clubId": 1, "dni": "30111222", "password": "..." }
```

```json
200 OK
{
  "accessToken": "eyJ...",
  "refreshToken": "x7Hk...",
  "expiresIn": 3600,
  "userAccountId": 12,
  "role": "ADMIN",
  "memberId": 34
}
```

`refreshToken` y `expiresIn` se sumaron con el PR #16 (§2.2). La respuesta es plana, sin objeto `user` anidado.

Lo que cambió del lado de la app: el formulario pide **DNI**, no correo; el `clubId` viaja por
`--dart-define=CLUB_ID` hasta que exista `GET /api/clubs` (§2.4); `tokenType` se fija en `Bearer` en el cliente;
y la entidad de usuario ya no tiene `email` ni `fullName`, porque `user_account` no tiene columna de nombre.

**Errores**: el 401 único para DNI inexistente, contraseña incorrecta y cuenta desactivada es deliberado — hacerlo
distinguible permitiría enumerar qué DNI existen en el club. La app lo acepta y muestra un solo mensaje. El
`message` en inglés del envelope nunca se muestra al usuario; se decide por status code.

### 2.2 Refresh de token — ✅ implementado e integrado

**Cerrado.** El endpoint existe desde el PR #16 (2026-09-19) y la app ya consume el contrato real. El detalle
vigente está en [backend_api.md](backend_api.md) §3.2; acá queda lo que se pidió y en qué difirió:

```
POST /api/auth/refresh
{ "refreshToken": "eyJ..." }
```

```json
200 OK
{ "accessToken": "eyJ...", "refreshToken": "eyJ...", "expiresIn": 3600 }
```

**Lo que se cumplió como se acordó**: el refresco **rota** y revoca el anterior; TTL de 1 hora para el
`accessToken`; los dos 401 se distinguen **por endpoint** (un 401 en `/api/auth/refresh` es cerrar sesión, en
cualquier otro es refrescar y reintentar una vez).

**Tres diferencias con lo acordado, a tener en cuenta**:

- El TTL del `refreshToken` es de **60 días**, no de 30 (`JWT_REFRESH_EXPIRATION_MS` = 5 184 000 000 ms).
- **No hay `POST /api/auth/logout`** ni ningún endpoint de revocación. El logout es local: se borra el storage y
  el token descartado sigue válido en base hasta vencer o hasta usarse y rotar.
- **No hay detección de reuso en cascada.** Reusar un token revocado rechaza esa llamada con 401, pero no
  invalida los demás tokens vivos de la cuenta: no es una familia de tokens con detección de robo.

También cambió algo a favor: **el login devuelve `refreshToken` y `expiresIn`**, no solo el `/refresh`, así que no
hace falta una llamada extra para armar la sesión.

**Estado del lado de la app**: integrado. El `TokenRefreshInterceptor` persiste el `refreshToken` rotado de cada
respuesta, `AuthResponseModel` ya lo parsea y `StorageKeys.currentSessionSchemaVersion` está en `3`.

### 2.3 Roles y vínculo con socio

**✅ Resuelto.** `LoginResponse.role` ya devuelve el enum completo:

| Valor | Significado |
| :--- | :--- |
| `MEMBER` | Socio |
| `ADMIN` | Administrador |
| `SUPER_ADMIN` | Administrador + gestión de administradores |

La app ya mapea los tres en E2. Queda registrado el riesgo que esto cerró: la app solo conocía `ADMIN` y `MEMBER` y cualquier otro valor caía a `MEMBER` por defecto, así que un super admin habría entrado con permisos de socio.

**También resuelto**: `memberId` viene en la respuesta del login, `null` si la cuenta no tiene socio asociado — y siempre `null` para un `SUPER_ADMIN`, que lo garantiza un `CHECK` en base. Es el dato que necesitábamos para saber si mostrarle accesos de socio a un admin.

**Pregunta de diseño** — contestada: el rol vive en `user_account.role` como columna `VARCHAR(20)` con un `CHECK`, no hay tabla de roles, y además viaja como claim `role` dentro del JWT.

### 2.4 Multi-tenencia — ✅ resuelto: quedó la opción A

**Quedó la opción A**, la que preferíamos: el `clubId` va dentro del JWT (claim `clubId`) y el backend lo resuelve solo. **Ningún endpoint lo recibe** por path, query ni header, así que un bug del cliente no puede leer datos de otro club.

Dos consecuencias que no habíamos previsto:

- **El login no devuelve `clubId`.** Pedimos `user.clubId` aunque fuera informativo y no está, así que la app lo sigue necesitando por `--dart-define=CLUB_ID` para poder mandarlo en el `POST /auth/login`, y no puede recuperarlo de la sesión.
- **La tabla `club` todavía no existe.** `club_id` es un `BIGINT` sin FK y sin tabla del otro lado: no hay nombre de club para mostrar en la interfaz, ni `GET /api/clubs`, ni flags de rollout por club.

La pregunta de si un `user_account` puede pertenecer a más de un club sigue sin contestarse explícitamente, pero el esquema la cierra de hecho: `club_id` es una columna única por fila de `user_account`, así que una cuenta pertenece a exactamente un club. No hace falta selector post-login.

### 2.5 Formato de error con código estable

**Parcialmente resuelto.** El caso que más nos preocupaba ya está: el DNI duplicado devuelve **`409 Conflict`** con un mensaje propio, distinguible por status code de un 400 genérico. Con eso alcanza para mostrarlo en el campo.

Lo que sigue abierto es generalizarlo: un envelope de error consistente en toda la API, con un **código legible por máquina**. El envelope consistente **ya existe** — todo error nacido en un controller o un service sale como `{ timestamp, status, error, message, details }` —, pero **no tiene `code` ni `fieldErrors`**: `error` es el reason phrase de HTTP y `message` es el texto de la excepción Java, en inglés y sujeto a cambiar de redacción. Hoy la app solo distingue por status code y para todo lo demás muestra un mensaje genérico.

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

El uso de **401 vs 403** quedó ✅ **resuelto y correcto**: 401 para sesión inválida o vencida, 403 para permiso insuficiente. Un detalle a tener en cuenta: los dos los emite la cadena de filtros de Spring Security, no el handler global, así que **su cuerpo no es el envelope de error** (el 401 viene vacío). Para esos dos códigos hay que decidir solo por status code.

### 2.6 Tipo de los `id` en JSON — ✅ resuelto

**Son números.** Las entidades usan `Long` y el JSON los serializa como número, no como string. La app ya se alineó y parsea con `(json['id'] as num).toInt()` en todos los modelos.

### 2.7 Contraseñas — cambio propio y reset por un administrador

**Modelo ya definido del lado del backend, lo tomamos como dado**: el reset de contraseña es una **acción manual de un ADMIN o SUPER_ADMIN**, no un flujo self-service por email. No pedimos "recuperar contraseña por email" — la pantalla `/login/forgot` de la app se rediseña como pantalla informativa que dirige al usuario a contactar a un administrador del club.

Sobre eso necesitamos dos endpoints:

- **Cambio de contraseña propio**, para el usuario logueado: recibe la actual y la nueva. Bloquea E7 (Perfil del admin).
- **Reset de contraseña de un tercero**, restringido a `ADMIN` / `SUPER_ADMIN`: sobre qué cuenta opera, y si la contraseña nueva la define quien la resetea o la genera la API y se devuelve una vez.

Y una decisión de producto asociada: cuando un admin resetea la contraseña de alguien, **¿esa cuenta queda obligada a cambiarla en el próximo ingreso?** Si sí, el login necesita un flag en la respuesta y la app suma esa pantalla al flujo de primer ingreso.

---

## 3. Inicio del Administrador — E3

Pantalla de aterrizaje del admin. En esta etapa muestra dos contadores; el bloque de próximos turnos queda **fuera de alcance** hasta la entrega de canchas y agenda.

### 3.1 Endpoint de resumen — no existe, y ya no hace falta

**`GET /admin/summary` no se implementó, y E3 se cerró sin él.** Los dos contadores se arman con lo que la API ya expone. Mejor todavía: `GET /api/payments/delinquency` devuelve **una fila por cada socio activo** (no solo por los morosos), así que de esa única llamada salen los dos números — total de activos y cuántos tienen `daysOverdue > 0`. Ver [backend_api.md](backend_api.md) §6.5.

Queda como mejora menor, ya sin la urgencia que tenía: un endpoint que devuelva dos enteros en lugar de una fila por socio. El pedido original, tal como se escribió:

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

### 3.2 Modelo de estado del socio — ✅ resuelto

**Los cuatro puntos de abajo quedaron contestados.** Resumen de cómo quedó, con el detalle en [backend_api.md](backend_api.md) §7.1:

1. **Sí existe** `member.status`, un enum `ACTIVE` / `INACTIVE` con `CHECK` en base, movible por `PATCH /api/members/{id}/deactivate` y `/reactivate`.
2. **El estado de cuota lo calcula el backend** y nunca es una columna guardada: se computa comparando `payment.period_covered` contra la fecha de hoy, así que no puede desincronizarse. El cliente no lo deriva.
3. **Definición de "en mora"**: `daysOverdue = max(0, días entre coverageStart y hoy)`, donde `coverageStart` es el mes siguiente al último período pagado, o el primer día del mes de alta si el socio nunca pagó. **No hay días de gracia** y el paso a `INACTIVE` nunca es automático. Dos consecuencias de producto que conviene mirar: quien pagó septiembre figura en mora el 6 de octubre, y **un socio recién creado nace en mora** (uno cargado el día 20 aparece con 19 días).
4. **`overdueMembers` cuenta solo socios activos**, como pedíamos: `GET /api/payments/delinquency` no incluye a los inactivos.

El pedido original, tal como se escribió:

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

En el `README` del backend la tabla de reservas se llamaba **`booking`**, mientras que en nuestra documentación de flujos la venimos llamando `reservation`. Hoy el `CLAUDE.md` del backend ya usa `reservation` en todo el diseño, así que el vocabulario quedó unificado de hecho — y como **la tabla todavía no existe** (ninguna migración la crea), no hay nada que renombrar. A confirmar recién cuando se escriba la migración, antes de la entrega de agenda.
