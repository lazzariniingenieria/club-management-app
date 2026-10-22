# Mapa de Flujos, Pantallas y Entregas (`club-management-app`)

Documento de referencia del frontend: **qué pantallas existen, cómo se navega, qué ve cada rol, y en qué orden se entrega**. De acá salen los PRs (§8).

No define píxeles. Define estructura, flujos, estados y alcance por entrega.

> **Estado al 2026-10-22.** La superficie del **administrador es el camino crítico**: se construye completa antes de la del socio. Entregada hasta E6; el Bloque 1 (E6.5, E7, E8, E10 y la parte informativa de E11) cierra el resto del admin sin canchas. La paleta de §7 está confirmada en código (`AppColors`).
>
> **El contrato de la API no se documenta acá**: vive en [backend_api.md](backend_api.md), verificado contra `develop`. Este archivo manda en pantallas, flujos y entregas; ese otro manda en endpoints, shapes, errores y reglas del servidor.

---

## 1. Principios de diseño

| Principio | Implicancia concreta |
| :--- | :--- |
| **Pocos pasos** | Máximo 3 toques desde el Inicio hasta confirmar cualquier flujo principal, salvo flujos especiales que realmente lo necesiten, con el motivo escrito en su sección (registrar un pago: 4, §4.2). |
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

Se construye entonces como pantalla informativa: explica que un administrador del club puede restablecer la contraseña y ofrece volver al login. El canal de contacto queda pendiente: la API no expone datos de contacto del club ([backend_api.md](backend_api.md) §10). Sin campo de email, sin botón "Enviar" — un formulario que no manda nada a ningún lado es peor que no tener la pantalla.

### 3.2 Shell del Administrador

Bottom navigation navy, 3 items con ícono **y** etiqueta. Badge `RoleBadge` ("ADMINISTRADOR" / "SUPER ADMIN") en el header de las **tres pantallas raíz** de los tabs. Las pantallas push muestran solo la flecha de volver y el título: con el badge, un título de dos palabras ya no entraba ("Registrar p…").

| Tab | Ruta | Contenido |
| :--- | :--- | :--- |
| **Inicio** | `/admin` | Resumen General + Accesos Rápidos (§3.2.1) |
| **Pagos** | `/admin/payments` | Listado de socios con buscador y chips Todos / En mora (§3.2.2) |
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

**Accesos Rápidos** — dos cards lado a lado, cada una una **acción**, no un destino que ya está en otro lado: *Nuevo socio* (navy) → alta de socio (`/admin/members/new`), *Registrar pago* (verde) → elegir socio → registro de pago (§4.2). Hasta E6 estuvo dibujada en gris.

**Sin card de socios marcados para cobrar.** Se diseñó sobre la canasta "A cobrar" de §3.2.2 y se descartó con ella en E6, antes de construirse.

Las dos cards de la primera versión salieron: *Gestión de Socios* abría exactamente lo mismo que el card "Socios activos" (tres caminos al mismo listado en una pantalla), y *Gestión de Canchas* abría un "próximamente" — el mismo tab muerto que §3.2 decidió evitar, en forma de card. Canchas vuelve al Inicio con la agenda (E9).

**Cada card lleva a lo que su título dice.** Un card que anuncia "SOCIOS EN MORA" con un número y abre el listado completo sin filtrar rompe la expectativa de manipulación directa en la primera pantalla que ve el admin, y le enseña a no confiar en que tocar algo específico devuelva algo específico. No es una mejora posterior: el filtro de mora ya se construye para los chips de §3.2.2, así que el costo es pasar un parámetro de ruta.

El filtro viaja como query param (`/admin/payments?filter=overdue`), no como estado global ni como estado interno del listado: así el listado es enlazable y, sobre todo, cada card vuelve a imponer *su* filtro. Si el chip activo viviera solo en el Cubit, un admin que cambió de chip a mano y después tocara "Socios activos" se encontraría con el filtro anterior, porque la URL del branch no habría cambiado y no habría nada que avisara al listado.

Los contadores de los chips (§3.2.2) salen del mismo listado que ya está en memoria, así que cambiar de chip no vuelve a pegarle a la API.

#### 3.2.2 Pagos — listado de socios y cobranza

1. **Header**: "Pagos" + `RoleBadge`.
2. **Buscador**: placeholder "Buscar socio por nombre o DNI...". Lo resuelve el cliente sobre el padrón ya cargado, porque la API no expone búsqueda; ignora mayúsculas y acentos, así que "alvarez" encuentra a "Álvarez".
3. **Filtros**: dos chips con contador — "Todos (n)" y "En mora (n)". Seleccionado en navy sólido.
4. **Listado**: `ListView.builder` de `MemberListTile`, ordenado por apellido. Cada fila: nombre, badge **Activo / Inactivo** y acción **lápiz** → edición. **Tocar el resto de la fila abre las cuotas del socio** (§4.2.1); el lápiz sigue siendo un target propio de 48×48.
5. **FAB azul, abajo derecha**: crear socio. Es el único FAB de la pantalla.

**Qué filtra cada chip**:

| Chip | Contenido |
| :--- | :--- |
| **Todos** | Todo el padrón, activos e inactivos |
| **En mora** | Socios con la cuota vencida (`daysOverdue > 0`) |

**Sin chip "A cobrar".** E4 lo construyó como una canasta de socios marcados a mano con un ícono de documento en cada fila, para alimentar el reporte. Se quitó en E6, cuando el reporte se redefinió como un PDF de los pagos registrados en un período (§4.6): ese reporte no sale de una selección de socios, así que la canasta, la marca de cada fila y el botón "Generar reporte" del pie quedaron sin uso. La fila queda con dos destinos: sus cuotas y su edición.

**El badge de la fila muestra un solo eje: Activo / Inactivo.**

| Estado | Badge | Color |
| :--- | :--- | :--- |
| Activo | "Activo" | `successSurface` / `successText` |
| Inactivo | "Inactivo" | `disabledSurface` / `textSecondary` |

Los dos ejes de estado siguen siendo independientes en el dominio (§9): `activo/inactivo` dice si sigue siendo socio, `al día/en mora` dice si la cuota está paga, y un socio puede estar activo y en mora a la vez. Lo que cambió es cómo se muestran: la mora se consulta entrando al chip "En mora", no leyendo fila por fila. **Consecuencia asumida**: en "Todos" no se distingue a simple vista quién debe. Si molesta en uso real, el badge combinado ("Activo · En mora") ya está diseñado y es un cambio de una sola función. El listado tampoco se ordena por días de mora ni los muestra, aunque V6 lo mencione: el chip "En mora" alcanza para el uso real (decisión del 22/10/2026).

**Tres vacíos distintos, no uno** (§5): padrón sin socios, "ningún socio está en mora" y búsqueda sin resultados con acción "Limpiar búsqueda".

**Acciones todavía no disponibles**: se dibujan en gris y, al tocarlas, explican en qué entrega se habilitan, en lugar de ocultarse. Así la pantalla tiene su forma definitiva y las filas no cambian de layout en cada entrega. Así se hizo con el FAB de alta y el lápiz hasta E5.

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
Inicio ──[Socios activos ⇒ chip Todos  ]──►
       ──[Socios en mora ⇒ chip En mora]──►  tab Pagos
       ──[Nuevo socio]──────┐                   │
                            │        ┌──────────┼───────────────┐
                            │        ▼          ▼               ▼
                            │    [FAB + ]   [lápiz fila]  [buscar / chips]
                            │        │          │
                            └──► Alta de socio  Edición de socio
                                     └────┬─────┘
                                          ▼
                                 Confirmar ──► Listado actualizado
```

- La búsqueda y el filtrado hoy los resuelve el cliente sobre el padrón completo, porque la API devuelve la lista entera sin paginar ni filtrar. Sirve con los ~245 socios del club; cuando el backend exponga paginación, el listado pasa a "cargando más" al pie y el mapeo no cambia.
- El DNI duplicado lo valida el backend y se muestra en el campo, no en un snackbar genérico (E5).
- Al volver de un alta exitosa el listado refresca y hace scroll al socio creado.
- El listado se recarga solo cuando el padrón cambia (alta, edición, baja o reactivación), venga el cambio de donde venga: un alta hecha desde el Inicio ya aparece al abrir Pagos, sin pull-to-refresh. La recarga conserva búsqueda y chip.
- Abandonar un formulario con cambios pide confirmación, también con el gesto de deslizar desde el borde en iOS. Sin cambios, el gesto vuelve directo. La búsqueda y el filtro sobreviven a la ida y vuelta.

### 4.2 Registrar un pago

```
Inicio ──[Registrar pago]──► Elegir socio ──┐
Pagos ──[fila]──► Cuotas del socio ─────────┼──► Registrar pago ──► Confirmar ──► Cuotas del socio
                        ▲  [Registrar pago] ┘                                    (meses nuevos marcados)
                        └── [historial] ──► Detalle del pago ──► Anular
```

**Cuatro toques desde el Inicio** para el caso común — un socio que paga el mes siguiente al último, en efectivo y a la cuota del club: *Registrar pago* → socio → *Revisar y confirmar* → *Confirmar*. El tope de tres no alcanza sin sacrificar la confirmación, que en un pago no se negocia.

**Elegir socio** (`/admin/payments/new`): buscador con foco al entrar y solo socios activos, en dos grupos: **en mora** primero, de más días a menos, y **al día** de la A a la Z. Quien viene a pagar suele ser el que debe. Elegir un socio abre el registro; al confirmar, la pantalla de elegir se reemplaza por las cuotas de ese socio, así que "volver" lleva al Inicio y no a una lista que ya no sirve.

**Registrar pago** (`/admin/members/:memberId/payments/new`), de arriba abajo:

- **Encabezado** con el socio, su DNI y su situación (al día, días de mora, o sin pagos).
- **Meses**: grilla de 12 meses (4 × 3) con selector de año. Cada mes está *libre*, *Elegido* o *Pagado*; los pagados no se pueden tocar. Arranca con **un mes sugerido** — el que sigue al último pago, o el del alta si nunca pagó — y un texto que dice por qué. Se pueden sumar meses futuros sin límite y meses viejos sueltos que hayan quedado sin pagar.
- **Importe por mes**, precargado con la cuota de referencia del club cuando existe; si el club no la tiene cargada, el campo arranca vacío y lo dice. Acepta lo mismo que la API: hasta 8 enteros y 2 decimales, con coma decimal (`15.000,50`). Solo la coma abre los decimales: un punto tipeado a mano se ignora, porque los puntos de miles los pone el campo y en es-AR el punto se lee como miles — tipear `15.000` tiene que dar quince mil, no quince pesos. Debajo, el **total** (importe × meses) se actualiza mientras se elige, porque la API registra el importe por mes ([backend_api.md](backend_api.md) §6).
- **Medio de pago**: Efectivo (por defecto), Transferencia u Otro.
- **¿Quién pagó?**: el socio, o un integrante de su grupo familiar. Si el socio no tiene grupo, la sección no aparece.
- **Barra inferior** con el resumen y *Revisar y confirmar*, que se habilita con al menos un mes y un importe.

**Los meses se resumen** cuando son muchos: hasta tres se listan ("Octubre, noviembre y diciembre de 2026"); más de tres se muestran como rango ("6 meses, de octubre 2026 a marzo 2027") o, si no son seguidos, como "entre" uno y otro.

**Confirmación** en una hoja inferior: socio, meses, importe por mes, total, medio y quién pagó, con el aviso *"Un pago registrado no se edita: si hay un error, hay que anularlo desde el historial del socio y cargarlo de nuevo."* y dos acciones, *Confirmar* y *Volver a editar*.

**Después de confirmar** se vuelve a las cuotas del socio con un snackbar ("Pago registrado …") y los meses recién pagos marcados como *NUEVO* en el historial. Pagos, sus contadores de mora y el Inicio se actualizan solos.

**Lo que puede salir mal, sin perder lo cargado**:

| Caso | Qué ve el admin |
| :--- | :--- |
| Sin conexión al confirmar | Aviso arriba del formulario; todo lo elegido queda como estaba. El pedido no salió, así que el pago seguro no se registró |
| El servidor no respondió a tiempo | El pago pudo haberse registrado, así que la app relee el historial: si todos los meses figuran, termina como registrado. Si no figuran (o no se puede leer el historial) **no afirma que no se registró** — el servidor puede seguir commiteando —, dice que no sabe y el reintento revisa el historial antes de enviar: si los encuentra, termina como registrado. Si figuran solo algunos, se quitan de la selección y el resto queda igual de en duda. Ese reintento solo se toma como "el pago de antes" si el formulario no cambió: con otro importe, medio o pagador, los meses encontrados se tratan como cobrados por otro |
| Uno de los meses ya figura pago (otro admin lo cobró mientras tanto) | Aviso con los meses en cuestión; se quitan de la selección y la grilla los muestra como *Pagado* |
| El familiar elegido ya no está en el grupo | El `400` no dice por qué rechazó el pago, así que la app relee el grupo: si el familiar ya no está, aviso y quién pagó vuelve al socio; si sigue (o no se pudo releer), queda elegido y se muestra el error como cualquier otro |
| El socio ya no existe | Pantalla de "No encontramos a este socio" con *Volver a Pagos* |
| El socio fue dado de baja mientras tanto | Pantalla de "Este socio está dado de baja" con *Volver* |
| Otro error del servidor | Aviso con el mensaje; el formulario sigue editable |

**Reintentar siempre vuelve a la confirmación**: entre el error y el reintento el admin pudo haber cambiado el importe o los meses, y un pago no se manda sin ver el resumen que se va a registrar.

**Un mes ya pago no se puede volver a cobrar.** La API lo rechaza con `409`, también cuando dos pedidos llegan a la vez ([backend_api.md](backend_api.md) §6). La app igual relee el historial justo antes de enviar, para frenar el caso común sin un viaje de más; y si el `409` llega igual (otro admin cobró en el mismo segundo, o el primer envío de un timeout terminó de guardarse después de esa relectura), relee el historial y lo trata como *meses ya pagos*: si era el propio envío sin confirmar, termina como registrado; si no, quita esos meses y avisa.

**Un socio inactivo no puede pagar.** No aparece al elegir socio, y en sus cuotas el botón se reemplaza por una nota que explica por qué y un acceso a *Editar socio* para reactivarlo. La API no lo impide, así que la app lo controla en tres lugares: al abrir el registro, al releer el historial antes de enviar, y en las cuotas, que se recargan cuando el socio cambia (una baja o una reactivación hecha desde *Editar socio* se ve al volver) y cuando un pago pudo haber cambiado (un registro que no respondió a tiempo pero entró se ve al volver atrás).

#### 4.2.1 Cuotas del socio y anulación

`/admin/members/:memberId/payments` — se llega desde la fila de Pagos o después de registrar.

- **Encabezado** del socio y **card de situación**: al día, *n* días de mora o inactivo, con el último mes pago (o "Todavía no tiene pagos", con la fecha de alta, para quien recién se sumó).
- **Historial**, del mes más nuevo al más viejo: mes, importe, medio, fecha de carga y quién pagó cuando no fue el socio. Vacío con mensaje propio si nunca pagó.
- **Pie fijo** con *Registrar pago* (*Registrar primer pago* si no tiene ninguno).
- Estados de §5: skeleton, sin conexión y error del servidor con *Reintentar*, y socio inexistente.

**Anular un pago**: tocar una fila del historial abre el **detalle** (los mismos datos y la fecha de carga; quién lo cargó queda pendiente de backend, [backend_api.md](backend_api.md) §10) con la acción *Anular pago*, que pide confirmación en una segunda hoja:

- Dice el efecto: *"Ese mes vuelve a figurar impago y la mora se recalcula. La anulación queda registrada y no se puede revertir: si fue un error, vas a tener que cargar el pago de nuevo."*
- **Motivo opcional**, hasta 150 caracteres.
- Cualquier admin puede anular, no solo quien registró el pago.
- Se anula **un mes por vez**: un pago de tres meses son tres filas.
- Si otro admin ya lo había anulado, se avisa y el historial se refresca.

**Los pagos anulados siguen en el historial**, tachados, con la marca *ANULADO*, la fecha y el motivo. Desaparecer sin rastro haría creer que nunca se cobró. Un pago anulado no se puede tocar ni des-anular.

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

`Generar reporte → período (un mes o un rango de fechas) → PDF`

Un PDF con **todos los pagos registrados en el período**: fecha, socio, mes cubierto, importe, medio y quién pagó, con el total al pie. Lo arma la app con la búsqueda de pagos, que existe pero filtra por mes cubierto y no por fecha de cobro ([backend_api.md](backend_api.md) §6 y §10). Los pagos anulados no entran. La entrada al reporte se define con el diseño de E10.

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

**Tres vacíos distintos en el listado de socios**, error clásico tratarlos igual: padrón sin socios, ningún socio en mora (que es una buena noticia, no un error) y búsqueda sin resultados → "Limpiar búsqueda".

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
│   ├── branch: /admin/payments      → Pagos   ?filter=all|overdue
│   ├── branch: /admin/profile       → Perfil
│   └── branch: /admin/reservations  → Agenda        ← se suma en E9
├── rutas push del admin
│   ├── /admin/members/new, /admin/members/:memberId/edit  ← se suman en E5
│   ├── /admin/payments/new                            ← elegir socio (E6)
│   ├── /admin/members/:memberId/payments  (+ /new)    ← cuotas y registro (E6)
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

Las rutas con `:memberId` que no es un número vuelven a Pagos en lugar de abrir una pantalla rota.

Esto requiere un `AuthBloc` de sesión, separado del `LoginCubit` de formulario que ya existe. Ambos existen desde E2; los seis guards se testean por rol.

---

## 7. Dirección visual

Paleta derivada de las capturas, confirmada en `AppColors`.

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
| E5 | Alta y edición de socio | No bloquea | ✅ Entregada — sin el scroll al socio recién creado (§4.1) |
| E6 | Registrar un pago, cuotas del socio y anulación, sobre el listado de E4 | No bloquea | 🚧 En revisión |
| E7 | Perfil del admin + cambiar contraseña + logout | **Sí** | — |
| E8 | ABM de administradores (superAdmin) | No bloquea | — |
| E9 | Agenda / Reservas + canchas + bloqueos | **Bloqueada** | — |
| E10 | Reporte de pagos en PDF, por período | **Bloqueada** | — |
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
- *(E6 quitó el chip "A cobrar", la marca de cada fila y el botón de reporte — §3.2.2.)*

**Terminado cuando**: las tres entradas del Inicio abren Pagos con el chip correcto, la búsqueda ignora acentos, la selección de "A cobrar" sobrevive a cambiar de chip y a un refresh, los cuatro vacíos se explican, y la pantalla renderiza sin overflow a 130% y 200% de escala de texto.

### E5 — Alta y edición de socio

Las dos primeras pantallas de escritura de la app. El contrato está en [backend_api.md](backend_api.md) §5; lo que define esta entrega es el comportamiento del formulario, que es donde se juega la usabilidad.

**Validación**: híbrida, no una sola estrategia.
- **Al perder el foco** se valida el campo que se abandona, solo si el usuario ya escribió algo. Validar mientras se tipea marca en rojo un DNI a medio escribir; validar recién al enviar obliga a recorrer el formulario de nuevo.
- **Al enviar** se validan todos los campos, se hace foco y scroll al primero con error.
- El mensaje va **debajo del campo**, en `dangerText`, y el campo queda con borde de error. Nunca en un snackbar: se va solo y no dice a qué campo corresponde.
- Un campo con error se limpia en cuanto pasa a ser válido, sin esperar al submit.

**Teclado y formato**: `TextInputType.number` para DNI, `TextInputType.phone` para teléfono, `emailAddress` para email, capitalización de palabras en nombre y apellido. Un admin cargando socios de a diez no debería cambiar de teclado a mano.

**Formato mientras se escribe**: el DNI se agrupa con puntos (`30.111.222`) y el teléfono lleva un guion después de la característica (`3498-462578`, `342-4123456`, `11-55667788`), solo para leerlos mejor. La característica se detecta con las reglas del plan de numeración que publica `libphonenumber`, porque su largo (2, 3 o 4 dígitos) no se deduce de los primeros dígitos solos: el guion aparece recién cuando la característica queda definida. Los dos campos aceptan únicamente dígitos y **viajan a la API sin separadores**: el DNI tiene que coincidir con el de la base para que la búsqueda y el `409` de duplicado funcionen, y el teléfono se guarda con el mismo criterio.

**Errores del servidor**: el 409 de DNI duplicado se mapea al campo `dni` **por el status code**, nunca por el texto del mensaje, porque la API no expone un código de error estable ([backend_api.md](backend_api.md) §4). En este endpoint alcanza: el DNI es la única restricción que puede chocar. El resto de los campos conserva lo cargado.

**Terminado cuando**: alta y edición funcionan contra fakes y contra la API, el DNI duplicado se muestra en el campo, abandonar con cambios pide confirmación, y hay tests de widget de la validación y unitarios del mapeo DTO ↔ dominio.

### E6 — Registrar un pago, cuotas del socio y anulación

La primera escritura que mueve plata. Las pantallas y sus decisiones están en §4.2; el contrato, en [backend_api.md](backend_api.md) §6.

- **Feature `payments`** con sus tres capas. El dominio modela el mes como `BillingMonth` (año + mes), no como `DateTime`: la API habla de "primer día del mes" y comparar fechas con hora trae errores de zona horaria en los bordes.
- **Las cuotas del socio se arman con cuatro llamadas**: padrón, mora, historial con anulados y cuota del club. Si la cuota del club falla, la pantalla sigue y el importe arranca vacío: es una comodidad, no un dato necesario.
- **Control de mes ya pago y de socio activo en el cliente** (`RegisterPaymentUseCase`): antes de enviar relee el socio y su historial — solo esas dos llamadas, no el ledger completo. El socio inactivo solo lo controla la app (la API no lo rechaza); el mes ya pago lo rechaza también la API, y su `409` se traduce a los meses que el historial muestra pagos.
- **Un timeout no es una falta de conexión** (`ResponseTimeoutFailure`, subtipo de `NetworkFailure`): sin respuesta, la escritura pudo haber llegado, así que el registro y la anulación lo resuelven releyendo el historial en lugar de afirmar que no se guardó.
- **El padrón se recarga cuando cambia un pago**, igual que cuando cambia un socio, así que Pagos y sus contadores de mora no quedan viejos después de cobrar o anular.
- **Fake de pagos** coherente con el de socios: cada socio arranca con seis meses de historial que cierran con sus días de mora, valida duplicados, mes ya pago, familiar fuera de grupo, socio inexistente y doble anulación, y al cobrar o anular le recalcula la mora al socio en el fake del padrón.
- Se quitan el chip "A cobrar", la marca de cada fila y el botón de reporte del pie (§3.2.2).
- El `404` de la API pasa a tener su propia falla (`NotFoundFailure`) en lugar de caer como error genérico del servidor.

**Terminado cuando**: se puede cobrar desde el Inicio en cuatro toques y desde la fila del socio, anular un pago desde su historial, los cinco casos de error de §4.2 conservan lo cargado, un mes ya pago no se cobra dos veces, Pagos refleja la mora nueva al volver, y hay tests de dominio, del mapeo DTO ↔ dominio, de los dos Cubits y del flujo completo en pantalla.

El orden E4 → E5 → E6 → E10 es intencional: listado antes de escrituras, y el reporte al final porque lista los pagos que E6 registra y depende de un filtro que el backend todavía no tiene.

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
| Un mes ya pago no se cobra dos veces | Ya es así: la API lo rechaza con `409`, con un índice único que cubre los pedidos simultáneos |

**Lo único que no se puede averiguar leyendo el repo del backend**: las URLs de los dos entornos de Railway, que son variables del dashboard. Hay que pedirlas.
