# Backend Migration Plan

## Goal

Safely evolve the current nested Express backend into a production-grade backend boundary that supports:

- API gateway separation
- service layering
- validation and error discipline
- config isolation
- realtime separation
- worker/queue growth

without rewriting current business logic during the planning phase.

## Current State

The backend currently lives under `server/` and combines:

- Express bootstrap
- Socket.IO bootstrap
- MongoDB connection
- auth route/controller logic
- cybercrime route logic
- realtime SOS handlers

This is compact and workable, but too centralized for long-term evolution.

## Target Backend Layout

```text
backend/
├── api_gateway/
│   ├── src/
│   │   ├── app/
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── modules/
│   │   ├── repositories/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── validators/
│   │   └── utils/
│   ├── tests/
│   ├── docs/
│   └── package.json
├── realtime/
├── services/
├── workers/
├── uploads/
└── tests/
```

## Express Restructuring Plan

### Current issue

`server.js` is both:

- composition root
- runtime bootstrap
- database bootstrap
- route registration point
- socket bootstrap origin

### Planned structure

- `app/` for app composition
- `config/` for validated environment loading
- `routes/` for transport mapping only
- `controllers/` for request orchestration only
- `services/` for business operations
- `repositories/` for persistence access
- `validators/` for request schema enforcement

## Service Layer Planning

### Current gap

- business logic lives in routes, controller, and socket handlers

### Target

Service boundaries should eventually include:

- `AuthService`
- `CyberCrimeService`
- `SOSService`
- `ProfileService`
- `MedicalService`
- `EvidenceService`
- `NotificationService`

### Safe migration rule

Do not move every route at once. Stabilize services in this order:

1. auth
2. SOS
3. cybercrime

## Repository Layer Planning

### Current gap

Mongoose models are accessed directly from:

- routes
- controllers
- sockets

### Target repositories

- `UserRepository`
- `SOSEventRepository`
- `CyberCrimeReportRepository`

### Purpose

Repositories provide:

- index-aware query composition
- persistence boundary for tests
- easier future data-model evolution

## Socket Isolation Planning

### Current issue

Socket.IO logic is bootstrapped through the API server and writes directly to models.

### Target direction

- isolate realtime contracts and handlers under `backend/realtime`
- allow the realtime subsystem to remain logically distinct even if still deployed with the API in early phases
- prepare for Redis adapter and multi-node scaling later

## API Versioning Strategy

### Current state

- routes are mounted under `/api/*`

### Target state

- introduce `/api/v1/*`
- keep versioning at gateway boundary
- version transport contracts, not just implementation folders

### Migration rule

Versioning should be introduced before broadening public API surface.

## Middleware Architecture Planning

### Current state

- auth middleware exists
- no validation, correlation, rate limiting, or central error middleware

### Target middleware stack

- request ID / correlation
- security headers
- CORS by environment
- body size controls
- auth middleware
- authorization middleware
- validation middleware
- rate limiting
- centralized error serializer

## Validation Architecture Planning

### Current issue

- payloads are effectively trusted

### Target

Each module should define transport-level validation schemas for:

- request body
- params
- query
- socket event payloads

### Strategy

Validation should sit at the edge, before controller/service execution.

## Error Handling Architecture

### Current issue

- each route handles errors ad hoc
- raw exception messages are exposed

### Target

- one centralized operational error model
- transport-safe error responses
- domain error mapping in services
- consistent incident logging

## Config and Environment Management

### Current state

- `dotenv` is loaded
- environment validation is absent
- fallback secrets and localhost defaults are present

### Target

- validated config module
- explicit required env variables
- environment files/templates per stage
- no insecure secret fallbacks

## Logging Architecture Planning

### Current state

- console logging only

### Target

- structured JSON logs
- request correlation IDs
- severity-aware logging
- audit-specific incident logs for SOS and security actions

## Worker and Queue Planning

### Why it is needed

The platform will soon need async execution for:

- notifications
- evidence processing
- AI proxy and moderation
- responder fan-out
- analytics projection

### Target shape

`backend/workers` should eventually own:

- queue consumers
- retry policies
- dead-letter workflows
- scheduled maintenance jobs

## Safe Backend Migration Sequence

1. introduce backend root boundary in documentation and folder planning
2. separate API gateway from realtime conceptually
3. introduce config validation and middleware architecture
4. add repositories and services in highest-risk modules first
5. move async concerns into worker planning before implementation

## Backend Migration Outcome

At the end of the backend migration journey, Suraksha should have:

- a dedicated backend root
- versioned API gateway boundaries
- service/repository layering
- validated inputs
- centralized error/logging patterns
- isolated realtime subsystem
- clear future path for workers and integrations
