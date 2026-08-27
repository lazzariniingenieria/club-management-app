# Mapa de Flujos, Pantallas y Entregas (`club-management-app`)

Documento de referencia del frontend: **qué pantallas existen, cómo se navega, qué ve cada rol, y en qué orden se entrega**. De acá salen los PRs (§8) y los pedidos al equipo de backend (§9).

No define píxeles. Define estructura, flujos, estados y alcance por entrega.

> **Revisión 2026-08-27.** La superficie del **administrador es el camino crítico**: se construye completa antes de la del socio. La paleta de §7 y la navegación del admin de §3.2 derivan de dos capturas de referencia (*Inicio - Administrador*, *Gestión de Socios - Administrador*); los hexadecimales están estimados visualmente y hay que confirmarlos. Backend: [club-management-api](https://github.com/lazzariniingenieria/club-management-api).

---

## 1. Principios de diseño

| Principio | Implicancia concreta |
| :--- | :--- |
| **Pocos pasos** | Máximo 3 toques desde el Inicio hasta confirmar cualquier flujo principal. |
| **Íconos con etiqueta, según superficie** | **Socio**: nunca un ícono solo (uso esporádico, rango de edad amplio). **Admin**: se permite ícono-only en filas densas, con `Semantics(label:)`, `tooltip` y área táctil de 48×48. |
| **Estado siempre explícito** | Nadie debe preguntarse "¿se guardó o no?". Confirmación textual, no solo cambio de color. |
| **El color nunca solo** | Todo estado va acompañado de texto o ícono. Daltonismo y pantallas al sol en el predio. |
| **Tolerancia al error** | Toda acción irreversible (baja de socio, registrar pago, cancelar reserva) pide confirmación. |
| **Sin jerga técnica** | "Turno fijo", no "recurring slot". "Cuota al día", no "payment status: OK". |

---

## 2. Roles y superficies

| Rol | `UserRole` | Alcance |
| :--- | :--- | :--- |
| **Socio** | `member` | Consume el club: reserva, paga, consulta. |
| **Administrador** | `admin` | Opera el club: socios, pagos, reservas y canchas. **Superficie de las primeras entregas.** |
| **Super administrador** | `superAdmin` | Todo lo del admin **+ ABM de administradores**. |

**Dos shells de navegación, no tres.** Socio y admin tienen árboles separados elegidos por rol en el `redirect` del router, para evitar pantallas llenas de `if (isAdmin)`.

El **superAdmin comparte el shell del admin**: su único delta es la gestión de administradores. Un tercer shell duplicaría cuatro tabs por una sola pantalla extra. La diferencia se resuelve con un único punto de control — un getter `canManageAdmins` sobre el rol — que habilita el acceso en el Perfil. Una sola condición, en un solo lugar.

**El admin que reserva para sí mismo** no tiene modo especial: usa el flujo de reserva del admin y selecciona su propia cuenta de socio. La reserva es indistinguible de cualquier otra. Consecuencia a respetar: el paso de selección de socio está **siempre**, sin preseleccionar ni atajar casos.

---

## 3. Inventario de pantallas

### 3.1 Autenticación (fuera de los shells)

| Pantalla | Ruta | Estado |
| :--- | :--- | :--- |
| Splash / Bootstrap | `/` | A construir — resuelve sesión persistida y redirige |
| Login | `/login` | ✅ Implementada |
| Primer ingreso | `/login/activate` | A construir — CTA ya existe en `AppStrings.loginFirstTimeUser` |
| Recuperar contraseña | `/login/forgot` | A construir — CTA ya existe en `AppStrings.loginForgotPassword` |

### 3.2 Shell del Administrador

Bottom navigation navy, 4 items con ícono **y** etiqueta. Badge `RoleBadge` ("ADMINISTRADOR" / "SUPER ADMIN") en el header de toda pantalla del shell.

| Tab | Ruta | Contenido |
| :--- | :--- | :--- |
| **Inicio** | `/admin` | Resumen General + Accesos Rápidos (§3.2.1) |
| **Reservas** | `/admin/reservations` | Agenda por cancha, bloqueos, alta a nombre de un socio. **Estado "Próximamente" hasta E9** |
| **Pagos** | `/admin/payments` | Cuotas con filtro por estado, registrar pago, detalle |
| **Perfil** | `/admin/profile` | Datos, cambiar contraseña, logout, y acceso a Administradores si `canManageAdmins` |

Rutas push, fuera de los tabs:

| Pantalla | Ruta | Rol |
| :--- | :--- | :--- |
| Gestión de socios | `/admin/members` | admin |
| Alta / edición de socio | `/admin/members/new`, `/admin/members/:memberId/edit` | admin |
| Reporte de pagos | `/admin/members/report` | admin |
| Gestión de canchas | `/admin/courts` | admin |
| Gestión de administradores | `/admin/admins` (+ `/new`, `/:adminId/edit`) | **superAdmin** |

**Socios y Canchas no son tabs.** Son tareas de sesión (entrás, resolvés, volvés); la barra inferior queda para lo que el admin mira varias veces por día. El tab Reservas se muestra desde la primera entrega con estado "Próximamente" para que la barra no cambie de forma entre releases.

#### 3.2.1 Inicio del Administrador

**Resumen General**

| Bloque | Contenido | Visual | Al tocar |
| :--- | :--- | :--- | :--- |
| `ActiveMembersCard` | "SOCIOS ACTIVOS" + contador | Card navy sólida, texto blanco | → `/admin/members` |
| `OverdueMembersCard` | "SOCIOS EN MORA" + contador | Card azul claro, contador en rojo | → `/admin/members` |
| `UpcomingSlotsCard` | "PRÓXIMOS TURNOS" + cancha / horario | Card azul claro, horario en azul a la derecha | → agenda (no navegable hasta E9) |

**Accesos Rápidos** — dos cards lado a lado: *Gestión de Socios* (navy) → `/admin/members`, *Gestión de Canchas* (verde) → `/admin/courts`.

Los tres puntos de entrada a socios van a la **misma** pantalla sin pre-filtro. Mejora posterior: que "Socios en mora" abra el listado con el filtro de mora aplicado.

#### 3.2.2 Gestión de Socios

1. **Header**: "Socios" + `RoleBadge`.
2. **Buscador**: placeholder "Buscar socio por nombre o DNI". Debounce ~300 ms, la consulta la resuelve el backend.
3. **Filtros**: chips con contador — "Todos (n)", "Activos (n)", "Inactivos (n)". Seleccionado en navy sólido. *La captura dice "Inactivas"; va "Inactivos".*
4. **Listado**: `ListView.builder` paginado de `MemberListTile`. Cada fila: barra de acento izquierda por estado de cuota, nombre, pill de estado, acción **lápiz** → edición, acción **documento** → agrega o quita del reporte (con estado visual propio).
5. **FAB verde, abajo izquierda**: ver reporte de pagos, con badge de cantidad. Deshabilitado en cero.
6. **FAB azul, abajo derecha**: crear socio → `/admin/members/new`.

**Los dos ejes de estado son independientes** (§9): `activo/inactivo` dice si sigue siendo socio; `al día/en mora` dice si la cuota está paga. Los chips filtran por el primero y el pill muestra el segundo, así que un socio puede estar **activo y en mora a la vez**. La fila debe poder mostrar ambos cuando difieren — un solo distintivo por fila no alcanza.

**Dos FABs no es patrón estándar de Material.** Funciona porque son acciones de peso distinto y están separadas, pero el verde necesita etiqueta: conviene **FAB extendido "Ver reporte"** en lugar de circular.

### 3.3 Shell del Socio

Se construye recién con el admin terminado (E12+). Cuatro tabs con ícono y etiqueta:

| Tab | Ruta | Pantallas |
| :--- | :--- | :--- |
| Inicio | `/home` | Próxima reserva, estado de cuota, atajos, avisos |
| Reservas | `/reservations` | Mis reservas · elegir cancha → horario → confirmar · detalle |
| Cuotas | `/payments` | Estado de cuota + historial · detalle de pago |
| Perfil | `/profile` | Mi perfil · grupo familiar · turnos fijos · cambiar contraseña · logout |

---

## 4. Flujos críticos

Ordenados por entrega: primero los del admin.

### 4.1 Gestión de socios — listado, alta y edición

```
Inicio ──[Socios activos | Socios en mora | Gestión de Socios]──► Gestión de Socios
                                         │
                    ┌────────────────────┼────────────────────┐
                    ▼                    ▼                    ▼
              [FAB azul +]         [lápiz fila]        [buscar / filtrar]
                    │                    │
              Alta de socio       Edición de socio
                    └──────────┬─────────┘
                               ▼
                        Confirmar ──► Listado actualizado
```

- La búsqueda y el filtro los resuelve el backend; el listado es paginado con "cargando más" al pie.
- El DNI duplicado lo valida el backend: la app mapea el error a un mensaje en el campo, no a un snackbar genérico.
- Al volver de un alta exitosa el listado refresca y hace scroll al socio creado.
- Abandonar un formulario con cambios pide confirmación. La búsqueda y el filtro sobreviven a la ida y vuelta.

### 4.2 Registrar un pago

`Pagos → filtro "vencidas" → socio → Registrar pago → Confirmar → Listado actualizado`

Impacta en dinero: confirmación con resumen (socio, período, monto, medio) antes de escribir.

### 4.3 ABM de administradores (solo superAdmin)

`Perfil → Administradores → [+ | lápiz | baja] → Confirmar`

- La baja de un admin pide confirmación con el nombre escrito, no un "¿Está seguro?" genérico.
- El superAdmin no puede darse de baja a sí mismo: la acción viene deshabilitada con el motivo visible.

### 4.4 Reservar una cancha (admin)

`Reservas → Nueva → Seleccionar socio → Cancha → Horario → Confirmar → Éxito`

- El paso de selección de socio está siempre, también cuando el admin reserva para sí mismo (§2).
- La fecha arranca en **hoy**. Las franjas ocupadas se muestran **deshabilitadas con motivo** ("Ocupado", "Mantenimiento", "Turno fijo"), no ocultas: ocultarlas hace creer que la app está rota.
- La confirmación es una pantalla, no un diálogo.

### 4.5 Bloquear una cancha (admin)

`Reservas → Bloquear → Rango + motivo → Confirmar → Agenda actualizada`

Si el bloqueo pisa reservas existentes, la confirmación **debe listar las reservas afectadas** y decir qué pasa con ellas. Es el flujo con mayor potencial de daño de la app.

### 4.6 Reporte de pagos

`Gestión de Socios → [ícono documento en n filas] → FAB verde → Reporte`

La selección vive en el estado del listado y se envía recién al pedir el reporte, que lo genera el backend. Un error de generación **no** borra la selección: si un error pierde 20 socios elegidos a mano, el admin no vuelve a usar la función.

---

## 5. Estados por pantalla

Toda pantalla con datos remotos maneja estos casos. No se agregan "después".

| Estado | Tratamiento |
| :--- | :--- |
| **Loading** | Skeleton con la forma del contenido real. Spinner solo dentro de un botón, en acciones puntuales. |
| **Empty** | Mensaje + acción sugerida. Nunca una lista vacía muda. |
| **Error** | Mensaje en lenguaje del usuario + "Reintentar". Distinguir sin conexión de error del servidor. |
| **Success** | Confirmación textual + refresco del estado afectado. |
| **Sin conexión** | Mensaje propio. La conectividad dentro del predio es un caso real. |
| **Cargando más** | En listados paginados: indicador al pie, sin tapar lo ya cargado. |

**Dos vacíos distintos en el listado de socios**, error clásico tratarlos igual: sin socios cargados → "Crear el primer socio"; búsqueda sin resultados → "Limpiar búsqueda".

**Consecuencia técnica**: un `AsyncStateBuilder` compartido en `shared/widgets/` que reciba el estado del Cubit y los builders de cada caso, para no reimplementar el árbol de estados por pantalla.

---

## 6. Router y guards

Estructura objetivo de [app_router.dart](lib/core/router/app_router.dart), hoy con dos rutas planas:

```
GoRouter
├── /                              → SplashScreen (resuelve sesión)
├── /login  (+ /activate, /forgot)
├── StatefulShellRoute (admin + superAdmin)
│   ├── branch: /admin              → Inicio
│   ├── branch: /admin/reservations  → Agenda ("Próximamente" hasta E9)
│   ├── branch: /admin/payments      → Pagos
│   └── branch: /admin/profile       → Perfil
├── rutas push del admin
│   ├── /admin/members  (+ /new, /:memberId/edit, /report)
│   ├── /admin/courts
│   └── /admin/admins   (+ /new, /:adminId/edit)      ← solo superAdmin
└── StatefulShellRoute (socio)      → E12+
    ├── branch: /home
    ├── branch: /reservations
    ├── branch: /payments
    └── branch: /profile
```

`StatefulShellRoute.indexedStack`: preserva el estado de cada tab, que es lo que el admin espera al volver de Pagos a un listado a medio filtrar. `initialLocation` es `/`; el destino post-login del admin es `/admin`.

**Guards** en el `redirect`:

1. Sin sesión + ruta protegida → `/login`.
2. Con sesión + ruta de auth → shell según rol.
3. `member` mientras su shell no exista → pantalla explícita de "la app para socios está en preparación", no un redirect a rutas inexistentes.
4. `member` intentando `/admin/*` → fuera de la superficie admin.
5. `admin` intentando `/admin/admins` → fuera; solo `superAdmin`.
6. Sesión expirada (401 no recuperable del interceptor) → `/login` con mensaje de sesión vencida.

Esto requiere un `AuthBloc` de sesión, separado del `LoginCubit` de formulario que ya existe.

---

## 7. Dirección visual

Paleta derivada de las capturas. **Valores estimados visualmente, a confirmar.**

| Token | Hex | Uso |
| :--- | :--- | :--- |
| `brandNavy` | `#0C2340` | Bottom nav, cards destacadas, chip activo, texto primario |
| `brandGreen` | `#12784A` | Card "Gestión de Canchas", FAB de reporte |
| `accentBlue` | `#2563EB` | FAB de crear socio, horarios, enlaces |
| `infoSurface` | `#DDE7F7` | Fondo de cards informativas (mora, próximos turnos) |
| `successSurface` / `successText` | `#C8EFD9` / `#0F6B41` | Pill "ACTIVO", `RoleBadge` |
| `dangerSurface` / `dangerText` | `#FADBDB` / `#D32F2F` | Pill "EN MORA", contador de mora |
| `background` / `surface` | `#F4F6F9` / `#FFFFFF` | Fondo de pantalla / cards y campos |
| `textSecondary` | `#6B7280` | Placeholders y labels |

**Separar la rampa de marca de la semántica aunque hoy compartan tono.** El verde del FAB de reporte es `brandGreen`; el del pill "ACTIVO" es `successText`. Si mañana "al día" cambia de color, no se arrastra el FAB. Igual con `accentBlue` (acción) frente a `infoSurface` (información). Es lo que se degrada solo si no se explicita ahora.

**Tipografía**: Inter (ya está vía `google_fonts`), cuerpo en 16sp.

**Modo oscuro fuera de alcance.** Las capturas son un diseño *light*. Un `darkTheme` inventado sobre una identidad ajena es deuda, no feature.

---

## 8. Entregas

Vertical slices: cada PR entrega una feature de punta a punta (`domain` → `data` → `presentation`) con sus estados y sus tests. Antes de cerrar cada una: `flutter analyze` sin warnings y suite verde.

| # | Entrega | Depende de backend | Estado |
| :--- | :--- | :--- | :--- |
| **E1** | **Migración de paleta y theming de lo ya construido** | — | Próxima |
| **E2** | **Base de conexión + shell del admin** | — (contra fakes) | — |
| E3 | Inicio del Administrador | §9.4 | — |
| E4 | Gestión de socios: listado, búsqueda, filtros, paginación | §9.1 | — |
| E5 | Alta y edición de socio | §9.2 | — |
| E6 | Pagos del admin: listado, registrar pago, detalle | §9.5 | — |
| E7 | Perfil del admin + cambiar contraseña + logout | §9.3 | — |
| E8 | ABM de administradores (superAdmin) | §9.6 | — |
| E9 | Agenda / Reservas + canchas + bloqueos | §9.8 | — |
| E10 | Reporte de pagos | §9.7 | — |
| E11 | Recuperar contraseña + primer ingreso | §9.3 | — |
| E12+ | Superficie del socio completa | §9.8 | — |

### E1 — Migración de paleta y theming

Primera entrega: llevar lo que ya existe a la identidad de las capturas. **Sin cambios funcionales y sin tocar backend.**

- Reemplazar [app_colors.dart](lib/core/theme/app_colors.dart) — hoy Tailwind sky/slate — por los tokens de §7.
- Activar `useMaterial3: true` en [app_theme.dart](lib/core/theme/app_theme.dart); hoy corre con defaults de Material 2.
- Extraer `AppSpacing` y `AppRadius`: el valor `12` está repetido en cinco lugares del theme.
- Crear `app_text_styles.dart` con la escala tipográfica; hoy los estilos están inline en el `ThemeData`.
- Quitar los colores dark que no se usan, en lugar de dejar el `darkTheme` a medio cablear.
- Aplicar la paleta a lo existente: `login_screen`, `login_form`, `login_header`, `app_button`, `app_text_form_field`.
- Ruta `/dev/gallery`, solo en debug, con cada componente en cada estado. Reemplaza a Figma como catálogo y no se desincroniza porque *es* el código.

**Terminado cuando**: el login se ve con la paleta nueva, `/dev/gallery` muestra el catálogo completo, `flutter analyze` limpio y los tests existentes en verde.

### E2 — Base de conexión + shell del admin

Dejar la conexión al backend **armada y lista**, sin depender de que la API esté disponible.

- `--dart-define=API_BASE_URL` con el **remoto por defecto**: hoy [api_client.dart](lib/core/network/api_client.dart) tiene `localhost` hardcodeado como default, contra lo que fija el `CLAUDE.md`.
- Centralizar endpoints en `core/constants/api_constants.dart` en lugar de strings dispersos por los data sources.
- Sumar `superAdmin` al enum `UserRole` de [user.dart](lib/features/auth/domain/entities/user.dart) y al mapeo del `UserModel`.
- Interceptor de refresco de token en el `ApiClient`, detrás del contrato de §9.3. Queda escrito y testeado contra un mock aunque el endpoint todavía no exista.
- **Fake data sources por flavor**: cada repositorio con implementación remota y una fake seleccionada por `--dart-define`. Es lo que permite construir E3–E8 sin backend, y lo que el `CLAUDE.md` ya pide ("UI development con datos mockeados"). Los fakes viven junto a la implementación remota, detrás de la misma interfaz de `domain`.
- `AuthBloc` de sesión + Splash + guards de §6.
- Shell del admin con los 4 tabs, Reservas en "Próximamente".

**Terminado cuando**: se puede navegar el shell completo del admin contra fakes, cambiar a remoto solo con un `--dart-define`, y los guards se testean por rol (`member`, `admin`, `superAdmin`).

El orden E4 → E5 → E10 es intencional: listado antes de escrituras, y el reporte al final porque depende del listado y de un contrato todavía abierto.

---

## 9. Necesidades del backend

Lista para enviar al equipo de [club-management-api](https://github.com/lazzariniingenieria/club-management-api). Ordenada por la entrega que bloquea.

**Ya definido, a reflejar en la API:**
- `activo/inactivo` (sigue siendo socio) y `al día/en mora` (estado de cuota) son **dos campos independientes**: la API los expone por separado y ambos son filtrables.
- El **filtrado y la búsqueda los resuelve el backend**, no el cliente.
- El listado de socios es **paginado**.
- El alta de socio crea **solo `member`**, no `user_account`.

### 9.1 Listado de socios — bloquea E4

`GET /members` con paginación, búsqueda por nombre y DNI, y filtro por estado. Necesitamos:
- Nombres exactos de los parámetros de paginación, búsqueda y filtro.
- Shape de la respuesta con metadata de paginación (total de elementos, total de páginas, página actual).
- Cada socio con **ambos** campos de estado, más `id`, nombre completo y DNI.
- Contadores por estado para los chips ("Todos / Activos / Inactivos"), idealmente en la misma respuesta para no pedir tres veces.

### 9.2 Alta y edición de socio — bloquea E5

`POST /members` y `PUT /members/{id}`. Necesitamos:
- Campos obligatorios y opcionales, con sus validaciones (formato de DNI, largo de nombre).
- **Código de error específico para DNI duplicado**, distinguible de un 400 genérico, para poder mostrarlo en el campo y no en un snackbar.
- Qué devuelve el 201: idealmente el socio creado completo.

### 9.3 Autenticación — bloquea E2, E7 y E11

- `POST /auth/refresh`: contrato del refresco de token. Lo necesitamos — el admin usa la app todos los días y hoy el interceptor solo inyecta el `accessToken`.
- El `role` del login debe poder devolver **`SUPER_ADMIN`** además de `ADMIN` y `MEMBER`.
- Cambio de contraseña y flujo de recuperación por email.

### 9.4 Resumen del Inicio — bloquea E3

Pedimos un endpoint de resumen que devuelva en **una sola llamada**: cantidad de socios activos, cantidad en mora, y los próximos turnos del día. Si no es viable, son tres endpoints y el Inicio pasa a ser tres Cubits en vez de uno.

Definir además la **fuente de verdad de cada contador**: en las capturas el Inicio muestra 450 socios activos y el listado 245 totales. Son datos mock, pero no pueden quedar dos números distintos del mismo concepto en producción.

### 9.5 Pagos — bloquea E6

`GET /payments` con filtro por estado de cuota y por socio, y `POST /payments` para registrar un pago. Necesitamos los campos del pago (período, monto, medio, fecha) y qué se considera "cuota vencida".

### 9.6 ABM de administradores — bloquea E8

`GET / POST / PUT / DELETE` de administradores, restringido a `SUPER_ADMIN`. Necesitamos saber si la baja es física o lógica, y qué responde la API si un superAdmin intenta darse de baja a sí mismo.

### 9.7 Reporte de pagos — bloquea E10

Postergado por decisión de producto: no es necesario para las primeras entregas. Cuando se retome, definir endpoint, formato (PDF / Excel), si recibe lista de IDs de socios y rango de fechas, y si devuelve binario o URL descargable.

### 9.8 Reservas y superficie del socio — bloquea E9 y E12+

- **Disponibilidad**: un endpoint que devuelva las franjas libres de una cancha para una fecha. Debe resolverlo el backend — cruzar `reservation` + `court_block` + `recurring_slot` en el cliente es una fuente garantizada de bugs.
- **Cuota vencida y reservas**: ¿bloquea la reserva? Define si interceptamos antes de elegir horario.
- **Turnos fijos**: ¿generan `reservation` materializadas o son una regla evaluada al consultar disponibilidad?
- **Cancelación**: ¿hay ventana mínima de antelación?
- **Grupo familiar**: ¿el titular puede reservar a nombre de un integrante?
