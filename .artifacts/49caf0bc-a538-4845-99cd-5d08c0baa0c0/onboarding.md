# Clibo Project Onboarding Guide

Welcome to **Clibo** — an advanced AI-powered assistant and companion ecosystem featuring a robust Spring Boot backend (`clibobe`) and a feature-rich Flutter client application (`clibofe`).

This document serves as the comprehensive onboarding guide for developers, covering project architecture, build configurations, dependency management, environment setup, and local development workflows.

---

## 1. Project Overview & Repository Structure

Clibo is organized as a monorepo containing two main subsystems:
```
Clibo/
├── clibobe/                  # Spring Boot Backend (Java 21)
├── clibofe/                  # Flutter Frontend Application (Dart ^3.11.1)
├── docs/                     # Project Documentation (including this onboarding guide)
├── docker-compose.yml        # Local orchestration (PostgreSQL, Backend, Ollama)
└── README.md
```

---

## 2. Backend: `clibobe` (Spring Boot)

The backend is built with **Spring Boot** (version `4.1.1`) running on **Java 21**. It acts as the orchestration and proxy layer for AI models (Google Gemini, Ollama), user management, authentication, and usage guardrails.

### Key Build & Configuration Files
- **[pom.xml](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/pom.xml)**: Maven configuration file defining core dependencies:
  - `spring-boot-starter-data-jpa` & PostgreSQL / H2 database drivers.
  - `spring-boot-starter-webflux` & `spring-boot-starter-webclient` for reactive HTTP and proxy calls.
  - `firebase-admin` (v9.2.0) for server-side Firebase authentication verification.
  - `google-genai` (v1.73.0) for interacting with Google's Gemini models.
  - Lombok for boilerplate reduction.
  - Testcontainers (`spring-boot-testcontainers`, `testcontainers-postgresql`) for robust integration testing.
- **[docker-compose.yml](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/docker-compose.yml)**: Defines containerized services for local development:
  - `postgres-db`: PostgreSQL 16 container (`clibo_db`, user: `clibo_user`, pass: `clibo_pass`, port `5432`).
  - `spring-backend`: Builds and runs the Spring Boot application on port `8080`.
  - `ollama`: Local Ollama instance (`ollama/ollama:latest`) on port `11434` for zero-token local AI development and testing.

### Key Backend Components (`src/main/java/com/claybytes/clibobe/`)
- **Controllers**:
  - [`AuthController.java`](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/controller/AuthController.java): Handles user authentication flows.
  - [`GeminiProxyController.java`](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/controller/GeminiProxyController.java): Proxies requests to Gemini / AI providers with streaming and prompt management.
  - [`UserController.java`](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/controller/UserController.java): Manages user profiles and metadata.
- **Services**:
  - [`UsageGuardrailService.java`](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/service/UsageGuardrailService.java): Enforces usage limits and guardrails.
  - `FirebaseAuthService.java`, `GoogleAuthService.java`: Authentication integrations.
- **Entities**:
  - `User`, `ChatSession`, `ChatMessage`, `Organization`, `UserUsage`, `ModalityType`.

---

## 3. Frontend: `clibofe` (Flutter)

The frontend is a cross-platform Flutter application supporting mobile, desktop, and overlay capabilities.

### Key Build & Configuration Files
- **[pubspec.yaml](file:///C:/Users/Clayt/Documents/Development/Clibo/clibofe/pubspec.yaml)**: Flutter package configuration:
  - **State Management & DI**: `get_it` (v9.2.1) for dependency injection.
  - **UI & Design**: `shadcn_ui` (v0.56.3) for modern shadcn-style components, `lucide_icons_flutter`.
  - **Firebase**: `firebase_core`, `firebase_auth`, `cloud_firestore`.
  - **Authentication**: `google_sign_in`.
  - **Networking & Storage**: `http`, `flutter_secure_storage` for securely storing API keys and user configs locally.
  - **System Integrations**: `flutter_overlay_window` for floating overlay widgets and companion features.
- **[analysis_options.yaml](file:///C:/Users/Clayt/Documents/Development/Clibo/clibofe/analysis_options.yaml)**: Dart linting rules (`flutter_lints`).
- **[firebase.json](file:///C:/Users/Clayt/Documents/Development/Clibo/clibofe/firebase.json)**: Firebase project configuration.

### Key Frontend Architecture (`lib/`)
- **[service_locator.dart](file:///C:/Users/Clayt/Documents/Development/Clibo/clibofe/lib/app/service_locator.dart)**: Centralized GetIt service locator setup.
- **Data & Repositories**:
  - Auth repositories (`auth_repository.dart`, `auth_repository_remote.dart`, `auth_repository_dev.dart`).
  - User repositories and configuration services (`config_service.dart`).
- **Domain**:
  - AI provider configurations (`ai_provider_config.dart`) supporting Gemini, Ollama, BYOK (Bring Your Own Key), and custom endpoints.
- **Features (Companion)**:
  - Screens: `home_screen.dart`, `login_screen.dart`, `splash_screen.dart`.
  - Tabs: `config_tab.dart`, `history_tab.dart`, `metrics_tab.dart`.
  - Widgets: Config cards (`ollama_config_card.dart`, `custom_endpoint_card.dart`, `connection_status_card.dart`, `byok_key_input.dart`, `provider_dropdown.dart`), Google sign-in buttons.

---

## 4. Getting Started & Local Development

### Prerequisites
1. **Java 21 JDK** installed.
2. **Maven** (or use bundled Maven wrapper `mvnw` / `mvnw.cmd` in `clibobe`).
3. **Flutter SDK** (`^3.11.1`).
4. **Docker & Docker Compose** (for running PostgreSQL and Ollama locally).

### Step 1: Clone and Environment Setup
Ensure you have cloned the repository and configured any necessary local environment variables (such as Gemini API keys or Google Client IDs) in your environment or `.env` / `docker-compose.yml` overrides.

### Step 2: Running Services via Docker Compose
To spin up PostgreSQL, the backend service, and Ollama:
```bash
docker compose up --build
```
This starts:
- PostgreSQL on port `5432`
- Spring Boot backend on port `8080`
- Ollama LLM container on port `11434`

### Step 3: Running the Backend Manually (Alternative)
Navigate to `clibobe/`:
```bash
cd clibobe
./mvnw spring-boot:run
```

### Step 4: Running the Flutter Frontend
Navigate to `clibofe/`:
```bash
cd clibofe
flutter pub get
flutter run
```

---

## 5. Summary of Architecture & Integrations
- **AI Providers**: Configurable via the frontend UI (`config_tab.dart`) and backend proxy (`GeminiProxyController.java`), allowing seamless switching between Google Gemini cloud models and local Ollama instances.
- **Authentication**: Firebase Auth paired with Google Sign-In on the client side, verified securely via `firebase-admin` on the Spring Boot backend.
- **State & DI**: Clean separation of concerns with GetIt service locator in Flutter and Spring Dependency Injection on the backend.

---

## 6. Troubleshooting & Common Issues

### PostgreSQL Database Schema Missing (`ERROR: schema "public" does not exist`)
If you encounter database errors during startup indicating that the `public` schema or relations like `public.users` do not exist (often occurring when restarting Docker compose with a stale or uninitialized persistent volume):
1. Stop the containers and prune the persistent volume:
   ```bash
   docker compose down -v
   ```
2. Rebuild and restart the stack:
   ```bash
   docker compose up --build
   ```
   This ensures PostgreSQL re-initializes cleanly with the default `public` schema and Hibernate DDL auto-creates the required tables.
