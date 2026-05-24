# Realtime System Analysis

## Executive Summary

The realtime layer is a prototype Socket.IO implementation focused solely on SOS signaling. It proves that the client can emit an emergency event and that the server can broadcast it, but it is not yet safe, targeted, or scalable enough for a production emergency response platform.

## Current Realtime Topology

### Client

`lib/features/sos/sos_provider.dart`

- initializes Socket.IO only when `authState.user?.id` is non-null
- emits `join_sos` on connect
- emits `trigger_sos`
- emits `update_location`
- emits `cancel_sos`

### Server

`server/sockets/sosSocket.js`

- listens for `trigger_sos`
- listens for `update_location`
- listens for `cancel_sos`
- broadcasts `emergency_alert`
- broadcasts `live_location_update`
- broadcasts `sos_resolved`

## Event Contract Matrix

| Event | Producer | Consumer | Current Behavior | Gap |
| --- | --- | --- | --- | --- |
| `join_sos` | mobile client | server | emitted on connect | server has no handler |
| `trigger_sos` | mobile client | server | creates `SOSEvent` and broadcasts alert | no auth, no ack, no targeting |
| `update_location` | mobile client | server | broadcasts location to all other sockets | not persisted, not room-scoped |
| `cancel_sos` | mobile client | server | broadcasts resolution | does not update DB |
| `emergency_alert` | server | all other clients | alert broadcast | no responder filtering |
| `live_location_update` | server | all other clients | location broadcast | no subscription or privacy control |
| `sos_resolved` | server | all other clients | resolution broadcast | no state reconciliation |

## Functional Findings

### What works

- socket server starts with Express
- client can connect over websocket transport
- server creates an SOS document on `trigger_sos`
- basic realtime fan-out exists

### What does not

- the client expects a room-join flow that the server never implements
- no identity proof is attached to socket connections
- broadcasts are global except for excluding sender
- there is no concept of responder, emergency contact, admin, or observer audience

## Authentication and Authorization

This is the most important realtime gap.

### Current state

- sockets are unauthenticated
- event payload contains `userId` supplied by the client
- server trusts the client-provided `userId`

### Risk

Any connected client can impersonate any user and emit:

- false SOS alerts
- false location updates
- false SOS cancellations

For a safety platform, this is a critical issue.

## Reliability Assessment

### Missing reliability controls

- connection acknowledgement handshake
- event acknowledgement callbacks
- replay or recovery after reconnect
- deduplication or idempotency on repeated triggers
- timeout handling
- fallback transport strategy

### Client-side reliability concerns

- if auth is bypassed and `userId` is null, the socket is never initialized
- `triggerSOS()` still runs, which means the UI can enter emergency mode without any socket transmission
- location stream subscription is not stored or canceled

## Privacy Assessment

### Current issue

Location updates are broadcast to all other clients connected to the namespace.

### Why this matters

Emergency location data must be shared only with:

- the user
- authorized emergency contacts
- authorized responders
- internal operations staff with audit controls

The current broadcast model is incompatible with privacy and trust requirements.

## Data Consistency Assessment

### Current write path

- `trigger_sos` creates a `SOSEvent`
- `update_location` does not update the `SOSEvent`
- `cancel_sos` does not mark the `SOSEvent` as cancelled

### Consequences

- DB state drifts from realtime state
- incident history is incomplete
- there is no source of truth for active vs cancelled events
- analytics and audit replay will be inaccurate

## Scalability Assessment

### Current architecture

- single Socket.IO instance
- in-memory connection tracking only
- no adapter such as Redis
- global broadcast semantics

### Scaling limits

- cannot horizontally scale safely
- room state is not externalized
- event fan-out will become noisy and wasteful
- no backpressure or throttling controls exist

## Event Naming and Contract Quality

### Positives

- event names are readable
- naming is semantically clear

### Issues

- request and response events are not versioned
- there is no shared contract/schema between client and server
- `join_sos` is dead contract surface today

## Recommended Target Realtime Design

### Phase 1

- authenticate sockets during handshake using JWT
- reject client-supplied arbitrary `userId`
- add a server handler for join/subscription semantics
- persist cancellation and optionally location updates

### Phase 2

- introduce rooms by incident, responder team, and emergency contact set
- add acks for critical events
- add throttling on location emission
- reconcile socket lifecycle with incident lifecycle

### Phase 3

- add Redis adapter for horizontal scale
- externalize responder state
- add incident event log for replay and audit

## Realtime Verdict

The current realtime system is a proof of concept for SOS broadcasting, not a secure emergency communications layer. It demonstrates intent, but it cannot yet support production-grade trust, privacy, or operational reliability.

## Realtime Scorecard

| Category | Score | Notes |
| --- | --- | --- |
| Functional prototype value | 6/10 | enough to demo SOS event flow |
| Security | 1/10 | unauthenticated and client-trusting |
| Privacy | 1/10 | broadcasts sensitive location broadly |
| Reliability | 2/10 | no ack, replay, or reconnect model |
| Scalability | 2/10 | single-node in-memory socket model |
