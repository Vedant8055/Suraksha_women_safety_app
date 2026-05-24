# Target Enterprise Structure

## Objective

The target repository should evolve into a safe monorepo-style layout where:

- frontend ownership is isolated
- backend ownership is isolated
- infrastructure assets have a dedicated home
- documentation is first-class
- future shared contracts and schemas are formalized
- migration can happen incrementally without a big-bang cutover

## Target Structure

```text
suraksha/
├── frontend/
│   ├── mobile_app/
│   │   ├── lib/
│   │   ├── android/
│   │   ├── ios/
│   │   ├── web/
│   │   ├── linux/
│   │   ├── macos/
│   │   ├── windows/
│   │   ├── test/
│   │   ├── pubspec.yaml
│   │   └── analysis_options.yaml
│   ├── shared_ui/
│   │   ├── lib/
│   │   ├── test/
│   │   └── pubspec.yaml
│   ├── assets/
│   │   ├── animations/
│   │   ├── icons/
│   │   └── images/
│   └── docs/
│       ├── design_system/
│       ├── navigation/
│       └── platform_setup/
├── backend/
│   ├── api_gateway/
│   │   ├── src/
│   │   │   ├── app/
│   │   │   ├── config/
│   │   │   ├── controllers/
│   │   │   ├── middleware/
│   │   │   ├── modules/
│   │   │   ├── repositories/
│   │   │   ├── routes/
│   │   │   ├── services/
│   │   │   ├── validators/
│   │   │   └── utils/
│   │   ├── tests/
│   │   ├── package.json
│   │   └── docs/
│   ├── realtime/
│   │   ├── socket_server/
│   │   ├── adapters/
│   │   ├── handlers/
│   │   ├── rooms/
│   │   ├── contracts/
│   │   └── docs/
│   ├── services/
│   │   ├── ai_gateway/
│   │   ├── notifications/
│   │   ├── evidence/
│   │   └── analytics/
│   ├── workers/
│   │   ├── jobs/
│   │   ├── queues/
│   │   └── docs/
│   ├── uploads/
│   └── tests/
├── infrastructure/
│   ├── docker/
│   ├── nginx/
│   ├── kubernetes/
│   ├── monitoring/
│   ├── environments/
│   └── ci/
├── docs/
│   ├── architecture/
│   ├── security/
│   ├── api/
│   ├── operations/
│   └── roadmap/
├── scripts/
│   ├── dev/
│   ├── build/
│   ├── verify/
│   └── release/
└── shared/
    ├── contracts/
    │   ├── rest/
    │   └── realtime/
    ├── schemas/
    ├── constants/
    └── docs/
```

## Why This Structure

### `frontend/`

- isolates Flutter runtime, platform folders, assets, and mobile-specific documentation
- enables future addition of web dashboard or responder app without polluting root
- gives shared UI a separate lifecycle from the main mobile app

### `backend/`

- separates API gateway concerns from realtime concerns
- creates room for future service extraction without forcing microservices immediately
- gives workers and async processing a real home before they are introduced

### `infrastructure/`

- prevents deployment artifacts from being scattered across app directories
- enables environment-specific packaging and ops tooling

### `docs/`

- allows architecture, security, API, and roadmap documents to live outside app source trees
- reduces documentation drift and supports onboarding

### `shared/`

- creates a future home for REST DTOs, socket event contracts, validation schemas, and shared constants
- reduces string-based drift between Flutter and Node

## Safe Migration Rules

1. introduce target folders first
2. document ownership and intended future contents
3. move source only in controlled phases
4. preserve existing run commands until replacement scripts exist
5. avoid moving generated folders and build artifacts into permanent source boundaries

## Transitional Command Compatibility

During migration, the repository should preserve the ability to run:

- Flutter locally from a well-documented mobile app path
- Node backend from a well-documented backend path

The target state should standardize this through scripts, for example:

- `scripts/dev/start-mobile`
- `scripts/dev/start-api`
- `scripts/dev/start-realtime`

Those are planning targets only, not implementation instructions for this phase.

## Recommended Ownership Boundaries

| Area | Primary Ownership |
| --- | --- |
| `frontend/mobile_app` | mobile engineering |
| `frontend/shared_ui` | design systems / mobile platform |
| `backend/api_gateway` | backend platform |
| `backend/realtime` | realtime platform |
| `backend/services` | domain platform / integrations |
| `infrastructure` | DevOps / platform engineering |
| `shared/contracts` | backend + frontend integration ownership |
| `docs` | shared cross-functional ownership |

## Target-State Conclusion

The target structure is intentionally more mature than the current codebase, but it should be adopted incrementally. The purpose is not to force early microservices or over-engineering. The purpose is to give the repository safe long-term boundaries so the current prototype can evolve into a scalable, multi-team, production-oriented system without repeated structural churn.
