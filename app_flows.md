# Mapa de Flujos, Pantallas y Entregas (`club-management-app`)

Documento de referencia del frontend: **qué pantallas existen, cómo se navega, qué ve cada rol, y en qué orden se entrega**. De acá salen los PRs (§8) y los pedidos al equipo de backend (§9).

No define píxeles. Define estructura, flujos, estados y alcance por entrega.

> **Revisión 2026-09-01.** La superficie del **administrador es el camino crítico**: se construye completa antes de la del socio. La paleta de §7 y la navegación del admin de §3.2 derivan de dos capturas de referencia (*Inicio - Administrador*, *Gestión de Socios - Administrador*); los hexadecimales están estimados visualmente y hay que confirmarlos. Backend: [club-management-api](https://github.com/lazzariniingenieria/club-management-api).
>
> Esta revisión incorpora la revisión del PR #3: §9 quedó alineada contra la implementación real de la API (verbos, códigos de error y contratos ya resueltos), el reset de contraseña se rediseñó como acción manual del admin (§3.1, §9.3), la fila de socio pasó a un badge combinado único (§3.2.2) y los pares de color de §7 se verificaron contra WCAG AA.

---

## 1. Principios de diseño

| Principio | Implicancia concreta |
| :--- | :--- |
| **Pocos pasos** | Máximo 3 toques desde el Inicio hasta confirmar cualquier flujo principal. |
| **Íconos con etiqueta, según superficie** | **Socio**: nunca un ícono solo (uso esporádico, rango de edad amplio). **Admin**: se permite ícono-only en filas densas, con `Semantics(label:)`, `tooltip` y área táctil de 48×48. |
| **Estado siempre explícito** | Nadie debe preguntarse "¿se guardó o no?". Confirmación textual, no solo cambio de color. |
| **El color nunca solo** | Todo estado va acompañado de texto o ícono. Daltonismo y pantallas al sol en el predio. Los pares texto/fondo cumplen **WCAG AA** (§7). |
| **Respetar la escala del sistema** | El layout tolera el `textScaleFactor` del usuario sin recortar ni desbordar. Criterio verificable, no intención: ver el "Terminado cuando" de E1. |
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

El **superAdmin comparte el shell del admin**: su único delta es la gestión de administradores. Un tercer shell duplicaría la barra entera por una sola pantalla extra. La diferencia se resuelve con un único punto de control — un getter `canManageAdmins` sobre el rol — que habilita el acceso en el Perfil. Una sola condición, en un solo lugar.

**El admin que reserva para sí mismo** no tiene modo especial: usa el flujo de reserva del admin y selecciona su propia cuenta de socio. La reserva es indistinguible de cualquier otra. Consecuencia a respetar: el paso de selección de socio está **siempre**, sin preseleccionar ni atajar casos.

---

## 3. Inventario de pantallas

### 3.1 Autenticación (fuera de los shells)

| Pantalla | Ruta | Estado |
| :--- | :--- | :--- |
| Splash / Bootstrap | `/` | A construir — resuelve sesión persistida y redirige (§3.1.1) |
| Login | `/login` | ✅ Implementada |
| Primer ingreso | `/login/activate` | A construir — CTA ya existe en `AppStrings.loginFirstTimeUser` |
| Recuperar contraseña | `/login/forgot` | A construir — **pantalla informativa**, no formulario (§3.1.2) |

#### 3.1.1 Splash — no es una pantalla instantánea

Es la primera pantalla que ve cualquier usuario y resuelve una sesión persistida contra el storage y, si hace falta, contra la red. Le aplican los mismos estados de §5 que a cualquier pantalla con datos remotos, sin excepción por ser el arranque:

| Caso | Tratamiento |
| :--- | :--- |
| Resolución rápida (< ~300 ms) | Logo estático. No se muestra spinner: parpadearía. |
| Resolución lenta | El logo suma un indicador de progreso, sin cambiar de pantalla. |
| **Timeout** (~5 s sin respuesta) | Se corta la espera y cae al login. Una sesión que no se pudo validar no bloquea el arranque. |
| **Error de red** | Si hay sesión persistida válida en storage, se entra igual y el 401 lo resuelve el interceptor. Si no, login con "No pudimos verificar tu sesión" + "Reintentar". |
| Sin sesión | Login directo, sin flash intermedio. |

La regla de fondo: **el Splash nunca es una pantalla sin salida**. Cualquier rama termina en el login o en el shell, nunca en un logo indefinido.

#### 3.1.2 Recuperar contraseña — no es self-service

El backend no expone ni va a exponer recuperación por email: **el reset de contraseña es una acción manual de un ADMIN o SUPER_ADMIN**, decisión de arquitectura ya tomada del lado de la API. La pantalla no puede ser un formulario de email porque no hay endpoint del otro lado.

Se construye entonces como pantalla informativa: explica que un administrador del club puede restablecer la contraseña, muestra el canal de contacto y ofrece volver al login. Sin campo de email, sin botón "Enviar" — un formulario que no manda nada a ningún lado es peor que no tener la pantalla.

### 3.2 Shell del Administrador

Bottom navigation navy, 3 items con ícono **y** etiqueta. Badge `RoleBadge` ("ADMINISTRADOR" / "SUPER ADMIN") en el header de toda pantalla del shell.

| Tab | Ruta | Contenido |
| :--- | :--- | :--- |
| **Inicio** | `/admin` | Resumen General + Accesos Rápidos (§3.2.1) |
| **Pagos** | `/admin/payments` | Cuotas con filtro por estado, registrar pago, detalle |
| **Perfil** | `/admin/profile` | Datos, cambiar contraseña, logout, y acceso a Administradores si `canManageAdmins` |

**Reservas entra como cuarto tab recién en E9**, cuando la agenda exista. Un tab que no hace nada, tocado varias veces por semana durante varios sprints, se lee como app rota, no como app simple: el costo de que la barra cambie de forma una vez es menor que el de sostener un tab muerto. Hasta entonces la agenda ya tiene presencia en el Inicio a través de `UpcomingSlotsCard` (§3.2.1), marcada como no navegable: ahí la ausencia se explica sola y no ocupa un lugar permanente en la navegación.

Rutas push, fuera de los tabs:

| Pantalla | Ruta | Rol |
| :--- | :--- | :--- |
| Gestión de socios | `/admin/members` | admin |
| Alta / edición de socio | `/admin/members/new`, `/admin/members/:memberId/edit` | admin |
| Reporte de pagos | `/admin/members/report` | admin |
| Gestión de canchas | `/admin/courts` | admin |
| Gestión de administradores | `/admin/admins` (+ `/new`, `/:adminId/edit`) | **superAdmin** |

**Socios y Canchas no son tabs.** Son tareas de sesión (entrás, resolvés, volvés); la barra inferior queda para lo que el admin mira varias veces por día.

#### 3.2.1 Inicio del Administrador

**Resumen General**

| Bloque | Contenido | Visual | Al tocar |
| :--- | :--- | :--- | :--- |
| `ActiveMembersCard` | "SOCIOS ACTIVOS" + contador | Card navy sólida, texto blanco | → `/admin/members` con filtro **Activos** |
| `OverdueMembersCard` | "SOCIOS EN MORA" + contador | Card azul claro, contador en rojo | → `/admin/members` con filtro **En mora** |
| `UpcomingSlotsCard` | "PRÓXIMOS TURNOS" + cancha / horario | Card azul claro, horario en azul a la derecha | → agenda (no navegable hasta E9) |

**Accesos Rápidos** — dos cards lado a lado: *Gestión de Socios* (navy) → `/admin/members` sin filtro, *Gestión de Canchas* (verde) → `/admin/courts`.

**Cada card lleva a lo que su título dice.** Un card que anuncia "SOCIOS EN MORA" con un número y abre el listado completo sin filtrar rompe la expectativa de manipulación directa en la primera pantalla que ve el admin, y le enseña a no confiar en que tocar algo específico devuelva algo específico. No es una mejora posterior: el filtro de mora ya se construye para los chips de §3.2.2, así que el costo es pasar un parámetro de ruta.

Las rutas reciben el filtro como query param (`/admin/members?filter=overdue`), no como estado global: así el listado es enlazable, el back del sistema devuelve al Inicio limpio y el filtro sobrevive a la restauración de estado del tab.

#### 3.2.2 Gestión de Socios

1. **Header**: "Socios" + `RoleBadge`.
2. **Buscador**: placeholder "Buscar socio por nombre o DNI". Debounce ~300 ms, la consulta la resuelve el backend.
3. **Filtros**: chips con contador — "Todos (n)", "Activos (n)", "Inactivos (n)", "En mora (n)". Seleccionado en navy sólido. *La captura dice "Inactivas"; va "Inactivos".*
4. **Listado**: `ListView.builder` paginado de `MemberListTile`. Cada fila: nombre, **badge de estado combinado**, acción **lápiz** → edición, acción **documento** → agrega o quita del reporte (con estado visual propio).
5. **Acción "Ver reporte"** en el `AppBar`, junto al buscador: ícono con badge de cantidad, deshabilitado en cero.
6. **FAB azul, abajo derecha**: crear socio → `/admin/members/new`. Es el único FAB de la pantalla.

**Los dos ejes de estado son independientes** (§9): `activo/inactivo` dice si sigue siendo socio; `al día/en mora` dice si la cuota está paga. Un socio puede estar **activo y en mora a la vez**, así que la fila tiene que poder mostrar ambos.

**Se resuelven en un solo badge, no en dos indicadores.** La pantalla es la de mayor densidad de datos de la app; barra de acento más dos pills serían cinco o seis elementos compitiendo por atención en cada fila. Un único badge con texto y color transmite lo mismo con un elemento:

| Estado | Badge | Color |
| :--- | :--- | :--- |
| Activo, cuota paga | "Activo · Al día" | `successSurface` / `successText` |
| Activo, cuota impaga | "Activo · En mora" | `dangerSurface` / `dangerText` |
| Inactivo | "Inactivo" | gris neutro |

**Un socio inactivo no muestra estado de cuota**: dejó de ser socio, la cuota del mes no le aplica y mostrarla invita a cobrarle. Los chips filtran por cualquiera de los dos ejes; el badge muestra siempre los dos cuando corresponde.

**"Ver reporte" no es un FAB.** Material desaconseja varios FABs porque diluyen la señal de una acción primaria por pantalla, y el reporte es una consulta de estado acumulado, no una acción de creación: encaja como ícono con badge en el `AppBar`. Así queda un solo FAB real — crear socio — y el problema se resuelve en la raíz en vez de mitigarse con una etiqueta.

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
Inicio ──[Socios activos ⇒ filtro Activos ]──►
       ──[Socios en mora  ⇒ filtro En mora ]──►  Gestión de Socios
       ──[Gestión de Socios ⇒ sin filtro   ]──►
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
- El DNI duplicado lo valida el backend con un **409** y un código estable: la app lo mapea a un mensaje en el campo `dni`, no a un snackbar genérico (§9.2).
- Al volver de un alta exitosa el listado refresca y hace scroll al socio creado.
- Abandonar un formulario con cambios pide confirmación. La búsqueda y el filtro sobreviven a la ida y vuelta.

### 4.2 Registrar un pago

`Pagos → filtro "vencidas" → socio → Registrar pago → Confirmar → Listado actualizado`

Impacta en dinero: confirmación con resumen (socio, período, monto, medio) antes de escribir.

### 4.3 ABM de administradores (solo superAdmin)

`Perfil → Administradores → [+ | lápiz | baja | reactivar] → Confirmar`

- **La baja es lógica y reversible** (`PATCH /api/admins/{id}/deactivate`, con `/reactivate` del otro lado). No hay borrado físico en la API.
- Por eso la confirmación es un diálogo estándar con copy claro — *"¿Dar de baja a Juan Pérez? Vas a poder reactivarlo cuando quieras."* — y **no** el patrón de escribir el nombre. Ese patrón se reserva para acciones genuinamente irreversibles; gastarlo en algo que se deshace con un tap es fricción sin contrapartida, y lo deja desgastado para el día que exista una acción que sí lo amerite.
- Un admin dado de baja sigue en el listado, marcado como inactivo, con la acción de reactivar en su fila. Desaparecer de la lista al desactivar hace creer que se borró.
- **No hace falta lógica defensiva contra la auto-baja del superAdmin**: `GET /api/admins` solo devuelve cuentas con `role = ADMIN`, y el SUPER_ADMIN es una única cuenta seedeada en base que nunca aparece en ese listado. No existe la fila que se podría tocar por error.

### 4.4 Reservar una cancha (admin)

`Reservas → Nueva → Seleccionar socio → Cancha → Horario → Confirmar → Éxito`

- El paso de selección de socio está siempre, también cuando el admin reserva para sí mismo (§2).
- La fecha arranca en **hoy**. Las franjas ocupadas se muestran **deshabilitadas con motivo** ("Ocupado", "Mantenimiento", "Turno fijo"), no ocultas: ocultarlas hace creer que la app está rota.
- La confirmación es una pantalla, no un diálogo.

### 4.5 Bloquear una cancha (admin)

`Reservas → Bloquear → Rango + motivo → Confirmar → Agenda actualizada`

Si el bloqueo pisa reservas existentes, la confirmación **debe listar las reservas afectadas** y decir qué pasa con ellas. Es el flujo con mayor potencial de daño de la app.

### 4.6 Reporte de pagos

`Gestión de Socios → [ícono documento en n filas] → acción "Ver reporte" del AppBar → Reporte`

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
│   ├── branch: /admin/payments      → Pagos
│   ├── branch: /admin/profile       → Perfil
│   └── branch: /admin/reservations  → Agenda        ← se suma en E9
├── rutas push del admin
│   ├── /admin/members  (+ /new, /:memberId/edit, /report)   ?filter=all|active|inactive|overdue
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
| `brandGreen` | `#12784A` | Card "Gestión de Canchas" |
| `accentBlue` | `#2563EB` | FAB de crear socio, horarios, enlaces |
| `infoSurface` | `#DDE7F7` | Fondo de cards informativas (mora, próximos turnos) |
| `successSurface` / `successText` | `#C8EFD9` / `#0F6B41` | Badge "Activo · Al día", `RoleBadge` |
| `dangerSurface` / `dangerText` | `#FADBDB` / `#B3261E` | Badge "Activo · En mora", contador de mora |
| `background` / `surface` | `#F4F6F9` / `#FFFFFF` | Fondo de pantalla / cards y campos |
| `textSecondary` | `#5B6472` | Placeholders y labels |

#### Contraste verificado — WCAG AA

§1 fija pantallas al sol en el predio y rango etario amplio como restricciones reales, así que los pares se miden antes de fijarse como tokens, no después. Mínimo exigido: **4.5:1** para texto normal.

| Par | Ratio | AA |
| :--- | :--- | :--- |
| `dangerText` sobre `dangerSurface` | 5.05 | ✅ |
| `successText` sobre `successSurface` | 5.25 | ✅ |
| `textSecondary` sobre `background` | 5.53 | ✅ |
| `textSecondary` sobre `surface` | 5.98 | ✅ |
| `brandNavy` sobre `background` | 14.58 | ✅ |
| `brandNavy` sobre `infoSurface` | 12.67 | ✅ |
| `accentBlue` sobre `surface` | 5.17 | ✅ |
| blanco sobre `brandNavy` | 15.79 | ✅ |
| blanco sobre `brandGreen` | 5.51 | ✅ |

Dos valores se corrigieron a partir de esta medición, antes de que quedaran fijados: `dangerText` era `#D32F2F` (**3.85** sobre `dangerSurface`, por debajo del mínimo) y `textSecondary` era `#6B7280` (**4.47** sobre `background`, apenas corto). Ambos son ajustes de luminosidad sobre el mismo tono, así que la lectura visual frente a las capturas no cambia.

**Separar la rampa de marca de la semántica aunque hoy compartan tono.** El verde de la card "Gestión de Canchas" es `brandGreen`; el del badge "Al día" es `successText`. Si mañana "al día" cambia de color, no se arrastra el FAB. Igual con `accentBlue` (acción) frente a `infoSurface` (información). Es lo que se degrada solo si no se explicita ahora.

**Tipografía**: Inter (ya está vía `google_fonts`), cuerpo en 16sp.

**Modo oscuro fuera de alcance.** Las capturas son un diseño *light*. Un `darkTheme` inventado sobre una identidad ajena es deuda, no feature.

---

## 8. Entregas

Vertical slices: cada PR entrega una feature de punta a punta (`domain` → `data` → `presentation`) con sus estados y sus tests. Antes de cerrar cada una: `flutter analyze` sin warnings y suite verde.

| # | Entrega | Depende de backend | Estado |
| :--- | :--- | :--- | :--- |
| **E1** | **Migración de paleta y theming de lo ya construido** | — | ✅ Entregada |
| **E2** | **Base de conexión + shell del admin** | — (contra fakes) | Próxima |
| E3 | Inicio del Administrador | §9.4 | — |
| E4 | Gestión de socios: listado, búsqueda, filtros, paginación | §9.1 | — |
| E5 | Alta y edición de socio | §9.2 | — |
| E6 | Pagos del admin: listado, registrar pago, detalle | §9.5 | — |
| E7 | Perfil del admin + cambiar contraseña + logout | §9.3 | — |
| E8 | ABM de administradores (superAdmin) | §9.6 | — |
| E9 | Agenda / Reservas + canchas + bloqueos | §9.8 | — |
| E10 | Reporte de pagos | §9.7 | — |
| E11 | Recuperar contraseña (informativa) + primer ingreso | §9.3 | — |
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

**Terminado cuando**:
- El login se ve con la paleta nueva y `/dev/gallery` muestra el catálogo completo.
- Todos los pares texto/fondo de §7 dan **≥ 4.5:1**, medidos, no estimados.
- La galería y el login se ven **a 130% y a 200% de escala de sistema sin overflow ni texto recortado** — verificado a mano en el emulador, no asumido. Es un criterio de aceptación, no un principio: sin número y sin pantalla concreta, es lo primero que se cae ante presión de tiempo.
- `flutter analyze` limpio y los tests existentes en verde.

### E2 — Base de conexión + shell del admin

Dejar la conexión al backend **armada y lista**, sin depender de que la API esté disponible.

- `--dart-define=API_BASE_URL` con el **remoto por defecto**: hoy [api_client.dart](lib/core/network/api_client.dart) tiene `localhost` hardcodeado como default, contra lo que fija el `CLAUDE.md`.
- Centralizar endpoints en `core/constants/api_constants.dart` en lugar de strings dispersos por los data sources.
- Sumar `superAdmin` al enum `UserRole` de [user.dart](lib/features/auth/domain/entities/user.dart) y al mapeo del `UserModel`.
- Interceptor de refresco de token en el `ApiClient`, detrás del contrato de §9.3. Queda escrito y testeado contra un mock aunque el endpoint todavía no exista.
- **Fake data sources por flavor**: cada repositorio con implementación remota y una fake seleccionada por `--dart-define`. Es lo que permite construir E3–E8 sin backend, y lo que el `CLAUDE.md` ya pide ("UI development con datos mockeados"). Los fakes viven junto a la implementación remota, detrás de la misma interfaz de `domain`.
- `AuthBloc` de sesión + Splash con los estados de §3.1.1 + guards de §6.
- Shell del admin con los 3 tabs de §3.2.

**Terminado cuando**: se puede navegar el shell completo del admin contra fakes, cambiar a remoto solo con un `--dart-define`, un build de release con fakes **falla al arrancar** en lugar de entregar cuentas de prueba, y los guards se testean por rol (`member`, `admin`, `superAdmin`).

### E5 — Alta y edición de socio

Las dos primeras pantallas de escritura de la app. El contrato con el backend está en §9.2; lo que define esta entrega es el comportamiento del formulario, que es donde se juega la usabilidad.

**Validación**: híbrida, no una sola estrategia.
- **Al perder el foco** se valida el campo que se abandona, solo si el usuario ya escribió algo. Validar mientras se tipea marca en rojo un DNI a medio escribir; validar recién al enviar obliga a recorrer el formulario de nuevo.
- **Al enviar** se validan todos los campos, se hace foco y scroll al primero con error.
- El mensaje va **debajo del campo**, en `dangerText`, y el campo queda con borde de error. Nunca en un snackbar: se va solo y no dice a qué campo corresponde.
- Un campo con error se limpia en cuanto pasa a ser válido, sin esperar al submit.

**Teclado y formato**: `TextInputType.number` para DNI, `TextInputType.phone` para teléfono, `emailAddress` para email, capitalización de palabras en nombre y apellido. Un admin cargando socios de a diez no debería cambiar de teclado a mano.

**Errores del servidor**: el 409 de DNI duplicado se mapea al campo `dni` por el `code` de la respuesta, no por el texto del mensaje (§9.2). El resto de los campos conserva lo cargado.

**Terminado cuando**: alta y edición funcionan contra fakes y contra la API, el DNI duplicado se muestra en el campo, abandonar con cambios pide confirmación, y hay tests de widget de la validación y unitarios del mapeo DTO ↔ dominio.

El orden E4 → E5 → E10 es intencional: listado antes de escrituras, y el reporte al final porque depende del listado y de un contrato todavía abierto.

---

## 9. Necesidades del backend

Lista para enviar al equipo de [club-management-api](https://github.com/lazzariniingenieria/club-management-api). Ordenada por la entrega que bloquea.

**Pedidos ya redactados**: [backend_request_e2_e3.md](backend_request_e2_e3.md) cubre E2 y E3 (§9.3 y §9.4), sin el bloque de próximos turnos. Al 2026-08-27 la API todavía no tiene código — solo `README` con el diseño previsto — así que estos pedidos son acuerdos de contrato previos a la implementación, no consultas sobre lo existente.

**Ya definido, a reflejar en la API:**
- `activo/inactivo` (sigue siendo socio) y `al día/en mora` (estado de cuota) son **dos campos independientes**: la API los expone por separado y ambos son filtrables.
- El **filtrado y la búsqueda los resuelve el backend**, no el cliente.
- El listado de socios es **paginado**.
- El alta de socio crea **solo `member`**, no `user_account`.

**Ya resuelto del lado de la API — no se pide, se consume.** Confirmado contra `develop` de `club-management-api`:

| Punto | Estado |
| :--- | :--- |
| Verbos HTTP | La API usa **`GET` / `POST` / `PATCH`**. No existe `PUT` ni `DELETE` en ningún endpoint del proyecto. |
| DNI duplicado | Devuelve **`409 Conflict`** con mensaje específico, no un 400 genérico. La app distingue por status code. |
| Alta de socio | El **`201`** de `POST /api/members` ya devuelve el `MemberResponse` completo. |
| Rol en el login | `LoginResponse.role` ya devuelve el enum completo: `SUPER_ADMIN` / `ADMIN` / `MEMBER`. |
| Bajas | Siempre **lógicas** (booleano `active`), nunca borrado físico, con endpoint de reactivación. |
| Reset de contraseña | Es una **acción manual de un ADMIN o SUPER_ADMIN**. No hay ni va a haber flujo self-service por email. |
| Refresh token | **No existe hoy, ni parcialmente.** Es una feature nueva de cero (§9.3). |

### 9.1 Listado de socios — bloquea E4

`GET /api/members` con paginación, búsqueda por nombre y DNI, y filtro por estado. Necesitamos:
- Nombres exactos de los parámetros de paginación, búsqueda y filtro.
- Shape de la respuesta con metadata de paginación (total de elementos, total de páginas, página actual). Tamaño de página objetivo: **20**.
- Cada socio con **ambos** campos de estado, más `id`, nombre completo y DNI.
- Contadores por estado para los chips ("Todos / Activos / Inactivos / En mora"), en la misma respuesta para no pedir cuatro veces.
- Que el filtro acepte **los dos ejes a la vez** (activo + en mora), porque el Inicio entra pre-filtrado por mora (§3.2.1).

### 9.2 Alta y edición de socio — bloquea E5

`POST /api/members` y **`PATCH /api/members/{memberId}`** — la edición es `PATCH`, no `PUT`; sigue siendo reemplazo completo (van todos los campos igual), solo cambia el verbo. Codearlo como `PUT` da **405** contra la API real.

Ya resuelto: el DNI duplicado devuelve **409** y el 201 trae el `MemberResponse` completo. Lo que falta:
- Campos obligatorios y opcionales, con sus validaciones (formato de DNI, largo de nombre).
- El **`code` estable** dentro del cuerpo del 409, para mapear el error al campo sin hacer matching sobre el texto del mensaje.
- Si el alta admite cargar el **último mes pagado**, para que un socio que entra con deuda previa no aparezca al día desde el minuto cero.

### 9.3 Autenticación — bloquea E2 y E7

- `POST /auth/refresh`: contrato del refresco de token. **Es una feature nueva**, confirmado que hoy no existe ningún concepto de refresh en el backend. Se construye del lado de la app contra un mock mientras tanto, pero el contrato hay que acordarlo antes de integrar. Lo importante: TTL de cada token, si el `refreshToken` rota, y **qué status devuelve un refresh vencido o revocado** — si es un 401 indistinguible del otro, la app entra en bucle de refresco.
- Cambio de contraseña del propio usuario logueado.
- **Reset de contraseña de un tercero**: endpoint para que un ADMIN o SUPER_ADMIN restablezca la contraseña de otra cuenta. Es el modelo que ya eligió el backend y el que consume §3.1.2; no pedimos recuperación por email.

### 9.4 Resumen del Inicio — bloquea E3

Pedimos un endpoint de resumen que devuelva en **una sola llamada**: cantidad de socios activos, cantidad en mora, y los próximos turnos del día. Si no es viable, son tres endpoints y el Inicio pasa a ser tres Cubits en vez de uno.

Definir además la **fuente de verdad de cada contador**: en las capturas el Inicio muestra 450 socios activos y el listado 245 totales. Son datos mock, pero no pueden quedar dos números distintos del mismo concepto en producción.

### 9.5 Pagos — bloquea E6

`GET /api/payments` con filtro por estado de cuota y por socio, y `POST /api/payments` para registrar un pago. Necesitamos los campos del pago (período, monto, medio, fecha) y qué se considera "cuota vencida".

### 9.6 ABM de administradores — bloquea E8

Contrato ya confirmado, se documenta acá para que la app codee contra esto y no contra una suposición:

| Operación | Endpoint |
| :--- | :--- |
| Listar | `GET /api/admins` — solo cuentas con `role = ADMIN` |
| Crear | `POST /api/admins` |
| Editar | `PATCH /api/admins/{id}` |
| Dar de baja | `PATCH /api/admins/{id}/deactivate` |
| Reactivar | `PATCH /api/admins/{id}/reactivate` |

La baja es **lógica** (booleano `active`) y reversible; no hay `DELETE`. El **SUPER_ADMIN es una única cuenta seedeada en base**, sin pantalla de alta, y nunca aparece en el listado — así que la app no necesita defenderse de una auto-baja (§4.3).

Lo que falta: campos del alta de un admin y si la contraseña inicial la define el SUPER_ADMIN o la genera la API.

### 9.7 Reporte de pagos — bloquea E10

Postergado por decisión de producto: no es necesario para las primeras entregas. Cuando se retome, definir endpoint, formato (PDF / Excel), si recibe lista de IDs de socios y rango de fechas, y si devuelve binario o URL descargable.

### 9.8 Reservas y superficie del socio — bloquea E9 y E12+

- **Disponibilidad**: un endpoint que devuelva las franjas libres de una cancha para una fecha. Debe resolverlo el backend — cruzar `reservation` + `court_block` + `recurring_slot` en el cliente es una fuente garantizada de bugs.
- **Cuota vencida y reservas**: ¿bloquea la reserva? Define si interceptamos antes de elegir horario.
- **Turnos fijos**: ¿generan `reservation` materializadas o son una regla evaluada al consultar disponibilidad?
- **Cancelación**: ¿hay ventana mínima de antelación?
- **Grupo familiar**: ¿el titular puede reservar a nombre de un integrante?
