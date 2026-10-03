# Implementation Plan - Google Sign-In Fix & Organization Registration Flow

This plan outlines the steps to fix Google Sign-In on physical Android devices and implement a multi-tenant Organization Registration and Sign-Up flow on both the Spring Boot backend (`clibobe`) and Flutter frontend (`clibofe`).

## User Review Required

> [!IMPORTANT]
> **Google Sign-In SHA-1 Requirement**: For Google Sign-In to work on physical Android devices, your PC's debug keystore SHA-1 fingerprint must be registered in your Firebase Console project settings.

## Open Questions
- Should organization registration be tied directly to Google Sign-In domain matching (e.g., auto-joining based on `@company.com`), or a dedicated sign-up screen? (We propose a dedicated Organization Sign-Up form during onboarding).

## Proposed Changes

### Backend (`clibobe`)

#### [MODIFY] [OrganizationRepository.java](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/repository/OrganizationRepository.java)
- Add data access methods for finding and saving organizations.

#### [NEW] [OrganizationController.java](file:///C:/Users/Clayt/Documents/Development/Clibo/clibobe/src/main/java/com/claybytes/clibobe/controller/OrganizationController.java)
- Create endpoints for registering new organizations (`POST /api/v1/organizations/register`) and fetching organization details.

### Frontend (`clibofe`)

#### [MODIFY] [auth_repository_remote.dart](file:///C:/Users/Clayt/Documents/Development/Clibo/clibofe/lib/data/repositories/auth/auth_repository_remote.dart)
- Enhance Google Sign-In error handling and logging to diagnose platform sign-in exceptions (e.g., SHA-1 / configuration issues).
- Add organization registration method `registerOrganization(...)`.

#### [NEW] [register_organization_screen.dart](file:///C:/Users/Clayt/Documents/Development/Clibo/clibofe/lib/features/companion/presentation/screens/register_organization_screen.dart)
- Build a company account sign-up screen where admins can input organization name, domain, and plan tier.

## Verification Plan

### Automated Tests
- Backend unit tests for organization registration and Google auth endpoints.
### Manual Verification
- Deploy backend and test Google Sign-In on physical USB-connected device.
- Test organization registration flow from the Flutter app.
