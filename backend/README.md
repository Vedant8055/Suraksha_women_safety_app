# Suraksha Backend MVP

## Setup
1. `cd backend`
2. `npm install`
3. Copy `.env.example` to `.env` and fill values.
4. `npm run dev`

## Core APIs
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/sos/create`
- `GET /api/sos/active`
- `POST /api/location/update`
- `POST /api/incident/report`
- `GET /api/nearby/police?lat=..&lng=..`
- `GET /api/nearby/hospitals?lat=..&lng=..`
- `POST /api/ai/chat`
- `POST /api/media/upload`
- `GET /api/notifications`
- `GET /api/profile`
- `GET /api/profile/contacts`
- `POST /api/profile/contacts`

## Notes
- MongoDB Atlas is used via `MONGO_URI`.
- Socket.IO events: `trigger_sos`, `update_location`, `cancel_sos`.
- Use separate git repo for backend and frontend when deploying.
