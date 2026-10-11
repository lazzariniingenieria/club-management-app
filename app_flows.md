# Mapa de Flujos, Pantallas y Entregas (`club-management-app`)

Documento de referencia del frontend: **qué pantallas existen, cómo se navega, qué ve cada rol, y en qué orden se entrega**. De acá salen los PRs (§8).

No define píxeles. Define estructura, flujos, estados y alcance por entrega.

> **Estado al 2026-10-06.** La superficie del **administrador es el camino crítico**: se construye completa antes de la del socio, y va entregada hasta E4. La paleta de §7 y la navegación de §3.2 derivan de dos capturas de referencia; los hexadecimales están estimados visualmente y hay que confirmarlos.
>
> **El contrato de la API no se documenta acá**: vive en [backend_api.md](backend_api.md), verificado contra `develop`. Este archivo manda en pantallas, flujos y entregas; ese otro manda en endpoints, shapes, errores y reglas del servidor.

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
| Splash / Bootstrap | `/` | ✅ Implementada — resuelve sesión persistida y redirige (§3.1.1) |
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
| **Pagos** | `/admin/payments` | Listado de socios con buscador y chips Todos / En mora / A cobrar (§3.2.2) |
| **Perfil** | `/admin/profile` | Datos, cambiar contraseña, logout, y acceso a Administradores si `canManageAdmins` |

**Reservas entra como cuarto tab recién en E9**, cuando la agenda exista. Un tab que no hace nada, tocado varias veces por semana durante varios sprints, se lee como app rota, no como app simple: el costo de que la barra cambie de forma una vez es menor que el de sostener un tab muerto. Hasta entonces la agenda no tiene presencia en ninguna superficie: el `UpcomingSlotsCard` de §3.2.1 se diseñó y quedó **sin construir**, porque un card que no puede mostrar ni un turno real es un hueco anunciado, no una pista útil. Entra con la agenda.

Rutas push, fuera de los tabs:

| Pantalla | Ruta | Rol | Entrega |
| :--- | :--- | :--- | :--- |
| Alta / edición de socio | `/admin/members/new`, `/admin/members/:memberId/edit` | admin | E5 |
| Reporte de pagos | `/admin/payments/report` | admin | E10 |
| Gestión de canchas | `/admin/courts` | admin | E9 |
| Gestión de administradores | `/admin/admins` (+ `/new`, `/:adminId/edit`) | **superAdmin** | E8 |

**El listado de socios vive dentro del tab Pagos, no en una pantalla aparte.** El diseño original lo tenía como ruta push en `/admin/members`, con un tab Pagos separado para las cuotas. Son la misma tarea: el admin abre la lista de socios *para cobrar*, y partirla en dos superficies obligaba a saltar entre ellas para resolver un solo trámite. Una pantalla menos, un tab que ahora hace algo, y el estado del listado lo preserva el `StatefulShellRoute` en lugar de reconstruirse en cada push.

**Canchas sigue sin ser tab.** Es una tarea de sesión (entrás, resolvés, volvés); la barra inferior queda para lo que el admin mira varias veces por día.

#### 3.2.1 Inicio del Administrador

**Resumen General**

| Bloque | Contenido | Visual | Al tocar |
| :--- | :--- | :--- | :--- |
| `ActiveMembersCard` | "SOCIOS ACTIVOS" + contador | Card navy sólida, texto blanco | → tab **Pagos** con el chip **Todos** |
| `OverdueMembersCard` | "SOCIOS EN MORA" + contador | Card azul claro, contador en rojo | → tab **Pagos** con el chip **En mora** |
| `UpcomingSlotsCard` **(E9, sin construir)** | "PRÓXIMOS TURNOS" + cancha / horario | Card azul claro, horario en azul a la derecha | → agenda |

**Accesos Rápidos** — dos cards lado a lado: *Gestión de Socios* (navy) → tab **Pagos** con el chip **Todos**, *Gestión de Canchas* (verde) → `/admin/courts`.

**Cada card lleva a lo que su título dice.** Un card que anuncia "SOCIOS EN MORA" con un número y abre el listado completo sin filtrar rompe la expectativa de manipulación directa en la primera pantalla que ve el admin, y le enseña a no confiar en que tocar algo específico devuelva algo específico. No es una mejora posterior: el filtro de mora ya se construye para los chips de §3.2.2, así que el costo es pasar un parámetro de ruta.

El filtro viaja como query param (`/admin/payments?filter=overdue`), no como estado global ni como estado interno del listado: así el listado es enlazable y, sobre todo, cada card vuelve a imponer *su* filtro. Si el chip activo viviera solo en el Cubit, un admin que cambió de chip a mano y después tocara "Socios activos" se encontraría con el filtro anterior, porque la URL del branch no habría cambiado y no habría nada que avisara al listado.

Los tres contadores de los chips (§3.2.2) salen del mismo listado que ya está en memoria, así que cambiar de chip no vuelve a pegarle a la API.

#### 3.2.2 Pagos — listado de socios y cobranza

1. **Header**: "Pagos" + `RoleBadge`.
2. **Buscador**: placeholder "Buscar socio por nombre o DNI...". Lo resuelve el cliente sobre el padrón ya cargado, porque la API no expone búsqueda; ignora mayúsculas y acentos, así que "alvarez" encuentra a "Álvarez".
3. **Filtros**: tres chips con contador — "Todos (n)", "En mora (n)", "A cobrar (n)". Seleccionado en navy sólido.
4. **Listado**: `ListView.builder` de `MemberListTile`, ordenado por apellido. Cada fila: nombre, badge **Activo / Inactivo**, acción **lápiz** → edición, acción **documento** → agrega o quita del reporte, con estado visual propio.
5. **Botón "Generar reporte (n)"** al pie, visible solo con el chip "A cobrar" seleccionado y una selección no vacía.
6. **FAB azul, abajo derecha**: crear socio. Es el único FAB de la pantalla.

**Qué filtra cada chip**:

| Chip | Contenido |
| :--- | :--- |
| **Todos** | Todo el padrón, activos e inactivos |
| **En mora** | Socios con la cuota vencida (`daysOverdue > 0`) |
| **A cobrar** | Los socios que el admin fue marcando con el ícono de documento, y que alimentan el reporte |

**"A cobrar" no es un filtro de estado, es una canasta.** Los otros dos chips se llenan solos con lo que devuelve la API; este se llena a mano, fila por fila. Reemplaza al botón flotante con badge que las capturas tenían abajo a la izquierda: dos FABs en la misma pantalla diluyen cuál es la acción primaria, y el reporte no es una acción de creación sino un estado acumulado — que es exactamente lo que un chip con contador comunica. Así queda un solo FAB real, crear socio.

**La selección vive mientras la app esté abierta.** Sobrevive a cambiar de chip, a buscar, a ir al Inicio y volver, y a un pull-to-refresh — donde un socio que ya no está en el padrón se cae de la selección en lugar de quedar colgado. No se persiste en el dispositivo: el reporte cierra una jornada de cobranza, no es un estado de largo plazo.

**El badge de la fila muestra un solo eje: Activo / Inactivo.**

| Estado | Badge | Color |
| :--- | :--- | :--- |
| Activo | "Activo" | `successSurface` / `successText` |
| Inactivo | "Inactivo" | `disabledSurface` / `textSecondary` |

Los dos ejes de estado siguen siendo independientes en el dominio (§9): `activo/inactivo` dice si sigue siendo socio, `al día/en mora` dice si la cuota está paga, y un socio puede estar activo y en mora a la vez. Lo que cambió es cómo se muestran: la mora se consulta entrando al chip "En mora", no leyendo fila por fila. **Consecuencia asumida**: en "Todos" no se distingue a simple vista quién debe. Si molesta en uso real, el badge combinado ("Activo · En mora") ya está diseñado y es un cambio de una sola función.

**Cuatro vacíos distintos, no uno** (§5): padrón sin socios, "ningún socio está en mora", "todavía no marcaste socios para el reporte" y búsqueda sin resultados con acción "Limpiar búsqueda". El tercero es el que más trabaja: es donde el admin descubre cómo se arma el reporte.

**Acciones todavía deshabilitadas**: el FAB de alta (E5), el lápiz de edición (E5) y el botón de reporte (E10) se dibujan en gris y, al tocarlos, explican en qué entrega se habilitan. Dibujarlos apagados en vez de ocultarlos deja la pantalla con su forma definitiva y evita que las filas y el pie cambien de layout en cada entrega.

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
Inicio ──[Socios activos    ⇒ chip Todos   ]──►
       ──[Socios en mora     ⇒ chip En mora ]──►  tab Pagos
       ──[Gestión de Socios  ⇒ chip Todos   ]──►
                                         │
                    ┌────────────────────┼────────────────────┐
                    ▼                    ▼                    ▼
              [FAB + ]             [lápiz fila]        [buscar / chips]
                    │                    │
              Alta de socio       Edición de socio
                    └──────────┬─────────┘
                               ▼
                        Confirmar ──► Listado actualizado
```

- La búsqueda y el filtrado hoy los resuelve el cliente sobre el padrón completo, porque la API devuelve la lista entera sin paginar ni filtrar. Sirve con los ~245 socios del club; cuando el backend exponga paginación, el listado pasa a "cargando más" al pie y el mapeo no cambia.
- El DNI duplicado lo valida el backend y se muestra en el campo, no en un snackbar genérico (E5).
- Al volver de un alta exitosa el listado refresca y hace scroll al socio creado.
- Abandonar un formulario con cambios pide confirmación. La búsqueda y el filtro sobreviven a la ida y vuelta.

### 4.2 Registrar un pago

`Pagos → filtro "vencidas" → socio → Registrar pago → Confirmar → Listado actualizado`

Impacta en dinero: confirmación con resumen (socio, período, monto, medio) antes de escribir.

### 4.3 ABM de administradores (solo superAdmin)

`Perfil → Administradores → [+ | lápiz | baja | reactivar] → Confirmar`

- **La baja es lógica y reversible**, nunca un borrado.
- Por eso la confirmación es un diálogo estándar con copy claro — *"¿Dar de baja a Juan Pérez? Vas a poder reactivarlo cuando quieras."* — y **no** el patrón de escribir el nombre. Ese patrón se reserva para acciones genuinamente irreversibles; gastarlo en algo que se deshace con un tap es fricción sin contrapartida, y lo deja desgastado para el día que exista una acción que sí lo amerite.
- Un admin dado de baja sigue en el listado, marcado como inactivo, con la acción de reactivar en su fila. Desaparecer de la lista al desactivar hace creer que se borró.
- **No hace falta lógica defensiva contra la auto-baja del superAdmin**: el listado de la API nunca devuelve esa cuenta, así que no existe la fila que se podría tocar por error.

### 4.4 Reservar una cancha (admin)

`Reservas → Nueva → Seleccionar socio → Cancha → Horario → Confirmar → Éxito`

- El paso de selección de socio está siempre, también cuando el admin reserva para sí mismo (§2).
- La fecha arranca en **hoy**. Las franjas ocupadas se muestran **deshabilitadas con motivo** ("Ocupado", "Mantenimiento", "Turno fijo"), no ocultas: ocultarlas hace creer que la app está rota.
- La confirmación es una pantalla, no un diálogo.

### 4.5 Bloquear una cancha (admin)

`Reservas → Bloquear → Rango + motivo → Confirmar → Agenda actualizada`

Si el bloqueo pisa reservas existentes, la confirmación **debe listar las reservas afectadas** y decir qué pasa con ellas. Es el flujo con mayor potencial de daño de la app.

### 4.6 Reporte de pagos

`Pagos → [ícono documento en n filas] → chip "A cobrar" → Generar reporte`

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

**Cuatro vacíos distintos en el listado de socios**, error clásico tratarlos igual: padrón sin socios, ningún socio en mora (que es una buena noticia, no un error), reporte sin marcar (que tiene que explicar cómo se marca) y búsqueda sin resultados → "Limpiar búsqueda".

**Consecuencia técnica**: un `AsyncStateBuilder` compartido en `shared/widgets/` que reciba el estado del Cubit y los builders de cada caso, para no reimplementar el árbol de estados por pantalla.

---

## 6. Router y guards

Estructura de [app_router.dart](lib/core/router/app_router.dart), construida en E2 salvo el shell del socio:

```
GoRouter
├── /                              → SplashScreen (resuelve sesión)
├── /login                          (+ /activate, /forgot ← se suman en E11)
├── /member                         → superficie del socio en preparación
├── StatefulShellRoute (admin + superAdmin)
│   ├── branch: /admin              → Inicio
│   ├── branch: /admin/payments      → Pagos   ?filter=all|overdue|to-collect
│   ├── branch: /admin/profile       → Perfil
│   └── branch: /admin/reservations  → Agenda        ← se suma en E9
├── rutas push del admin
│   ├── /admin/members/new, /admin/members/:memberId/edit  ← se suman en E5
│   ├── /admin/payments/report                        ← se suma en E10
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

Esto requiere un `AuthBloc` de sesión, separado del `LoginCubit` de formulario que ya existe. Ambos existen desde E2; los seis guards se testean por rol.

---

## 7. Dirección visual

Paleta derivada de las capturas. **Valores estimados visualmente, a confirmar.**

| Token | Hex | Uso |
| :--- | :--- | :--- |
| `brandNavy` | `#0C2340` | Bottom nav, cards destacadas, chip activo, texto primario |
| `brandGreen` | `#12784A` | Card "Gestión de Canchas" |
| `accentBlue` | `#2563EB` | FAB de crear socio, horarios, enlaces |
| `infoSurface` | `#DDE7F7` | Fondo de cards informativas (mora, próximos turnos) |
| `successSurface` / `successText` | `#C8EFD9` / `#0F6B41` | Badge "Activo" de la fila de socio, `RoleBadge` |
| `dangerSurface` / `dangerText` | `#FADBDB` / `#B3261E` | Contador de mora, errores de campo |
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

**Separar la rampa de marca de la semántica aunque hoy compartan tono.** El verde de la card "Gestión de Canchas" es `brandGreen`; el del badge "Activo" es `successText`. Si mañana el estado del socio cambia de color, no se arrastra la card. Igual con `accentBlue` (acción) frente a `infoSurface` (información). Es lo que se degrada solo si no se explicita ahora.

**Tipografía**: Inter (ya está vía `google_fonts`), cuerpo en 16sp.

**Modo oscuro fuera de alcance.** Las capturas son un diseño *light*. Un `darkTheme` inventado sobre una identidad ajena es deuda, no feature.

---

## 8. Entregas

Vertical slices: cada PR entrega una feature de punta a punta (`domain` → `data` → `presentation`) con sus estados y sus tests. Antes de cerrar cada una: `flutter analyze` sin warnings y suite verde.

La columna **Falta backend** dice si la entrega necesita algo que la API todavía no expone; qué le falta exactamente a cada una está en [backend_api.md](backend_api.md) §10.

| # | Entrega | Falta backend | Estado |
| :--- | :--- | :--- | :--- |
| **E1** | **Migración de paleta y theming de lo ya construido** | — | ✅ Entregada |
| **E2** | **Base de conexión + shell del admin** | — (contra fakes) | ✅ Entregada |
| E3 | Inicio del Administrador | — | ✅ Entregada |
| E4 | Pagos: padrón de socios, búsqueda, chips y selección para el reporte | — | ✅ Entregada |
| E5 | Alta y edición de socio | No bloquea | — |
| E6 | Registrar un pago y detalle de cuotas, sobre el listado de E4 | **Sí** | — |
| E7 | Perfil del admin + cambiar contraseña + logout | **Sí** | — |
| E8 | ABM de administradores (superAdmin) | No bloquea | — |
| E9 | Agenda / Reservas + canchas + bloqueos | **Bloqueada** | — |
| E10 | Reporte de pagos | **Bloqueada** | — |
| E11 | Recuperar contraseña (informativa) + primer ingreso | **Sí** | — |
| E12+ | Superficie del socio completa | **Bloqueada** | — |

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
- Interceptor de refresco de token en el `ApiClient`, detrás del contrato acordado. Quedó escrito y testeado contra un mock antes de que el endpoint existiera.
- **Fake data sources por flavor**: cada repositorio con implementación remota y una fake seleccionada por `--dart-define`. Es lo que permite construir E3–E8 sin backend, y lo que el `CLAUDE.md` ya pide ("UI development con datos mockeados"). Los fakes viven junto a la implementación remota, detrás de la misma interfaz de `domain`.
- `AuthBloc` de sesión + Splash con los estados de §3.1.1 + guards de §6.
- Shell del admin con los 3 tabs de §3.2.

**Terminado cuando**: se puede navegar el shell completo del admin contra fakes, cambiar a remoto solo con un `--dart-define`, un build de release con fakes **falla al arrancar** en lugar de entregar cuentas de prueba, y los guards se testean por rol (`member`, `admin`, `superAdmin`).

### E3 — Inicio del Administrador

Primera pantalla de la app que lee datos reales del club.

- **Sin endpoint de resumen**: los dos contadores se arman con `GET /api/members` y `GET /api/payments/delinquency`, las dos llamadas en paralelo y un solo estado de carga. Un endpoint de resumen sigue siendo una mejora posible, no un bloqueo.
- `ActiveMembersCard` y `OverdueMembersCard`, ambas navegan a `/admin/members` sin pre-filtro. *(E4 las repuntó al tab Pagos, cada una con su chip — §3.2.1.)*
- Accesos rápidos a *Gestión de socios* y *Gestión de canchas*.
- **"Próximos turnos" queda fuera**: la API todavía no tiene canchas ni reservas. Se suma en E9, con la agenda.
- Estados de §5 resueltos en la pantalla: skeleton con la forma de las cards, error con "Reintentar" que no tapa los accesos rápidos, y pull-to-refresh para volver a pedir el resumen.

**Terminado cuando**: el Inicio muestra ambos contadores contra la API real, un fallo de red se explica y se puede reintentar sin salir de la pantalla, y los accesos rápidos abren las pantallas de socios y canchas.

### E4 — Pagos: padrón de socios y selección de cobranza

El listado de socios deja de ser una pantalla aparte y pasa a ser **el contenido del tab Pagos** (§3.2.2). Con eso desaparece `/admin/members` como ruta push y el tab deja de ser un placeholder.

- Tres chips con contador en lugar de cuatro: **Todos**, **En mora** y **A cobrar**. Los dos primeros se derivan de la API; el tercero es la canasta manual que reemplaza al FAB verde de las capturas.
- El filtro viaja por query param, así que las tres entradas del Inicio (card de activos, card de mora, acceso rápido a socios) llegan cada una con su chip puesto.
- **Sin endpoint nuevo**: el padrón se arma con `GET /api/members` y `GET /api/payments/delinquency` en paralelo, las mismas dos llamadas que ya usa el Inicio. Búsqueda, filtrado y orden se resuelven en el cliente porque la API no los expone.
- Fake data source con 40 socios (34 activos, 6 inactivos, 5 en mora), chico a propósito para poder recorrerlo de punta a punta mientras se desarrolla. **El fake del Inicio deriva sus contadores de ese mismo padrón**, así que los dos números del mismo concepto no pueden contradecirse ni aunque alguien toque el generador; un test lo fija.
- Alta, edición y generación del reporte quedan **dibujadas y deshabilitadas**, con aviso de en qué entrega se habilitan.

**Terminado cuando**: las tres entradas del Inicio abren Pagos con el chip correcto, la búsqueda ignora acentos, la selección de "A cobrar" sobrevive a cambiar de chip y a un refresh, los cuatro vacíos se explican, y la pantalla renderiza sin overflow a 130% y 200% de escala de texto.

### E5 — Alta y edición de socio

Las dos primeras pantallas de escritura de la app. El contrato está en [backend_api.md](backend_api.md) §5; lo que define esta entrega es el comportamiento del formulario, que es donde se juega la usabilidad.

**Validación**: híbrida, no una sola estrategia.
- **Al perder el foco** se valida el campo que se abandona, solo si el usuario ya escribió algo. Validar mientras se tipea marca en rojo un DNI a medio escribir; validar recién al enviar obliga a recorrer el formulario de nuevo.
- **Al enviar** se validan todos los campos, se hace foco y scroll al primero con error.
- El mensaje va **debajo del campo**, en `dangerText`, y el campo queda con borde de error. Nunca en un snackbar: se va solo y no dice a qué campo corresponde.
- Un campo con error se limpia en cuanto pasa a ser válido, sin esperar al submit.

**Teclado y formato**: `TextInputType.number` para DNI, `TextInputType.phone` para teléfono, `emailAddress` para email, capitalización de palabras en nombre y apellido. Un admin cargando socios de a diez no debería cambiar de teclado a mano.

**Errores del servidor**: el 409 de DNI duplicado se mapea al campo `dni` **por el status code**, nunca por el texto del mensaje, porque la API no expone un código de error estable ([backend_api.md](backend_api.md) §4). En este endpoint alcanza: el DNI es la única restricción que puede chocar. El resto de los campos conserva lo cargado.

**Terminado cuando**: alta y edición funcionan contra fakes y contra la API, el DNI duplicado se muestra en el campo, abandonar con cambios pide confirmación, y hay tests de widget de la validación y unitarios del mapeo DTO ↔ dominio.

El orden E4 → E5 → E10 es intencional: listado antes de escrituras, y el reporte al final porque depende del listado y de un contrato todavía abierto.

---

## 9. Necesidades del backend

**El contrato vigente vive en [backend_api.md](backend_api.md)**, y el inventario de lo que falta — con la entrega que bloquea cada cosa — en su §10. Esta sección no los repite. Deja solo las **decisiones de producto** que la app sostiene mientras la API no las soporte, que es lo que no se puede leer del lado del backend:

| Decisión ya tomada | Cómo se sostiene hoy |
| :--- | :--- |
| El filtrado y la búsqueda los resuelve el backend | Los resuelve el cliente sobre el padrón completo (§3.2.2). Con ~245 socios son dos llamadas y unos kilobytes; cuando exista en la API, el mapeo no cambia |
| El listado de socios es paginado, con página de 20 | Sin paginar. Al existir, el listado suma "cargando más" al pie |
| `activo/inactivo` y `al día/en mora` son dos ejes independientes, y los dos filtrables | La API los expone en dos endpoints que la app cruza por `memberId`. El filtro combinado (activo + en mora) sigue sin existir, y el Inicio entra pre-filtrado por mora |
| El umbral de "en mora" lo define el backend, no el cliente | La app toma `daysOverdue > 0` y no inventa días de gracia |
| El alta de socio crea solo `member`, nunca `user_account` | Ya es así |
| Un error de formulario se muestra en su campo | Se usa el status code donde alcanza (E5) y un mensaje genérico donde no (E8), hasta que el envelope traiga un `code` estable |

**Lo único que no se puede averiguar leyendo el repo del backend**: las URLs de los dos entornos de Railway, que son variables del dashboard. Hay que pedirlas.
