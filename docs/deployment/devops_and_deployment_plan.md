# DevOps and Deployment Plan

## Goal

Prepare Suraksha for a repeatable delivery pipeline and production operations model without prematurely introducing complex infrastructure before the codebase structure is ready.

## Current State

Current gaps include:

- no Docker strategy
- no compose-based local orchestration
- no CI/CD workflow
- no environment template files
- no structured observability stack
- no deployment manifests

## Deployment Topology Planning

### Short-term target

- one mobile app artifact pipeline
- one backend API artifact pipeline
- one realtime deployment unit, initially colocated with backend if needed

### Mid-term target

- API gateway runtime isolated
- realtime runtime isolated
- async workers isolated

## Docker Strategy

### Planned containers

- backend API container
- realtime container or combined gateway/realtime image during transitional phases
- MongoDB only for local/dev composition if needed
- Redis for later realtime scaling phases

### Docker planning principles

- keep images environment-agnostic
- inject environment config at runtime
- use multi-stage builds where appropriate
- keep local dev and CI images aligned

## Docker Compose Planning

### Purpose

Compose should support local integration testing and staging-like developer setup.

### Planned services

- api
- realtime
- mongo
- redis in later phases
- optional observability sidecars in non-production environments

## CI/CD Planning

### Current need

Introduce quality gates before deployment automation becomes sophisticated.

### Planned CI stages

1. lint and static analysis
2. Flutter tests
3. backend tests
4. contract/schema validation when introduced
5. build verification

### Planned CD stages

- staging deployment on protected branch
- production deployment on tagged release or approved release workflow

## GitHub Actions Planning

### Candidate workflows

- `frontend-verify.yml`
- `backend-verify.yml`
- `integration-verify.yml`
- `staging-deploy.yml`
- `production-deploy.yml`

### Planned responsibilities

- dependency caching
- test execution
- build artifact generation
- environment-specific deployment steps

## Environment Strategy

### Target environments

- local
- development
- staging
- production

### Configuration planning

- environment-specific frontend endpoints
- backend env validation
- separate secret sources per environment
- staging mirrors production routing and auth expectations as closely as practical

## Staging vs Production Planning

### Staging

- feature validation
- integration testing
- non-production secrets
- synthetic or scrubbed data where possible

### Production

- hardened security settings
- stronger logging and alert thresholds
- audited secrets flow
- operational dashboards

## Observability Stack Planning

### Metrics

- API latency
- error rates
- auth failures
- SOS trigger volumes
- socket connection counts
- AI usage metrics

### Logging

- structured JSON logs
- correlation IDs
- incident lifecycle logs
- security event logs

### Tracing

- request-level tracing across auth, incident, and report workflows
- future distributed traces when backend split grows

## Monitoring Planning

### Required signals

- service uptime
- database connectivity
- socket health
- queue health
- rate-limit breaches
- failed incident notifications

### Alerting classes

- critical incident pipeline failure
- auth failure spike
- AI backend degradation
- high socket disconnect rate

## Crash Reporting Planning

### Mobile

- app crash reporting
- unhandled exception reporting
- feature-specific breadcrumbing around SOS flows

### Backend

- runtime exception capture
- deploy change correlation
- worker failure visibility

## Scaling Strategy

### Phase 1

- single-node services with basic automation

### Phase 2

- Redis-backed socket scaling
- separated workers for async processing

### Phase 3

- container orchestration and autoscaling policies where justified

## Operational Readiness Planning

### Documentation targets

- environment bootstrap docs
- deploy checklist
- rollback checklist
- incident response checklist
- production access policy

## DevOps Implementation Sequence

1. repository structure stabilization
2. CI verification workflows
3. containerization and local compose
4. staging environment
5. production deployment automation
6. observability and alerting maturity

## Target Outcome

Suraksha should evolve toward a deployment model where:

- builds are reproducible
- environments are isolated
- deployments are scripted and reversible
- incidents are observable
- scaling paths are pre-planned rather than improvised
