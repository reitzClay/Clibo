# Task List - Production-Ready Text MVP Polish & Refactoring

- `[x]` **1. Roadmap & Strategic Pivot**
  - `[x]` Pivot focus to Text-Only Floating Assistant MVP for immediate production release & DevLogs.
  - `[x]` Update roadmap and task artifacts.

- `[x]` **2. Floating Overlay UX, Gesture & Theme Polish**
  - `[x]` Fix overlay text field long-press paste menu on physical Android devices.
  - `[x]` Fix chat list scrolling (remove nested `SingleChildScrollView` inside bubbles and configure smooth `ListView.builder` physics).
  - `[x]` Full-Screen Reading Mode: Snap overlay to screen margins when maximized and add electric blue `RawScrollbar`.
  - `[x]` Soft Keyboard Handling: Configure `Scaffold.resizeToAvoidBottomInset` so text box rides above soft keyboard.
  - `[x]` Status Bar Margins: Apply safe top margin (`topSafeArea + 28px`) clearing phone clock, Wi-Fi, and battery icons.
  - `[x]` Prominent Action Pill Buttons: Encapsulate Fullscreen and Close (`X`) buttons in semi-transparent pill container with vertical divider.
  - `[x]` Buttery-Smooth Marquee Ticker: 60fps VSync `AnimationController` marquee with interactive robot avatar tap toggle and glowing cyan update badge.
  - `[x]` Sleek Midnight Theme: Apply unified dark palette (`#121212` background, `#1E1E1E` cards, `blueAccent` primary) across whole app.

- `[x]` **3. "Cozy" & User-Friendly Model Selector UI**
  - `[x]` Redesign `ProviderDropdown` with visual cards and badges (Google Gemini, Ollama, OpenAI, Claude).
  - `[x]` Add official brand logo assets (`gemini.png`, `ollama.png`, `openai.png`, `claude.png`, `custom.png`) across Config, Metrics, and History tabs.
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
    - Group chat messages into session threads with turn count badges.
    - Enable viewing, searching, and restoring previous chat conversations in overlay / main app.
    - Enable **Resume in Overlay** (`RESUME_CHAT` inter-isolate bridge) to continue any past conversation thread seamlessly.
    - Implement per-message provider tracking so switching models never corrupts past chat logs.
    - Cascading PostgreSQL deletion for chat sessions and messages.

- `[x]` **7. Analytics, A/B Testing & Remote Config Setup**
  - `[x]` Add `firebase_analytics`, `firebase_remote_config`, and `firebase_crashlytics` to `clibofe/pubspec.yaml`.
  - `[x]` Create `AnalyticsService` for logging user events (`prompt_sent`, `model_changed`, `overlay_toggled`, `byok_saved`, `app_error`).
  - `[x]` Create `RemoteConfigService` for dynamic quota limits, feature flags, and A/B testing parameters with offline fallbacks.
  - `[x]` Bind uncaught Flutter/platform errors to `FirebaseCrashlytics` in `main.dart`.

- `[x]` **8. Backend Performance & Project Loom Enablement**
  - `[x]` Enable Java 21 **Virtual Threads (Project Loom)** in Spring Boot (`spring.threads.virtual.enabled=true`).
  - `[x]` Bounded HikariCP database connection pool (`maximum-pool-size: 15`).
  - `[x]` Add `ClaudeAiService.java` for Anthropic Claude integration (`claude-3-5-sonnet-20241022`).
  - `[x]` Environment variable security (`clibobe/.env`) for server API keys (`GEMINI_API_KEY`, `OPENAI_API_KEY`, `CLAUDE_API_KEY`).
  - `[x]` Container JVM memory tuning (`-XX:MaxRAMPercentage=75.0`, `-XX:+UseG1GC`) for 512MB-1GB hosting (Google Cloud Run).
  - `[x]` Multi-cloud IP resolution in `ConsentController.java` (`ServerHttpRequest` + `X-Forwarded-For` + `X-Real-IP` + `CF-Connecting-IP`).

- `[x]` **9. App Store Assets & Native Branding**
  - `[x]` Configured `flutter_launcher_icons` with `assets/images/clibo.jpg`.
  - `[x]` Generated native Android icons across all resolution buckets (`mipmap-hdpi` through `mipmap-xxxhdpi`).
  - `[x]` Updated native app label `android:label="Clibo AI"` and startup window launch background in `launch_background.xml`.
  - `[x]` Updated startup splash screen (`splash_screen.dart`) with white circle background blending with `clibo.jpg`.
