# Clibo AI Companion & ClayBytes Ecosystem Roadmap

## Vision & Strategic Core Concept
Clibo is a context-aware, cross-app floating AI companion designed to bridge the gap between users and their digital environment across Android devices.

Beyond being a standalone product, Clibo serves as the flagship flagship open-portfolio showcase for **ClayBytes** ([claybytes.nl](https://claybytes.nl/)), highlighting 17+ years of elite software engineering evolved into modern **AI-First Development** (Flutter, Java 21, Spring Boot, Docker, GCP, and multi-model LLM orchestration).

### Growth & Monetization Strategy
1. **Portfolio & Authority Marketing (YouTube Dev-Logs)**: Documenting the end-to-end building journey, teaching the next generation of developers how to program with AI, and building an engaged audience that converts into consultancy clients and students.
2. **Free, Robust Developer Preview (Beta)**: Keeping the app free during initial rollout to iron out bugs, gather user feedback, and establish rock-solid stability.
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

### Phase 2: Multi-Provider Chat Testing & Stability (Up Next)
*Status: [/] In Progress*
- [ ] Test and verify robust text chat across multiple AI providers (Google Gemini, Local Ollama, BYOK keys, and custom endpoints).
- [ ] Ensure seamless provider switching and error handling in the frontend config and backend proxy.

### Phase 3: Multi-Modal Vision & Screen Intelligence
*Status: [ ] Planned*
- [ ] Implement `AndroidScreenCapturer` for on-demand screenshot acquisition.
- [ ] Transmit image payloads securely through the Spring Boot backend proxy.
- [ ] Integrate multi-modal AI models (e.g., Gemini Flash, Llava via Ollama) to interpret screen contents.
- [ ] Add quick-action screen analysis triggers ("What's on my screen?", "Summarize this page").

### Phase 4: Voice & Audio Interactivity
*Status: [ ] Planned*
- [ ] Implement audio recording service within the floating overlay.
- [ ] Support voice note attachments and transcription workflows.
- [ ] Enable real-time audio interaction and text-to-speech feedback.

### Phase 5: Advanced UI/UX, Lottie Animations & Creator Marketplace
*Status: [ ] Future Vision*
- [ ] Replace static placeholder avatar with dynamic **Lottie animations**.
- [ ] Integrate device sensors (gyroscope and accelerometer) so the floating character reacts to phone tilt and physical shakes.
- [ ] Build the in-app **Lottie Overlay Creator Store** enabling artists to publish and monetize custom companion skins.
