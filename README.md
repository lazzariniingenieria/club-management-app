# club-management-app

Native mobile app (Flutter) for members and admins of a neighborhood sports
club: court bookings, family group members, payment status, and club
management for admins. Talks to [club-management-api](https://github.com/lazzariniingenieria/club-management-api),
a Spring Boot backend, over REST.

## Documentation

Three documents, one owner per topic — no fact is stated in two of them:

| Document | What it owns |
| :--- | :--- |
| [backend_api.md](backend_api.md) | **The API contract.** Endpoints, shapes, error model, authorization, server-side business rules, the migrated data model, known pitfalls, and what doesn't exist yet. Read this instead of the backend repo. |
| [app_flows.md](app_flows.md) | Screens, navigation, per-role surfaces, screen states, visual direction and delivery order. |
| [CLAUDE.md](CLAUDE.md) | Coding rules, architecture, testing standards and workflow. **Read it before changing code** — it is the authoritative set of rules, not duplicated here. |

## Getting Started

```bash
flutter pub get
flutter run        # fake data sources, no backend needed
```

## Running against fakes or against the API

Every repository has a remote implementation and a fake one behind the same
domain interface, selected by `--dart-define`. The fakes are the default, so a
bare `flutter run` opens a navigable app:

```bash
flutter run \
  --dart-define=DATA_SOURCE=remote \
  --dart-define=API_BASE_URL=https://<railway-host>/api \
  --dart-define=CLUB_ID=<seeded-club-id>
```

| Define | Default | Notes |
| :--- | :--- | :--- |
| `DATA_SOURCE` | `fake` | `remote` targets the API. A release build wired to the fakes refuses to boot. |
| `API_BASE_URL` | *(empty)* | Includes the `/api` prefix, no trailing slash. |
| `CLUB_ID` | *(unset)* | The club the login authenticates against. Required because it cannot be derived from the session — see [backend_api.md](backend_api.md) §3. |

All three are read in `lib/core/config/app_environment.dart`. A `remote` build
missing `API_BASE_URL` or `CLUB_ID` throws at startup rather than failing
later: the API answers one indistinguishable `401` for every credential
problem, so a wrong `CLUB_ID` would look exactly like a wrong password.

Fake accounts, all with password `123456`:

| DNI | Role |
| :--- | :--- |
| `11111111` | `ADMIN` |
| `22222222` | `SUPER_ADMIN` |
| `33333333` | `MEMBER` |

Secrets never live in the repository: pass them with `--dart-define` or a
git-ignored `.env`.

## Design system

Design tokens live in `lib/core/theme/` — `app_colors.dart`,
`app_spacing.dart`, `app_radius.dart`, `app_text_styles.dart` — wired into a
single `ThemeData` in `app_theme.dart`. Widgets read the theme instead of
hardcoding values; the palette itself is documented in [app_flows.md](app_flows.md) §7.

The component gallery is the living catalog of every shared component in every
state. It replaces a static design file, so it cannot drift from the code. It
is registered only in debug builds:

```bash
flutter run
# then navigate to /dev/gallery
```
