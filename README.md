# club-management-app

Native mobile app (Flutter) for members and admins of a neighborhood sports
club: viewing/making court bookings, managing family group members, checking
payment status, and (for admins) managing the club.

## Tech Stack

- **Flutter** / **Dart** (latest stable versions)
- Talks to `club-management-api` (Spring Boot backend)
- Distributed as a native app (not a wrapped web app)

## Architecture

Feature-first structure, favoring the most professional/production-grade
pattern over the simplest one when there's a trade-off:

```
lib/
  core/         # networking, error handling, theming, routing, DI
  features/
    auth/
    bookings/
    members/
    payments/
    <feature>/
      data/
      domain/
      presentation/
  shared/       # shared widgets, extensions, utils
```

## Instructions for AI Assistants (Claude Code, Copilot, etc.)

When writing or modifying code in this repository, follow these rules strictly:

1. **Act as a senior Flutter developer (20+ years equivalent experience).**
   Code must be simple, high-quality, and scalable — never clever for the sake
   of being clever.
2. **Functions are single-purpose.** Max ~20 lines and max 3 parameters,
   unless there's a clearly justified exception (explain it if you make one).
3. **Everything in English.** Variable, class, method, and file names — no
   Spanish anywhere in code, even though product/domain discussions happen in
   Spanish.
4. **No comments**, except to justify a genuinely non-obvious decision. The
   code itself must be self-explanatory.
5. **Code should read like a story.** Use full, descriptive names. Prefer
   clarity over brevity.
6. **Always write tests** for new logic where feasible (widget tests, unit
   tests for business logic) — meaningful tests, not coverage padding.
7. **Always prefer the professional/production-grade approach** over the
   simplest option when teaching or implementing a pattern (e.g. proper state
   management and layered architecture over a quick inline `setState` hack),
   even if it takes a bit more code.
8. **Always use the latest stable versions** of packages in `pubspec.yaml`
   unless there's a compatibility reason not to — state that reason if so.
9. **Log important errors clearly**, with enough context to debug in
   production (never swallow exceptions silently).
10. Before implementing, if a request is ambiguous or introduces meaningful
    complexity, surface the trade-off instead of silently picking one — this
    team validates design before writing code.

## Getting Started

```bash
flutter pub get
flutter run
```

## Running against fakes or against the API

Every repository has a remote implementation and a fake one behind the same
interface, selected by `--dart-define`. Until the API is deployed the fakes are
the default, so a bare `flutter run` opens a navigable app:

```bash
flutter run                                      # fake data sources

flutter run \
  --dart-define=DATA_SOURCE=remote \
  --dart-define=API_BASE_URL=https://<railway-host>/api \
  --dart-define=CLUB_ID=<seeded-club-id>
```

| Define | Default | Notes |
| :--- | :--- | :--- |
| `DATA_SOURCE` | `fake` | `remote` targets the API. A release build wired to the fakes refuses to boot. |
| `API_BASE_URL` | *(empty)* | Includes the `/api` prefix, no trailing slash, no version segment. |
| `CLUB_ID` | *(unset)* | The club the login authenticates against, until `GET /api/clubs` exists. |

All three are read in `lib/core/config/app_environment.dart`. A `remote` build
missing `API_BASE_URL` or `CLUB_ID` throws at startup rather than failing later:
the API answers one indistinguishable `401` for every credential problem, so a
wrong `CLUB_ID` would look exactly like a wrong password.

Fake accounts, one per role, all with password `123456`:

| DNI | Role |
| :--- | :--- |
| `11111111` | `ADMIN` |
| `22222222` | `SUPER_ADMIN` |
| `33333333` | `MEMBER` |

Secrets never live in the repository: pass them with `--dart-define` or a
git-ignored `.env`.

## Design system

Design tokens live in `lib/core/theme/`: `app_colors.dart` (palette),
`app_spacing.dart`, `app_radius.dart` and `app_text_styles.dart`. They are
wired into a single `ThemeData` in `app_theme.dart` — widgets read the theme
instead of hardcoding values.

The component gallery is the living catalog of every shared component in every
state. It replaces a static design file, so it cannot drift from the code.
It is registered only in debug builds:

```bash
flutter run
# then navigate to /dev/gallery
```
