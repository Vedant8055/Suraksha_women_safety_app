# Realtime Architecture Plan

## Goal

Evolve the current SOS Socket.IO prototype into a privacy-safe, authenticated, room-oriented realtime subsystem that can support:

- incident-centric communication
- responder targeting
- emergency contact targeting
- reliable acknowledgements
- future horizontal scaling

without redesigning the entire product in one step.

## Current State

### Current client behavior

- opens socket when user identity exists
- emits `join_sos`
- emits `trigger_sos`
- emits `update_location`
- emits `cancel_sos`

### Current server behavior

- accepts `trigger_sos`
- accepts `update_location`
- accepts `cancel_sos`
- broadcasts to all other clients

### Current problems

- no authenticated socket handshake
- client-supplied `userId` is trusted
- rooming is not implemented
- privacy boundaries do not exist
- location update lifecycle is not tied to incident lifecycle

## Target Realtime Topology

```text
backend/realtime/
├── socket_server/
├── adapters/
├── contracts/
├── handlers/
├── lifecycle/
├── rooms/
└── docs/
```

## Room Architecture Planning

### Room types

#### User room

- one room per authenticated user
- used for private user-specific notifications and acknowledgements

#### Incident room

- one room per active SOS incident
- includes the reporting user session(s)
- includes assigned responders
- optionally includes authorized emergency contacts

#### Emergency contact room

- user-linked group for contacts explicitly authorized to receive incident updates

#### Responder room

- organizational room for available responders by region/team/type

### Why this matters

Room-based delivery prevents:

- global broadcasting of sensitive location data
- unnecessary event fan-out
- privacy violations for unrelated connected users

## Authenticated Socket Handshake Planning

### Target

Every socket connection should:

- present authenticated identity at handshake time
- bind server-side user context to the socket
- avoid trusting arbitrary client payload identity fields

### Handshake outcomes

- accept and attach user session context
- reject unauthorized sockets
- allow role-aware room subscriptions

### Transition rule

Introduce handshake auth before broadening realtime capabilities.

## Incident Event Lifecycle Planning

### Proposed logical lifecycle

1. incident requested
2. incident acknowledged by server
3. incident activated
4. responders notified
5. live tracking active
6. evidence stream active if applicable
7. incident cancelled or resolved
8. incident archived

### Why lifecycle matters

Current realtime flow is event-based only. A production system needs stateful lifecycle semantics so:

- clients can reconnect safely
- responders know current state
- data persistence and realtime delivery stay aligned

## Acknowledgement and Retry Strategy

### Current state

- client emits fire-and-forget events
- no ack callbacks
- no delivery confirmation

### Planned direction

Critical realtime actions should support:

- ack for `trigger_sos`
- ack for incident activation
- ack for cancellation
- retry/backoff for network instability
- idempotent incident event handling

### Safe migration order

1. add acks to highest-risk events
2. add retry semantics
3. add reconnect state reconciliation

## Realtime Privacy Controls

### Principles

- least-privilege delivery
- incident-scoped visibility
- explicit contact authorization
- responder role scoping
- auditability of sensitive event delivery

### Controls to plan for

- room membership based on verified roles and incident authorization
- no raw global broadcasts
- minimization of payload contents for each audience type
- retention policy for transient realtime payload logs

## Redis Adapter Planning

### Why needed

As soon as the system scales past one node, in-memory room state becomes insufficient.

### Planned role of Redis

- Socket.IO adapter for horizontal room/event propagation
- optional short-lived incident presence cache
- optional rate limiting support

### Timing

Plan Redis in Phase 4, after auth and lifecycle semantics are stabilized.

## Realtime Module Responsibilities

### `contracts/`

- event name registry
- payload schema definitions
- versioning guidance

### `handlers/`

- event-specific input processing
- no direct controller-like sprawl in bootstrap file

### `rooms/`

- room naming standards
- join/leave policy rules

### `lifecycle/`

- incident state transitions
- reconciliation logic between DB state and live sessions

## Migration Risks

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| Adding rooms before auth | rooms will still be forgeable | auth handshake first |
| Adding Redis before lifecycle design | scales flawed semantics | stabilize contracts and state model first |
| Mixing API and socket state ownership | causes drift | define incident lifecycle ownership clearly |
| Broadcasting during transition | privacy leak persists | introduce audience-specific delivery early |

## Target Outcome

The end-state realtime subsystem should provide:

- authenticated sockets
- incident-scoped rooms
- contact/responder targeting
- acknowledgements for critical events
- Redis-ready scaling path
- privacy-aware payload delivery
