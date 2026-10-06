# Task List - Production-Ready Text MVP Polish & Refactoring

- `[x]` **1. Roadmap & Strategic Pivot**
  - `[x]` Pivot focus to Text-Only Floating Assistant MVP for immediate production release & DevLogs.
  - `[x]` Update roadmap and task artifacts.

- `[x]` **2. Floating Overlay UX, Gesture & Theme Polish**
  - `[x]` Fix overlay text field long-press paste menu on physical Android devices.
  - `[x]` Fix chat list scrolling (remove nested `SingleChildScrollView` inside bubbles and configure smooth `ListView.builder` physics).
  - `[x]` Full-Screen Reading Mode: Snap overlay to screen margins when maximized and add electric blue `RawScrollbar`.
  - `[x]` Soft Keyboard Handling: Configure `Scaffold.resizeToAvoidBottomInset` so text box rides above soft keyboard.
  - `[x]` Status Bar Margins: Apply safe top margin (`topSafeArea + 8px`) clearing phone clock, Wi-Fi, and battery icons.
  - `[x]` Buttery-Smooth Marquee Ticker: 60fps VSync `AnimationController` marquee with interactive robot avatar tap toggle and glowing cyan update badge.
  - `[x]` Sleek Midnight Theme: Apply unified dark palette (`#121212` background, `#1E1E1E` cards, `blueAccent` primary) across whole app.

- `[x]` **3. "Cozy" & User-Friendly Model Selector UI**
  - `[x]` Redesign `ProviderDropdown` with visual cards and badges (Google Gemini, Ollama, OpenAI, Claude).
  - `[x]` Replace technical raw model strings with friendly descriptions and optional BYOK key input.
  - `[x]` Tuck Spring Boot Gateway URL into expandable `⚙️ Advanced Gateway Server Settings` accordion.

- `[x]` **4. Metrics Tab & Quota Componentization**
  - `[x]` Remove screenshot analysis metrics for Text-Only MVP launch.
  - `[x]` Extract reusable `UsageMeterCard` adhering strictly to Single Responsibility Principle (SRP).
  - `[x]` Add dynamic BYOK / Local mode detection showing green **"♾️ UNLIMITED"** meter.

- `[x]` **5. Code Architecture Refactoring & Quality Clean-up**
  - `[x]` Extract `CliboRobotOverlay` out of `main.dart` into `lib/features/companion/presentation/widgets/overlay/clibo_robot_overlay.dart`.
  - `[x]` Clean up `main.dart` to strictly handle app initialization (~50 lines).
  - `[x]` Convert relative imports to package imports and resolve all compiler warnings/errors (0 errors, 0 warnings).

- `[x]` **6. Navigation Drawer Cleanup & Chat History Feature**
  - `[x]` Remove redundant side panel items (such as the redundant API key placeholder in `HomeScreen` drawer).
  - `[x]` Build out **Chat History & Session Management**:
    - Display past chat sessions fetched from Spring Boot / local storage.
    - Enable viewing, searching, and restoring previous chat conversations in overlay / main app.
    - Clear chat history and handle session deletion.

- `[/]` **7. Analytics, A/B Testing & Remote Config Setup (ACTIVE FOCUS)**
  - `[ ]` Add `firebase_analytics`, `firebase_remote_config`, and `firebase_crashlytics` to `clibofe/pubspec.yaml`.
  - `[ ]` Configure Firebase Analytics service / event logging (prompt sent, model switched, overlay opened, BYOK toggled).
  - `[ ]` Configure Firebase Remote Config for dynamic quota limits, feature flags, and A/B testing parameters.
  - `[ ]` Wire Remote Config values into `UsageGuardrailService` / `ConfigService`.

- `[ ]` **8. Production Build & Monetization Setup**
  - `[ ]` Finalize monetization strategy (BYOK + Free Proxy Tier + Optional Main App Ad Banner).
  - `[ ]` Production app bundle build preparation and store assets check.
