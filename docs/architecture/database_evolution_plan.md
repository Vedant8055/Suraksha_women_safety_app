# Database Evolution Plan

## Goal

Evolve the current MongoDB model set from prototype-friendly schemas into a production-safe data foundation that supports:

- emergency workflows
- live tracking
- cybercrime evidence lifecycle
- analytics
- retention controls
- privacy-aware storage

without forcing an immediate full data-model rewrite.

## Current State

Current modeled collections:

- `users`
- `sosevents`
- `cybercrimereports`

Current constraints:

- limited indexing strategy
- no timestamps standardization
- live tracking embedded inside SOS document
- no archival or analytics projections

## Collection Evolution Strategy

### Users

Current role:

- identity
- profile
- medical context
- emergency contacts
- trusted locations
- SOS preferences

Planned evolution:

- retain user as primary profile aggregate
- normalize only if arrays or related workflows outgrow practical embedding
- introduce standardized timestamps and update audit fields

### SOS incidents

Current role:

- incident root document
- initial trigger location
- status
- evidence references
- embedded live tracking

Planned evolution:

- keep incident as aggregate root
- move high-frequency tracking out of embedded array model
- introduce responder assignment and state transition metadata

### Cybercrime reports

Current role:

- user-submitted incident record
- evidence URL references
- simple status

Planned evolution:

- add workflow metadata
- add evidence metadata references
- support pagination, moderation, and investigator handling

## Live Tracking Redesign Plan

### Current problem

`SOSEvent.liveTracking` is an unbounded embedded array.

### Planned target

Separate tracking into a dedicated incident-location event model or time-bucketed tracking model.

### Candidate patterns

#### Option A: Dedicated tracking collection

- one document per location ping
- strongest query flexibility
- clean retention strategy

#### Option B: Time-bucketed tracking documents

- groups pings by incident and time window
- reduces document explosion

### Recommended direction

Prefer a dedicated tracking event collection for clarity and operational flexibility.

## Indexing Strategy

### Immediate planned indexes

- `users.email` unique normalized
- `users.phone` unique normalized
- `sosevents.userId`
- `sosevents.status`
- `sosevents.createdAt`
- `cybercrimereports.userId`
- `cybercrimereports.status`
- `cybercrimereports.createdAt`

### Geospatial planned indexes

- incident origin location
- trusted locations if map intelligence depends on them
- future hotspot/risk aggregation collections

## Geospatial Indexing Plan

### Why needed

The product roadmap includes:

- safety intelligence mapping
- location-aware incident visibility
- trusted places
- zone analytics

### Planned direction

- adopt geospatial representation appropriate for MongoDB queries
- use indexed location fields for proximity and map workloads
- avoid ad hoc lat/lng filtering at application layer for mature map features

## Archival Strategy

### Current state

- no data lifecycle strategy

### Planned lifecycle categories

- active incidents
- recently resolved incidents
- archived incident history
- long-term analytics-safe aggregates

### Why this matters

- keeps operational collections lean
- supports privacy and retention policy goals
- helps separate support workflows from analytics workflows

## Event Stream Planning

### Target concept

An incident should eventually be reconstructed from durable events such as:

- incident created
- responder notified
- location updated
- evidence attached
- user cancelled
- responder resolved

### Benefit

- better auditability
- improved reconciliation with realtime flows
- cleaner analytics and timeline generation

## Analytics Read Models

Current data model is operational-first only.

Planned read models may include:

- incident heatmaps
- district/time safety trends
- report category trends
- responder load summaries
- incident resolution metrics

These should be read-optimized projections, not overloaded operational collections.

## PII Protection Planning

### Sensitive domains

- user identity
- medical data
- emergency contacts
- precise location trails
- evidence references

### Planning priorities

- field classification by sensitivity
- redaction strategy for logs and support tools
- retention windows for high-risk data
- optional encryption strategy for the most sensitive fields

## Migration Sequencing

### Phase 1

- standardize timestamps and index planning
- normalize identity inputs

### Phase 2

- split tracking from SOS root document
- add workflow metadata to incidents and reports

### Phase 3

- add analytics read models and archival pipeline
- introduce privacy-aware retention operations

## Target Outcome

The end-state data platform should support:

- operational emergency workflows
- scalable live tracking
- geospatial intelligence
- analytics-friendly projections
- privacy-aware retention and storage boundaries
