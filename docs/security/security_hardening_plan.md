# Security Hardening Plan

## Goal

Create a security-first stabilization roadmap that hardens the existing prototype into a trustworthy platform without rewriting core product flows in one pass.

## Current Security Pressure Points

- app-level auth bypass
- insecure JWT fallback secret
- client-side AI key strategy
- unauthenticated socket events
- no validation or rate limiting
- incomplete platform permission/privacy configuration
- no upload security design despite evidence-oriented product direction

## Security Workstreams

## 1. Auth Stabilization

### Current issue

- login bypass undermines identity guarantees
- session restoration is incomplete

### Planning goals

- restore real auth-controlled app shell
- define session bootstrap behavior
- separate development shortcuts from production paths

## 2. JWT Hardening

### Current issue

- fallback secret exists
- token lifecycle is simplistic

### Planning goals

- require environment-provided secrets
- define access token and refresh strategy
- define logout/session invalidation behavior
- define issuer/audience and rotation expectations

## 3. Socket Security

### Current issue

- socket identity is client-asserted

### Planning goals

- authenticated handshake
- server-derived actor identity
- role-aware room authorization
- event-level validation and ack discipline

## 4. API Validation and Protection

### Current issue

- payloads are mostly trusted
- no throttling exists

### Planning goals

- request schema validation at transport edge
- route-level rate limiting
- body size limits
- consistent auth/authorization enforcement

## 5. AI Key Protection

### Current issue

- AI secret pattern is client-side

### Planning goals

- move AI invocation behind backend proxy
- isolate vendor secrets server-side
- add rate control and abuse monitoring
- plan response moderation and high-risk escalation

## 6. Upload Security

### Current issue

- upload dependencies exist but no secure pipeline exists

### Planning goals

- define allowed media types
- define file size ceilings
- define malware scanning or content screening approach
- define signed upload / server-mediated upload policy
- define evidence ownership and access rules

## 7. Secrets Management

### Current issue

- environment strategy is informal

### Planning goals

- no secrets committed to repo
- environment-specific secret sources
- documented secret inventory
- secure local-dev bootstrap approach

## 8. Environment Isolation

### Current issue

- localhost assumptions exist in app code and backend defaults

### Planning goals

- development, staging, production separation
- per-environment URLs and policies
- no production fallbacks embedded in code paths

## 9. Rate Limiting and Abuse Control

### Targets

- auth routes
- cybercrime report creation
- SOS trigger abuse
- AI usage
- upload endpoints
- socket connection churn

### Planning goals

- IP-aware throttling
- identity-aware throttling
- special protection for emergency misuse surfaces

## 10. Audit Logging

### Why needed

Safety platforms need traceability.

### Planning goals

- auth event logs
- SOS lifecycle logs
- admin/responder access logs
- evidence access logs
- AI moderation / escalation logs

## Security Sequencing

### Immediate hardening order

1. auth stabilization
2. JWT hardening
3. socket handshake security
4. API validation and rate limiting
5. AI key protection

### Secondary hardening order

1. upload security
2. audit logging
3. environment isolation
4. deeper abuse monitoring

## Security Non-Goals for This Planning Phase

- no full zero-trust rewrite
- no immediate microservice security redesign
- no advanced IAM platform adoption before core auth is stabilized

## Target Outcome

The end-state security posture should provide:

- trustworthy user identity
- protected APIs and sockets
- server-side secrets
- evidence-safe upload design
- audit-ready incident and access traces
- environment-specific controls suitable for staged rollout
