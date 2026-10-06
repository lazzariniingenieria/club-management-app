# Contrato del backend — `club-management-api`

Fuente de verdad única de lo que la API expone. Ante una duda sobre endpoints, shapes, errores o reglas del servidor, se contesta acá y no leyendo el repo del backend.

**Verificado contra** [`club-management-api`](https://github.com/lazzariniingenieria/club-management-api) `develop`, commit `142b070` — 2026-10-06.

**Cómo se refresca**: releer `controller/`, `dto/`, `entity/`, `security/`, `config/SecurityConfig`, `exception/GlobalExceptionHandler` y `db/migration/` — eso es todo el contrato. Actualizar lo que cambió y mover el commit de arriba.

**Qué no va acá**: pantallas, flujos y entregas van en [app_flows.md](app_flows.md); reglas de código, en [CLAUDE.md](CLAUDE.md).

| | |
| :--- | :--- |
| [1. Entorno](#1-entorno) | [6. Pagos](#6-pagos) |
| [2. Convenciones](#2-convenciones) | [7. Cómo se calcula la mora](#7-cómo-se-calcula-la-mora) |
| [3. Autenticación](#3-autenticación) | [8. Modelo de datos](#8-modelo-de-datos) |
| [4. Autorización y errores](#4-autorización-y-errores) | [9. Trampas](#9-trampas) |
| [5. Socios, grupos y admins](#5-socios-grupos-y-admins) | [10. Lo que no existe](#10-lo-que-no-existe) |

---

## 1. Entorno

Dos entornos en Railway con su propio Postgres: **producción** (deploy desde `main`) y **test** (desde `develop`).

| Dato | Valor |
| :--- | :--- |
| Prefijo de rutas | **`/api`**, sin segmento de versión — `/api/v1` no existe |
| `API_BASE_URL` | `https://<host>/api` — incluye el prefijo, sin barra final |
| URLs de los dos entornos | **No están en el repo**: son variables de Railway. Hay que pedirlas |

---

## 2. Convenciones

| Convención | Valor real |
| :--- | :--- |
| Verbos | `GET`, `POST`, `PATCH` y **un** `DELETE` (§5). No hay `PUT`: usarlo da **405** |
| `id` | **Números** JSON (`Long`), nunca strings. Parsear con `(json['id'] as num).toInt()` |
| `PATCH` | **Reemplazo completo** de los campos del DTO, no un merge: omitir un campo lo escribe en `null` |
| Fechas de día | `"2026-09-01"` — ISO, sin hora ni zona (`joinedAt`, `periodCovered`, `lastPeriodCovered`) |
| Timestamps | `"2026-09-19T23:09:57.123456Z"` — ISO-8601 UTC. Es el default de Spring Boot, sin configuración explícita: **confirmar en la primera pantalla que los consuma** |
| Montos | Número JSON con hasta 2 decimales. `NUMERIC(10,2)` en base, nunca parsear a `double` para operar |
| Enums | Strings en `SCREAMING_SNAKE_CASE` |
| Listados | Array JSON plano, sin envelope ni metadata. **Ningún endpoint pagina** |
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

### Claims del JWT

`sub` (= `userAccountId` como string), `userAccountId`, `clubId`, `role`, `memberId` (ausente si es `null`), `iat`, `exp`.

---

## 4. Autorización y errores

| Ruta | Quién entra |
| :--- | :--- |
| `/api/auth/login`, `/api/auth/refresh` | público |
| `/api/admins/**` | **solo `SUPER_ADMIN`** |
| `/api/members/**`, `/api/family-groups/**`, `/api/payments/**` | `ADMIN`, `SUPER_ADMIN` |

**Un token con `role = MEMBER` no entra a ningún endpoint implementado.** Puede autenticarse y nada más.

`401` es sesión ausente, inválida o vencida; `403` es rol insuficiente. Los emite la cadena de filtros de Spring Security, no el handler global, así que **ninguno de los dos trae cuerpo de error**: para esos dos códigos se decide solo por status code.

Todo lo demás sale con este envelope:

```json
{ "timestamp": "...", "status": 409, "error": "Conflict",
  "message": "dni 30111222 is already in use in this club", "details": [] }
```

`error` es el reason phrase de HTTP. `message` está **en inglés y no es estable** — nunca mostrarlo al usuario ni hacer matching sobre su texto. `details` solo se llena en validaciones, con strings `"campo: mensaje"`. **No hay `code` ni `fieldErrors`.**

| Status | Cuándo |
| :--- | :--- |
| `400` | Validación fallida (`details` por campo), body ilegible, `paidByMemberId` fuera del grupo familiar, `periodsCovered` con repetidos |
| `404` | El recurso no existe **en tu club** — indistinguible de uno de otro club, porque todo filtra por el `clubId` del token |
| `409` | DNI ya usado en el club, o cualquier otra violación de constraint |
| `500` | Excepción no manejada |

---

## 5. Socios, grupos y admins

### Socios — `/api/members`

| Verbo | Ruta | Respuesta |
| :--- | :--- | :--- |
| `POST` | `/api/members` | `201` + `MemberResponse` · `404` · `409` |
| `GET` | `/api/members` | `200` + `MemberResponse[]` |
| `GET` | `/api/members/{id}` | `200` · `404` |
| `PATCH` | `/api/members/{id}` | `200` · `404` · `409` |
| `PATCH` | `/api/members/{id}/deactivate` · `/reactivate` | `200` · `404` |
| `PATCH` | `/api/members/{id}/family-group` | `200` · `404` |
| `DELETE` | `/api/members/{id}/family-group` | `200` · `404` — el único `DELETE` de la API |

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

### Grupos familiares — `/api/family-groups`

`POST` (`201`), `GET` listado, `GET /{id}` y `PATCH /{id}`. Respuesta: `{ id, name, createdAt, updatedAt, createdByUserId, updatedByUserId }`.

`name` es **opcional** (≤ 150) en el alta y en la edición: un grupo sin nombre es válido, y un `PATCH` sin `name` lo pone en `null`. La respuesta **no trae los integrantes ni cuántos son**: se filtra `GET /api/members` por `familyGroupId`.

### Administradores — `/api/admins` · solo `SUPER_ADMIN`

`POST` (`201`), `GET` listado, `GET /{id}`, `PATCH /{id}`, `PATCH /{id}/deactivate` y `/reactivate`.

```json
{ "id": 12, "dni": "30222333", "email": "admin@example.com", "memberId": 5,
  "active": true, "createdAt": "...", "updatedAt": "...",
  "createdByUserId": 1, "updatedByUserId": 1 }
```

**No trae `role`** (siempre es `ADMIN`) y modela la baja como **`active` booleano**, no con el enum `status` de `member`: el mapeo a dominio tiene que normalizar los dos shapes.

**`POST`** — `dni` requerido (≤ 20, único entre las cuentas del club), `password` requerida (**8 a 100 caracteres**), `email` y `memberId` opcionales. O sea que **la contraseña inicial la define el SUPER_ADMIN**: la API no genera ninguna. El `role` lo fija el servidor en `ADMIN`.

**`PATCH`** sobrescribe `dni`, `email` y `memberId`: mandar el body sin `memberId` **desvincula** al admin de su socio.

**El listado solo devuelve `role = ADMIN`.** El `SUPER_ADMIN` es una única cuenta seedeada en base y nunca aparece, así que no existe la fila que se podría dar de baja por error. Los admins dados de baja sí siguen en el listado, con `active: false`.

**Dos fuentes de `409` acá**: DNI repetido, y `memberId` ya tomado por otra cuenta (`UNIQUE (member_id)`). Sin `code` estable (§4), distinguirlas obliga a leer el `message`.

### Bajas lógicas

Nunca hay borrado físico, y los dos modelos son reversibles con `/reactivate`:

| Entidad | En la respuesta |
| :--- | :--- |
| `member` | `status: "INACTIVE"` |
| `user_account` (admin) | `active: false` |

Una cuenta con `active: false` **no puede loguear**, y el rechazo es indistinguible de una contraseña incorrecta (§3).

---

## 6. Pagos

`/api/payments` · `ADMIN` + `SUPER_ADMIN`

| Verbo | Ruta | Respuesta |
| :--- | :--- | :--- |
| `POST` | `/api/payments` | `201` + `PaymentResponse[]` · `400` · `404` |
| `GET` | `/api/payments/members/{memberId}` | `200` + `PaymentResponse[]` · `404` |
| `GET` | `/api/payments/delinquency` | `200` + `MemberDelinquencyResponse[]` |

### `POST /api/payments`

`memberId` requerido (`404` si no está en el club), `paidByMemberId` opcional, `amount` requerido (> 0, hasta 8 enteros y 2 decimales), `periodsCovered` requerido (array no vacío de fechas, **sin repetidos** → `400`) y `paymentMethod` requerido (`CASH` \| `TRANSFER` \| `OTHER`).

**`amount` es por período, no el total.** El servidor crea **una fila por cada fecha de `periodsCovered`, cada una con el `amount` completo**: pagar junio y julio con `amount: 15000` registra dos pagos de 15 000, o sea 30 000. Devuelve el array de pagos creados, todo en una transacción.

Convención de `periodsCovered`: el **primer día del mes** que se paga — `"2026-07-01"` es la cuota de julio de 2026.

**`paidByMemberId`**: nulo o igual a `memberId` se guarda como `null` ("pagó el propio socio" se representa con `null`). Si viene otro socio, tiene que **compartir un `familyGroupId` no nulo** con el socio de la cuota, o `400`; dos socios los dos sin grupo no cuentan como el mismo grupo. No hay cuota familiar compartida: siempre se paga la cuota de un socio.

```json
{ "id": 88, "memberId": 34, "paidByMemberId": null, "amount": 15000.00,
  "paidAt": "...", "periodCovered": "2026-07-01", "paymentMethod": "CASH",
  "recordedByUserId": 12, "createdAt": "..." }
```

`GET /api/payments/members/{memberId}` devuelve el historial completo por `periodCovered` descendente.

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
lastPeriodCovered = MAX(period_covered) de todos los pagos del socio   // null si nunca pagó
coverageStart     = lastPeriodCovered != null ? lastPeriodCovered + 1 mes
                                              : primer día del mes de member.joinedAt
daysOverdue       = max(0, días entre coverageStart y hoy)
```

- **No hay días de gracia**: quien pagó septiembre figura con 5 días de mora el 6 de octubre.
- **Un socio recién creado nace en mora.** `joinedAt` es la fecha del alta y `coverageStart` el primer día de ese mes, así que uno cargado el día 20 aparece con 19 días. No hay forma de dar de alta a alguien al día salvo registrarle el pago del mes.
- Se mide en **días**, no en cuotas ni en meses.
- **Ignora los huecos**: quien pagó enero y después diciembre figura al día, porque solo se mira el máximo. La API no modela cuotas adeudadas una por una.
- No mira quién pagó: `paidByMemberId` no afecta el cálculo.
- `status` y mora son **dos ejes independientes** — un socio puede estar `ACTIVE` y en mora a la vez — y la API nunca los combina en un solo estado.

---

## 8. Modelo de datos

**Cinco tablas** (migraciones `V1`–`V7`): `user_account`, `member`, `family_group`, `refresh_token`, `payment`. El diseño de nueve tablas del `README` del backend es el plan, no el estado.

**La tabla `club` no existe**: `club_id` es un `BIGINT` sin FK ni tabla del otro lado, así que no hay nombre de club, ni flags de rollout, ni `GET /api/clubs`. Está en las tablas raíz (`user_account`, `member`, `family_group`) y cada query filtra por el `clubId` del token; las hojas quedan alcanzadas vía `member_id` / `user_account_id`.

Constraints que el cliente ve como comportamiento HTTP:

| Constraint | Efecto |
| :--- | :--- |
| `user_account UNIQUE (club_id, dni)` · `member UNIQUE (club_id, dni)` | El `409` de DNI duplicado. Único **por club**, no global: por eso el login pide el club |
| `user_account UNIQUE (member_id)` | Un socio no puede tener dos cuentas — el segundo `409` de `/api/admins`. Varios `NULL` sí se permiten |
| `CHECK (role <> 'SUPER_ADMIN' OR member_id IS NULL)` | El `memberId` del super admin es siempre `null` |
| `CHECK (amount > 0)` en `payment` | Refuerza la validación del `POST` |
| **No** hay `UNIQUE (member_id, period_covered)` | Nada impide pagar dos veces el mismo período (§9) |

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
| Nada impide pagar dos veces el mismo período | El duplicado entra: la protección contra el doble submit es del cliente | 8 |
| El `message` de los errores no es estable | Matchear texto se rompe cuando el backend corrige una redacción | 4 |
| `401` y `403` no traen cuerpo | Parsear la respuesta para leer `message` revienta | 4 |
| `GET /api/members` ignora todo query param | Un `?page=` o `?search=` vuelve la lista completa, en silencio | 5 |
| El `clubId` no vuelve en el login | No se puede derivar de la sesión | 3 |

---

## 10. Lo que no existe

Verificado por ausencia en `develop`. La columna de entregas refiere a [app_flows.md](app_flows.md) §8.

| Falta | Bloquea |
| :--- | :--- |
| Paginación, búsqueda y filtro por estado en `GET /api/members` | E4 a escala — hoy se trae el listado completo y filtra el cliente |
| Contadores por estado para los chips del listado | E4 |
| Cargar el último mes pagado en el alta de socio | E5 — sin eso, el socio nuevo nace en mora (§7) |
| `code` estable y `fieldErrors` en el envelope de error | Mapear un error al campo del formulario (E5, E8) |
| `GET /api/payments` con filtro por estado y por socio | E6 — hoy solo hay historial por socio |
| Anulación o corrección de un pago | E6 — un pago mal cargado no se deshace por API |
| Monto de referencia de la cuota del club | E6 — el importe lo tipea el admin en cada pago |
| Días de gracia configurables | El umbral de "en mora" |
| Cambio de contraseña del usuario logueado | E7 |
| Reset de contraseña de un tercero por un ADMIN / SUPER_ADMIN | E11 |
| Flag de "debe cambiar la contraseña en el próximo ingreso" | Primer ingreso (E11) |
| Endpoint de reporte de pagos (formato, binario o URL) | E10 |
| `court`, `court_block`, `recurring_slot`, `reservation` — ni tabla, ni endpoint | **E9 completa**, y "Próximos turnos" del Inicio |
| Cualquier endpoint que acepte un token `MEMBER` (§4) | **E12+ completa** |
| `POST /api/auth/logout` con revocación | Nada: el logout es local, y el refresh descartado vence solo |
| Tabla `club`, `GET /api/clubs`, nombre del club | Selector de club y header con el nombre |

No hay, ni va a haber, recuperación de contraseña por email: el reset es una acción manual de un ADMIN o SUPER_ADMIN, decisión de arquitectura ya tomada del lado de la API.
