# Task List - Multi-Modal Vision & Image Attachment (Phase 3)

- `[x]` Build multi-modal image payload pipeline (`imageBase64` + `imageMimeType`) in `BackendProxyAIClient` and Spring Boot `GeminiAiService.java`
- `[x]` Verify Google Gemini Cloud AI visual analysis responses for multi-modal text and visual prompts (`gemini-3.5-flash-lite`)
- `[x]` Verify database audit logging (`screenshots_used` increment in PostgreSQL `user_usages` table and `chat_messages` table)
- `[x]` Update Android 14+ / targetSDK 36 Foreground Service declarations (`foregroundServiceType="specialUse"`) in `AndroidManifest.xml`
- `[x]` Document Flutter overlay isolate boundaries (`OverlayService` runs in background service isolate requiring `ActivityBinding` bridging for plugins)
- `[x]` Integrated manual screenshot & image attachment workflow (`image_picker`) allowing users to attach screenshots directly in overlay chat
- `[x]` Multi-provider chat testing & 100% success rate on Google AI Studio
- `[x]` Streamlined login screen & contextual Config Tab redesign
