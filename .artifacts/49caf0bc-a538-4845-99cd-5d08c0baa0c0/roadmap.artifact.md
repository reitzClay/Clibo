# Clibo AI Companion - Updated Production Release Roadmap

## Vision & Strategic Core Concept
Clibo is a context-aware, zero-context-switching floating AI companion that sits over any Android app (Snapchat, Instagram, Browser, Notes, etc.).

**Production MVP Pivot Strategy**:
To get to market fast, generate YouTube DevLogs, and acquire real users, **Clibo is launching with a polished Text-Only Floating Assistant MVP**. Features like Multi-Modal Vision and Voice will be rolled out as major post-launch update episodes in the DevLog series.

---

## Roadmap Phases

### Phase 1: Core Architecture, Auth & Compliance (Completed)
*Status: [x] Completed*
- [x] Spring Boot enterprise backend (`clibobe`) with Strategy Pattern for multi-provider AI routing.
- [x] Flutter overlay window (`clibofe`) with real-time SSE streaming.
- [x] PostgreSQL metered usage guardrails and compliance logging.
- [x] Google Sign-In, Terms of Service & Privacy Policy integration (`user_consents` logging with multi-cloud IP resolution).

### Phase 2: Multi-Provider Chat Testing & Stability (Completed)
*Status: [x] Completed*
- [x] Context-aware Config Tab with provider dropdowns.
- [x] Google Gemini Cloud (`gemini-3.5-flash-lite`, `gemini-3.8-flash`) integration.
- [x] Local Ollama container support and physical device IP retention.
- [x] OpenAI (`gpt-4o-mini`) and Anthropic Claude (`claude-3-5-sonnet-20241022`) integrations.

### Phase 3: Text-Only Floating Companion MVP & Production Polish (Completed)
*Status: [x] Completed*
- [x] **Overlay Input & Gesture Fixes**: Long-press text paste menu, smooth chat scrolling, soft keyboard avoidance, safe status bar margins (`topSafeArea + 28px`), and double-tap header minimize gesture.
- [x] **Overlay Reading Mode**: Full screen window snapping, electric blue scrollbar, and 60fps VSync marquee ticker with interactive robot avatar toggle.
- [x] **Cozy UI Model Selector**: Provider cards with official brand logos (Gemini, Ollama, OpenAI, Claude, Custom), friendly names, isolated BYOK key inputs, and accordion gateway settings.
- [x] **Metrics Componentization**: Reusable `UsageMeterCard` with dynamic BYOK/Unlimited emerald progress meter and active provider logo banner.
- [x] **Code Refactoring**: Decoupled `main.dart` into `CliboRobotOverlay` (0 errors, 0 warnings).
- [x] **Drawer Cleanup & Chat History**:
  - Remove redundant side panel items.
  - Grouped **Chat History & Session Management**: thread grouping, turn count badges, per-turn model provider tracking, cascading PostgreSQL deletion, and **Resume in Overlay** (`RESUME_CHAT` inter-isolate bridge).
- [x] **Analytics, A/B Testing & Remote Config**:
  - `firebase_analytics`, `firebase_remote_config`, and `firebase_crashlytics` integrated.
  - Event tracking for prompt submissions, model switches, BYOK saves, and overlay toggles.
  - Dynamic Remote Config feature flags and A/B testing parameters with offline fallbacks.
- [x] **Java 21 Project Loom & Backend Infrastructure**:
  - Virtual threads enabled (`spring.threads.virtual.enabled=true`).
  - Bounded HikariCP pool and 512MB-1GB RAM container JVM tuning for low-cost Google Cloud Run hosting.
  - Server-side environment variable security (`clibobe/.env`) for API keys.
- [x] **Branding & Native Store Assets**:
  - Generated native Android launcher icons from `clibo.jpg`.
  - Updated native app label `Clibo AI`, dark startup window launch background, and white circular splash screen.

### Phase 4: Post-Launch DevLog Episode 1 - Multi-Modal Vision (Post-Launch Update)
*Status: [ ] Planned for DevLog Episode*
- [ ] Re-enable and polish multi-modal screenshot/image picking pipeline (`image_picker` inter-isolate bridge).
- [ ] Vision prompt templates (summarize document, analyze chart, describe screen).

### Phase 5: Post-Launch DevLog Episode 2 - Voice Interactivity & Lottie Marketplace (Future)
*Status: [ ] Planned for DevLog Episode*
- [ ] Inter-isolate audio recording bridge (`RECORD_AUDIO`).
- [ ] Lottie animation skins and creator marketplace.
