# CLAUDE.md — Frontend (Flutter)

## Role
Act as a senior Flutter/Dart developer with equivalent 20 years of experience. Always favor the most professional, production-grade approach over the simplest one to write.

## Stack
- Flutter (canal stable), Dart (versión estable acorde al SDK del proyecto). Versiones fijadas en `pubspec.yaml`/`pubspec.lock`; los bumps de versión son una decisión deliberada, no automática (ver "Gestión de dependencias").
- Consumo de API: backend Spring Boot desplegado en un entorno remoto (nunca localhost como base URL de trabajo diario).
- Gestión de estado: enfoque estructurado y escalable (Riverpod o Bloc — elegir uno al inicio del proyecto y mantener consistencia, sin mezclar patrones).
- Inyección de dependencias explícita (constructor injection / providers), evitando singletons globales y `Locator` patterns implícitos.
- Navegación: usar un router declarativo (go_router u otro equivalente) en vez de `Navigator` imperativo disperso por la app.

## Arquitectura
- Separación clara de capas: **data** (repositories, clientes HTTP/DTOs), **domain** (models, use cases/entidades), **presentation** (widgets, providers/blocs). Nunca llamadas HTTP directas desde un widget.
- Los widgets no conocen DTOs de red: mapear DTO → modelo de dominio en la capa data antes de exponerlo a presentación.
- Los use cases/repositorios se exponen mediante interfaces (abstract class) en domain, con su implementación concreta en data — facilita el mockeo en tests y el desacoplamiento del cliente HTTP concreto.
- Manejo de estado inmutable (freezed o equivalente) para evitar mutaciones accidentales y bugs de referencia compartida.

## Código
- Todo en inglés: nombres de variables, clases, widgets, archivos y carpetas.
- Funciones/métodos de propósito único, ≤20 líneas, ≤3 parámetros. Excepciones solo si están justificadas.
- Sin comentarios salvo excepciones justificadas. Nombres descriptivos que hagan innecesaria la explicación.
- Widgets pequeños y composables. Si un `build()` supera ~30-40 líneas, extraer sub-widgets con nombre propio.
- `const` siempre que sea posible en widgets e instancias, para minimizar rebuilds innecesarios.
- Manejo explícito de errores en cada llamada a la API: nunca un `try/catch` vacío. Loguear errores relevantes con contexto (endpoint, status code, payload cuando sea seguro loguearlo).
- Modelar los resultados de operaciones de red/dominio con un tipo explícito de éxito/error (`Result`/`Either` o sealed classes), evitando que las excepciones sean el único mecanismo de control de flujo hacia la UI.

## Gestión de dependencias
- Las versiones de dependencias en `pubspec.yaml` se actualizan de forma deliberada y revisada (changelog, breaking changes, impacto en la app), nunca de forma automática ni "siempre a la última".
- Antes de subir una versión mayor de una dependencia clave (state management, router, HTTP client), evaluar el changelog y correr la suite de tests completa.

## Testing
- Tests de widgets para componentes de UI con lógica no trivial.
- Tests unitarios para lógica de dominio y mapeo de datos (parsing de DTOs, validación de formularios).
- Mockear la capa de red en los tests — nunca golpear la API real desde un test automatizado (usar fakes/mocks sobre la interfaz de repositorio, no sobre el cliente HTTP concreto).
- Tests de integración (opcional pero recomendado) para flujos críticos: reserva de cancha, pago de cuota.

## Flujo de trabajo
- Configuración de entornos vía variables/flavors (`--dart-define` o flavors de Flutter) para alternar entre el backend remoto y un backend local, sin hardcodear URLs en el código.
- El entorno remoto es la base de trabajo diaria por defecto; lo local se usa solo para correr la suite de tests y para desarrollo de UI con datos mockeados cuando se necesita iteración rápida sin depender de la red.
- Antes de cada entrega: correr `flutter analyze` y la suite de tests completa. Cero warnings de analyzer antes de dar por cerrada una tarea.
- Manejar secretos (API keys, tokens) fuera del control de versiones (`--dart-define`, `.env` ignorado en git), nunca hardcodeados en el repositorio.

## UI/UX
- Diseño simple y funcional pensado para socios de un club de barrio (rango etario amplio, no asumir usuarios expertos en apps).
- Priorizar claridad y pocos pasos por flujo (reservar una cancha, revisar estado de cuota, etc.) por sobre la sofisticación visual.
- Accesibilidad básica: tamaños de texto legibles, contraste adecuado, soporte de `Semantics` en elementos interactivos clave.
- Manejar explícitamente los estados de carga, vacío y error en cada pantalla que consuma datos remotos (no solo el "happy path").

## Contexto de dominio
App móvil para socios y administradores de un club de barrio: reserva de canchas, turnos recurrentes y actividades, seguimiento de cuotas/pagos, grupos familiares. El backend es Spring Boot consumido vía REST. Ver el `CLAUDE.md` del repo de backend para el modelo de datos completo (nueve tablas: club, family_group, member, user_account, payment, court, court_block, recurring_slot, reservation).
