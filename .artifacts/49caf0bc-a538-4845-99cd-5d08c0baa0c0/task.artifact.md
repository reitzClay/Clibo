# Task List - Production-Ready Text MVP Polish & Refactoring

- `[/]` **1. Roadmap & Strategic Pivot**
  - `[x]` Pivot focus to Text-Only Floating Assistant MVP for immediate production release & DevLogs.
  - `[x]` Update roadmap and task artifacts.

- `[ ]` **2. Floating Overlay UX & Gesture Bug Fixes**
  - `[ ]` Fix overlay text field long-press paste menu on physical Android devices.
  - `[ ]` Fix chat list scrolling (remove nested `SingleChildScrollView` inside bubbles and configure smooth `ListView.builder` physics).
  - `[ ]` Gracefully simplify or hide image button for Text-Only MVP launch.

- `[ ]` **3. "Cozy" & User-Friendly Model Selector UI**
  - `[ ]` Redesign `ProviderDropdown` and model selector cards in `ConfigTab.dart`.
  - `[ ]` Add brand icons/badges (Google Gemini, Ollama, OpenAI, Claude).
  - `[ ]` Replace technical raw model IDs (`gemini-3.5-flash-lite`) with friendly names (e.g. "Gemini Flash - Fast & Efficient").

- `[ ]` **4. Code Architecture Refactoring & Quality Clean-up**
  - `[ ]` Extract `CliboRobotOverlay` out of `main.dart` into `lib/features/companion/presentation/widgets/overlay/clibo_robot_overlay.dart`.
  - `[ ]` Clean up `main.dart` to strictly handle app initialization and overlay listener setup.
  - `[ ]` Audit project files for SRP violations, hardcoded values, and code smells.

- `[ ]` **5. Production Build & Monetization Setup**
  - `[ ]` Finalize monetization strategy (BYOK + Free Proxy Tier + Optional Main App Banner).
  - `[ ]` Production app bundle build preparation and store assets check.
