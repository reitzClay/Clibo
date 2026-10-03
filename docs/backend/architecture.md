# Clibo Backend Architecture (`clibobe`)

## 1. Overview & Purpose

The **Clibo Backend (`clibobe`)** is a robust enterprise-grade service built with **Spring Boot 4.1.1** and **Java 21**. It serves as the secure orchestration gateway between the Clibo Flutter frontend and AI providers (Google Gemini, local Ollama), managing user authentication, quota enforcement, chat session history, and usage guardrails.

---

## 2. System Architecture (Mermaid Diagram)

```mermaid
graph TD
    subgraph Frontend [Flutter Client - clibofe]
        UI[App UI / Floating Overlay]
        Client[BackendProxyAIClient]
    end

    subgraph Backend [Spring Boot Backend - clibobe]
        AuthController[AuthController]
        ProxyController[GeminiProxyController]
        Guardrail[UsageGuardrailService]
        FirebaseAuth[FirebaseAuthService / TokenVerifier]
    end

    subgraph External [External Services & DB]
        Firebase[(Firebase Auth)]
        Gemini[Google GenAI SDK / Gemini API]
        Ollama[Local Ollama LLM Container]
        Postgres[(PostgreSQL Database)]
    end

    UI -->|Google Sign-In Token| AuthController
    AuthController -->|Verify ID Token| Firebase
    
    Client -->|HTTP POST / SSE /ai/chat| ProxyController
    ProxyController -->|Verify Bearer Token| FirebaseAuth
    ProxyController -->|Check Quota & Limits| Guardrail
    Guardrail -->|Persist Usage Stats| Postgres
    
    ProxyController -->|Prompt + Images/Audio| Gemini
    ProxyController -->|Fallback / Local AI| Ollama
    
    ProxyController -->|Stream SSE Chunks| Client
```

---

## 3. Core Request Flow & Sequence

```mermaid
sequenceDiagram
    participant Client as Flutter App (clibofe)
    participant Proxy as GeminiProxyController
    participant Guard as UsageGuardrailService
    participant AI as Google GenAI / Ollama
    participant DB as PostgreSQL

    Client->>Proxy: POST /api/v1/ai/chat (Prompt, Image/Audio, Bearer Token)
    Proxy->>Guard: Check usage limits & guardrails for user
    Guard->>DB: Query user usage quota
    DB-->>Guard: Usage stats valid
    Guard-->>Proxy: Approval granted
    
    Proxy->>AI: Send multi-modal request (Text + Visuals + Voice)
    AI-->>Proxy: Stream response chunks (SSE)
    
    loop Streaming Chunks
        Proxy-->>Client: data: {"text": "chunk..."}
    end
    
    Proxy->>DB: Increment user message count & token usage
    Proxy-->>Client: Stream completed [DONE]
```

---

## 4. Package Structure & Components (`src/main/java/com/claybytes/clibobe/`)

```
clibobe/src/main/java/com/claybytes/clibobe/
├── ClibobeApplication.java
├── config/
│   ├── GeminiConfig.java         # Google GenAI configuration
│   └── GoogleAuthConfig.java     # Google Auth configuration
├── controller/
│   ├── AuthController.java       # User authentication & token exchange
│   ├── GeminiProxyController.java # Multi-modal AI proxy & SSE streaming endpoint
│   └── UserController.java       # User profile and settings management
├── dto/
│   ├── AiPromptRequest.java      # Incoming request DTO (prompt, base64 media)
│   ├── GeminiRequest.java
│   └── Part.java                 # Multi-modal content parts
├── entity/
│   ├── ChatMessage.java          # Individual chat messages in session
│   ├── ChatSession.java          # Grouped conversation threads
│   ├── ModalityType.java         # Enum for text, image, audio modalities
│   ├── Organization.java         # Multi-tenant organization grouping
│   ├── User.java                 # User account entity
│   └── UserUsage.java            # Usage tracking and guardrail quotas
├── repository/
│   ├── OrganizationRepository.java
│   ├── UserRepository.java
│   └── UserUsageRepository.java
├── service/
│   ├── FirebaseAuthService.java  # Firebase Admin token verification
│   ├── TokenVerifier.java
│   ├── UsageGuardrailService.java# Quota checking & rate limiting logic
│   └── UserService.java
└── utilityService/
    └── GoogleAuthService.java
```

---

## 5. Key Services & Security

- **Authentication**: Stateless token validation using `FirebaseAuthService` verifying incoming Firebase JWTs against Firebase Admin SDK.
- **AI Proxying**: `GeminiProxyController` handles multipart multimodal payloads (text prompts, Base64 screen capture images, and audio notes) and streams responses back to clients via Server-Sent Events (SSE).
- **Guardrails**: `UsageGuardrailService` tracks request volume, token counts, and feature limits per user to prevent abuse and manage API costs.
- **Database Persistence**: Spring Data JPA with PostgreSQL for relational storage of users, organizations, chat history, and usage metrics.
