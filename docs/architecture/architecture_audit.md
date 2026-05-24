# Architecture Audit

## Executive Summary

Suraksha presents as a feature-oriented Flutter + Node.js application with an ambitious product scope, but the current implementation is closer to a high-fidelity prototype than a production-grade safety platform. The repository contains a usable visual shell, a minimal authentication backend, a basic Socket.IO SOS channel, and several domain models, but it does not yet implement Clean Architecture in the strict sense claimed by the README.

The strongest architectural trait is that the codebase is already separated into a Flutter frontend and an Express/MongoDB backend with recognizable feature boundaries. The weakest trait is that most cross-cutting concerns are still direct and inline: no repository layer, no use-case layer, no backend service layer, no dependency injection container, no environment abstraction, and no operational boundary between prototyping code and production code.

## System Separation

### Frontend

Authored frontend code lives primarily in `lib/`, with supporting platform configuration under `android/`, `ios/`, `web/`, `linux/`, `macos/`, and `windows/`.

The frontend currently owns:

- UI composition and navigation
- Riverpod state containers
- API and socket client calls
- local token storage
- on-device sensor triggers
- direct Gemini API invocation

### Backend

Authored backend code lives in `server/`.

The backend currently owns:

- Express server bootstrap
- authentication REST API
- cybercrime reporting REST API
- JWT verification middleware
- Mongoose models
- Socket.IO SOS event handling

### Non-authored / Generated Areas

These folders exist but are not core authored architecture:

- `build/`
- `.dart_tool/`
- `server/node_modules/`
- generated Flutter platform registrants

## Frontend Structure

```text
frontend
├── lib
│   ├── main.dart
│   ├── constants
│   │   └── api_constants.dart
│   ├── core
│   │   └── network
│   │       └── dio_client.dart
│   ├── features
│   │   ├── ai_assistant
│   │   │   └── ai_service.dart
│   │   ├── auth
│   │   │   ├── auth_provider.dart
│   │   │   └── login_screen.dart
│   │   ├── cybercrime
│   │   │   └── cybercrime_screen.dart
│   │   ├── dashboard
│   │   │   └── dashboard_screen.dart
│   │   ├── maps
│   │   │   └── safety_map_screen.dart
│   │   ├── medical
│   │   │   └── medical_vault_screen.dart
│   │   ├── posh
│   │   │   └── posh_chat_screen.dart
│   │   ├── profile
│   │   │   └── profile_screen.dart
│   │   └── sos
│   │       ├── emergency_mode_screen.dart
│   │       ├── scream_detection_service.dart
│   │       ├── sensor_service.dart
│   │       └── sos_provider.dart
│   ├── models
│   │   └── user_model.dart
│   ├── theme
│   │   └── app_theme.dart
│   └── widgets
│       └── safety_radar.dart
├── test
│   ├── sos_test.dart
│   └── widget_test.dart
├── android
├── ios
├── web
├── macos
├── linux
└── windows
```

## Backend Structure

```text
backend
├── server
│   ├── server.js
│   ├── package.json
│   ├── controllers
│   │   └── authController.js
│   ├── middleware
│   │   └── authMiddleware.js
│   ├── models
│   │   ├── CyberCrimeReport.js
│   │   ├── SOSEvent.js
│   │   └── User.js
│   ├── routes
│   │   ├── authRoutes.js
│   │   └── cyberCrimeRoutes.js
│   ├── sockets
│   │   └── sosSocket.js
│   ├── test
│   │   └── auth.test.js
│   ├── config
│   ├── database
│   ├── services
│   ├── uploads
│   └── utils
```

## Folder-by-Folder Assessment

### Frontend Folders

#### `lib/main.dart`

- Why it exists: application entry point and top-level app composition.
- Current quality: simple and readable, but routing and session bootstrapping are incomplete.
- Scalability concern: `MaterialApp` with direct `home` switching does not scale to guarded multi-route flows.
- Production concern: login is currently bypassed through `kBypassLogin = true`, which invalidates auth assumptions for downstream modules.

#### `lib/constants`

- Why it exists: central place for endpoint constants.
- Current quality: minimal.
- Scalability concern: hardcoded localhost URLs do not support environments, flavors, or remote device testing.
- Production concern: environment management is not abstracted.

#### `lib/core/network`

- Why it exists: shared HTTP client setup.
- Current quality: good starting point with auth header injection.
- Scalability concern: no retry policy, refresh token strategy, structured error mapping, telemetry, or circuit breaking.
- Production concern: HTTP failures are not normalized into domain-safe states.

#### `lib/features`

- Why it exists: coarse feature-level modularization.
- Current quality: visually organized, but each feature mixes UI, orchestration, and transport concerns.
- Scalability concern: no `data/domain/presentation` layering inside features.
- Production concern: features are mostly UI prototypes, not full vertical slices.

#### `lib/models`

- Why it exists: shared DTO/model types.
- Current quality: acceptable for a small app.
- Scalability concern: one shared model folder becomes brittle as feature count grows.
- Production concern: DTOs are tightly coupled to backend payload shape.

#### `lib/theme`

- Why it exists: centralized look-and-feel.
- Current quality: consistent but small.
- Scalability concern: no semantic tokens, spacing system, typography ramps, or light/dark variants.
- Production concern: theme is not accessibility-tuned.

#### `lib/widgets`

- Why it exists: shared reusable components.
- Current quality: currently contains only `SafetyRadar`.
- Scalability concern: reusable component library is not yet developed.
- Production concern: custom painter runs continuously and is not performance-budgeted.

### Backend Folders

#### `server/server.js`

- Why it exists: runtime bootstrap for Express, Socket.IO, and MongoDB.
- Current quality: functional but monolithic.
- Scalability concern: all bootstrap, configuration, middleware, routing, and realtime setup live in one file.
- Production concern: no graceful shutdown, health checks, metrics, or environment validation.

#### `server/controllers`

- Why it exists: business logic boundary.
- Current quality: only auth uses it.
- Scalability concern: controller pattern is inconsistent because cybercrime routes inline their logic.
- Production concern: service boundaries are absent.

#### `server/middleware`

- Why it exists: shared request pipeline logic.
- Current quality: only auth protection exists.
- Scalability concern: no validation, error middleware, audit logging, rate limiting, or request correlation.
- Production concern: auth middleware trusts a fallback secret and does not guard for missing users cleanly.

#### `server/models`

- Why it exists: MongoDB schema definitions.
- Current quality: enough to model prototype flows.
- Scalability concern: index strategy, timestamps, and growth management are underdeveloped.
- Production concern: SOS tracking arrays can grow without bound and geospatial indexing is absent.

#### `server/routes`

- Why it exists: API surface definition.
- Current quality: easy to read but narrow in scope.
- Scalability concern: route inventory covers only auth and cybercrime, while frontend constants and README imply a much broader API.
- Production concern: response shape consistency and validation are not standardized.

#### `server/sockets`

- Why it exists: realtime event handling.
- Current quality: minimal proof-of-concept.
- Scalability concern: no rooms, no auth, no acknowledgements, no event contracts, no adapter for horizontal scale.
- Production concern: events broadcast to all connected clients rather than authorized parties.

#### `server/config`, `database`, `services`, `utils`, `uploads`

- Why they exist: these suggest intended layering and future operational concerns.
- Current quality: empty placeholders.
- Scalability concern: architectural intent is present, but not implemented.
- Production concern: empty architectural folders can create false confidence during reviews.

## Dependency Flow

### Frontend

Current dependency flow is:

`UI screen -> Riverpod provider or local state -> DioClient / direct service -> REST API or external API`

`UI screen -> Riverpod provider -> Socket.IO client -> backend socket events`

This is not Clean Architecture because:

- screens know concrete services
- providers know transport and persistence details
- there are no repositories or interfaces
- there is no domain layer or use-case layer

### Backend

Current dependency flow is:

`Express route -> controller or inline route logic -> Mongoose model`

`Socket.IO handler -> Mongoose model -> socket broadcast`

This is not a layered service architecture because:

- route handlers own persistence orchestration directly
- there is no service abstraction
- validation is inline or absent
- business rules are not centralized

## Clean Architecture Assessment

### Claimed State

The README claims Flutter Clean Architecture.

### Actual State

The Flutter codebase is feature-grouped, not Clean Architecture. There is no evidence of:

- domain entities separate from transport DTOs
- repository abstractions
- use cases / interactors
- dependency inversion between presentation and data
- environment-aware dependency injection

The backend similarly does not implement a service-oriented or hexagonal architecture. It is a compact Express app with direct model access.

## Separation of Concerns Assessment

### What works

- frontend and backend are physically separated
- feature folders make navigation through the codebase easy
- auth, SOS, cybercrime, map, profile, and AI are conceptually distinct
- backend models are distinct from routes

### What does not

- presentation and integration logic are interwoven in the frontend
- business logic sits in providers, widgets, sockets, and route handlers
- the backend has no unified service layer
- there is no contract or schema package shared across client and server

## Dependency Injection Assessment

- Flutter uses Riverpod for provider creation, which is a good base.
- Actual DI depth is shallow: providers instantiate concrete classes directly.
- Backend has no DI container or composition root beyond direct `require()` calls.

## API Abstraction Assessment

- `DioClient` is the only real shared abstraction in the frontend.
- there are no typed repositories for auth, cybercrime, SOS, map, medical, AI, or profile.
- AI calls bypass backend abstraction entirely.
- Socket contracts are stringly typed and unmanaged.

## Socket Architecture Assessment

The SOS socket implementation is the clearest example of "prototype architecture":

- client emits `join_sos`, but the server does not handle it
- client emits unauthenticated SOS events
- server broadcasts to all clients instead of rooms or responder groups
- location updates are not persisted
- SOS cancellation is not persisted
- no retry, ack, dedupe, replay, or backpressure control exists

## Architectural Strengths

- clear project ambition and product decomposition
- readable small codebase
- good candidate for incremental hardening
- existing Riverpod and Mongoose baselines reduce migration cost

## Architectural Weaknesses

- claimed architecture is materially ahead of implemented architecture
- feature completeness is uneven
- core safety workflows are not end-to-end hardened
- environment, security, and observability concerns are largely absent

## Overall Architecture Verdict

Suraksha is structurally positioned as a vertical-slice prototype with partial backend support, not a production-ready cleanly layered platform. The next major milestone should not be feature expansion first; it should be stabilization of architecture boundaries, platform permissions, API coverage, and security fundamentals.

## Architecture Scores

| Category | Score | Notes |
| --- | --- | --- |
| Frontend structure | 5/10 | Feature-grouped and readable, but not layered |
| Backend structure | 4/10 | Minimal Express app with only partial modularity |
| Clean Architecture adherence | 2/10 | Claimed, but not implemented in practice |
| Separation of concerns | 4/10 | Better folder separation than runtime separation |
| Scalability readiness | 3/10 | Prototype flow, limited operational scaffolding |
| Production architecture readiness | 2/10 | Major blockers across auth, sockets, AI, and ops |
