# Frontend Migration Plan

## Goal

Safely evolve the current root-level Flutter app into an isolated frontend boundary inside a monorepo-style repository, while preserving developer workflow and avoiding immediate business-logic rewrites.

## Current State

The Flutter app currently owns:

- `lib/`
- `test/`
- `assets/`
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`
- `pubspec.yaml`
- `analysis_options.yaml`

This is a valid Flutter package layout, but it currently doubles as the root of the entire system repository.

## Target Frontend Layout

```text
frontend/
├── mobile_app/
│   ├── lib/
│   ├── test/
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── linux/
│   ├── macos/
│   ├── windows/
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── shared_ui/
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
├── assets/
└── docs/
```

## Safe Migration Strategy

### Stage 1: Introduce frontend boundary logically

- define `frontend/mobile_app` as the future canonical Flutter application root
- keep current Flutter app at root until scripts and docs are ready
- document which files will eventually move together as one unit

### Stage 2: Extract support boundaries before moving code

- identify shared widgets, theme tokens, reusable cards, and form controls
- define `frontend/shared_ui` as future package boundary
- define root-level asset ownership strategy so assets are not duplicated during migration

### Stage 3: Move the Flutter package as a unit

- move all platform folders and Flutter package files together
- do not split `lib/` away from platform folders in an intermediate state
- preserve package identity and asset resolution during the move

### Stage 4: Clean up imports and docs only after path stability

- update documentation, scripts, and CI assumptions after the move
- avoid business logic changes during relocation phase

## Feature Module Restructuring Plan

Current feature structure is readable, but internal layering is shallow.

### Current shape

```text
features/
├── auth/
├── sos/
├── maps/
├── medical/
├── cybercrime/
├── profile/
├── posh/
└── ai_assistant/
```

### Target internal pattern

Each mature feature should eventually evolve toward:

```text
features/<feature>/
├── data/
│   ├── datasources/
│   ├── dto/
│   ├── repositories/
│   └── services/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── providers/
    ├── screens/
    ├── widgets/
    └── state/
```

### Transition rule

Do not force all features into this shape at once. Start with:

- auth
- SOS
- cybercrime
- profile

These are the highest-value features for architectural stabilization.

## Riverpod Restructuring Plan

### Current state

- providers instantiate concrete dependencies directly
- provider scope is global but shallow
- there is no bootstrapping or environment-aware composition layer

### Target state

- app-level provider composition boundary
- repository providers separated from presentation state providers
- lifecycle-specific providers for auth bootstrap, permissions, connectivity, and session state
- test-friendly override strategy

### Migration path

1. introduce app-level provider composition conventions
2. split transport dependencies from UI-facing providers
3. introduce repository providers before use-case providers
4. add feature-scoped provider organization later

## Repository Layer Planning

The frontend currently talks directly to:

- `DioClient`
- Gemini API service
- Socket.IO client

### Planned repository boundaries

- `AuthRepository`
- `SOSRepository`
- `CyberCrimeRepository`
- `ProfileRepository`
- `MedicalVaultRepository`
- `AIRepository`

Repositories should hide:

- endpoint strings
- transport-specific DTOs
- socket event details
- storage details

## Clean Architecture Migration Strategy

### Current gap

- widgets and providers know too much about transport details
- DTOs are effectively domain models
- no use-case boundary exists

### Planned direction

- stabilize vertical slice boundaries first
- create domain entities where business meaning matters
- add use cases for critical flows only after repositories exist
- avoid premature abstraction for purely static prototype screens

## Route Architecture Planning

### Current state

- `Navigator.push`
- `MaterialApp`
- no auth guards
- `go_router` dependency unused

### Target state

- `MaterialApp.router`
- central route registry
- auth-aware redirects
- future deep-link support for notifications and incident workflows

### Safe migration rule

Adopt router architecture after app relocation or in parallel with shell stabilization, but before major feature growth.

## Environment and Flavor Planning

### Current state

- hardcoded localhost endpoints
- no flavor isolation

### Target state

- development, staging, production flavors
- environment-bound API and socket URLs
- environment-aware feature flags and logging

### Planned artifacts

- frontend environment config abstraction
- flavor docs under `frontend/docs/platform_setup`

## Asset Management Planning

### Current state

- root `assets/` directory exists
- asset folders are empty today

### Target state

- `frontend/assets` becomes the canonical source
- assets grouped by domain and resolution strategy
- naming standards and usage guidance documented

## Shared Widget Library Planning

### Current state

- only one clear reusable widget exists
- repeated visual patterns are embedded in screens

### Target state

`frontend/shared_ui` should eventually own:

- design tokens
- cards
- buttons
- forms
- badges
- modal shells
- emergency status components

### Migration rule

Extract only after patterns stabilize across at least two features.

## Frontend Migration Risks

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| Moving Flutter package too early | can break platform tooling paths | move app as a full package unit |
| Extracting shared UI too early | may fossilize unstable patterns | extract only repeated, stable components |
| Adding too many abstractions at once | can stall delivery | phase repositories before use cases |
| Route migration during unstable auth | can create compounding failures | stabilize auth shell before full route guards |

## Frontend Migration Outcome

At the end of the frontend migration journey, Suraksha should have:

- an isolated mobile app package
- a reusable shared UI boundary
- environment-aware configuration
- router-based app shell
- repository-driven feature integration
- clean future path toward proper domain layering
