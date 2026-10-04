# Clibo AI Companion Roadmap

## Vision & Core Concept
Clibo is a context-aware, cross-app floating AI companion designed to bridge the gap between users and their digital environment. By operating as a persistent system overlay, Clibo allows users to see, hear, and interpret whatever is on their device screen or in their surroundings **without needing to switch apps**.

The ultimate experience combines multi-modal perception (text, vision, voice) with an interactive, responsive floating character powered by Lottie animations and physical device sensors (gyroscope, accelerometer/shakes).

---

## Roadmap Phases

### Phase 1: Core Architecture & Authentication (In Progress)
*Status: [/] In Progress*
- [x] Spring Boot enterprise backend (`clibobe`) with Strategy Pattern for multi-provider AI routing.
- [x] Flutter overlay window (`clibofe`) with real-time SSE streaming.
- [x] PostgreSQL metered usage guardrails and quotas (`user_usages` & `organization_usages`).
- [x] Google Sign-In, Organization registration & company login flows.
- [/] **Logout Chat History Reset**: Ensure chat overlay messages are cleared across user sessions when logging out.

### Phase 2: Multi-Provider Chat Testing & Stability (Up Next)
*Status: [ ] Planned*
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

### Phase 5: Advanced UI/UX, Lottie Animations & Sensors
*Status: [ ] Future Vision*
- [ ] Replace static placeholder avatar with dynamic **Lottie animations**.
- [ ] Integrate device sensors (gyroscope and accelerometer) so the floating character reacts to phone tilt and physical shakes.
- [ ] Polish glassmorphism styling, ambient glowing borders, and expandable full-screen chat modes.
