# Clibo AI Companion & ClayBytes Ecosystem Roadmap

## Vision & Strategic Core Concept
Clibo is a context-aware, cross-app floating AI companion designed to bridge the gap between users and their digital environment across Android devices.

Beyond being a standalone product, Clibo serves as the flagship open-portfolio showcase for **ClayBytes** ([claybytes.nl](https://claybytes.nl/)), highlighting 17+ years of elite software engineering evolved into modern **AI-First Development** (Flutter, Java 21, Spring Boot, Docker, GCP, and multi-model LLM orchestration).

### Growth & Monetization Strategy
1. **Portfolio & Authority Marketing (YouTube Dev-Logs)**: Documenting the end-to-end building journey, teaching the next generation of developers how to program with AI, and building an engaged audience that converts into consultancy clients and students.
2. **Free, Robust Developer Preview (Beta)**: Keeping the app free during initial rollout to iron out bugs, gather user feedback, and establish rock-solid stability with a Free Gemini Tier + BYOK (Bring Your Own Key) options.
3. **The Lottie Overlay Creator Marketplace (Future Ecosystem)**: An in-app creator store where digital artists and animators can design, publish, and sell custom Lottie companion overlays and skins via In-App Purchases (IAP).

---

## Roadmap Phases

### Phase 1: Core Architecture, Auth & Compliance (Completed)
*Status: [x] Completed*
- [x] Spring Boot enterprise backend (`clibobe`) with Strategy Pattern for multi-provider AI routing.
- [x] Flutter overlay window (`clibofe`) with real-time SSE streaming.
- [x] PostgreSQL metered usage guardrails, multi-tenant organization workspaces, and database chat audit logging (`chat_sessions`, `chat_messages`, `user_consents`).
- [x] Google Sign-In, Company login, organization registration, and legal Terms of Service / Privacy Policy compliance for ClayBytes.
- [x] Chat history cache clearing on logout and overlay dismissal.

### Phase 2: Multi-Provider Chat Testing & Stability (Completed)
*Status: [x] Completed*
- [x] Streamlined login screen flow: Removed popup interceptor on Google Sign-In button and commented out B2B company login clutter.
- [x] Redesigned Config Tab with context-aware provider cards (`GeminiConfigCard`, `OllamaConfigCard`, `ByokKeyInput`, `CustomEndpointCard`).
- [x] Moved Spring Boot Gateway URL into an expandable `⚙️ Advanced Gateway Settings` accordion.
- [x] Integrated Google Gemini Cloud models (`gemini-3.5-flash-lite`, `gemini-3.8-flash`, `gemini-3.5-flash`) with 100% success rate on Google AI Studio.
- [x] Verified BYOK API key passing and local network physical device IP retention (`192.168.0.103`).
- [x] Enhanced SSE error parsing in `BackendProxyAIClient` for clean error rendering.

### Phase 3: Multi-Modal Vision & Image Attachments (Completed)
*Status: [x] Completed*
- [x] Built multi-modal image payload pipeline (`imageBase64` + `imageMimeType`) in `BackendProxyAIClient` and Spring Boot `GeminiAiService.java`.
- [x] Integrated Google Gemini `gemini-3.5-flash-lite` vision analysis for multi-modal text and visual prompts.
- [x] Updated Android 14+ / targetSDK 36 Foreground Service declarations (`foregroundServiceType="specialUse"`) in `AndroidManifest.xml`.
- [x] Documented Flutter overlay isolate boundaries: `OverlayService` runs in a background service isolate where plugins requiring `ActivityBinding` (`image_picker`, `MediaProjectionManager`) require activity-context bridging.
- [x] Integrated manual screenshot and image attachment workflow (`image_picker`) allowing users to attach screenshots and photos directly into the overlay chat.

### Phase 4: Voice & Audio Interactivity (Up Next)
*Status: [/] In Progress*
- [ ] Extend Inter-Isolate Communication Bridge for audio recording (`RECORD_AUDIO` / `AUDIO_CAPTURED`).
- [ ] Implement audio recording service in Flutter overlay / main engine.
- [ ] Transmit `audioBase64` and `audioMimeType` through backend proxy to Gemini multi-modal audio pipeline.
- [ ] Enable real-time voice notes and text-to-speech audio feedback.

### Phase 5: Advanced UI/UX, Lottie Animations & Creator Marketplace
*Status: [ ] Future Vision*
- [ ] Replace static placeholder avatar with dynamic **Lottie animations**.
- [ ] Integrate device sensors (gyroscope and accelerometer) so the floating character reacts to phone tilt and physical shakes.
- [ ] Build the in-app **Lottie Overlay Creator Store** enabling artists to publish and monetize custom companion skins.
