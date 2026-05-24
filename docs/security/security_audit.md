# Security Audit

## Executive Summary

Suraksha currently has several security fundamentals in place, such as password hashing, JWT-based auth, and `helmet`, but the implementation contains multiple critical gaps that would block any production launch. The highest-risk issues are current auth bypass in the mobile app, client-side Gemini key exposure, unauthenticated socket events, wildcard CORS, and JWT secret fallback behavior.

## Risk Rating Summary

| Severity | Count | Themes |
| --- | --- | --- |
| Critical | 4 | auth bypass, AI secret exposure, unauthenticated SOS sockets, insecure JWT fallback |
| High | 5 | CORS openness, missing rate limiting, missing validation, privacy leaks, missing mobile privacy configuration |
| Medium | 6 | error leakage, long-lived tokens, placeholder data, logging strategy, missing upload validation, weak environment hygiene |
| Low | 3 | lint warnings, default metadata, README security overstatement |

## Critical Findings

### 1. Authentication is currently bypassed in the app

- Evidence: `main.dart` uses `kBypassLogin = true`
- Risk: any app user reaches protected product surfaces without session establishment
- Impact: profile, SOS, and feature behavior operate outside real identity guarantees
- Recommendation: remove bypass before any shared environment build is distributed

### 2. Gemini API key is designed to live in client code

- Evidence: `AIService` uses `YOUR_GEMINI_API_KEY` directly on-device
- Risk: API key extraction, quota abuse, prompt abuse, legal misuse, billing exposure
- Impact: no control plane exists for moderation, rate limiting, or audit
- Recommendation: move AI access behind a backend proxy with secrets stored server-side

### 3. Socket.IO accepts unauthenticated emergency events

- Evidence: socket connection has no JWT handshake; event payload contains arbitrary `userId`
- Risk: attacker can forge SOS triggers, fake movement, or cancel incidents
- Impact: emergency platform trust collapses
- Recommendation: require authenticated socket handshake and derive actor identity from verified token only

### 4. JWT secret fallback allows insecure default signing

- Evidence: `process.env.JWT_SECRET || 'secret_key'`
- Risk: predictable tokens in misconfigured environments
- Impact: account compromise across every protected REST route
- Recommendation: fail fast on missing secret, do not ship with fallback

## High Findings

### 5. CORS is fully open

- Evidence: Socket.IO and Express both allow broad origins
- Risk: unintended web origins can interact with APIs and sockets
- Recommendation: explicitly whitelist trusted origins per environment

### 6. No rate limiting or brute-force controls

- Evidence: no rate limiter middleware present despite README claim
- Risk: credential stuffing, login abuse, spam report creation, SOS event flooding
- Recommendation: add route-level and socket-level throttling immediately

### 7. No request validation or sanitization layer

- Evidence: raw request bodies are passed into model creation and auth logic
- Risk: malformed payloads, oversized submissions, business logic abuse, noisy persistence
- Recommendation: add schema validation for every route and event payload

### 8. Sensitive location data is logged

- Evidence: `console.log` outputs `userId`, latitude, and longitude on SOS events
- Risk: operational logs become a PII location leak
- Recommendation: redact or hash identifiers and remove raw coordinate logs from normal operations

### 9. Mobile platform privacy configuration is incomplete

- Evidence: Android main manifest lacks location/microphone/camera permissions; iOS `Info.plist` lacks usage descriptions
- Risk: undefined runtime behavior, app review rejection, privacy compliance failure
- Recommendation: explicitly declare only required permissions and privacy strings

## Medium Findings

### 10. Tokens are long-lived without refresh/rotation strategy

- Evidence: JWT expiry is `30d`
- Risk: stolen token reuse window is long
- Recommendation: shorten access token lifetime and introduce refresh controls

### 11. Error responses expose internal exception messages

- Evidence: several routes return `error.message`
- Risk: internal details may leak into client-visible responses
- Recommendation: map exceptions to sanitized operational error envelopes

### 12. Cloudinary and multer are declared but not implemented

- Risk: frontend implies evidence uploads, but there is no secure upload validation path yet
- Recommendation: design content-type, size, malware, and authorization rules before enabling uploads

### 13. Session restoration is incomplete on the frontend

- Evidence: token is stored in secure storage but no bootstrapped profile/session restore exists
- Risk: app state may diverge from actual auth state
- Recommendation: validate stored tokens on launch and hydrate user state from backend

### 14. Placeholder and hardcoded user-facing data may create false safety signals

- Evidence: hardcoded safe zone messaging, safety score, medical values, contacts count
- Risk: users can misinterpret demo UI as real safety intelligence
- Recommendation: clearly distinguish mock/demo states from verified states

### 15. Test stack depends on unsecured local MongoDB assumptions

- Evidence: auth tests connect to `mongodb://127.0.0.1/suraksha_test`
- Risk: inconsistent security posture in CI and local dev, brittle verification
- Recommendation: use ephemeral/in-memory database for automated tests

## Low Findings

### 16. README overstates implemented security controls

- It claims secure Cloudinary uploads and rate limiting that are not present in authored backend logic.

### 17. Default package/application metadata remains template-grade

- Android application ID is still `com.example...`
- release signing remains TODO

### 18. Analyzer warnings include production-unfriendly patterns

- `print` usage
- deprecated APIs
- async context warning

## Positive Security Controls Present

- passwords are hashed with bcrypt before save
- JWT expiry exists
- `helmet` is enabled
- protected REST routes exist for profile and cybercrime
- tokens are stored with `flutter_secure_storage`

## File Upload Security Assessment

Current state:

- no authored upload route
- no malware scanning
- no MIME/type validation
- no size guardrails
- no ownership rules
- no signed upload workflow

Verdict:

Upload security is not implemented, even though the product direction suggests it will be important.

## Injection and Data Abuse Assessment

### REST

- no explicit sanitization or DTO validation exists
- current Mongoose usage limits some injection risk, but business abuse risk remains high

### Socket

- socket events trust arbitrary payload shapes from clients
- this is a more urgent abuse surface than classic query injection

## DDoS / Abuse Resilience

Current state:

- no request throttling
- no circuit breaking
- no abuse detection
- no IP/device heuristics
- no queue buffering for spikes

For a public safety product, this is insufficient.

## Recommended Remediation Order

### Immediate

1. remove auth bypass
2. move AI secrets server-side
3. require JWT-authenticated sockets
4. remove JWT fallback secret
5. add rate limiting and validation

### Near-term

1. add secure upload architecture before enabling evidence
2. sanitize logs and error envelopes
3. implement session restoration and token verification
4. add platform privacy declarations

### Mid-term

1. add audit logging and incident traceability
2. add secrets management and environment validation
3. introduce abuse monitoring and alerting

## Security Verdict

The codebase contains enough security scaffolding to evolve safely, but not enough to operate safely today. The current security posture is incompatible with production deployment because emergency identity, AI access, and realtime event integrity are not yet trustworthy.

## Security Scorecard

| Category | Score | Notes |
| --- | --- | --- |
| Auth security | 3/10 | hashing exists, but bypass and secret fallback are severe |
| API security | 3/10 | protected routes exist, validation/rate limit do not |
| Realtime security | 1/10 | unauthenticated and forgeable |
| Secrets management | 1/10 | client AI key pattern and fallback JWT secret |
| Privacy/compliance readiness | 2/10 | sensitive flows lack proper controls |
