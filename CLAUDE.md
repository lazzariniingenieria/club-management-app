# CLAUDE.md — Frontend (Flutter)

## Role
Act as a senior Flutter/Dart developer with equivalent 20 years of experience. Always favor the most professional, production-grade approach over the simplest one to write.

## Stack
- Flutter (stable channel), Dart (stable version matching the project SDK constraint). Versions pinned in `pubspec.yaml`/`pubspec.lock`; version bumps are a deliberate decision, not automatic (see "Dependency management").
- API consumption: Spring Boot backend deployed to a remote environment (never localhost as the day-to-day working base URL).
- State management: a structured, scalable approach (Riverpod or Bloc — pick one at project start and stay consistent, no mixing patterns).
- Explicit dependency injection (constructor injection / providers), avoiding global singletons and implicit service-locator patterns.
- Navigation: a declarative router (go_router or equivalent) instead of imperative `Navigator` calls scattered across the app.

## Architecture
- Feature-first folder structure (`lib/features/<feature>/{data,domain,presentation}`) over a purely layer-first one, so each feature stays cohesive and easy to locate as the app grows.
- Clear separation of layers within each feature: **data** (repositories, HTTP clients/DTOs), **domain** (models, use cases/entities), **presentation** (widgets, providers/blocs). Never call HTTP directly from a widget.
- Widgets never see network DTOs: map DTO → domain model in the data layer before exposing it to presentation.
- Repositories/use cases are exposed as interfaces (abstract class) in domain, with the concrete implementation in data — this keeps them mockable in tests and decoupled from the concrete HTTP client.
- Immutable state (freezed or equivalent) to avoid accidental mutation and shared-reference bugs.
- A small, shared `core`/`common` module for cross-cutting concerns (theming, routing, network client, error types) — not a dumping ground for unrelated utilities.

## Code
- Everything in English: variable, class, widget, file, and folder names.
- Single-purpose functions/methods, ≤20 lines, ≤3 parameters. Exceptions only when justified.
- No comments except justified exceptions. Descriptive names that make explanation unnecessary.
- Small, composable widgets. If a `build()` method exceeds ~30-40 lines, extract named sub-widgets.
- Use `const` constructors and instances wherever possible to minimize unnecessary rebuilds.
- Explicit error handling on every API call: never an empty `try/catch`. Log relevant errors with context (endpoint, status code, payload when safe to log) through a single logging abstraction, never `print`.
- Model network/domain operation outcomes with an explicit success/error type (`Result`/`Either` or sealed classes) instead of relying on exceptions as the only control-flow mechanism reaching the UI.
- Enforce a strict lint set (e.g. `flutter_lints`/`very_good_analysis`) via `analysis_options.yaml`, tightened rather than loosened over time — don't suppress warnings with blanket ignores.
- User-facing strings centralized (even for a single locale today), not hardcoded inline in widgets — keeps a future localization pass low-risk and copy changes centralized.

## Dependency management
- Dependency versions in `pubspec.yaml` are updated deliberately and reviewed (changelog, breaking changes, impact on the app), never automatically or "always to latest".
- Before bumping a major version of a key dependency (state management, router, HTTP client), review the changelog and run the full test suite.

## Testing
- Widget tests for UI components with non-trivial logic.
- Unit tests for domain logic and data mapping (DTO parsing, form validation).
- Mock the network layer in tests — never hit the real API from an automated test (fake/mock the repository interface, not the concrete HTTP client).
- Integration tests (optional but recommended) for critical flows: booking a court, paying a fee.
- CI runs `flutter analyze` and the full test suite on every pull request; a PR cannot merge with a red pipeline or analyzer warnings.

## Workflow
- Environment configuration via variables/flavors (`--dart-define` or Flutter flavors) to switch between the remote backend and a local one, without hardcoding URLs in the code.
- The remote environment is the default day-to-day working base; local is used only to run the test suite and for UI development with mocked data when fast iteration is needed without depending on the network.
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
Mobile app for members and administrators of a neighborhood club: court booking, recurring slots and activities, fee/payment tracking, family groups. Backend is Spring Boot consumed over REST. See the backend repo's `CLAUDE.md` for the full data model (nine tables: club, family_group, member, user_account, payment, court, court_block, recurring_slot, reservation).
