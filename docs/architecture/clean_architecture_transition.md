# Clean Architecture Transition

## Goal

Provide a controlled path from the current feature-grouped prototype architecture toward a proper clean architecture model, without forcing an immediate wholesale rewrite.

## Current Architecture Gaps

### Frontend gaps

- providers instantiate concrete services directly
- widgets contain orchestration logic
- DTOs and domain objects are not separated
- routing, auth gating, and transport concerns are mixed into app shell logic

### Backend gaps

- routes/controllers/sockets access models directly
- no repository layer
- no service layer consistency
- no domain-level use-case boundary

## Transition Principles

1. stabilize the repository structure first
2. introduce abstractions only where real change pressure exists
3. convert highest-risk vertical slices before low-risk demo surfaces
4. avoid speculative architecture in currently static screens

## Domain Layer Strategy

### Frontend

Introduce domain concepts for business-critical features first:

- authenticated user/session
- SOS incident
- cybercrime report
- emergency contact
- medical profile

These domain entities should represent business meaning, not transport payload shape.

### Backend

Backend domain logic should move toward service/use-case ownership for:

- auth operations
- incident lifecycle
- report workflow
- evidence handling

## Repository Strategy

### Frontend repositories

Purpose:

- hide HTTP/socket/storage details from UI state
- stabilize feature interfaces during backend change

Priority repositories:

- auth
- SOS
- cybercrime
- profile

### Backend repositories

Purpose:

- hide Mongoose access patterns
- centralize query semantics and indexing assumptions

Priority repositories:

- user
- SOS incident
- cybercrime report

## Use-Case / Interactor Strategy

Use cases should be introduced after repositories, not before them.

### Candidate frontend use cases

- login user
- restore session
- trigger SOS
- cancel SOS
- submit cybercrime report

### Candidate backend use cases

- register user
- authenticate user
- create incident
- append incident tracking point
- resolve incident
- create cybercrime report

## Dependency Inversion Strategy

### Current direction

presentation depends on concrete infrastructure

### Target direction

- presentation depends on domain abstractions
- repositories adapt infrastructure to domain expectations
- use cases orchestrate business actions
- infrastructure becomes replaceable behind interfaces

## Testing Strategy During Transition

### Current issue

Tests are weak and not aligned to architecture.

### Transition planning

- keep transport tests near current implementation until repository boundaries land
- add repository contract tests when repositories are introduced
- add use-case tests only after use-case layer is stable
- avoid building broad brittle test suites on unstable abstractions

## Recommended Adoption Order

### Phase A

- auth vertical slice
- SOS vertical slice

### Phase B

- cybercrime and profile

### Phase C

- medical vault and trusted contacts

### Phase D

- map intelligence and AI workflows

## What Not to Do

- do not force every feature into domain/data/presentation folders on day one
- do not introduce interfaces for purely static prototype screens yet
- do not split backend into microservices before monolith boundaries are clean

## End-State Outcome

The target clean architecture should produce:

- clearer feature boundaries
- easier testability
- safer backend/frontend contract evolution
- lower blast radius when security and realtime internals change
