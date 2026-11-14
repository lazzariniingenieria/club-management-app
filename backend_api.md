# Contrato del backend — `club-management-api`

Fuente de verdad única de lo que la API expone. Ante una duda sobre endpoints, shapes, errores o reglas del servidor, se contesta acá y no leyendo el repo del backend.

**Verificado contra** [`club-management-api`](https://github.com/lazzariniingenieria/club-management-api) `develop`, commit `12abf91` — 2026-10-30. Incluye el PR #22 (reporte de cuotas cobradas) y el #23 (dependencias del Bloque 1 del admin). **`main` (producción) todavía no tiene ninguno de los dos** (§1).

**Canchas** (`/api/courts` y `courtsEnabled` en `/api/clubs/me`, §5) viene del PR #25, los **bloqueos** (`/api/courts/{courtId}/blocks`) del PR #26 y las **reservas** (`/api/reservations`) del PR #27. **Los tres están en `develop` (test) desde el 2026-11-11, y todavía no en `main` (producción).** Los **turnos fijos** (`/api/recurring-slots`) vienen del **PR #28, todavía abierto** (verificado contra su commit `a92d08b`, 2026-11-13): no están ni en `develop`.

**Cómo se refresca**: releer `controller/`, `dto/`, `entity/`, `security/` (incluido `JwtAuthenticationFilter`), `config/SecurityConfig`, `exception/GlobalExceptionHandler` y `db/migration/` — eso es todo el contrato. Actualizar lo que cambió y mover el commit de arriba.

**Qué no va acá**: pantallas, flujos y entregas van en [app_flows.md](app_flows.md); reglas de código, en [CLAUDE.md](CLAUDE.md).

| | |
| :--- | :--- |
| [1. Entorno](#1-entorno) | [6. Pagos](#6-pagos) |
| [2. Convenciones](#2-convenciones) | [7. Cómo se calcula la mora](#7-cómo-se-calcula-la-mora) |
| [3. Autenticación](#3-autenticación) | [8. Modelo de datos](#8-modelo-de-datos) |
| [4. Autorización y errores](#4-autorización-y-errores) | [9. Trampas](#9-trampas) |
| [5. Socios, grupos, admins y canchas](#5-socios-grupos-admins-y-canchas) | [10. Lo que no existe](#10-lo-que-no-existe) |

---

## 1. Entorno

Dos entornos en Railway con su propio Postgres: **producción** (deploy desde `main`) y **test** (desde `develop`).

| Dato | Valor |
| :--- | :--- |
| Prefijo de rutas | **`/api`**, sin segmento de versión — `/api/v1` no existe |
| `API_BASE_URL` | `https://<host>/api` — incluye el prefijo, sin barra final |
| URLs de los dos entornos | **No están en el repo**: son variables de Railway. Hay que pedirlas |

**`main` va detrás de `develop`** (2026-10-30): producción no tiene el reporte de cuotas (§6), `POST /api/payments/batch`, `DELETE /api/family-groups/{id}`, el alta de grupo con `memberIds`, el cambio de contraseña propio, la cuota editable por `ADMIN`, el corte inmediato de sesión ni el límite de 72 bytes (§3 a §6). Un build de la app contra producción que use alguna de esas cosas espera a que el backend las lleve a `main`.

---

## 2. Convenciones

| Convención | Valor real |
| :--- | :--- |
| Verbos | `GET`, `POST`, `PATCH` y **tres** `DELETE` (§5). No hay `PUT`: usarlo da **405** |
| `id` | **Números** JSON (`Long`), nunca strings. Parsear con `(json['id'] as num).toInt()` |
| `PATCH` | **Reemplazo completo** de los campos del DTO, no un merge: omitir un campo lo escribe en `null` |
| Fechas de día | `"2026-09-01"` — ISO, sin hora ni zona (`joinedAt`, `periodCovered`, `lastPeriodCovered`) |
| Timestamps | `"2026-09-19T23:09:57.123456Z"` — ISO-8601 UTC. Es el default de Spring Boot, sin configuración explícita: **confirmar en la primera pantalla que los consuma** |
| Montos | Número JSON con hasta 2 decimales. `NUMERIC(10,2)` en base, nunca parsear a `double` para operar |
| Enums | Strings en `SCREAMING_SNAKE_CASE` |
| Listados | Array JSON plano, sin envelope ni metadata. **Ningún endpoint pagina** |
| Compresión | Desde `club-management-api#24`, las respuestas `application/json` de 2 KB o más llegan con `Content-Encoding: gzip` si el cliente lo pide. Dio lo pide y descomprime solo: no hay nada que hacer en la app. El PDF de `/payments/receipts` no se comprime |
| ETag | Desde `club-management-api#24`, toda respuesta `GET` exitosa de `/api` trae un `ETag` **débil** (`W/"0f3a…"`; con uno fuerte Tomcat no comprimiría la respuesta). Si el pedido manda `If-None-Match` con esa huella, tal cual llegó, y la respuesta no cambió, vuelve `304` sin cuerpo. `Cache-Control` sigue siendo el de Spring Security (`no-cache, no-store, max-age=0, must-revalidate`): el navegador no guarda nada por su cuenta. La app lo aprovecha en `RevalidatingGet` |
| Documento | El campo se llama `dni`, no `nationalId` |

---

## 3. Autenticación

DNI + contraseña, sin proveedor externo. El `dni` es único **por club**, así que el login también pide el club.

### `POST /api/auth/login` · público

```json
// → { "clubId": 1, "dni": "30111222", "password": "s3cr3t123" }
// ← 200
{
  "accessToken": "eyJ...",
  "refreshToken": "x7Hk...",
  "expiresIn": 3600,
  "userAccountId": 12,
  "role": "ADMIN",
  "memberId": 34
}
```

| Campo | Notas |
| :--- | :--- |
| `accessToken` | JWT. Viaja como `Authorization: Bearer <token>` |
| `refreshToken` | **Token opaco, no un JWT**: 32 bytes aleatorios. No se puede decodificar ni leerle la expiración |
| `expiresIn` | Vida del **access token**, en segundos. No aplica al refresh |
| `role` | `SUPER_ADMIN` \| `ADMIN` \| `MEMBER` |
| `memberId` | `null` si la cuenta no es socia. Siempre `null` para `SUPER_ADMIN` |

**No devuelve `clubId`**: viaja dentro del JWT y ningún endpoint lo recibe por parámetro, así que la app lo necesita igual por `--dart-define=CLUB_ID` para poder mandarlo en el login, y no puede recuperarlo de la sesión.

**`401`** para DNI inexistente, contraseña incorrecta **y cuenta desactivada**, los tres indistinguibles: distinguirlos permitiría enumerar qué DNI existen en el club. **`400`** si falta un campo o el `dni` pasa de 20 caracteres.

### `POST /api/auth/refresh` · público

```json
// → { "refreshToken": "x7Hk..." }
// ← 200 { "accessToken": "eyJ...", "refreshToken": "9pQz...", "expiresIn": 3600 }
```

- **Rota siempre**: el token usado queda revocado. El cliente **debe** persistir el que viene en la respuesta.
- TTL: **1 hora** el access token, **60 días** el refresh.
- `401` si el refresh está vencido, revocado, ya rotado, o si la cuenta quedó desactivada.
- Reusar un token rotado rechaza esa llamada, pero **no invalida los demás tokens vivos** de la cuenta.

**Un `401` en `/auth/refresh` es cerrar sesión; en cualquier otro endpoint es refrescar y reintentar una vez.** Sin esa distinción por endpoint, un refresh vencido entra en bucle.

### Corte de sesión

`JwtAuthenticationFilter` lee la cuenta en cada request: un access token de una cuenta **inactiva**, o emitido antes de `sessions_revoked_at` (§8), da `401` aunque no haya vencido. Como el `iat` del JWT solo guarda segundos, también se rechaza un token emitido **en el mismo segundo** del corte; uno que se refresca después de ese segundo vale.

Cortan así todas las sesiones de una cuenta, y además le revocan los refresh tokens (el refresh también da `401`): la baja de un admin, el reset de su contraseña y el cambio de contraseña propio (§5). O sea, **el corte es inmediato**, no al vencer el access token.

### Claims del JWT

`sub` (= `userAccountId` como string), `userAccountId`, `clubId`, `role`, `memberId` (ausente si es `null`), `iat`, `exp`.

---

## 4. Autorización y errores

| Ruta | Quién entra |
| :--- | :--- |
| `/api/auth/login`, `/api/auth/refresh` | público |
| `PATCH /api/auth/me/password` | `ADMIN`, `SUPER_ADMIN` |
| `/api/admins/**`, incluido `PATCH /api/admins/{id}/password` | **solo `SUPER_ADMIN`** |
| `/api/members/**`, `/api/family-groups/**`, `/api/payments/**`, `/api/courts/**`, `/api/reservations/**`, `/api/recurring-slots/**` | `ADMIN`, `SUPER_ADMIN` |
| `/api/clubs/me` (`GET` y `PATCH`) | `ADMIN`, `SUPER_ADMIN` |

**Un token con `role = MEMBER` no entra a ningún endpoint implementado.** Puede autenticarse y nada más.

`401` es sesión ausente, inválida o vencida; `403` es rol insuficiente. Los emite la cadena de filtros de Spring Security, no el handler global, así que **ninguno de los dos trae cuerpo de error**: para esos dos códigos se decide solo por status code.

Todo lo demás sale con este envelope:

```json
{ "timestamp": "...", "status": 409, "error": "Conflict",
  "message": "dni 30111222 is already in use in this club", "details": [] }
```

El envelope sale siempre como `application/json`, aunque el pedido haya mandado `Accept: application/pdf` (§6, reporte). `error` es el reason phrase de HTTP. `message` está **en inglés y no es estable** — nunca mostrarlo al usuario ni hacer matching sobre su texto. `details` solo se llena en validaciones, con strings `"campo: mensaje"`. **No hay `code` ni `fieldErrors`.**

| Status | Cuándo |
| :--- | :--- |
| `400` | Validación fallida (`details` por campo), body ilegible, `paidByMemberId` fuera del grupo familiar, `periodsCovered` con repetidos, rango `from` > `to` en la búsqueda de pagos o `paidFrom` > `paidTo` en el reporte, query param con un valor que no se puede parsear |
| `404` | El recurso no existe **en tu club** — indistinguible de uno de otro club, porque todo filtra por el `clubId` del token. Aplica a socios, grupos, pagos y admins |
| `409` | DNI ya usado en el club, un período que el socio ya tiene pago, un pago que ya estaba anulado, un socio que ya tiene grupo al crear un grupo con `memberIds`, o cualquier otra violación de constraint |
| `500` | Excepción no manejada |

---

## 5. Socios, grupos, admins y canchas

### Socios — `/api/members`

| Verbo | Ruta | Respuesta |
| :--- | :--- | :--- |
| `POST` | `/api/members` | `201` + `MemberResponse` · `404` · `409` |
| `GET` | `/api/members` | `200` + `MemberResponse[]` |
| `GET` | `/api/members/{id}` | `200` · `404` |
| `PATCH` | `/api/members/{id}` | `200` · `404` · `409` |
| `PATCH` | `/api/members/{id}/deactivate` · `/reactivate` | `200` · `404` |
| `PATCH` | `/api/members/{id}/family-group` | `200` · `404` |
| `DELETE` | `/api/members/{id}/family-group` | `200` · `404` |

```json
{ "id": 34, "firstName": "Marcos", "lastName": "Gomez", "dni": "30111222",
  "phone": "+54 11 4444-5555", "email": "marcos@example.com", "familyGroupId": 7,
  "joinedAt": "2026-09-19", "status": "ACTIVE",
  "createdAt": "...", "updatedAt": "...", "createdByUserId": 12, "updatedByUserId": 12 }
```

`phone`, `email` y `familyGroupId` son nullables. `status` es `ACTIVE` \| `INACTIVE`. **No trae nada de estado de cuota**: eso se cruza por `memberId` contra `/api/payments/delinquency` (§6).

**`GET`** devuelve todos los socios del club, activos e inactivos, por `createdAt` descendente, y **no acepta ningún query param**.

**`POST`** — `firstName` y `lastName` requeridos (≤ 100), `dni` requerido (≤ 20, único por club → `409`), `phone` (≤ 30), `email` (formato, ≤ 150) y `familyGroupId` (tiene que existir → `404`) opcionales. El servidor fija `joinedAt = hoy` y `status = ACTIVE`: **el cliente no puede mandar ninguno de los dos ni retrodatar un alta.** El `201` ya trae el recurso completo.

**`PATCH`** recibe `firstName`, `lastName`, `dni` (requeridos), `phone` y `email`. **No toca `familyGroupId` ni `status`** — esos se mueven por sus endpoints.

**`PATCH /{id}/family-group`** recibe `{ "familyGroupId": 7 }` (requerido → `400` si falta; `404` si el grupo no es del club). Si el socio ya estaba en otro grupo, **lo mueve** sin aviso. **`DELETE /{id}/family-group`** lo deja sin grupo y es idempotente: un socio sin grupo devuelve `200` igual. Ninguno de los dos mira `status`: se puede agrupar a un socio inactivo.

### Grupos familiares — `/api/family-groups`

`POST` (`201`), `GET` listado, `GET /{id}`, `PATCH /{id}` y `DELETE /{id}` (`204`). Respuesta: `{ id, name, createdAt, updatedAt, createdByUserId, updatedByUserId }`.

`name` es **opcional** (≤ 150) en el alta y en la edición: un grupo sin nombre es válido, y un `PATCH` sin `name` lo pone en `null`. La respuesta **no trae los integrantes ni cuántos son**: se filtra `GET /api/members` por `familyGroupId`.

**`POST`** acepta además `memberIds` opcional (`[10, 11]`, sin `null` → `400`; los repetidos se ignoran) y **crea el grupo con esos integrantes en una sola transacción**: `404` si alguno no es socio del club y `409` si alguno ya tiene grupo (el `message` lista los ids, sin `code` estable, §4); en los dos casos no se crea nada. Sin `memberIds`, o con la lista vacía, crea un grupo vacío como antes. No mira `status`.

**`DELETE /{id}`** saca a todos los integrantes del grupo (quedan sin grupo, con sus pagos intactos) y borra el grupo, en una transacción. `404` si el grupo no es del club.

### Administradores — `/api/admins` · solo `SUPER_ADMIN`

`POST` (`201`), `GET` listado, `GET /{id}`, `PATCH /{id}`, `PATCH /{id}/deactivate` y `/reactivate`.

```json
{ "id": 12, "dni": "30222333", "email": "admin@example.com", "memberId": 5,
  "active": true, "createdAt": "...", "updatedAt": "...",
  "createdByUserId": 1, "updatedByUserId": 1 }
```

**No trae `role`** (siempre es `ADMIN`) y modela la baja como **`active` booleano**, no con el enum `status` de `member`: el mapeo a dominio tiene que normalizar los dos shapes.

**`POST`** — `dni` requerido (≤ 20, único entre las cuentas del club), `password` requerida (**de 8 caracteres a 72 bytes UTF-8**: `@MaxUtf8Bytes`, porque BCrypt ignora lo que sigue; las letras con tilde y la ñ cuentan como dos), `email` y `memberId` opcionales. O sea que **la contraseña inicial la define el SUPER_ADMIN**: la API no genera ninguna. El `role` lo fija el servidor en `ADMIN`.

**`PATCH`** sobrescribe `dni`, `email` y `memberId`: mandar el body sin `memberId` **desvincula** al admin de su socio.

**El listado solo devuelve `role = ADMIN`.** El `SUPER_ADMIN` es una única cuenta seedeada en base y nunca aparece, así que no existe la fila que se podría dar de baja por error. Los admins dados de baja sí siguen en el listado, con `active: false`.

**Dos fuentes de `409` acá**: DNI repetido, y `memberId` ya tomado por otra cuenta (`UNIQUE (member_id)`). Sin `code` estable (§4), distinguirlas obliga a leer el `message`. Un `memberId` que no es un socio del club da `404`.

**`PATCH /api/admins/{id}/password`** — reset de la contraseña **de otro admin**, solo `SUPER_ADMIN` (un `ADMIN` recibe `403`). `{ "newPassword": "..." }`, con las mismas reglas que la contraseña inicial. Registra `sessions_revoked_at` y revoca los refresh tokens de esa cuenta: sus sesiones se cortan en el próximo request (§3). Devuelve el `AdminResponse`. Busca la cuenta con `role = ADMIN`, así que **con el id del SUPER_ADMIN da `404`**: el SUPER_ADMIN cambia la suya con `/api/auth/me/password`, y si la olvida, se cambia directamente en la base.

**`PATCH /api/auth/me/password`** — cambio de contraseña **de la cuenta logueada**, para `ADMIN` y `SUPER_ADMIN` (`MEMBER` → `403`). Body `{ "newPassword": "..." }`, con las mismas reglas que la contraseña inicial y sin pedir la actual (decisión de producto). Responde **`204` sin body**. Registra `sessions_revoked_at` y revoca los refresh tokens: se cierran todas las sesiones de la cuenta, incluida la que hizo el cambio (§3).

### Canchas — `/api/courts`

`POST` (`201`), `GET` listado, `GET /{id}`, `PATCH /{id}`, `PATCH /{id}/deactivate` y `/reactivate`. `ADMIN` y `SUPER_ADMIN`.

```json
{ "id": 3, "name": "Cancha de Pádel 1", "type": "Pádel",
  "openingTime": "08:00:00", "closingTime": "23:00:00", "active": true,
  "createdAt": "...", "updatedAt": "...", "createdByUserId": 2, "updatedByUserId": 2 }
```

**`POST` y `PATCH`** reciben `name` (requerido, ≤ 100), `type` (opcional, ≤ 50, texto libre: "Pádel", "Tenis"), `openingTime` y `closingTime` (requeridos, `"HH:mm"` o `"HH:mm:ss"`). Los horarios **vuelven siempre con segundos**. `PATCH` es reemplazo completo: sin `type`, lo borra. Ninguno de los dos toca `active`.

| Status | Cuándo |
| :--- | :--- |
| `400` | Validación, un horario ilegible (`"25:00"`), o `closingTime` que no es posterior a `openingTime` |
| `404` | La cancha no es del club |
| `409` | Otra cancha del club ya tiene ese nombre, **sin distinguir mayúsculas** |

**El horario es de un solo día**: cierra después de abrir, sin cruzar la medianoche. Una cancha que cierra a las 24 se carga con `23:59`. El listado trae activas e inactivas, por nombre.

**`courtsEnabled`** de `/api/clubs/me` no bloquea estos endpoints: es la señal para que la app muestre la gestión de canchas.

### Bloqueos de cancha — `/api/courts/{courtId}/blocks`

PR #26, en `develop` y todavía no en `main`. `POST` (`201`), `GET` listado y `DELETE /{courtBlockId}` (`204`). `ADMIN` y `SUPER_ADMIN`.

```json
{ "id": 8, "courtId": 3, "startsAt": "2026-08-03T08:00:00", "endsAt": "2026-08-05T23:59:00",
  "reason": "Mantenimiento de superficie", "createdAt": "2026-07-30T12:00:00Z", "createdByUserId": 2 }
```

**`startsAt` y `endsAt` son hora local del club, sin zona** (`TIMESTAMP`): se leen y se mandan como `"yyyy-MM-ddTHH:mm[:ss]"`, nunca como instante UTC. `createdAt` sí es UTC, como en el resto de la API. `reason` es opcional (≤ 150). `endsAt` tiene que ser posterior a `startsAt` → si no, `400`. Un bloqueo puede durar varios días, solaparse con otro y caer en una cancha dada de baja.

**`GET`** acepta `from` y `to` opcionales (`yyyy-MM-dd`) y devuelve **los bloqueos que tocan ese rango**, por inicio: `from` deja los que terminan después de que empieza ese día; `to`, los que empiezan antes de que termine. Sin parámetros, todos los de la cancha. `from` > `to` → `400`; una fecha ilegible → `400` con `details: ["from: invalid value"]`.

**`DELETE`** borra la fila: la tabla no tiene estado. `404` si la cancha no es del club o el bloqueo no es de esa cancha.

### Reservas — `/api/reservations`

PR #27, en `develop` y todavía no en `main`. `POST` (`201`), `GET ?date=yyyy-MM-dd[&courtId=]` y `PATCH /{id}/cancel`. `ADMIN` y `SUPER_ADMIN`.

```json
{ "id": 20, "courtId": 3, "memberId": 10, "source": "MEMBER", "recurringSlotId": null,
  "description": null, "date": "2026-11-09", "startTime": "22:00:00", "endTime": "23:00:00",
  "status": "CONFIRMED", "createdAt": "...", "createdByUserId": 2,
  "cancelledAt": null, "cancelledByUserId": null }
```

**`source`** dice de dónde sale la reserva: `MEMBER` (suelta), `RECURRING` (una fecha del turno fijo de un socio) o `ACTIVITY` (una fecha de una actividad del club, sin socio). `recurringSlotId` y `description` llegan con el PR #28: `recurringSlotId` viene en `RECURRING` y `ACTIVITY` y es `null` en `MEMBER`; `description` es la de la actividad y solo viene en `ACTIVITY`. **`memberId` es `null` solo en `ACTIVITY`.** Antes del PR #28 todas las reservas son `MEMBER`.

**`POST`** recibe `courtId`, `memberId`, `date`, `startTime` y `endTime` (todos requeridos; horarios `HH:mm`, en hora del club). Valida en este orden: club con `courtsEnabled`, cancha y socio del club y activos, que termine después de empezar y entre en el horario de la cancha, y que no empiece en el pasado (con la hora del club, no la del servidor) → `400` o `404`. Que no caiga en un bloqueo ni se superponga con otra reserva confirmada → **`409`**. Dos reservas consecutivas (una termina 22:00 y la otra empieza 22:00) no se superponen. **No fija duración**: la app ofrece 60, 90 o 120 minutos. Un socio moroso reserva igual; el aviso lo da la app.

**`GET`** trae solo las **confirmadas** de ese día, de todas las canchas del club o de una, por hora de inicio, **de cualquier origen**: con el PR #28 incluye las fechas de turnos fijos y de actividades. `date` es obligatorio (`400` con `details: ["date: date is required"]`).

**`PATCH /{id}/cancel`** pasa la reserva a `CANCELLED`, con `cancelledAt` y `cancelledByUserId`. Ya cancelada → `409`. Sirve también para **saltear una fecha** de un turno fijo o de una actividad: el turno sigue las demás semanas.

**Dar de baja una cancha** (`PATCH /api/courts/{id}/deactivate`) **cancela las reservas confirmadas de esa cancha que empiezan después de ahora** (hora del club), en la misma transacción y a nombre de quien la da de baja. Las que ya empezaron quedan como estaban. Con el PR #28, además **da de baja los turnos fijos de la cancha**, incluidos los de actividades. Reactivar la cancha no recupera ni las reservas ni los turnos.

**Dar de baja un socio** (`PATCH /api/members/{id}/deactivate`), con el PR #28, **cancela todas sus reservas que todavía no empezaron** (sueltas y de turnos fijos, en cualquier cancha) **y da de baja sus turnos fijos**, en una transacción. Reactivarlo no los recupera.

### Turnos fijos — `/api/recurring-slots`

**PR #28, todavía abierto.** `ADMIN` y `SUPER_ADMIN`.

| Verbo | Ruta | Respuesta |
| :--- | :--- | :--- |
| `POST` | `/api/recurring-slots` | `201` · `400` · `404` · `409` |
| `GET` | `/api/recurring-slots?courtId=&memberId=&state=` | `200` · `400` (`state` inválido) · `404` (cancha o socio de otro club) |
| `GET` | `/api/recurring-slots/{id}` | `200` · `404` |
| `PATCH` | `/api/recurring-slots/{id}/deactivate` | `200` · `404` · `409` (ya estaba dado de baja) |
| `POST` | `/api/recurring-slots/{id}/renew` | `201` con el turno **nuevo** · `400` · `404` · `409` |

```json
{ "id": 4, "courtId": 3, "memberId": 10, "description": null, "dayOfWeek": "TUESDAY",
  "startTime": "18:00:00", "endTime": "19:00:00", "validFrom": "2026-11-17", "validUntil": "2027-03-30",
  "active": true, "state": "CURRENT", "createdAt": "...", "createdByUserId": 2,
  "deactivatedAt": null, "deactivatedByUserId": null }
```

Un turno es **de un socio** (`memberId`) **o de una actividad del club** (`description`, ≤ 100): exactamente uno de los dos. Una descripción en blanco cuenta como ausente. `dayOfWeek` va de `MONDAY` a `SUNDAY` (en base es el número ISO, 1 a 7). Los horarios vuelven con segundos, como en las canchas.

**`state`** lo calcula el servidor con la fecha del club: `CURRENT` (activo y vigente), `EXPIRED` (activo con `validUntil` anterior a hoy) o `INACTIVE` (dado de baja). El listado va por día, hora de inicio e id; sin `state` trae todos.

**`POST`** recibe `courtId`, `memberId` o `description`, `dayOfWeek`, `startTime` y `endTime` (`HH:mm`), `validFrom` y `validUntil`. **Genera todas las fechas como reservas en la misma transacción**: desde el primer `dayOfWeek` a partir de `validFrom`, cada 7 días hasta `validUntil` incluido; si la primera fecha es hoy y ya empezó, se omite.

| Condición | Error |
| :--- | :--- |
| El club no tiene canchas habilitadas | `400` |
| La cancha no es del club / está inactiva | `404` / `400` |
| No viene exactamente uno de socio o descripción | `400` |
| El socio no es del club / está inactivo. **Estar en mora no lo impide** | `404` / `400` |
| El horario no entra en el de la cancha o termina antes de empezar | `400` |
| `validFrom` anterior a hoy | `400` |
| `validUntil` no posterior a `validFrom`, o a más de un año | `400` |
| No queda ninguna fecha futura | `400` |
| **Alguna fecha choca con una reserva o un bloqueo: se rechaza todo** | `409` |

El `409` por choques lista las fechas en `details`:

```json
{ "message": "recurring slot conflicts with existing reservations or court blocks",
  "details": ["2026-12-01: court already reserved", "2026-12-08: court blocked"] }
```

Si dos pedidos chocan entre sí al mismo tiempo, el `409` es el genérico de constraint, **sin `details`**.

**No se edita**: para cambiar un turno se da de baja y se crea otro.

**`PATCH /{id}/deactivate`** cancela las fechas que todavía no empezaron (hora del club); las pasadas quedan. **No hay `/reactivate`.**

**`POST /{id}/renew`** recibe `{ "validFrom", "validUntil" }` y crea un turno nuevo copiando cancha, socio o descripción, día y horario, con las mismas reglas que el alta. **No da de baja el original** y funciona con cualquier `state`. Si la vigencia nueva se superpone con la del original, las fechas comunes salen como choques en el `409`: la nueva tiene que empezar después del `validUntil` del original.

### Bajas lógicas

Socios, admins y canchas nunca se borran físicamente, y los tres son reversibles con `/reactivate`. Los turnos fijos tampoco se borran, pero su baja **no se revierte**: se crea uno nuevo o se renueva. Lo único que se borra de verdad es un grupo familiar y un bloqueo de cancha (más arriba en esta sección):

| Entidad | En la respuesta |
| :--- | :--- |
| `member` | `status: "INACTIVE"` |
| `user_account` (admin) | `active: false` |
| `court` | `active: false` |
| `recurring_slot` | `active: false`, `state: "INACTIVE"`, con `deactivatedAt` |

Una cuenta con `active: false` **no puede loguear**, y el rechazo es indistinguible de una contraseña incorrecta (§3).

**La baja de un admin es inmediata.** `PATCH /api/admins/{id}/deactivate` pone `active = false`, registra `sessions_revoked_at` y revoca sus refresh tokens: su próximo request da `401`, el refresh también, y la sesión se cierra (§3). Reactivar no le devuelve las sesiones cortadas: vuelve a ingresar.

### Club — `/api/clubs/me`

```json
{ "id": 1, "name": "Club 1", "monthlyFeeAmount": 15000.00, "courtsEnabled": false,
  "updatedAt": "...", "updatedByUserId": 1 }
```

`GET` devuelve el club del token. `monthlyFeeAmount` es la **cuota de referencia** y es nullable: un club recién migrado no la tiene cargada. El `name` lo pone la migración como `"Club <id>"` hasta que se configure por entorno.

`courtsEnabled` (PR #25) dice si el club tiene habilitada la etapa de canchas. Es `false` hasta que se prende en la base; no hay endpoint para cambiarlo. Una API sin el PR #25 no manda el campo: la app lo lee como `false`.

`PATCH` (`ADMIN` y `SUPER_ADMIN`) recibe `{ "monthlyFeeAmount": 16000 }` (> 0, hasta 8 enteros y 2 decimales); mandarlo en `null` borra la cuota de referencia. Es solo una referencia: **no cambia ningún pago** ni la forma de calcular la mora, y `POST /api/payments` sigue exigiendo el `amount` explícito.

---

## 6. Pagos

`/api/payments` · `ADMIN` + `SUPER_ADMIN`

| Verbo | Ruta | Respuesta |
| :--- | :--- | :--- |
| `POST` | `/api/payments` | `201` + `PaymentResponse[]` · `400` · `404` · `409` |
| `POST` | `/api/payments/batch` | `201` + `PaymentResponse[]` · `400` · `404` · `409` |
| `GET` | `/api/payments` | `200` + `PaymentResponse[]` · `400` |
| `GET` | `/api/payments/members/{memberId}` | `200` + `PaymentResponse[]` · `404` |
| `PATCH` | `/api/payments/{paymentId}/void` | `200` + `PaymentResponse` · `404` · `409` |
| `GET` | `/api/payments/delinquency` | `200` + `MemberDelinquencyResponse[]` |
| `GET` | `/api/payments/receipts` | `200` + PDF · `204` · `400` |

### `POST /api/payments`

`memberId` requerido (`404` si no está en el club), `paidByMemberId` opcional, `amount` requerido (> 0, hasta 8 enteros y 2 decimales), `periodsCovered` requerido (array no vacío de fechas, **sin repetidos** → `400`) y `paymentMethod` requerido (`CASH` \| `TRANSFER` \| `OTHER`).

**`amount` es por período, no el total.** El servidor crea **una fila por cada fecha de `periodsCovered`, cada una con el `amount` completo**: pagar junio y julio con `amount: 15000` registra dos pagos de 15 000, o sea 30 000. Devuelve el array de pagos creados, todo en una transacción.

Convención de `periodsCovered`: el **primer día del mes** que se paga — `"2026-07-01"` es la cuota de julio de 2026.

**`paidByMemberId`**: nulo o igual a `memberId` se guarda como `null` ("pagó el propio socio" se representa con `null`). Si viene otro socio, tiene que **compartir un `familyGroupId` no nulo** con el socio de la cuota, o `400`; dos socios los dos sin grupo no cuentan como el mismo grupo. No hay cuota familiar compartida: siempre se paga la cuota de un socio.

**Rechaza un período que ya está pago → `409`**, y rechaza el pedido entero: si uno solo de los meses ya tiene un pago no anulado, no se registra ninguno. Lo controla dos veces: el servicio compara contra los pagos vigentes antes de guardar (el `message` lista los períodos, pero sin `code` estable, §4), y un índice único parcial en base (§8) frena los dos pedidos simultáneos que pasan juntos ese control — ese `409` llega con el mensaje genérico de constraint. Un período **anulado** sí se puede volver a pagar.

```json
{ "id": 88, "memberId": 34, "paidByMemberId": null, "amount": 15000.00,
  "paidAt": "...", "periodCovered": "2026-07-01", "paymentMethod": "CASH",
  "recordedByUserId": 12, "createdAt": "...",
  "voidedAt": null, "voidedByUserId": null, "voidReason": null }
```

### `POST /api/payments/batch`

Registra los pagos de **varios socios en una sola transacción**: `{ "payments": [RecordPaymentRequest, …] }`, cada entrada con las mismas reglas que `POST /api/payments` (un socio por entrada, con su `paidByMemberId`, `amount` y `periodsCovered`).

- La lista no puede venir vacía ni con entradas `null` → `400`. Las validaciones de cada entrada nombran su posición en `details` (`"payments[1].amount: amount must be greater than zero"`).
- **Todo o nada**: si una entrada falla — socio fuera del club (`404`), pagador fuera del grupo o meses repetidos (`400`), período ya pago (`409`) —, no se registra ninguna. El `message` nombra el `memberId` de la entrada que falló, sin `code` estable (§4).
- `201` con la **lista plana** de los pagos creados de todas las entradas, una fila por socio y mes.

### `GET /api/payments/members/{memberId}`

Historial del socio por `periodCovered` descendente. **Por defecto oculta los pagos anulados**: con `?includeVoided=true` los incluye, con `voidedAt`, `voidedByUserId` y `voidReason` cargados. `404` si el socio no es del club.

### `PATCH /api/payments/{paymentId}/void`

Anula un pago: body opcional `{ "reason": "..." }` (≤ 150; vacío o en blanco se guarda como `null`). Lo puede hacer **cualquier `ADMIN` o `SUPER_ADMIN`**. Devuelve el pago con los tres campos de anulación cargados.

- **Es una baja lógica sin vuelta atrás**: el pago sigue en la base, pero no hay endpoint para des-anularlo. Si fue un error, se registra un pago nuevo.
- Se anula **un período por vez**: un pago de dos meses son dos filas, y cada una se anula por separado.
- `404` si el pago no es del club; `409` si ya estaba anulado (lo anuló otro admin, o es un doble toque).
- Un pago anulado **deja de contar para la mora** (§7) y desaparece del historial por defecto.

### `GET /api/payments` — búsqueda

Todos los pagos del club, del `paidAt` más reciente al más viejo. Filtros opcionales por query param: `memberId`, `from` y `to` (fechas ISO, **sobre `periodCovered`, no sobre la fecha de carga**; `from` > `to` → `400`), `paymentMethod` e `includeVoided` (por defecto, sin anulados). Sin paginar.

### `GET /api/payments/receipts` — tabletas de cuotas cobradas

En `develop` desde el PR #22 de la API; todavía no en `main` (§1).

Query params `paidFrom` y `paidTo`, los dos requeridos, en formato `"2026-10-01"`. Filtra por **fecha de cobro** (`paid_at`), en días calendario de Argentina e incluyendo los dos extremos, y deja afuera los pagos anulados. `paidFrom` > `paidTo` → `400`.

- `200` con `Content-Type: application/pdf` y `Content-Disposition: attachment; filename="cuotas-cobradas-<paidFrom>-al-<paidTo>.pdf"`. Es un A4 hecho con PDFBox: una tableta por grupo familiar y mes cubierto (o por socio si no tiene grupo), con cada socio que pagó ese mes, su importe y el total; cada tableta sale dos veces lado a lado, con líneas de corte, y nunca se parte entre páginas. Orden alfabético (es-AR) por el primer socio y después por mes.
- **`204` sin cuerpo si no hubo cobros** en el rango: no es un error.
- Un `400` llega con el envelope de error en `application/json` aunque el pedido haya mandado `Accept: application/pdf` (§4).
- Abierto a `ADMIN` y `SUPER_ADMIN`, como el resto de `/api/payments/**`.

### `GET /api/payments/delinquency`

```json
[ { "memberId": 34, "firstName": "Marcos", "lastName": "Gomez",
    "lastPeriodCovered": "2026-07-01", "daysOverdue": 45 } ]
```

- Devuelve **una fila por cada socio `ACTIVE`**, no solo por los morosos: las filas con `daysOverdue: 0` son socios al día. Los inactivos no aparecen nunca.
- Por eso `response.length` **es** la cantidad de socios activos del club, y las filas con `daysOverdue > 0` son los morosos: los dos contadores salen de esta única llamada.
- Ordenado por `daysOverdue` descendente. `lastPeriodCovered` es `null` si el socio nunca pagó.
- **No trae `dni` ni `status`**: para una fila de listado completa hay que cruzar contra `GET /api/members`.

---

## 7. Cómo se calcula la mora

Nunca es una columna guardada: se computa en cada llamada, así que no puede desincronizarse.

```
lastPeriodCovered = MAX(period_covered) de los pagos no anulados del socio   // null si nunca pagó
coverageStart     = lastPeriodCovered != null ? lastPeriodCovered + 1 mes
                                              : primer día del mes de member.joinedAt
daysOverdue       = max(0, días entre coverageStart y hoy)
```

- **No hay días de gracia**: quien pagó septiembre figura con 5 días de mora el 6 de octubre.
- **Un socio recién creado nace en mora.** `joinedAt` es la fecha del alta y `coverageStart` el primer día de ese mes, así que uno cargado el día 20 aparece con 19 días. No hay forma de dar de alta a alguien al día salvo registrarle el pago del mes.
- Se mide en **días**, no en cuotas ni en meses.
- **Ignora los huecos**: quien pagó enero y después diciembre figura al día, porque solo se mira el máximo. La API no modela cuotas adeudadas una por una.
- No mira quién pagó: `paidByMemberId` no afecta el cálculo.
- **Ignora los pagos anulados**: anular el último mes pago vuelve a correr la mora desde ese mes.
- `status` y mora son **dos ejes independientes** — un socio puede estar `ACTIVE` y en mora a la vez — y la API nunca los combina en un solo estado.

---

## 8. Modelo de datos

**Seis tablas** (migraciones `V1`–`V13`): `user_account`, `member`, `family_group`, `refresh_token`, `payment` y `club`; con el PR #25, siete (`V14` crea `court`), y con el #26, ocho (`V15` crea `court_block`), con el #27, nueve (`V16` crea `reservation` y habilita `btree_gist`), y con el #28 (abierto), diez (`V17` crea `recurring_slot` y suma `reservation.recurring_slot_id`). El diseño de nueve tablas del `README` del backend es el plan, no el estado.

**`club`** tiene `name`, `address`, `courts_enabled`, `member_app_enabled` y `monthly_fee_amount` (la cuota de referencia, nullable y > 0). `member.club_id` y `user_account.club_id` ya tienen FK a esa tabla; cada query sigue filtrando por el `clubId` del token, y las hojas quedan alcanzadas vía `member_id` / `user_account_id`. **`courts_enabled` sale como `courtsEnabled` en `GET /api/clubs/me` desde el PR #25; `member_app_enabled` no lo expone ningún endpoint.**

**`court`** (PR #25) tiene `club_id` (FK a `club`), `name`, `type` nullable, `opening_time`, `closing_time`, `active` y las cuatro columnas de auditoría.

**`recurring_slot`** (PR #28) tiene `court_id`, `member_id` o `description`, `day_of_week` (ISO, 1 a 7), `start_time`, `end_time`, `valid_from`, `valid_until`, `active`, `created_at`, `created_by_user_id`, `deactivated_at` y `deactivated_by_user_id`. Sin `club_id`: queda en el club por su cancha.

**`payment`** suma `voided_at`, `voided_by_user_id` y `void_reason` (≤ 150): los dos primeros van juntos o en `null`, y el motivo solo puede existir en un pago anulado. `user_account.member_id` tiene FK a `member` desde `V8`, y `user_account.sessions_revoked_at` (`V13`, nullable) guarda el último corte de sesiones de la cuenta (§3). No viaja en ninguna respuesta.

Constraints que el cliente ve como comportamiento HTTP:

| Constraint | Efecto |
| :--- | :--- |
| `user_account UNIQUE (club_id, dni)` · `member UNIQUE (club_id, dni)` | El `409` de DNI duplicado. Único **por club**, no global: por eso el login pide el club |
| `user_account UNIQUE (member_id)` | Un socio no puede tener dos cuentas — el segundo `409` de `/api/admins`. Varios `NULL` sí se permiten |
| `CHECK (role <> 'SUPER_ADMIN' OR member_id IS NULL)` | El `memberId` del super admin es siempre `null` |
| `CHECK (amount > 0)` en `payment` | Refuerza la validación del `POST` |
| `court UNIQUE (club_id, LOWER(name))` · `CHECK (closing_time > opening_time)` (`V14`) | El `409` de nombre repetido aun con dos altas a la vez, y el `400` de horario como última defensa |
| `court_block CHECK (ends_at > starts_at)` (`V15`) | El `400` de un bloqueo que no termina después de empezar, como última defensa |
| `reservation EXCLUDE USING gist` (`V16`), por cancha y rango, solo entre confirmadas | Dos reservas superpuestas en la misma cancha son imposibles aun si llegan a la vez: la segunda da el `409` genérico de constraint |
| `recurring_slot CHECK ((member_id IS NULL) <> (description IS NULL))` · tope de un año · `active = (deactivated_at IS NULL)` (`V17`) | Socio o actividad, nunca los dos ni ninguno; la vigencia no pasa de un año; un turno dado de baja siempre trae `deactivatedAt` |
| `reservation CHECK ((member_id IS NULL) = (source = 'ACTIVITY'))` · `CHECK ((recurring_slot_id IS NULL) = (source = 'MEMBER'))` (`V17`) | `memberId` es `null` si y solo si es una actividad; `recurringSlotId` es `null` si y solo si es suelta |
| `UNIQUE (member_id, period_covered) WHERE voided_at IS NULL` (`V12`) | Un período tiene a lo sumo un pago vigente: el segundo da `409`, aun si los dos pedidos llegan a la vez. Anular libera el período |

`user_account`, `member` y `family_group` llevan `created_at`, `updated_at`, `created_by_user_id` y `updated_by_user_id`, todas expuestas en las respuestas, por si hace falta mostrar "cargado por".

Un nullable acá nunca es "falta el dato", es parte del significado de la fila: `payment.paid_by_member_id = null` es "pagó el propio socio"; `user_account.member_id = null` es "esta cuenta no es socia".

---

## 9. Trampas

Lo que es fácil codear mal porque el contrato dice otra cosa de la que uno espera. Todo lo de acá está explicado arriba; esta tabla es el checklist.

| Trampa | Si se ignora | § |
| :--- | :--- | :--- |
| `amount` es por período, no el total | Pagar 3 meses con el total cobra el triple en base | 6 |
| `PATCH` es reemplazo completo | Editar el teléfono con un body parcial borra el email | 2 |
| `PATCH /api/admins/{id}` sin `memberId` | El admin pierde el vínculo con su socio | 5 |
| Un socio recién creado figura en mora | El alta "funciona" y el socio aparece en rojo al instante | 7 |
| `/delinquency` trae a todos los activos | Contar filas da los activos, no los morosos | 6 |
| El historial oculta los anulados por defecto | Sin `?includeVoided=true` un pago anulado desaparece sin rastro | 6 |
| Anular no se revierte | Un toque de más deja un mes impago que hay que volver a registrar | 6 |
| La búsqueda de pagos filtra por mes cubierto | Un rango "de octubre" trae lo que cubre octubre, no lo cobrado en octubre | 6 |
| El `message` de los errores no es estable | Matchear texto se rompe cuando el backend corrige una redacción | 4 |
| `401` y `403` no traen cuerpo | Parsear la respuesta para leer `message` revienta | 4 |
| `GET /api/members` ignora todo query param | Un `?page=` o `?search=` vuelve la lista completa, en silencio | 5 |
| El `clubId` no vuelve en el login | No se puede derivar de la sesión | 3 |
| El máximo de una contraseña es en bytes UTF-8, no en caracteres | Una de 40 letras con tilde pasa un `maxLength` y vuelve `400` | 5 |
| `POST /api/payments` no es transaccional entre socios | Un pago de varios socios con un `POST` por socio puede quedar a medias; para todo o nada está `/batch` | 6 |
| Los horarios de cancha vuelven con segundos | Comparar `"08:00"` con `"08:00:00"` da distinto | 5 |
| Los bloqueos son hora local del club, sin zona | Mandar `toUtc().toIso8601String()` corre el bloqueo tres horas | 5 |
| `memberId` de una reserva es `null` en las actividades | Asumir que toda reserva tiene socio revienta la agenda con la primera clase de tenis | 5 |
| Renovar no da de baja el turno original, y una vigencia superpuesta da `409` | Renovar "desde hoy" un turno vigente choca consigo mismo | 5 |
| El `409` de un turno fijo puede venir sin `details` | Si llegan dos altas a la vez no hay fechas para mostrar: hace falta un mensaje genérico | 5 |
| Cancelar una reserva ya cancelada da `409` | Mostrar un error cuando otro admin ya la había cancelado. La app la toma como cancelada | 5 |

---

## 10. Lo que no existe

Verificado por ausencia en `develop`. La columna de entregas refiere a [app_flows.md](app_flows.md) §8.

| Falta | Bloquea |
| :--- | :--- |
| Paginación, búsqueda y filtro por estado en `GET /api/members` | E4 a escala — hoy se trae el listado completo y filtra el cliente |
| Contadores por estado para los chips del listado | E4 |
| Cargar el último mes pagado en el alta de socio | E6 — el socio recién creado nace en mora desde el 1° del mes (§7) |
| `code` estable y `fieldErrors` en el envelope de error | Mapear un error al campo del formulario (E5, E8) |
| Filtro de `GET /api/payments` por fecha de carga (`paidAt`) | Nada hoy: el reporte de E10 filtra por fecha de cobro en el backend. La búsqueda sigue filtrando por mes cubierto |
| Mora de un socio y padrón de su grupo familiar sin bajar todo el club (filtro por `memberId` en `GET /api/payments/delinquency`, por `familyGroupId` en `GET /api/members`) | Cuotas del socio a escala — hoy cada apertura del ledger trae el padrón entero y la mora de todo el club para mostrar a un socio. La verificación previa al registrar ya no lo necesita: usa `GET /api/members/{id}` y el historial del socio |
| Edición de un pago | Corregir un pago es anularlo y registrarlo de nuevo |
| Fecha de baja de un socio (`deactivatedAt` o un historial de estado): `PATCH /deactivate` solo cambia `status`, y `updatedAt` se mueve con cualquier edición | "Socios dados de baja por mes" en Reportes y métricas: hoy no se muestra |
| Un resumen agregado de cobros por mes, filtrable por fecha de cobro (`paidFrom`/`paidTo`, como `GET /api/payments/receipts`) | Nada hoy: Reportes y métricas suma en el cliente sobre `GET /api/payments` completo, que no pagina, crece unas 12 filas por socio por año y se vuelve a bajar con cada aviso de pagos o socios mientras la pantalla está abierta. Con el filtro, pediría solo los 6 meses que muestra el gráfico |
| Días de gracia configurables | El umbral de "en mora" |
| Mostrar a un ADMIN quién cargó o anuló un pago: `recordedByUserId` y `voidedByUserId` no se pueden traducir a una persona (`GET /api/admins` es solo para SUPER_ADMIN y un admin no tiene nombre) | "Quién lo cargó" en el detalle del pago |
| Datos de contacto del club en `GET /api/clubs/me` | El canal de contacto de Recuperar contraseña (E11) |
| Asignar grupo en el alta y en la edición de forma pareja: `POST /api/members` acepta `familyGroupId` y `PATCH` no | Nada hoy: el grupo se arma desde las cuotas del socio (E6.5) |
| Reset de contraseña de un **socio** por un ADMIN / SUPER_ADMIN | E12+ — existe solo para cuentas de admin (§5); un socio todavía no tiene cuenta |
| Registro del socio con DNI, emparejado con el socio que ya cargó el admin (documento técnico V6, Etapa 3) | Registro del socio en `/login/activate` (E12+) |
| Turnos fijos en `develop`: están en el PR #28, todavía abierto | **Turnos fijos** (E9d) |
| Preview de las reservas que pisa un bloqueo nuevo, y que crear el bloqueo las cancele (decidido en club-management-api#26). Hoy un bloqueo no mira las reservas | El flujo §4.5 de la app (listarlas antes de confirmar el bloqueo), E9d |
| Cualquier endpoint que acepte un token `MEMBER` (§4) | **E12+ completa** |
| `POST /api/auth/logout` con revocación | Nada: el logout es local, y el refresh descartado vence solo |
| Listado de clubes y nombre real configurado | Selector de club. `GET /api/clubs/me` ya da el club del token, con un nombre provisorio |

No hay, ni va a haber, recuperación de contraseña por email: el reset es una acción manual de un ADMIN o SUPER_ADMIN, decisión de arquitectura ya tomada del lado de la API.
