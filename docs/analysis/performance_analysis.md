# Performance Analysis

## Executive Summary

The current performance profile is acceptable for demo-scale usage, but several implementation choices will become problematic under real emergency workloads. The largest risks are uncontrolled sensor/audio activity on mobile, continuous location streaming without lifecycle discipline, broad socket broadcasts, and data models that do not scale well for high-frequency event streams.

## Frontend Performance Findings

### UI and rendering

#### `SafetyRadar`

- continuously animates with an `AnimationController`
- `CustomPainter.shouldRepaint` always returns `true`
- acceptable for a small home widget, but should be measured on lower-end devices

#### Dashboard visuals

- frequent use of animations and shadows/glows
- likely fine for modern devices, but not optimized for reduced-motion or low-power modes

### State and rebuild behavior

- no severe Riverpod rebuild issue is evident today because provider usage is shallow
- the bigger issue is that screens hold direct orchestration logic, making future optimization harder

### SOS and sensor flow

#### `SOSNotifier`

- starts a position stream but does not store the subscription
- stream cannot be explicitly canceled on SOS stop or notifier disposal
- long-lived streams can outlive intended session boundaries

#### `SensorService`

- impact detection triggers directly on acceleration threshold
- no debounce, cooldown, or confirmation step exists
- repeated triggers can cause duplicate work and noisy network traffic

#### `ScreamDetectionService`

- opens recorder and listens every 100 ms
- writes to a file while monitoring
- this is battery-intensive and may cause disk churn

## Backend Performance Findings

### HTTP layer

- backend is small and low-overhead for current route volume
- absence of validation means malformed large payloads are not bounded early

### Realtime layer

- `socket.broadcast.emit` sends SOS and location data to all other clients
- this is inefficient and becomes increasingly wasteful with more connected users
- no rate controls exist on location events

### Database layer

- current query load is light
- indexing gaps will become noticeable as report and incident history grows
- `SOSEvent.liveTracking` as an ever-growing array is the main long-term performance risk

## Latency Risks

### Frontend

- direct Gemini calls from mobile introduce variable network latency with no queueing or timeout strategy beyond Dio defaults
- geolocation acquisition can delay SOS emission, especially without pre-warmed location state

### Backend

- socket event processing currently performs DB create for SOS trigger inline
- lack of background job separation means spikes in emergency traffic could affect event latency

## Memory and Resource Risks

### Mobile

- location streams not explicitly disposed
- recorder resources need careful lifecycle management
- chat messages are stored only in-memory and could grow unbounded in a long session

### Backend

- single-process realtime memory model
- no queue isolation for expensive future tasks such as media processing or notifications

## Asset and Payload Considerations

- asset directories are currently empty, so asset size is not a present bottleneck
- future evidence uploads will need compression, chunking, and retention policies
- map overlays are static and light today

## Lazy Loading and Defer Strategies

Not yet implemented.

Potential candidates:

- feature-level deferred initialization for map, AI, and recorder workflows
- lazy activation of sensor/audio services only after explicit user enablement
- deferred loading of historical reports and incident media

## Recommended Performance Improvements

### Immediate

- store and cancel live location subscriptions explicitly
- add SOS trigger cooldown/debounce
- stop treating global broadcast as delivery strategy
- add pagination for report retrieval before scale arrives

### Near-term

- move AI calls behind backend proxy with rate and timeout control
- separate incident tracking points from main SOS document
- optimize map data loading model before dynamic overlays are introduced

### Long-term

- introduce background workers for notifications, uploads, and AI post-processing
- add Redis-backed socket scaling and fan-out control
- define cold-storage lifecycle for historical incident data

## Performance Verdict

The system will feel responsive in prototype conditions, but the current design is not prepared for sustained emergency usage, concurrent SOS activity, or heavy media/AI workflows. The main performance work is not micro-optimization; it is lifecycle control, event targeting, and data-model redesign.

## Performance Scorecard

| Category | Score | Notes |
| --- | --- | --- |
| Demo responsiveness | 7/10 | light current workload |
| Mobile runtime efficiency | 4/10 | sensors, recorder, and location lifecycles are weak |
| Backend throughput readiness | 3/10 | small API, but no abuse or scaling controls |
| Realtime efficiency | 2/10 | global broadcasts do not scale |
| Data-layer scalability | 3/10 | live tracking design is the main bottleneck |
