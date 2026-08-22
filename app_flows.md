# Mapa de Flujos e Inventario de Pantallas (`club-management-app`)

Este documento define **qué pantallas existen, cómo se navega entre ellas, qué ve cada rol y qué estados debe manejar cada una**. Es el artefacto de referencia previo a escribir UI: de acá sale el orden de los PRs y el contrato que le pedimos al backend.

No define píxeles. Define estructura, flujos y estados.

> **Base de este documento (2026-08-21)**: la **superficie del administrador es el camino crítico** — se construye completa antes de empezar la del socio. La paleta de la §7 y la estructura de navegación del admin de la §3.2 derivan de dos capturas de referencia aportadas por el cliente (*Inicio - Administrador* y *Gestión de Socios - Administrador*), no son propuestas especulativas. Los hexadecimales están estimados visualmente de esas capturas y hay que confirmarlos contra el diseño original.

---

## 1. Principios de diseño para este producto

El público del lado socio son miembros de un club de barrio con rango de edad amplio, no usuarios expertos en apps. El público del lado admin es distinto: poca gente, uso diario, interfaz aprendida. Los principios se aplican con ese matiz.

| Principio | Implicancia concreta |
| :--- | :--- |
| **Pocos pasos por flujo** | Reservar una cancha: máximo 3 toques desde el Inicio hasta la confirmación (más el paso de selección de socio en el flujo del admin). |
| **Íconos con etiqueta, según superficie** | **Socio**: nunca un ícono solo — uso esporádico y rango de edad amplio. **Admin**: se permiten acciones ícono-only en filas de listado densas, con tres requisitos no negociables: `Semantics(label:)`, `tooltip` en press largo, y área táctil de 48×48 aunque el ícono se dibuje más chico. |
| **Estado siempre explícito** | El usuario nunca debe preguntarse "¿se guardó o no?". Confirmaciones textuales, no solo cambios de color. |
| **Selección visible** | Toda acción que acumula estado (agregar un socio al reporte) cambia el aspecto del ítem seleccionado y permite quitarlo desde el mismo lugar. Un contador en el FAB no alcanza si la fila no cambia. |
| **Texto legible por defecto** | Base de 16sp para cuerpo, mínimo 14sp para secundarios. Respetar el `textScaleFactor` del sistema sin romper layouts. |
| **Sin jerga técnica** | "Turno fijo", no "recurring slot". "Cuota al día", no "payment status: OK". |
| **Tolerancia al error** | Toda acción irreversible (cancelar reserva, registrar pago, dar de baja un socio) pide confirmación explícita. |
| **El color nunca solo** | Ningún estado se comunica únicamente por color: siempre acompañado de texto o ícono. Requisito para daltonismo y para pantallas al sol en el predio. |

---

## 2. Roles y superficies

Hay dos superficies de aplicación distintas, no una con condicionales dispersos:

- **Administrador (`UserRole.admin`)**: opera el club. Gestiona socios, pagos, reservas y canchas. **Es la superficie de la primera entrega.**
- **Socio (`UserRole.member`)**: consume el club. Reserva, paga, consulta.

**Decisión**: dos *shells* de navegación separados, elegidos por `UserRole` en el redirect del router. Un admin no ve tabs de socio deshabilitados; ve su propio conjunto. Esto evita el antipatrón de una sola pantalla llena de `if (isAdmin)`.

### El admin que reserva para sí mismo

Cuando un admin es además socio y quiere reservar para sí mismo, **no hay modo especial ni cambio de superficie**: usa el flujo de reserva del admin y selecciona su propia cuenta de socio en el paso de selección de socio. La reserva resultante es indistinguible de cualquier otra — mismo registro, misma visualización, sin distintivo.

Consecuencia a respetar al construir: el flujo de reserva del admin **siempre** incluye el paso de selección de socio, incluso cuando reserva para sí mismo. No se atajan casos ni se preselecciona su cuenta. Esto elimina la pregunta de "¿en qué modo estoy?" y ahorra un segundo árbol de navegación.

---

## 3. Inventario de pantallas

### 3.1 Autenticación (fuera de los shells)

| Pantalla | Ruta | Estado | Propósito |
| :--- | :--- | :--- | :--- |
| Splash / Bootstrap | `/` | A construir | Resuelve sesión persistida y redirige. Evita el flash de login al abrir la app ya logueado. |
| Login | `/login` | ✅ Implementada | Ingreso con email + contraseña. |
| Primer ingreso | `/login/activate` | A construir | El socio ya existe en el club pero no tiene `user_account`. Activa su cuenta. Ya hay CTA en `AppStrings.loginFirstTimeUser`. |
| Recuperar contraseña | `/login/forgot` | A construir | Envío de instrucciones por email. Ya hay CTA en `AppStrings.loginForgotPassword`. |

### 3.2 Shell del Administrador — 4 tabs

Bottom navigation de fondo navy oscuro, 4 items con ícono **y** etiqueta: **Inicio / Reservas / Pagos / Perfil**.

Toda pantalla del shell lleva en el header el badge **"ADMINISTRADOR"** en verde claro. Es la señal permanente de superficie y se implementa como componente compartido (`RoleBadge`), no repetido por pantalla.

| Tab | Ruta | Contenido |
| :--- | :--- | :--- |
| **Inicio** | `/admin` | Resumen General + Accesos Rápidos (detalle en §3.2.1) |
| **Reservas** | `/admin/reservations` | Agenda del día por cancha, detalle de reserva, bloqueos, alta a nombre de un socio. **En la primera entrega: estado "Próximamente"** |
| **Pagos** | `/admin/payments` | Listado de cuotas con filtro por estado, registrar pago, detalle |
| **Perfil** | `/admin/profile` | Datos del admin, cambiar contraseña, cerrar sesión |

Rutas alcanzadas por navegación push, fuera de los tabs:

| Pantalla | Ruta |
| :--- | :--- |
| Gestión de socios | `/admin/members` |
| Alta de socio | `/admin/members/new` |
| Edición de socio | `/admin/members/:memberId/edit` |
| Reporte de pagos | `/admin/members/report` |
| Gestión de canchas | `/admin/courts` |

**Socios y Canchas no son tabs.** Se alcanzan desde el Inicio. El criterio: son tareas de sesión (entrás, resolvés, volvés), no destinos de consulta permanente como la agenda o los pagos. La barra inferior queda reservada para lo que el admin mira varias veces por día.

**El tab Reservas se muestra desde la primera entrega con un estado "Próximamente"** explícito, en lugar de arrancar con 3 tabs y agregar el cuarto después. La forma de la barra no cambia entre releases.

#### 3.2.1 Inicio del Administrador

Primera pantalla después del login del admin. De arriba a abajo:

**Sección "Resumen General"**

| Bloque | Contenido | Tratamiento visual | Al tocar |
| :--- | :--- | :--- | :--- |
| `ActiveMembersCard` | "SOCIOS ACTIVOS" + contador | Card navy sólida, texto blanco, ancho completo | → `/admin/members` |
| `OverdueMembersCard` | "SOCIOS EN MORA" + contador | Card azul claro, contador en rojo | → `/admin/members` |
| `UpcomingSlotsCard` | "PRÓXIMOS TURNOS" + filas cancha / horario | Card azul claro, horario en azul alineado a la derecha | → agenda. En la primera entrega no navegable |

**Sección "Accesos Rápidos"** — dos cards lado a lado, mismo alto:

| Card | Color | Destino |
| :--- | :--- | :--- |
| Gestión de Socios (ícono personas) | navy sólido | `/admin/members` |
| Gestión de Canchas (ícono calendario) | verde sólido | `/admin/courts` |

Los **tres** puntos de entrada a socios (las dos cards del resumen y el acceso rápido) van a la **misma** pantalla `/admin/members`, sin pre-filtro. Mejora posterior anotada: que "Socios en mora" abra el listado con el filtro de mora ya aplicado.

**Hallazgo de las capturas a resolver**: los contadores no cierran entre pantallas — el Inicio muestra 450 socios activos y el listado muestra 245 totales / 230 activos. Son datos mock, pero hay que definir la fuente de verdad de cada contador para no terminar con dos números distintos del mismo concepto en producción. Ver §8.3.

#### 3.2.2 Gestión de Socios

De arriba a abajo:

1. **Header**: título "Socios" + `RoleBadge`.
2. **Buscador**: campo de ancho completo, placeholder "Buscar socio por nombre o DNI". Debounce de ~300 ms, no una consulta por pulsación.
3. **Filtros**: chips con contador — "Todos (n)", "Activos (n)", "Inactivos (n)". El seleccionado en navy sólido, los demás en superficie clara. *Corrección de copy respecto de la captura: dice "Inactivas", va "Inactivos".*
4. **Listado**: `ListView.builder` de `MemberListTile`. Cada fila:
   - Barra de acento en el borde izquierdo, coloreada por estado de cuota (verde = al día, rojo = en mora).
   - Nombre del socio.
   - Pill de estado: "ACTIVO" sobre verde claro / "EN MORA" sobre rojo claro.
   - Acción **lápiz** → `/admin/members/:memberId/edit`.
   - Acción **documento** → agrega o quita el socio del reporte en curso. Con estado visual distinto cuando ya está agregado.
5. **FAB verde, abajo a la izquierda**: ver el reporte de pagos, con badge de cantidad de socios agregados. Deshabilitado cuando el contador está en cero.
6. **FAB azul, abajo a la derecha**: crear socio → `/admin/members/new`.

Dos observaciones registradas, sin cambiar la decisión de diseño:

- **Dos FABs no es un patrón estándar de Material.** Acá funciona porque son acciones de peso distinto (crear vs. consultar lo acumulado) y están separadas espacialmente, pero exige que el verde comunique su función sin depender solo del ícono: conviene **FAB extendido con etiqueta "Ver reporte"** en lugar de circular.
- **La barra de acento y el pill codifican lo mismo** (estado de cuota), mientras que los chips de arriba segmentan por otro eje (activo / inactivo). Dos ejes en el mismo espacio visual se vuelven ambiguos con 245 socios. Ver §8.2.

### 3.3 Shell del Socio — 4 tabs

Se construye recién con la superficie del admin terminada. Bottom navigation de 4 items con ícono y etiqueta.

**Tab 1 — Inicio** (`/home`)

El tablero. Responde de un vistazo las preguntas que el socio trae al abrir la app:

1. `NextReservationCard` — ¿cuándo juego? Cancha, día, hora, con acción "Cancelar".
2. `MembershipStatusCard` — ¿estoy al día? Semáforo textual: al día / vence pronto / vencida, con monto y vencimiento.
3. `QuickActionsRow` — atajos a Reservar y a Mis turnos fijos.
4. `ClubNoticesSection` — avisos del club (opcional, depende de si el backend los expone).

**Tab 2 — Reservas** (`/reservations`)

| Pantalla | Ruta | Propósito |
| :--- | :--- | :--- |
| Mis reservas | `/reservations` | Dos secciones: próximas (con cancelar) e historial. Turnos fijos marcados con distintivo. |
| Elegir cancha | `/reservations/new` | Listado de canchas por deporte y superficie. |
| Elegir horario | `/reservations/new/:courtId` | Selector de fecha (7 días hacia adelante) + grilla de franjas. |
| Confirmar reserva | `/reservations/new/:courtId/confirm` | Resumen y confirmación explícita. |
| Detalle de reserva | `/reservations/:reservationId` | Datos completos, cancelación con confirmación. |

**Tab 3 — Cuotas** (`/payments`)

| Pantalla | Ruta | Propósito |
| :--- | :--- | :--- |
| Estado de cuota | `/payments` | Estado actual destacado + historial de pagos descendente. |
| Detalle de pago | `/payments/:paymentId` | Período, monto, fecha, medio, comprobante. |

**Tab 4 — Perfil** (`/profile`)

| Pantalla | Ruta | Propósito |
| :--- | :--- | :--- |
| Mi perfil | `/profile` | Datos del socio, número de socio, antigüedad. |
| Mi grupo familiar | `/profile/family` | Integrantes y estado de cuota de cada uno. Solo lectura. |
| Mis turnos fijos | `/profile/recurring` | Turnos fijos asignados (día, hora, cancha, vigencia). |
| Cambiar contraseña | `/profile/password` | — |
| Cerrar sesión | acción | Confirmación explícita y limpieza de `secure_storage`. |

---

## 4. Flujos críticos

Ordenados por entrega: primero los del admin.

### 4.1 Entrar a gestión de socios, dar de alta y editar

```
Inicio ──[Socios activos | Socios en mora | Gestión de Socios]──► Gestión de Socios
                                                                       │
                                    ┌──────────────────┬───────────────┴──────┐
                                    ▼                  ▼                      ▼
                              [FAB azul +]        [lápiz fila]          [buscar / filtrar]
                                    │                  │
                              Alta de socio      Edición de socio
                                    └────────┬─────────┘
                                             ▼
                                     Confirmar ──► Listado actualizado
```

**Reglas del flujo:**
- El alta valida DNI duplicado contra el backend antes de enviar, no después del error 409.
- Al volver de un alta exitosa, el listado refresca y hace scroll hasta el socio creado. Sin eso el admin no tiene confirmación de que quedó.
- Abandonar un formulario con cambios sin guardar pide confirmación.
- La búsqueda y el filtro sobreviven a la ida y vuelta al formulario: el admin que estaba filtrando por mora no pierde el contexto.

### 4.2 Armar y ver el reporte de pagos

```
Gestión de Socios ──[ícono documento en n filas]──► contador del FAB verde = n
                                                              │
                                                    [FAB verde]▼
                                                    Reporte de pagos
                                                    (lo genera el backend)
```

**Reglas del flujo:**
- La selección vive en el estado del listado, no en el backend. Se envía recién al pedir el reporte.
- La fila seleccionada cambia de aspecto; volver a tocar el ícono la quita.
- Salir de la pantalla con ítems acumulados pide confirmación, porque la selección se pierde.
- La generación puede tardar: estado de carga propio, y error con reintento **sin perder la selección**. Si un error borra 20 socios seleccionados a mano, el admin no vuelve a usar la función.

### 4.3 Registrar un pago (admin)

```
Pagos ──[filtro: vencidas]──► Socio ──► Registrar pago ──► Confirmar ──► Listado actualizado
```

Acción con impacto en dinero: requiere confirmación con resumen (socio, período, monto, medio) antes de escribir.

### 4.4 Reservar una cancha (admin)

```
Reservas ──[Nueva]──► Seleccionar socio ──► Elegir cancha ──► Elegir horario ──► Confirmar ──► Éxito
```

**Reglas del flujo:**
- El paso de selección de socio está **siempre**, también cuando el admin reserva para sí mismo (§2).
- La fecha arranca en **hoy**, no en un selector vacío. El caso más común es hoy o mañana.
- Las franjas ocupadas se muestran **deshabilitadas con motivo** ("Ocupado", "Mantenimiento", "Turno fijo"), no ocultas. Ocultarlas hace creer que la app está rota.
- La confirmación es una pantalla, no un diálogo: cancha, día, hora, socio y costo si aplica.
- El éxito reemplaza el stack y lleva a la agenda.

### 4.5 Bloquear una cancha (admin)

```
Reservas ──[Bloquear]──► Rango + motivo ──► Confirmar ──► Agenda actualizada
```

Si el bloqueo pisa reservas existentes, la confirmación **debe listar las reservas afectadas** y decir explícitamente qué pasa con ellas. Es el flujo con mayor potencial de daño de la app.

### 4.6 Reservar y consultar cuota (socio)

```
Inicio ──[Reservar]──► Elegir cancha ──► Elegir horario ──► Confirmar ──► Mis reservas
Inicio ──[MembershipStatusCard]──► Cuotas ──► Detalle de pago
```

Mismas reglas que 4.4, sin el paso de selección de socio. Para la cuota: un solo toque desde el Inicio, y la tarjeta del Inicio ya trae el dato resuelto (al día / vencida + monto), no un "Ver estado" ciego.

**Caso borde a definir con el backend**: si el socio tiene la cuota vencida, ¿puede reservar? Si no, hay que interceptar **antes** de que elija horario, con un mensaje claro y un atajo a Cuotas. Interceptar en la confirmación es frustrante. Ver §8.8.

---

## 5. Estados por pantalla

Toda pantalla que consuma datos remotos maneja estos casos. No es opcional y no se agrega "después".

| Estado | Tratamiento |
| :--- | :--- |
| **Loading** | Skeleton con la forma del contenido real (no un spinner centrado) en cargas iniciales. Spinner solo en acciones puntuales dentro de un botón. |
| **Empty** | Mensaje explicativo + acción sugerida. Nunca una lista vacía muda. |
| **Error** | Mensaje en lenguaje del usuario + botón "Reintentar". Distinguir sin conexión de error del servidor: son dos acciones distintas del usuario. |
| **Success** | Confirmación textual explícita. Para escrituras, refresco del estado afectado. |
| **Sin conexión** | Detectable y con mensaje propio. En un club, la conectividad dentro del predio es un caso real, no un borde teórico. |
| **Cargando más** | En listados paginados, distinto del loading inicial: indicador al pie, sin tapar lo ya cargado. |

**Dos vacíos distintos en el listado de socios.** Es un error clásico tratarlos igual:
- El club no tiene socios cargados → CTA "Crear el primer socio".
- La búsqueda no arrojó resultados → CTA "Limpiar búsqueda".

**Paginación**: con 245 socios el listado necesita paginado o scroll infinito. Ver §8.5.

**Consecuencia técnica**: conviene un `AsyncStateBuilder` compartido en `shared/widgets/` que reciba el estado del Cubit y los builders de cada caso, para no reimplementar el árbol de estados en cada pantalla.

---

## 6. Router y guards

Estructura objetivo de [app_router.dart](lib/core/router/app_router.dart), hoy con dos rutas planas:

```
GoRouter
├── /                              → SplashScreen (resuelve sesión)
├── /login                         → LoginScreen
│   ├── /login/activate            → ActivateAccountScreen
│   └── /login/forgot              → ForgotPasswordScreen
├── StatefulShellRoute (admin)
│   ├── branch: /admin             → Inicio
│   ├── branch: /admin/reservations→ Agenda ("Próximamente" en la 1ª entrega)
│   ├── branch: /admin/payments    → Pagos
│   └── branch: /admin/profile     → Perfil
├── rutas push del admin (fuera de los tabs)
│   ├── /admin/members             → Gestión de socios
│   │   ├── /admin/members/new     → Alta
│   │   ├── /admin/members/:id/edit→ Edición
│   │   └── /admin/members/report  → Reporte de pagos
│   └── /admin/courts              → Gestión de canchas
└── StatefulShellRoute (socio)     → entregas posteriores
    ├── branch: /home
    ├── branch: /reservations       (+ rutas hijas de reserva)
    ├── branch: /payments
    └── branch: /profile
```

`StatefulShellRoute.indexedStack` es la opción correcta: preserva el estado de cada tab al cambiar, que es lo que el admin espera al volver de Pagos a un listado a medio filtrar.

`initialLocation` sigue siendo `/` (splash). El destino post-login del admin es `/admin`.

**Guards necesarios** en el `redirect`:

1. Sin sesión + ruta protegida → `/login`.
2. Con sesión + ruta de auth → shell según rol.
3. `UserRole.member` en la primera entrega → **pantalla explícita de "la app para socios está en preparación"**, no un redirect a rutas que todavía no existen. Cuando el shell del socio exista, este guard pasa a ser el redirect normal por rol.
4. `UserRole.member` intentando `/admin/*` → fuera de la superficie admin.
5. Sesión expirada durante el uso (401 no recuperable del interceptor) → `/login` con mensaje de sesión vencida.

El guard depende del estado global de autenticación. Eso requiere un `AuthBloc` de sesión, separado del `LoginCubit` de formulario que ya existe.

---

## 7. Dirección visual

Paleta derivada de las capturas de referencia. **Valores estimados visualmente, a confirmar contra el diseño original.**

| Token | Hex | Uso en las capturas |
| :--- | :--- | :--- |
| `brandNavy` | `#0C2340` | Bottom nav, cards destacadas, card "Gestión de Socios", chip de filtro activo, texto primario |
| `brandGreen` | `#12784A` | Card "Gestión de Canchas", FAB de reporte |
| `accentBlue` | `#2563EB` | FAB de crear socio, horarios, enlaces |
| `infoSurface` | `#DDE7F7` | Fondo de cards informativas (mora, próximos turnos) |
| `successSurface` / `successText` | `#C8EFD9` / `#0F6B41` | Pill "ACTIVO", badge "ADMINISTRADOR" |
| `dangerSurface` / `dangerText` | `#FADBDB` / `#D32F2F` | Pill "EN MORA", contador de mora |
| `background` | `#F4F6F9` | Fondo de pantalla |
| `surface` | `#FFFFFF` | Cards, campo de búsqueda |
| `textSecondary` | `#6B7280` | Placeholders y labels |

**Regla de tokens — separar la rampa de marca de la rampa semántica aunque hoy compartan tono.** El verde del FAB de reporte es `brandGreen`; el verde del pill "ACTIVO" es `successText`. Si mañana el estado "al día" cambia de color, no se arrastra el FAB. Lo mismo con `accentBlue` (acción) frente a `infoSurface` (información). Es el punto que se degrada solo si no se explicita ahora.

**Tipografía**: mantener Inter (ya está vía `google_fonts`) y subir la escala base — cuerpo en 16sp, no 14sp.

**Modo oscuro fuera de alcance.** Las capturas son un diseño *light*, con superficies navy sobre fondo claro. Un `darkTheme` inventado sobre una identidad ajena es deuda, no feature: queda pendiente hasta tener las capturas equivalentes.

**Deuda técnica de theming a resolver antes de sumar pantallas** (detectada en el código actual):

1. La paleta de [app_colors.dart](lib/core/theme/app_colors.dart) es Tailwind sky/slate por defecto: hay que reemplazarla entera por la tabla de arriba.
2. [app_theme.dart](lib/core/theme/app_theme.dart) no activa `useMaterial3: true` → se están usando defaults de Material 2.
3. El `darkTheme` no está cableado en `MaterialApp` aunque los colores dark existen en `AppColors` — se remueven o se dejan explícitamente sin usar, no a medio camino.
4. No hay tokens de spacing ni de radios: el valor `12` está repetido en cinco lugares de `app_theme.dart`.
5. Falta `app_text_styles.dart`, que el plan de login contemplaba.

---

## 8. Preguntas abiertas para el backend

### Bloqueantes de la primera entrega (admin)

1. **Reporte de pagos** — decidido que lo genera el backend. Falta el contrato: endpoint, formato (PDF / Excel), si recibe lista de IDs de socios y rango de fechas, y si devuelve binario o URL descargable.
2. **Ejes de estado del socio** — ¿`activo/inactivo` y `al día/en mora` son dos campos independientes? Las capturas los mezclan: los chips filtran por uno y los pills muestran el otro. Define el modelo y el filtrado. ¿Puede existir un socio inactivo en mora?
3. **Contadores del Inicio** — ¿hay un endpoint de resumen que devuelva activos / en mora / próximos turnos en una sola llamada, o son tres pedidos? Define si el Inicio es un Cubit o tres. Y cuál es la fuente de verdad de cada número (ver §3.2.1).
4. **Búsqueda de socios** — ¿la filtra el backend por nombre y DNI, o se trae todo y se filtra en cliente? Con 245 socios el cliente aún es viable, pero no escala y define el diseño del Cubit.
5. **Paginación del listado de socios** — tamaño de página, y si el filtro por estado se aplica server-side.
6. **Alta de socio** — campos obligatorios, unicidad de DNI, y si el alta crea también `user_account` o solo `member`.
7. **Refresh token** — ¿existe el endpoint de refresco? El interceptor de [api_client.dart](lib/core/network/api_client.dart) hoy solo inyecta el `accessToken`, no lo refresca. Bloqueante desde la primera entrega: el admin usa la app todos los días.

### Bloqueantes de las entregas de reservas y del socio

8. **Cuota vencida y reservas** — ¿bloquea la reserva? Define dónde interceptamos en 4.4 y 4.6.
9. **Disponibilidad** — ¿hay un endpoint que devuelva franjas libres de una cancha para una fecha, o el cliente debe cruzar `reservation` + `court_block` + `recurring_slot`? Debe resolverlo el backend: la lógica de solapamiento en el cliente es una fuente garantizada de bugs.
10. **Turnos fijos** — ¿generan `reservation` materializadas o son una regla evaluada al consultar disponibilidad? Cambia cómo se listan.
11. **Cancelación** — ¿hay ventana mínima de antelación? Define si el botón se deshabilita y con qué mensaje.
12. **Grupo familiar** — ¿el titular puede reservar a nombre de un integrante? Si sí, el flujo del socio necesita también un paso de selección de jugador.
13. **Paginación de historiales** — ¿vienen paginados? Define si el scroll es infinito o completo.

---

## 9. Orden de construcción

Vertical slices: cada PR entrega una feature de punta a punta (`domain` → `data` → `presentation`) con sus estados y sus tests.

| # | Entrega | Por qué acá |
| :--- | :--- | :--- |
| 0 | Design system con la paleta de la §7 + tokens + `/dev/gallery` + flavors | Base de todo lo visual, y las capturas ya definen los valores. Incluye invertir el default `localhost` → remoto de [api_client.dart](lib/core/network/api_client.dart) |
| 1 | `AuthBloc` de sesión + Splash + shell del admin (4 tabs, Reservas en "Próximamente") + guards | Sin esto no hay navegación; hoy `/home` es un `Placeholder` |
| 2 | Inicio del Administrador | Primera pantalla con datos remotos: valida el patrón de estados completo |
| 3 | Gestión de Socios: listado, búsqueda, filtros, paginación | Núcleo de la primera entrega |
| 4 | Alta y edición de socio | Primeras escrituras de la app: valida formularios y manejo de error de escritura |
| 5 | Reporte de pagos: selección + generación | Depende de 3 y de un contrato de backend todavía abierto (§8.1) |
| 6 | Cuotas y pagos del admin: listado, registrar pago, detalle | Completa "socios y cuotas" |
| 7 | Perfil del admin + cambiar contraseña + logout | Cierra el shell del admin |
| 8 | Agenda / Reservas del admin + gestión de canchas + bloqueos | Reemplaza el "Próximamente"; cierra la superficie admin completa |
| 9 | Recuperar contraseña + primer ingreso | Los CTAs ya existen en el login sin destino |
| 10+ | Superficie del socio: shell, Inicio, reservar, mis reservas, cuotas, perfil, grupo familiar | Arranca recién con la superficie del admin terminada |

El orden 3 → 4 → 5 es intencional: listado antes de escrituras, y el reporte al final porque depende del listado y de una definición de backend que todavía no está cerrada.
