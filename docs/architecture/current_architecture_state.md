# Current Architecture State

## Executive Summary

The current Suraksha repository is a single-project prototype repo with a Flutter application at the root and a Node.js backend nested under `server/`. This is workable for early iteration, but it creates structural ambiguity as the system grows because product layers, platform assets, backend runtime, generated artifacts, and documentation all coexist at the same repository level.

The present codebase is best characterized as:

- a root-hosted Flutter app
- a nested backend service
- no formal shared-contract layer
- no infrastructure layer
- no environment separation strategy
- no CI/CD or deployment packaging boundary

This is not yet unsafe from a code execution perspective, but it is risky from a long-term maintainability and scaling perspective.

## Current Top-Level Structure

```text
suraksha_women_safety_app/
├── lib/
├── test/
├── assets/
├── android/
├── ios/
├── web/
├── linux/
├── macos/
├── windows/
├── server/
├── build/
├── .dart_tool/
├── pubspec.yaml
├── pubspec.lock
├── README.md
└── audit and planning markdown files
```

## Current Frontend Structure

```text
lib/
├── main.dart
├── constants/
├── core/network/
├── features/
│   ├── ai_assistant/
│   ├── auth/
│   ├── cybercrime/
│   ├── dashboard/
│   ├── maps/
│   ├── medical/
│   ├── posh/
│   ├── profile/
│   └── sos/
├── models/
├── theme/
└── widgets/
```

### Frontend observations

- feature grouping exists and is readable
- runtime orchestration is still concentrated in widgets and providers
- root Flutter platform folders live beside backend code rather than under a frontend boundary
- generated/build artifacts are mixed into the same repository root as source

## Current Backend Structure

```text
server/
├── server.js
├── package.json
├── controllers/
├── middleware/
├── models/
├── routes/
├── sockets/
├── test/
├── config/
├── database/
├── services/
├── uploads/
└── utils/
```

### Backend observations

- backend already hints at a future layered structure
- several future-oriented directories are empty placeholders
- only auth, cybercrime, and SOS socket flows are materially implemented
- backend dependency installation and runtime are not isolated from future infrastructure concerns

## Runtime Coupling Map

### Frontend to backend coupling

Current coupling points are direct and string-based:

- `ApiConstants.baseUrl = http://localhost:5000/api`
- `ApiConstants.socketUrl = http://localhost:5000`
- REST endpoints are hardcoded in Dart
- socket event names are hardcoded in Dart and Node
- no shared API contract package exists

### Frontend to external vendor coupling

- mobile client is designed to call Gemini directly
- Google Maps is used directly in UI layer
- mobile platform permissions are assumed by code but not fully reflected in platform config

### Backend to database coupling

- Mongoose models are used directly from routes/controllers/sockets
- no repository abstraction or domain service boundary exists

## Shared Assumptions and Hidden Contracts

The system currently relies on several hidden assumptions that are not formalized:

- frontend and backend both assume localhost development topology
- frontend expects socket event `join_sos`, but backend does not handle it
- frontend expects auth state to decide app shell, but current bypass disables that contract
- frontend declares endpoints for SOS REST APIs that backend does not expose
- README describes capabilities that are broader than the implemented API surface

## Unsafe Architectural Overlaps

### 1. Repository root acts as both app root and system root

The root currently represents:

- Flutter package root
- future mono-repo root
- documentation root
- backend parent directory

This becomes problematic once:

- multiple apps or services are introduced
- infra automation is added
- shared packages need versioning

### 2. Build tooling boundaries are not isolated

- Flutter build outputs live at root
- backend dependencies live under `server/node_modules`
- future CI and caching strategies will be harder without clearer workspace boundaries

### 3. Contract definitions are implicit

- no shared schema or event-contract folder exists
- API payloads are redefined by hand on each side
- socket events are string literals in both runtimes

### 4. Operations concerns have no home

There is currently no dedicated location for:

- Docker assets
- deployment manifests
- nginx / ingress configs
- monitoring configs
- environment templates

## Current Coupling Risks

| Risk | Current State | Impact |
| --- | --- | --- |
| Hardcoded frontend URLs | present | weak environment portability |
| Shared event strings without contracts | present | socket drift and silent breakage |
| No formal frontend/backend boundary | present | unclear migration path as repo scales |
| Root-level Flutter ownership of repo | present | hard to add shared packages or infra cleanly |
| Empty backend placeholder folders | present | false sense of architecture maturity |
| No shared schema layer | present | duplicated DTO/event assumptions |

## Safe Separation Principles

The migration should be planned around these constraints:

1. keep the current Flutter app buildable during transition
2. keep the current backend runnable during transition
3. avoid immediate path-breaking moves to platform folders until commands are re-documented
4. introduce new root boundaries before moving implementation code
5. separate source ownership from generated artifacts and vendor dependencies

## What the Current Repo Is Ready For

- documentation-first monorepo planning
- introduction of dedicated `frontend/`, `backend/`, `docs/`, `infrastructure/`, `shared/`, and `scripts/` roots
- staged relocation of source trees
- future workspace-style separation without immediate business-logic rewrites

## What It Is Not Ready For Yet

- multi-service runtime orchestration
- independent deployable environments
- shared-contract-driven integration
- production operations automation

## Current-State Conclusion

The existing structure is still acceptable for a prototype, but it is not a safe long-term repository shape for a startup-grade, security-sensitive, multi-surface safety platform. The next move should be structural separation planning, not feature expansion. That separation should preserve current run paths while establishing clear long-term homes for frontend, backend, shared contracts, infrastructure, and documentation.
