# Clibo Frontend Architecture (`clibofe`)

## 1. Overview & Purpose

The **Clibo Frontend (`clibofe`)** is a cross-platform Flutter application built with **Dart (^3.11.1)** designed to act as a ubiquitous AI companion. It provides users with a modern, responsive workspace and a powerful system-level **Floating Overlay** that allows interacting with AI models (Google Gemini, local Ollama, or custom endpoints) across any screen on the device.

---

## 2. Core Architectural Layers

```
clibofe/lib/
├── app/                  # Application startup & Service Locator (GetIt)
├── core/
│   ├── services/
│   │   ├── overlay/      # System floating window controllers (Android/iOS)
│   │   └── capture/      # Screen capture & MediaProjection services
│   └── network/          # Network configuration & HTTP clients
├── data/
│   ├── repositories/     # Auth & User data repositories (Remote/Dev)
│   └── services/         # Config & authentication service layers
├── domain/
│   ├── config/           # AI provider configuration models (Gemini, Ollama, BYOK)
│   └── user/             # User domain models
├── features/
│   └── companion/
│       └── presentation/
│           ├── screens/  # HomeScreen, LoginScreen, SplashScreen, Terms/Privacy screens
│           ├── tabs/     # ConfigTab, HistoryTab, MetricsTab
│           └── widgets/  # Config cards (Gemini, Ollama, Custom), status cards
└── interface/
    └── clibo_ai_client.dart # Abstract AI client & BackendProxyAIClient (SSE streaming)
```

---

## 3. The Floating Overlay System

A core differentiator of Clibo is its system-wide **Floating Overlay** (`flutter_overlay_window`).

- **Activation**: Users can toggle the floating overlay from the app's navigation drawer (`HomeScreen`).
- **Permissions**: Automatically checks and requests system overlay permissions (`SYSTEM_ALERT_WINDOW` on Android).
- **Behavior**: Spawns a lightweight, draggable floating assistant widget (`OverlayAlignment.centerRight` or custom coordinates) that remains on top of other running applications.
- **Inter-Process / Isolate Communication**: Uses `FlutterOverlayWindow.shareData()` to push state updates and share context between the main app process and the running overlay isolate.

---

## 4. Multi-Modal Input Handling (Visuals, Text, & Voice)

Clibo's AI client abstraction ([clibo_ai_client.dart](file:///C:/Users/Clayt/Documents/Development/Clibo/clibofe/lib/interface/clibo_aI_client.dart)) supports rich multi-modal inputs:

### A. Visuals & Screen Capture
- **`AndroidScreenCapturer`**: Interfaces with native Android screen recording/capture APIs (`MediaProjection`).
- Captures screen pixels into `Uint8List`, compresses them, and passes them as Base64-encoded images (`imageBase64` + `imageMimeType`) to the AI proxy. This enables the assistant to "see" what is on the user's screen and answer questions about it contextually.

### B. Text & SSE Streaming
- Standard natural language prompts submitted via text input fields.
- Processed with Server-Sent Events (SSE) streaming (`Accept: text/event-stream`), allowing real-time token rendering in the UI.
- Clean JSON error catching extracts server error messages seamlessly into the overlay interface.

### C. Voice
- Captures audio input from the user's microphone.
- Encodes audio streams into Base64 (`audioBase64` + `audioMimeType`) and transmits them alongside prompts to the backend for speech-to-text and multi-modal understanding.

---

## 5. AI Client Abstraction & Config Tab

The frontend uses the `CliboAIClient` interface to support multiple backend routing options:
1. **`BackendProxyAIClient`**: The primary production client. Proxies requests to the Spring Boot backend (`/api/v1/ai/chat`), attaching authentication tokens (`Bearer token`) and enforcing server-side usage guardrails.
2. **Context-Sensitive Config Tab**:
   - **Dropdown Selector**: Easily switch between **Google Gemini**, **Local Ollama**, **OpenAI**, **Claude**, or **Custom Endpoints**. Unnecessary configuration fields are automatically hidden.
   - **Google Gemini Card**: Supports **Gateway Proxy** (default free tier) and **Bring Your Own Key (BYOK)** modes.
   - **Local Ollama Card**: Shows zero-token local AI notice and host network IP configurations (`192.168.0.103:11434`).
   - **Expandable Advanced Settings**: Collapsible accordion tile hiding Spring Boot Gateway URL configuration to maintain a clean UI.
3. **`GeminiClient` / `OpenAiCompatibleClient`**: Client-side BYOK direct connection wrappers.
