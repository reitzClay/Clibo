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

## 3. The Floating Overlay & Isolate Boundaries

A core differentiator of Clibo is its system-wide **Floating Overlay** (`flutter_overlay_window`).

- **Activation**: Users can toggle the floating overlay from the app's navigation drawer (`HomeScreen`).
- **Permissions**:
  - Requires `SYSTEM_ALERT_WINDOW` permission on Android.
  - Declared as `foregroundServiceType="specialUse"` in `AndroidManifest.xml` (complying with Android 14+ / targetSDK 36 Foreground Service restrictions).
- **Behavior**: Spawns a lightweight, draggable floating assistant widget (`OverlayAlignment.centerRight` or custom coordinates) that remains on top of other running applications.
- **Isolate & Service Constraints**:
  - The overlay runs in a secondary background isolate (`overlayMain`) inside an Android `Service` (`OverlayService`).
  - Because `OverlayService` is a `Service` and not an `Activity`, Flutter plugins that require `ActivityBinding` (such as `image_picker` or direct `Activity.startActivityForResult` calls) cannot execute directly inside `overlayMain`.
- **Inter-Isolate Bridge**: Uses `FlutterOverlayWindow.shareData()` to communicate asynchronously between the running overlay isolate and the main application isolate (`MainActivity`).

---

## 4. Multi-Modal Input Handling (Visuals, Text, & Voice)

Clibo's AI client abstraction ([clibo_ai_client.dart](file:///C:/Users/Clayt/Documents/Development/Clibo/clibofe/lib/interface/clibo_ai_client.dart)) supports rich multi-modal inputs:

### A. Visuals & Image Attachments
- **Image Attachment Pipeline**: Supports attaching screenshots and images via `image_picker`.
- **Base64 Encoding**: Encodes raw image bytes into Base64 (`imageBase64` + `imageMimeType`) and transmits them to the Spring Boot proxy (`clibobe`).
- **Google Gemini Cloud Processing**: The backend forwards multi-modal payloads to `gemini-3.5-flash-lite` for visual understanding and page analysis.

### B. Text & SSE Streaming
- Standard natural language prompts submitted via text input fields.
- Processed with Server-Sent Events (SSE) streaming (`Accept: text/event-stream`), allowing real-time token rendering in the UI.
- Clean JSON error catching extracts server error messages seamlessly into the overlay interface.

### C. Voice (Roadmap)
- Planned support for microphone audio capture, Base64 audio stream transmission (`audioBase64` + `audioMimeType`), and Gemini audio understanding.

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
