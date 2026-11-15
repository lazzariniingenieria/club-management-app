# CLAUDE.md — Frontend (Flutter)

## Role
Act as a senior Flutter/Dart developer with equivalent 20 years of experience. Always favor the most professional, production-grade approach over the simplest one to write.

## Stack
- Flutter (stable channel), Dart (stable version matching the project SDK constraint). Versions pinned in `pubspec.yaml`/`pubspec.lock`; version bumps are a deliberate decision, not automatic (see "Dependency management").
- API consumption: Spring Boot backend deployed to a remote environment (never localhost as the day-to-day working base URL).
- State management: Bloc/Cubit (`flutter_bloc`). It is the pattern this project chose; don't mix in another one.
- Dependency injection: a `get_it` container registered in `lib/core/di/injection_container.dart`. Classes receive their collaborators through the constructor; the container is read only where a screen or widget builds its cubit/bloc, never inside domain or data classes.
- Navigation: `go_router`, declarative, instead of imperative `Navigator` calls scattered across the app.

## Architecture
- Feature-first folder structure (`lib/features/<feature>/{data,domain,presentation}`) over a purely layer-first one, so each feature stays cohesive and easy to locate as the app grows.
- Clear separation of layers within each feature: **data** (repositories, HTTP clients/DTOs), **domain** (models, use cases/entities), **presentation** (widgets, providers/blocs). Never call HTTP directly from a widget.
- Widgets never see network DTOs: map DTO → domain model in the data layer before exposing it to presentation.
- Repositories/use cases are exposed as interfaces (abstract class) in domain, with the concrete implementation in data — this keeps them mockable in tests and decoupled from the concrete HTTP client.
- Immutable state: `Equatable` value classes with `final` fields, to avoid accidental mutation and shared-reference bugs.
- A small, shared `core`/`common` module for cross-cutting concerns (theming, routing, network client, error types) — not a dumping ground for unrelated utilities.

## Code
- Everything in English: variable, class, widget, file, and folder names.
- Single-purpose functions/methods, ≤20 lines, ≤3 parameters. Exceptions only when justified.
- No comments except justified exceptions. Descriptive names that make explanation unnecessary.
- Small, composable widgets. If a `build()` method exceeds ~30-40 lines, extract named sub-widgets.
- Use `const` constructors and instances wherever possible to minimize unnecessary rebuilds.
- Explicit error handling on every API call: never an empty `try/catch`. Log relevant errors with context (endpoint, status code, payload when safe to log) through a single logging abstraction, never `print`.
- Model network/domain operation outcomes with an explicit success/error type (`Either<Failure, T>` from `fpdart`) instead of relying on exceptions as the only control-flow mechanism reaching the UI.
- Lint set: `flutter_lints` via `analysis_options.yaml`, tightened rather than loosened over time — don't suppress warnings with blanket ignores.
- User-facing strings centralized (even for a single locale today), not hardcoded inline in widgets — keeps a future localization pass low-risk and copy changes centralized.

## Dependency management
- Dependency versions in `pubspec.yaml` are updated deliberately and reviewed (changelog, breaking changes, impact on the app), never automatically or "always to latest".
- Before bumping a major version of a key dependency (state management, router, HTTP client), review the changelog and run the full test suite.

## Testing
- Widget tests for UI components with non-trivial logic.
- Unit tests for domain logic and data mapping (DTO parsing, form validation).
- Mock the network layer in tests — never hit the real API from an automated test (fake/mock the repository interface, not the concrete HTTP client).
- Integration tests (optional but recommended) for critical flows: booking a court, paying a fee.
- There is no CI pipeline yet, so nothing checks a pull request automatically: `flutter analyze` and the full test suite are run locally before opening or updating one, and the PR description states the result.

## Workflow
- Environment configuration via `--dart-define` (`DATA_SOURCE`, `API_BASE_URL`, `CLUB_ID`, read in `lib/core/config/app_environment.dart`), without hardcoding URLs in the code.
- A bare `flutter run` uses the fake data sources, for UI work and the test suite without depending on the network. `DATA_SOURCE=remote` targets the hosted API on Railway — the test environment for day-to-day work. There is no local backend: the API is never run on localhost.
- Before each delivery: run `flutter analyze` and the full test suite locally. Zero analyzer warnings before considering a task done.
- Keep secrets (API keys, tokens) out of version control (`--dart-define`, a git-ignored `.env`), never hardcoded in the repository.
- Small, focused branches and pull requests (one feature/fix per PR); descriptive commit messages that explain *why*, not just *what*.
- Bump the app version/build number (`pubspec.yaml`) deliberately as part of the release process, not on every merge.

## UI/UX
- Simple, functional design built for real neighborhood club members (wide age range, don't assume app-savvy users).
- Prioritize clarity and few steps per flow (booking a court, checking fee status, etc.) over visual sophistication.
- Basic accessibility: legible text sizes, adequate contrast, `Semantics` support on key interactive elements.
- Explicitly handle loading, empty, and error states on every screen that consumes remote data — not just the happy path.
- Long or dynamic lists use `ListView.builder`/slivers instead of building the full list eagerly; images are cached and sized appropriately for the target device.

## Domain context
Mobile app for members and administrators of a neighborhood club: court booking, recurring slots and activities, fee/payment tracking, family groups. Backend is Spring Boot consumed over REST.

One app for the three roles (`SUPER_ADMIN`, `ADMIN`, `MEMBER`), delivered to the club in three stages that the API switches on per club:
1. **Members and fees** — admin surface only.
2. **Courts and bookings** (`courtsEnabled` in `/api/clubs/me`) — still admin only.
3. **Member self-service** (the club's `member_app_enabled` flag, which the API does not expose yet) — the member's own surface: their payments and their bookings.

Two rules about the DNI follow from that and apply everywhere in the app:
- **Every account logs in with DNI + password, and nobody registers themselves.** In stage 3 a member who wants the app asks an admin, who creates the account and gives them the initial password — the same way the super admin creates admin accounts today. The app has no sign-up screen and no password recovery by email. Whether the first login forces a password change is not decided yet.
- **A member's DNI is optional.** Some members won't give it when they join, so `Member.dni` is nullable and the member form doesn't require it; it is loaded later, at the latest when the member asks for an account. An admin's DNI stays required, because it is the login. Wherever a member's DNI would be shown, a member without one reads "Sin DNI".

**[backend_api.md](backend_api.md) is the single source of truth for the API contract** — endpoints, request/response shapes, error model, authorization, server-side business rules, the data model actually migrated, known pitfalls, and what does not exist yet. Read it instead of the backend repo: it states which commit it was verified against. Only go to [club-management-api](https://github.com/lazzariniingenieria/club-management-api) when it cannot answer the question — and when you do, update it with what you found.

[app_flows.md](app_flows.md) owns the other half: screens, navigation, per-role surfaces, screen states, visual direction and delivery order. Keep each fact in whichever of the two owns it; don't restate the contract in `app_flows.md` or screen decisions in `backend_api.md`.
