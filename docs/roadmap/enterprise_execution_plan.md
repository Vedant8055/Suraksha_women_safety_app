# Enterprise Execution Plan

## Date
2026-05-23

## Safe Execution Order
1. Runtime stabilization (port fallback, DB retry, graceful shutdown, env standardization).
2. Security hardening completion (refresh/session policy, auth abuse controls, audit logs, Firebase rules).
3. Backend modular expansion under `backend/src` while keeping `server/` runtime active.
4. Frontend clean-architecture migration in slices by feature.
5. Realtime reliability upgrades (ack/retry, offline queue, heartbeat).
6. Mobile device validation matrix.
7. Deployment hardening and CI/CD expansion.
8. QA gates and production cutover.

## Current Completed in This Iteration
- Added automatic port fallback when configured port is busy.
- Added MongoDB retry logic with exponential backoff.
- Added graceful shutdown for HTTP, Socket.IO, and MongoDB.
- Added `MONGO_URI`-first environment support.
- Added env retry knobs for Mongo connection.

## File-by-File Changes (This Iteration)
- `server/config/port.js`
- `server/database/mongo.connection.js`
- `server/server.js`
- `server/config/env.js`
- `server/.env`
- `server/.env.example`
- `server/.env.development.example`
- `server/.env.staging.example`
- `server/.env.production.example`

## Rollback Strategy
1. Revert changed files listed above.
2. Restore previous `server/server.js` startup logic.
3. Restore previous env keys (`MONGODB_URI`) if needed.
4. Restart backend and verify `/health`.

## Security Checklist (Near-Term)
- [ ] Rotate local development secrets if shared.
- [ ] Add Firebase rules files and enforce authenticated access isolation.
- [ ] Add token revocation strategy for compromised refresh tokens.
- [ ] Add suspicious auth attempt alerting.
- [ ] Restrict `CLIENT_ORIGINS` per environment.

## Testing Checklist (Near-Term)
- [ ] Start backend with busy port 5000; verify auto-fallback to 5001+.
- [ ] Stop MongoDB and verify retry logs and non-crash behavior.
- [ ] Start MongoDB and verify successful connect.
- [ ] Verify graceful shutdown on `Ctrl + C`.
- [ ] Verify auth endpoints still return access token and refresh token.
- [ ] Verify Flutter physical-device API connectivity via LAN IPv4.

## Production Readiness Checklist (Ongoing)
- [ ] Backend deploy secrets configured in cloud provider.
- [ ] `/health` and `/ready` integrated with deployment health checks.
- [ ] Crash reporting wired for frontend and backend.
- [ ] CI checks include backend tests and build.
- [ ] Staging signoff completed before production rollout.
