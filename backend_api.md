# Contrato del backend — `club-management-api`

**Qué es**: el espejo, del lado del frontend, de lo que la API expone **hoy**. Endpoints, shapes exactos, códigos de error, reglas de negocio que el cliente no debe reimplementar, y lo que todavía no existe.

**Para qué**: para no volver a leer el repo del backend en cada tarea. Si una pregunta sobre la API no se contesta acá, se contesta en §10 (lo que no existe) — y si tampoco, hay que ir al repo **y volver a actualizar este archivo**.

**Verificado contra**: [`club-management-api`](https://github.com/lazzariniingenieria/club-management-api) rama `develop`, commit `142b070` *"Add refresh token endpoint to auth (#16)"* — últimos merges `#16` y `#17` (2026-09-19). Leído el **2026-10-06**.

**Cómo se refresca este documento**: clonar `develop` y releer `controller/`, `dto/`, `entity/`, `security/`, `config/SecurityConfig`, `exception/GlobalExceptionHandler` y `resources/db/migration/`. Esas siete carpetas son todo el contrato. Actualizar acá lo que cambió y mover el commit del header.

> Este documento describe la API. **No** describe lo que la app necesita que exista: eso vive en [app_flows.md](app_flows.md) §9 y en [backend_request_e2_e3.md](backend_request_e2_e3.md).

---

## Índice

1. [Entornos y base URL](#1-entornos-y-base-url)
2. [Convenciones de transporte](#2-convenciones-de-transporte)
3. [Autenticación y sesión](#3-autenticación-y-sesión)
4. [Autorización por rol](#4-autorización-por-rol)
5. [Modelo de errores](#5-modelo-de-errores)
6. [Endpoints](#6-endpoints)
7. [Reglas de negocio del servidor](#7-reglas-de-negocio-del-servidor)
8. [Modelo de datos implementado](#8-modelo-de-datos-implementado)
9. [Trampas conocidas](#9-trampas-conocidas)
10. [Lo que no existe](#10-lo-que-no-existe)

---

## 1. Entornos y base URL

Dos entornos en Railway, los dos con su propio Postgres: **producción** (deploy desde `main`) y **test** (deploy desde `develop`). No hay Postgres local y la API nunca se corre local contra una base persistente — del lado del backend, localhost es solo para `mvnw clean verify`.

| Dato | Valor |
| :--- | :--- |
| Prefijo de rutas | **`/api`**, sin segmento de versión |
| `API_BASE_URL` de la app | `https://<host>/api` — incluye el prefijo, sin barra final |
| Ruta completa de ejemplo | `POST https://<host>/api/auth/login` |
| Puerto del servidor | `${PORT:8080}`, lo fija Railway |

**Las URLs de los dos entornos no están en el repo del backend** (son variables de Railway). Siguen siendo un dato a pedir: ver [backend_request_e2_e3.md](backend_request_e2_e3.md) §1.

`/api/v1` **no existe**. Cualquier ejemplo con `/api/v1` en documentos viejos de este repo es anterior a la implementación y da 404 contra la API real.

Variables de entorno del backend, por si hace falta leer un log de deploy: `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, `JWT_SECRET`, `JWT_EXPIRATION_MS` (default `3600000`), `JWT_REFRESH_EXPIRATION_MS` (default `5184000000`).

---

## 2. Convenciones de transporte

| Convención | Valor real | Consecuencia para la app |
| :--- | :--- | :--- |
| **Verbos** | `GET`, `POST`, `PATCH` y **un** `DELETE` (`/api/members/{id}/family-group`) | No hay `PUT` en ningún endpoint. Codear una edición como `PUT` da **405**. |
| **Tipo de los `id`** | **Números** JSON (`Long` de Java), nunca strings | Parsear siempre con `(json['id'] as num).toInt()`. Un `as String` falla en runtime. |
| **Semántica de `PATCH`** | **Reemplazo completo** de los campos que declara el DTO, no un merge parcial | Un campo omitido se escribe como `null`, no se conserva. Ver §9. |
| **Fechas de día** (`joinedAt`, `periodCovered`, `lastPeriodCovered`) | `LocalDate` → `"2026-09-01"` (ISO, sin hora ni zona) | — |
| **Timestamps** (`createdAt`, `updatedAt`, `paidAt`) | `Instant` → ISO-8601 en UTC (`"2026-09-19T23:09:57.123456Z"`) | Es el formato por default de Spring Boot: no hay configuración explícita de Jackson en el backend. **Verificar en la primera integración que los consuma** (E5/E6); hoy la app no parsea ninguna fecha. |
| **Montos** | `BigDecimal` → número JSON con hasta 2 decimales (`15000` o `15000.50`) | Nunca parsear a `double` para operar; en base es `NUMERIC(10,2)`. |
| **Enums** | Strings en `SCREAMING_SNAKE_CASE` | `MemberStatus`, `UserRole`, `PaymentMethod`. Mapear con default defensivo. |
| **Listados** | Array JSON **plano**, sin envelope ni metadata | No hay paginación en ningún endpoint. Ver §10. |
| **Campo de documento** | `dni`, no `nationalId` | Decisión deliberada del backend, no se va a traducir. |
| **`Content-Type`** | `application/json` | — |

No hay configuración de CORS, lo cual es irrelevante para una app nativa.

---

## 3. Autenticación y sesión

DNI + contraseña, sin proveedor de identidad externo. `dni` es único **por club**, no globalmente, así que el login también pide el club.

### 3.1 `POST /api/auth/login` — público

```json
// request
{ "clubId": 1, "dni": "30111222", "password": "s3cr3t123" }
```

```json
// 200 OK
{
  "accessToken": "eyJ...",
  "refreshToken": "x7Hk...",
  "expiresIn": 3600,
  "userAccountId": 12,
  "role": "ADMIN",
  "memberId": 34
}
```

| Campo | Tipo | Notas |
| :--- | :--- | :--- |
| `accessToken` | string | JWT firmado con HMAC. Viaja como `Authorization: Bearer <token>`. |
| `refreshToken` | string | **Token opaco, no un JWT**: 32 bytes aleatorios en base64url. No se puede decodificar ni leerle una expiración. |
| `expiresIn` | number | Vida del **access token** en **segundos** (3600 con el default). No aplica al refresh token. |
| `userAccountId` | number | PK de `user_account`. |
| `role` | string | `SUPER_ADMIN` \| `ADMIN` \| `MEMBER`. |
| `memberId` | number \| **null** | El socio asociado a la cuenta. `null` si la cuenta no es socia — siempre `null` para `SUPER_ADMIN`, lo garantiza un `CHECK` en base. |

**No devuelve `clubId`.** El club viaja dentro del JWT y el backend lo resuelve solo (§3.3), así que la app no lo recibe de vuelta y lo sigue necesitando por `--dart-define=CLUB_ID` para poder mandarlo en el login.

**Errores**:

| Status | Caso |
| :--- | :--- |
| `401` | DNI inexistente en ese club, contraseña incorrecta, **o cuenta desactivada** — los tres indistinguibles, con `message: "Invalid dni or password"`. Es deliberado: distinguirlos permitiría enumerar qué DNI existen en el club. |
| `400` | Falta `clubId`, `dni` o `password`, o `dni` supera 20 caracteres. |

### 3.2 `POST /api/auth/refresh` — público

**Implementado** (PR #16, 2026-09-19). Cualquier documento de este repo que lo describa como pendiente está vencido.

```json
// request
{ "refreshToken": "x7Hk..." }
```

```json
// 200 OK
{ "accessToken": "eyJ...", "refreshToken": "9pQz...", "expiresIn": 3600 }
```

Comportamiento, verificado en `RefreshTokenService` y `AuthService`:

- **Rota siempre**: el token usado queda con `revoked_at` y la respuesta trae uno nuevo. El cliente **debe** persistir el `refreshToken` de la respuesta; si guarda solo el `accessToken`, el próximo refresco falla.
- **TTL del refresh token: 60 días** (`JWT_REFRESH_EXPIRATION_MS` = 5 184 000 000 ms). No son 30.
- **TTL del access token: 1 hora** (`JWT_EXPIRATION_MS` = 3 600 000 ms).
- Un token ya rotado, revocado o vencido devuelve **`401`** con `message: "Invalid or expired refresh token"`. Lo mismo si la cuenta dueña del token quedó desactivada.
- **No hay revocación en cascada por reuso**: reusar un token revocado rechaza *esa* llamada, pero no invalida los demás tokens vivos de la cuenta. No es una familia de tokens con detección de robo.
- Es transaccional: o rota y emite, o no hace nada.

**Regla de distinción que la app ya implementa**: un `401` **en `/auth/refresh`** es cerrar sesión; un `401` en cualquier otro endpoint es intentar refrescar y reintentar **una** vez. Sin esa separación por endpoint, un refresh vencido entra en bucle.

### 3.3 Contenido del JWT (`accessToken`)

Firmado con HMAC-SHA sobre `JWT_SECRET`. Claims:

| Claim | Valor |
| :--- | :--- |
| `sub` | `userAccountId` como string |
| `userAccountId` | number |
| `clubId` | number |
| `role` | `"SUPER_ADMIN"` \| `"ADMIN"` \| `"MEMBER"` |
| `memberId` | number, o ausente si la cuenta no es socia |
| `iat` / `exp` | emisión y expiración |

**El `clubId` sale siempre del token, nunca de un parámetro del request.** Ningún endpoint recibe `clubId` por path, query o header — es la opción A de [backend_request_e2_e3.md](backend_request_e2_e3.md) §2.4, y quedó elegida. Un bug del cliente no puede leer datos de otro club.

Consecuencia práctica: **el `clubId` de la sesión queda fijado en el login**. Si hiciera falta mostrar el nombre del club o cambiar de club, hoy no hay dato ni endpoint.

### 3.4 Cierre de sesión

**No hay `POST /api/auth/logout`.** No existe ningún endpoint de revocación. El logout es puramente local: borrar el storage. El `refreshToken` descartado sigue siendo válido en base hasta que venza (60 días) o hasta que se use y rote.

---

## 4. Autorización por rol

De `SecurityConfig`. Sesión **stateless**, sin cookies.

| Ruta | Quién entra |
| :--- | :--- |
| `POST /api/auth/login` | público |
| `POST /api/auth/refresh` | público |
| `/api/admins/**` | **solo `SUPER_ADMIN`** |
| `/api/members/**` | `ADMIN`, `SUPER_ADMIN` |
| `/api/family-groups/**` | `ADMIN`, `SUPER_ADMIN` |
| `/api/payments/**` | `ADMIN`, `SUPER_ADMIN` |
| cualquier otra | autenticado |

**Un token con `role = MEMBER` no tiene acceso a ningún endpoint implementado.** Puede autenticarse y nada más: todas las rutas existentes piden `ADMIN` o `SUPER_ADMIN`. La superficie del socio (E12+) no tiene backend todavía, ni parcial.

**`401` vs `403`** — la app depende de distinguirlos y la API los separa bien:

| Status | Cuándo | Qué hace la app |
| :--- | :--- | :--- |
| `401` | Falta el header `Authorization`, el token está mal firmado, es ilegible o venció | Refresca y reintenta una vez (§3.2) |
| `403` | Token válido, **rol insuficiente** para la ruta | Muestra un mensaje y **no toca la sesión** |

**Los `401` y `403` no pasan por `GlobalExceptionHandler`**: los emite la cadena de filtros de Spring Security, así que su cuerpo **no** es un `ApiErrorDto` (el `401` viene con cuerpo vacío). Para esos dos códigos hay que decidir por status code y nada más.

Detalle de implementación con efecto visible: `JwtAuthenticationFilter` **no corta** la request cuando el token es inválido — simplemente no autentica y deja seguir la cadena, que termina en el `401` del entry point. Un token vencido y un token ausente son el mismo caso para el cliente.

---

## 5. Modelo de errores

Todo error que nace en un controller o un service sale con este envelope (`ApiErrorDto`):

```json
{
  "timestamp": "2026-09-19T23:09:57.123456Z",
  "status": 409,
  "error": "Conflict",
  "message": "dni 30111222 is already in use in this club",
  "details": []
}
```

| Campo | Notas |
| :--- | :--- |
| `status` | Repite el status HTTP. |
| `error` | Reason phrase de HTTP (`"Conflict"`, `"Bad Request"`, …), no un código de dominio. |
| `message` | **En inglés y no estable**: es el mensaje de la excepción Java. Nunca mostrarlo al usuario, nunca hacer matching sobre su texto. |
| `details` | Solo en errores de validación: array de strings `"campo: mensaje"`, p. ej. `"dni: dni is required"`. Vacío en todos los demás casos. |

**No hay campo `code`** legible por máquina, ni `fieldErrors` estructurados. Sigue siendo el pedido abierto de [backend_request_e2_e3.md](backend_request_e2_e3.md) §2.5.

**Consecuencia directa sobre el plan de E5**: mapear el 409 de DNI duplicado al campo `dni` **por el `code` de la respuesta no es posible hoy**. Para `POST` y `PATCH /api/members` igual alcanza el status code: ese endpoint no tiene otra restricción que pueda chocar, así que un `409` ahí **solo** puede ser el DNI duplicado y se puede mapear al campo sin leer el `message`. En `/api/admins` no alcanza, porque hay dos fuentes distintas de `409` (§6.4).

### 5.1 Tabla completa de status codes

| Status | Origen | `message` |
| :--- | :--- | :--- |
| `400` | Falla de validación de Bean Validation | `"Validation failed"` + `details` por campo |
| `400` | Body JSON ilegible o mal formado | `"Malformed request body"` |
| `400` | `paidByMemberId` fuera del grupo familiar del socio | `"Member X is not in the same family group as member Y"` |
| `400` | `periodsCovered` con fechas repetidas | `"periodsCovered must not contain duplicate dates"` |
| `401` | Login rechazado | `"Invalid dni or password"` |
| `401` | Refresh token inválido, revocado o vencido | `"Invalid or expired refresh token"` |
| `401` | Token ausente, inválido o vencido | *(sin cuerpo — lo emite Spring Security)* |
| `403` | Rol insuficiente | *(no es un `ApiErrorDto`)* |
| `404` | `Member X not found` / `Admin X not found` / `Family group X not found` | el texto de la excepción |
| `409` | DNI ya usado en el club | `"dni X is already in use in this club"` |
| `409` | Cualquier otra violación de constraint de base | `"Request violates a database constraint"` |
| `500` | Cualquier excepción no manejada | `"Unexpected error"` |

Todos los `404` son "no existe **en tu club**": las consultas filtran por el `clubId` del token, así que un recurso de otro club es indistinguible de uno inexistente. Correcto, y a tener en cuenta al leer logs.

---

## 6. Endpoints

Cinco controllers. Nada más que esto existe.

### 6.1 Auth — `/api/auth`

| Verbo | Ruta | Rol | Respuesta |
| :--- | :--- | :--- | :--- |
| `POST` | `/login` | público | `200` + `LoginResponse` (§3.1) |
| `POST` | `/refresh` | público | `200` + `RefreshResponse` (§3.2) |

### 6.2 Socios — `/api/members` · `ADMIN` + `SUPER_ADMIN`

| Verbo | Ruta | Respuesta |
| :--- | :--- | :--- |
| `POST` | `/api/members` | `201` + `MemberResponse` · `404` · `409` |
| `GET` | `/api/members` | `200` + `MemberResponse[]` |
| `GET` | `/api/members/{memberId}` | `200` + `MemberResponse` · `404` |
| `PATCH` | `/api/members/{memberId}` | `200` + `MemberResponse` · `404` · `409` |
| `PATCH` | `/api/members/{memberId}/deactivate` | `200` + `MemberResponse` · `404` |
| `PATCH` | `/api/members/{memberId}/reactivate` | `200` + `MemberResponse` · `404` |
| `PATCH` | `/api/members/{memberId}/family-group` | `200` + `MemberResponse` · `404` |
| `DELETE` | `/api/members/{memberId}/family-group` | `200` + `MemberResponse` · `404` |

**`MemberResponse`**

```json
{
  "id": 34,
  "firstName": "Marcos",
  "lastName": "Gomez",
  "dni": "30111222",
  "phone": "+54 11 4444-5555",
  "email": "marcos@example.com",
  "familyGroupId": 7,
  "joinedAt": "2026-09-19",
  "status": "ACTIVE",
  "createdAt": "2026-09-19T23:09:57.123456Z",
  "updatedAt": "2026-09-19T23:09:57.123456Z",
  "createdByUserId": 12,
  "updatedByUserId": 12
}
```

`phone`, `email` y `familyGroupId` son nullables. `status` es `ACTIVE` \| `INACTIVE`. **No trae nada de estado de cuota** — eso vive en `/api/payments/delinquency` (§6.5) y se cruza por `memberId`.

**`GET /api/members`** devuelve **todos** los socios del club, activos e inactivos, ordenados por `createdAt` descendente (el último creado primero). **Sin paginación, sin búsqueda y sin filtros**: no acepta ningún query param. Hoy el filtrado, la búsqueda y el orden alfabético los resuelve el cliente sobre la lista completa.

**`POST /api/members`** — body:

| Campo | Requerido | Validación |
| :--- | :--- | :--- |
| `firstName` | sí | no vacío, ≤ 100 |
| `lastName` | sí | no vacío, ≤ 100 |
| `dni` | sí | no vacío, ≤ 20, único por club → `409` |
| `phone` | no | ≤ 30 |
| `email` | no | formato de email, ≤ 150 |
| `familyGroupId` | no | tiene que existir en el club, si no → `404` |

El servidor fija `joinedAt = hoy` y `status = ACTIVE`; **el cliente no puede mandar ninguno de los dos**, ni retrodatar un alta. El `201` ya trae el `MemberResponse` completo, así que no hace falta un `GET` después.

**`PATCH /api/members/{memberId}`** — body con `firstName`, `lastName`, `dni` (los tres requeridos), `phone`, `email`. **No toca `familyGroupId` ni `status`**: esos se mueven por sus endpoints dedicados. Como es reemplazo completo, omitir `phone` o `email` los borra.

**Baja lógica**: `deactivate` escribe `status = INACTIVE`, `reactivate` vuelve a `ACTIVE`. Nunca hay borrado físico y la fila sigue apareciendo en `GET /api/members`.

**Grupo familiar**: `PATCH .../family-group` con `{ "familyGroupId": 7 }` (requerido) asigna; el `DELETE` desasigna. Es el único `DELETE` de toda la API.

### 6.3 Grupos familiares — `/api/family-groups` · `ADMIN` + `SUPER_ADMIN`

| Verbo | Ruta | Respuesta |
| :--- | :--- | :--- |
| `POST` | `/api/family-groups` | `201` + `FamilyGroupResponse` |
| `GET` | `/api/family-groups` | `200` + `FamilyGroupResponse[]` |
| `GET` | `/api/family-groups/{familyGroupId}` | `200` · `404` |
| `PATCH` | `/api/family-groups/{familyGroupId}` | `200` · `404` |

```json
{
  "id": 7,
  "name": "Familia Gomez",
  "createdAt": "2026-09-19T23:09:57.123456Z",
  "updatedAt": "2026-09-19T23:09:57.123456Z",
  "createdByUserId": 12,
  "updatedByUserId": 12
}
```

`name` es **opcional** en el alta y en la edición (≤ 150): un grupo sin nombre es una fila válida, y un `PATCH` sin `name` lo pone en `null`.

**No hay baja ni borrado de grupos**, y la respuesta **no trae los integrantes ni cuántos son**. Para saber quién está en un grupo hay que traer `GET /api/members` y filtrar por `familyGroupId` en el cliente.

### 6.4 Administradores — `/api/admins` · **solo `SUPER_ADMIN`**

| Verbo | Ruta | Respuesta |
| :--- | :--- | :--- |
| `POST` | `/api/admins` | `201` + `AdminResponse` · `409` |
| `GET` | `/api/admins` | `200` + `AdminResponse[]` |
| `GET` | `/api/admins/{adminId}` | `200` · `404` |
| `PATCH` | `/api/admins/{adminId}` | `200` · `404` · `409` |
| `PATCH` | `/api/admins/{adminId}/deactivate` | `200` · `404` |
| `PATCH` | `/api/admins/{adminId}/reactivate` | `200` · `404` |

```json
{
  "id": 12,
  "dni": "30222333",
  "email": "admin@example.com",
  "memberId": 5,
  "active": true,
  "createdAt": "2026-09-19T23:09:57.123456Z",
  "updatedAt": "2026-09-19T23:09:57.123456Z",
  "createdByUserId": 1,
  "updatedByUserId": 1
}
```

**`AdminResponse` no trae `role`** (siempre es `ADMIN`) y modela la baja como **`active` booleano**, no como el enum `status` que usa `member`. Son dos shapes distintos para el mismo concepto de producto: el mapeo a dominio tiene que normalizarlo.

**`POST /api/admins`** — contesta la pregunta que seguía abierta en [app_flows.md](app_flows.md) §9.6: **la contraseña inicial la define el SUPER_ADMIN**, la API no genera ninguna.

| Campo | Requerido | Validación |
| :--- | :--- | :--- |
| `dni` | sí | no vacío, ≤ 20, único entre las `user_account` del club → `409` |
| `password` | sí | **entre 8 y 100 caracteres** |
| `email` | no | formato de email, ≤ 150 |
| `memberId` | no | vincula al admin con su propio socio |

El `role` lo fija el servidor en `ADMIN`: no se puede crear un `SUPER_ADMIN` ni un `MEMBER` por acá.

**`PATCH /api/admins/{adminId}`** recibe `dni` (requerido), `email` y `memberId`, y **sobrescribe los tres**. Mandar el body sin `memberId` **desvincula** al admin de su socio. No hay endpoint para cambiarle la contraseña.

**Dos fuentes distintas de `409` en este endpoint**: el DNI repetido (`DuplicateDniException`) y el `memberId` ya tomado por otra cuenta (`uk_user_account_member_id` → `DataIntegrityViolationException` → `"Request violates a database constraint"`). Como no hay `code` estable (§5), distinguirlas para mostrar el error en el campo correcto obliga a leer el `message`. A tener en cuenta en E8.

**`GET /api/admins` devuelve solo cuentas con `role = ADMIN`.** El `SUPER_ADMIN` es una única cuenta seedeada en base, nunca aparece en el listado y no tiene pantalla de alta — por eso la app no necesita defenderse de una auto-baja. Los admins dados de baja **sí** siguen en el listado, con `active: false`.

### 6.5 Pagos — `/api/payments` · `ADMIN` + `SUPER_ADMIN`

| Verbo | Ruta | Respuesta |
| :--- | :--- | :--- |
| `POST` | `/api/payments` | `201` + `PaymentResponse[]` · `400` · `404` |
| `GET` | `/api/payments/members/{memberId}` | `200` + `PaymentResponse[]` · `404` |
| `GET` | `/api/payments/delinquency` | `200` + `MemberDelinquencyResponse[]` |

**No existe `GET /api/payments`** a secas, ni con filtros por estado o por socio. El historial se pide por socio.

**`POST /api/payments`** — body:

| Campo | Requerido | Validación |
| :--- | :--- | :--- |
| `memberId` | sí | tiene que existir en el club → `404` |
| `paidByMemberId` | no | quién paga, si no es el propio socio (§7.2) |
| `amount` | sí | > 0, máximo 8 dígitos enteros y **2 decimales** |
| `periodsCovered` | sí | array **no vacío** de fechas, sin repetidos → `400` |
| `paymentMethod` | sí | `CASH` \| `TRANSFER` \| `OTHER` |

**`amount` es por período, no el total de la operación.** El servidor crea **una fila de `payment` por cada fecha de `periodsCovered`, cada una con el `amount` completo**: pagar junio y julio con `amount: 15000` registra 2 pagos de 15 000, o sea 30 000 cobrados. La UI tiene que etiquetar el campo como importe de la cuota, no como total, y mostrar el total calculado antes de confirmar.

Devuelve `201` con el **array** de pagos creados, uno por período, en el orden en que llegaron. Todo en una sola transacción: o entran todos o no entra ninguno.

Convención de `periodsCovered`: es un `DATE`, y la práctica del backend (fixtures y cálculo de mora) es el **primer día del mes** que se está pagando — `"2026-07-01"` significa "la cuota de julio de 2026".

**`PaymentResponse`**

```json
{
  "id": 88,
  "memberId": 34,
  "paidByMemberId": null,
  "amount": 15000.00,
  "paidAt": "2026-09-19T23:09:57.123456Z",
  "periodCovered": "2026-07-01",
  "paymentMethod": "CASH",
  "recordedByUserId": 12,
  "createdAt": "2026-09-19T23:09:57.123456Z"
}
```

`GET /api/payments/members/{memberId}` devuelve el historial completo ordenado por `periodCovered` descendente. Sin paginación.

**`GET /api/payments/delinquency`** — `MemberDelinquencyResponse[]`:

```json
[
  { "memberId": 34, "firstName": "Marcos", "lastName": "Gomez", "lastPeriodCovered": "2026-07-01", "daysOverdue": 45 },
  { "memberId": 51, "firstName": "Ana",    "lastName": "Diaz",  "lastPeriodCovered": null,         "daysOverdue": 120 }
]
```

Cómo leerlo, que es menos obvio de lo que parece:

- Devuelve **una fila por cada socio `ACTIVE` del club**, no solo por los morosos: las filas con `daysOverdue: 0` son socios al día. Los inactivos no aparecen nunca.
- Está ordenado por `daysOverdue` **descendente**: el que más debe, primero.
- `lastPeriodCovered` es `null` si el socio nunca pagó nada.
- `daysOverdue` se mide en **días**, no en meses ni en cuotas. La fórmula está en §7.1.
- Por lo anterior, `response.length` **es** la cantidad de socios activos del club, y las filas con `daysOverdue > 0` la de socios en mora. Los dos contadores del Inicio salen de esta única llamada, sin traer el listado completo de socios.
- No trae `dni` ni `status`: para armar una fila de listado con el badge combinado hay que cruzar contra `GET /api/members` por `memberId`.

---

## 7. Reglas de negocio del servidor

Lo que el backend decide y el cliente **no** debe recalcular.

### 7.1 Mora — cómo se calcula

Nunca es una columna guardada: se computa en cada llamada comparando `payment.period_covered` contra la fecha de hoy, así que no puede desincronizarse.

```
lastPeriodCovered = MAX(period_covered) de todos los pagos del socio   // null si nunca pagó

coverageStart = lastPeriodCovered != null
                ? lastPeriodCovered + 1 mes
                : primer día del mes de member.joinedAt

daysOverdue   = max(0, días entre coverageStart y hoy)
```

Lo que se desprende, y conviene tener presente antes de diseñar una pantalla sobre esto:

- **No hay días de gracia.** Quien pagó septiembre figura con 5 días de mora el 6 de octubre. Si el club tiene tolerancia, el umbral hoy no existe del lado del servidor.
- **Un socio recién creado aparece en mora de entrada.** `joinedAt` es la fecha del alta y `coverageStart` es el primer día de ese mes, así que un socio cargado el día 20 nace con 19 días de mora. No hay forma de dar de alta a alguien "al día" salvo registrarle el pago del mes en curso.
- No importa **quién** pagó: `lastPeriodCovered` toma el máximo de todos los pagos del socio, sin mirar `paidByMemberId`.
- El cálculo ignora los **huecos**: un socio que pagó enero y después diciembre figura al día, porque solo se mira el máximo. La API no modela cuotas adeudadas una por una.
- `MemberStatus` y la mora son **dos ejes independientes**, como ya fijaba [app_flows.md](app_flows.md) §3.2.2: un socio puede estar `ACTIVE` y en mora a la vez. La API los expone en dos endpoints distintos y nunca los combina en un solo estado.

### 7.2 Pago de un tercero del grupo familiar

En `POST /api/payments`:

- `paidByMemberId` nulo, o igual a `memberId`, se **guarda como `null`**. "Pagó el propio socio" se representa con `null`, no repitiendo el id.
- Si viene otro socio, tiene que **compartir un `familyGroupId` no nulo** con el socio de la cuota. Si no, `400`. Dos socios los dos sin grupo **no** se consideran del mismo grupo.
- No hay cuota familiar compartida: siempre se paga la cuota de **un** socio, aunque la plata la ponga otro.

### 7.3 Multi-club

`club_id` está en todas las tablas raíz (`user_account`, `member`, `family_group`) y cada query filtra por el `clubId` del token. Las tablas hoja (`payment`, `refresh_token`) no repiten la columna: quedan alcanzadas a través de `member_id` / `user_account_id`.

**La tabla `club` todavía no existe.** `club_id` es un `BIGINT` sin FK y sin tabla del otro lado, así que no hay nombre de club, ni flags de rollout (`courts_enabled`, `member_app_enabled`), ni `GET /api/clubs`. Es por eso que la app sigue necesitando `--dart-define=CLUB_ID` con el id que tengan las filas seedeadas.

### 7.4 Bajas lógicas

Nunca hay borrado físico. Dos modelos distintos para lo mismo:

| Entidad | Cómo se da de baja | En la respuesta |
| :--- | :--- | :--- |
| `member` | `PATCH /api/members/{id}/deactivate` | `status: "INACTIVE"` |
| `user_account` (admin) | `PATCH /api/admins/{id}/deactivate` | `active: false` |

Las dos son reversibles con `/reactivate`. Una cuenta con `active: false` **no puede loguear**, y el rechazo es indistinguible de una contraseña incorrecta (§3.1).

---

## 8. Modelo de datos implementado

Lo que hay en base hoy son **cinco tablas** (migraciones `V1`–`V7`). El diseño de nueve tablas del `README` del backend sigue siendo el plan, no el estado.

| Tabla | Migración | Para qué |
| :--- | :--- | :--- |
| `user_account` | `V1`, `V5` | Cuentas con login: `SUPER_ADMIN`, `ADMIN`, `MEMBER` |
| `member` | `V2`, `V4`, `V5` | Socios del club — una persona, no necesariamente con login propio |
| `family_group` | `V3`, `V5` | Grupo familiar |
| `refresh_token` | `V6` | Refresh tokens hasheados, uno por emisión |
| `payment` | `V7` | Un pago = un socio × un período |

**No existen** `club`, `court`, `court_block`, `recurring_slot` ni `reservation`. Toda la superficie de canchas, turnos y reservas (E9, E12+) no tiene nada del otro lado: ni tabla, ni endpoint, ni entidad.

Las migraciones son inmutables una vez aplicadas: un error se corrige con una migración nueva, nunca editando una existente.

### 8.1 Columnas y constraints que importan al frontend

**`user_account`**
- `UNIQUE (club_id, dni)` — el DNI es único **por club**, no global. Es la razón por la que el login pide el club.
- `UNIQUE (member_id)` — un socio no puede tener dos cuentas. Múltiples `NULL` sí se permiten, así que puede haber muchas cuentas sin socio.
- `CHECK (role <> 'SUPER_ADMIN' OR member_id IS NULL)` — el super admin representa al club, no a una persona; su `memberId` es siempre `null`.
- `active BOOLEAN NOT NULL DEFAULT TRUE`.

**`member`**
- `UNIQUE (club_id, dni)` — el `409` de DNI duplicado del alta y de la edición.
- `CHECK (status IN ('ACTIVE','INACTIVE'))`.
- `joined_at DATE NOT NULL` — lo fija el servidor en el alta.
- `family_group_id` nullable, con FK a `family_group`.

**`payment`**
- `amount NUMERIC(10,2)` con `CHECK (amount > 0)`.
- `period_covered DATE NOT NULL`, **sin** unicidad por `(member_id, period_covered)`: ver §9.
- FKs a `member` (dos veces: `member_id` y `paid_by_member_id`) y a `user_account` (`recorded_by_user_id`).
- Índice en `(member_id, period_covered)`.

**`refresh_token`**
- `UNIQUE (token_hash)`; se guarda el **SHA-256 en base64** del token, nunca el token en claro.
- `expires_at`, y `revoked_at` nullable.

**Auditoría** — `user_account`, `member` y `family_group` tienen las cuatro columnas: `created_at`, `updated_at`, `created_by_user_id`, `updated_by_user_id`, las dos últimas con FK a `user_account`. `payment` tiene `created_at` y `recorded_by_user_id`. Todas se exponen en las respuestas; la app hoy no las usa, pero están si hace falta mostrar "cargado por".

**Semántica de los `NULL`**: en este esquema un nullable nunca es "falta el dato", es parte del significado de la fila. `member.phone` es un opcional suelto; `payment.paid_by_member_id = null` significa "pagó el propio socio"; `user_account.member_id = null` significa "esta cuenta no es socia".

---

## 9. Trampas conocidas

Lo que es fácil codear mal porque el contrato dice algo distinto de lo que uno espera.

| # | Trampa | Qué pasa si se ignora |
| :--- | :--- | :--- |
| 1 | **`amount` en `POST /api/payments` es por período**, no el total | Pagar 3 meses mandando el total en `amount` registra 3 pagos de ese total: se cobra el triple en base |
| 2 | **`PATCH` es reemplazo completo**, no merge | Editar solo el teléfono de un socio con un body parcial **borra** su email |
| 3 | **`PATCH /api/admins/{id}` sin `memberId`** lo pone en `null` | Un admin que además es socio pierde el vínculo con su socio al editarle el email |
| 4 | **Un socio recién creado figura en mora** (§7.1) | El alta "funciona" pero el socio aparece en rojo en el listado al instante |
| 5 | **`GET /api/payments/delinquency` trae a todos los activos**, no solo a los morosos | Contar las filas da la cantidad de socios activos, no la de morosos: hay que filtrar `daysOverdue > 0` |
| 6 | **Nada impide pagar dos veces el mismo período** en dos requests separadas | No hay constraint ni validación cruzada: el duplicado entra y la mora se recalcula igual. La protección contra el doble submit es del cliente |
| 7 | **No hay `logout`** | Borrar el storage local alcanza para la app, pero el refresh token descartado queda válido 60 días |
| 8 | **El `message` de los errores está en inglés y no es estable** | Matchear texto para decidir una pantalla se rompe la primera vez que el backend corrige una redacción |
| 9 | **`401` y `403` no traen `ApiErrorDto`** | Parsear el cuerpo de un `401` para leer `message` revienta: viene vacío |
| 10 | **Los `id` son números JSON** | Un `as String` sobre un `id` falla en runtime |
| 11 | **`GET /api/members` no acepta ningún query param** | Un `?page=`, `?search=` o `?status=` se ignora en silencio y vuelve la lista completa |
| 12 | **El `clubId` no vuelve en el login** | No se puede derivar de la sesión: hay que conservar el de `--dart-define` |

---

## 10. Lo que no existe

Verificado por ausencia en `develop`. Es el inventario de lo que sigue bloqueando entregas, y la fuente para mantener §9 de [app_flows.md](app_flows.md).

### Autenticación y cuentas

| Falta | Bloquea |
| :--- | :--- |
| `POST /api/auth/logout` con revocación | nada crítico — el logout es local |
| Cambio de contraseña del usuario logueado | **E7** (Perfil del admin) |
| Reset de contraseña de un tercero por un `ADMIN` / `SUPER_ADMIN` | **E11** y §3.1.2 de app_flows |
| Flag de "contraseña debe cambiarse en el próximo ingreso" | pantalla de primer ingreso (E11) |
| Endpoint de alta o activación de cuenta de socio | superficie del socio (E12+) |

No hay, ni va a haber, recuperación de contraseña por email: es una decisión de arquitectura ya tomada del lado de la API.

### Socios y listados

| Falta | Bloquea |
| :--- | :--- |
| Paginación en `GET /api/members` (página, tamaño, total) | **E4** a escala — hoy se trae el listado completo |
| Búsqueda por nombre o DNI del lado del servidor | **E4** — hoy filtra el cliente |
| Filtro por `status` y por mora como query params | **E4** |
| Contadores por estado para los chips del listado | **E4** |
| Cargar el último mes pagado en el alta | **E5** — sin esto, trampa #4 de §9 |

### Pagos

| Falta | Bloquea |
| :--- | :--- |
| `GET /api/payments` con filtro por estado y por socio | **E6** — hoy solo hay historial por socio |
| Anulación o corrección de un pago registrado | **E6** — un pago mal cargado no se puede deshacer por API |
| Monto de la cuota del club como valor de referencia | **E6** — el importe lo tipea el admin en cada pago |
| Días de gracia configurables para la mora | umbral de "en mora" |
| Endpoint de reporte de pagos (formato, binario o URL) | **E10** |

### Contrato transversal

| Falta | Bloquea |
| :--- | :--- |
| `code` estable y `fieldErrors` en el envelope de error | mapeo de errores al campo del formulario (E5, E8) |
| `GET /api/admin/summary` con los contadores en una llamada | nada — resuelto con `/payments/delinquency` (§6.5) |
| Tabla `club`, `GET /api/clubs`, nombre del club | selector de club y header con el nombre |
| Flags de rollout (`courts_enabled`, `member_app_enabled`) | habilitación por club |

### Canchas, turnos y reservas

**Nada.** No hay tabla, ni entidad, ni endpoint para `court`, `court_block`, `recurring_slot` ni `reservation`. **E9** está bloqueada de punta a punta, igual que el bloque "Próximos Turnos" del Inicio.

### Superficie del socio

Ningún endpoint acepta un token con `role = MEMBER` (§4). **E12+** no tiene backend, ni parcial.
