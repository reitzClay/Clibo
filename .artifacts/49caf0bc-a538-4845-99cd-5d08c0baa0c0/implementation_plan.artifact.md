# Implementation Plan - Terms of Service, Privacy Policy & Consent Logging System

This plan outlines the implementation of legal compliance features for Clibo (operated by **ClayBytes**), including persistent consent logging on the backend, clickable legal links, policy viewing screens, and an actionable consent modal on login/sign-up.

## User Review Required

> [!IMPORTANT]
> **Legal Policy Content**: The Terms of Service and Privacy Policy will be structured for **ClayBytes**, covering Google Authentication, encrypted local storage, multi-tenant organization workspaces, and database chat history auditing for compliance.

## Proposed Changes

### Backend (`clibobe`)

#### [NEW] [UserConsent.java](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/entity/UserConsent.java)
- Entity for recording user consent timestamp, IP address, user ID, and policy version (`v1.0`).

#### [NEW] [UserConsentRepository.java](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/repository/UserConsentRepository.java)
- Spring Data JPA repository for persisting user consents.

#### [NEW] [ConsentController.java](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/controller/ConsentController.java)
- REST endpoint (`POST /api/v1/auth/consent`) to log user acceptance of ToS and Privacy Policy.

### Frontend (`clibofe`)

#### [NEW] [terms_of_service_screen.dart](file:///C:/Users/Clayt/Documents/Development/Clibo/clibofe/lib/features/companion/presentation/screens/terms_of_service_screen.dart)
- Full-screen document viewer for ClayBytes / Clibo Terms of Service.

#### [NEW] [privacy_policy_screen.dart](file:///C:/Users/Clayt/Documents/Development/Clibo/clibofe/lib/features/companion/presentation/screens/privacy_policy_screen.dart)
- Full-screen document viewer for ClayBytes / Clibo Privacy Policy.

#### [MODIFY] [login_screen.dart](file:///C:/Users/Clayt/Documents/Development/Clibo/clibofe/lib/features/companion/presentation/screens/login_screen.dart)
- Update footer text with clickable spans or links for Terms of Service and Privacy Policy.
- Show actionable consent confirmation dialog upon sign-in/registration and log consent to backend.

## Verification Plan

### Automated Tests
- Backend unit tests for consent controller and repository.
### Manual Verification
- Test clicking ToS and Privacy Policy links on the login screen.
- Verify consent logging in PostgreSQL database.
