# Database Analysis

## Executive Summary

The MongoDB layer is small and understandable, but it is currently modeled for prototyping rather than scale, compliance, or operational analytics. The schema set is sensible for an MVP, yet indexing, growth control, and lifecycle management are not mature enough for realtime emergency and evidence-heavy workloads.

## Collections in Use

| Collection | Source Model | Purpose |
| --- | --- | --- |
| `users` | `User.js` | identity, emergency profile, trusted locations, SOS settings |
| `sosevents` | `SOSEvent.js` | SOS incidents, location snapshots, evidence references |
| `cybercrimereports` | `CyberCrimeReport.js` | user-submitted cybercrime reports |

## Schema Review

### `users`

#### Shape

- top-level identity: `name`, `email`, `phone`, `password`
- medical context: `bloodGroup`, `medicalConditions`, `allergies`
- response context: `emergencyContacts`, `trustedLocations`, `sosSettings`

#### Positives

- embedding emergency contacts is reasonable because they are tightly user-owned
- embedding trusted locations is acceptable for small bounded arrays
- SOS preferences are correctly modeled as subdocument state

#### Risks

- no max-length or cardinality guard on embedded arrays
- no timestamps for update auditing
- no normalized casing for email
- no geospatial representation for `trustedLocations`

### `sosevents`

#### Shape

- root user reference
- point-in-time trigger location
- mutable `status`
- optional `evidence`
- `liveTracking` array of location snapshots

#### Positives

- conceptually correct aggregation of a single emergency incident
- flexible enough to evolve into responder workflows

#### Risks

- `liveTracking` is an ever-growing embedded array
- no geospatial index on incident origin
- no responder assignment or acknowledgement metadata
- no retention/archive strategy for historical movement trails

### `cybercrimereports`

#### Shape

- user reference
- categorical classification
- free-form description
- evidence URLs
- status lifecycle

#### Positives

- minimal schema is sufficient for MVP intake

#### Risks

- no evidence metadata such as content type, size, hash, upload time, or provenance
- no investigator workflow fields
- no moderation state or abuse-report handling

## Relationship Model

### Current pattern

- `SOSEvent.userId -> User`
- `CyberCrimeReport.userId -> User`
- user-owned operational data is embedded inside `User`

### Assessment

This is a reasonable early-stage hybrid approach:

- references for event/report history
- embeddings for tightly-owned user profile data

The main problem is not normalization; it is the absence of scaling constraints and index strategy.

## Indexing Assessment

### Present implicitly

- `email` unique
- `phone` unique

### Missing important indexes

- `SOSEvent.userId`
- `SOSEvent.status`
- `SOSEvent.createdAt`
- geospatial index for SOS incident location
- `CyberCrimeReport.userId`
- `CyberCrimeReport.status`
- `CyberCrimeReport.createdAt`

### Why this matters

Without these indexes:

- per-user report history degrades as volume grows
- active SOS dashboards become expensive to query
- time-bounded incident review is slower than necessary
- map/radius-based intelligence is not feasible

## Query Efficiency

### Current observed patterns

- auth lookup by email or phone
- user profile by `_id`
- cybercrime reports by `userId`
- SOS incident creation on socket event

### Current state

For small volumes, these are fine.

### Future risk

The first real bottlenecks will likely come from:

- SOS analytics by time and status
- responder dashboards
- user incident history
- map intelligence queries
- evidence-rich report retrieval

## Scalability Concerns

### `SOSEvent.liveTracking`

This is the biggest data-model scaling concern.

- every incident can accumulate many location points
- document growth can become large and uneven
- very active incidents may approach MongoDB document size constraints over time
- updating the same large document repeatedly is inefficient

Better long-term patterns include:

- storing location pings in a separate capped/event collection
- time-bucketed subdocuments
- cold-storage archival after incident closure

### `User` aggregate growth

User embedding is acceptable if:

- emergency contacts remain small
- trusted locations remain small
- medical arrays remain bounded

If the product later adds history, incident preferences, evidence shortcuts, or responder relationships into `User`, the aggregate should be split.

## Data Integrity Concerns

- no Mongoose validation for email format
- no phone normalization
- no explicit enum for blood groups
- no requirement that trusted locations include both lat and lng together
- no validation on evidence URL origins

## Security and Compliance Concerns

The database stores highly sensitive information or implied future sensitive information:

- passwords
- emergency contacts
- medical data
- precise location trails
- cybercrime evidence references

Current concerns:

- no field-level encryption strategy
- no PII retention policy
- no audit trail fields
- no redaction strategy for exports or logs

## Recommended Database Evolution

### Near-term

- add indexes for user-linked and time-based retrieval
- add `timestamps: true` to all models
- normalize email and phone input
- validate bounded lengths and array sizes

### Mid-term

- split live tracking into a dedicated collection or event stream
- introduce geospatial indexing for incident mapping
- add evidence metadata model
- add audit fields such as `createdBy`, `updatedBy`, `source`, and `originDevice`

### Long-term

- archive closed incidents
- define data retention windows
- support analytics-friendly read models

## Database Verdict

The schema set is structurally reasonable for an MVP, but it lacks the indexing, lifecycle controls, and security posture needed for a real emergency platform. The biggest architectural database gap is that incident tracking is modeled as an append-only array inside the SOS document rather than a scalable event stream or dedicated tracking collection.

## Database Scorecard

| Category | Score | Notes |
| --- | --- | --- |
| Schema clarity | 6/10 | easy to understand |
| Index readiness | 2/10 | only implicit unique constraints are evident |
| Scalability design | 3/10 | live tracking model will not scale well |
| Query efficiency | 4/10 | current workloads are small, future workloads are not planned for |
| Security/compliance readiness | 2/10 | sensitive data controls are not defined |
