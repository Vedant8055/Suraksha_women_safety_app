# Suraksha Monorepo

This repository now keeps the Flutter mobile app and the Node.js backend as clean, independent siblings:

```text
project-root/
├── app/        Flutter application
├── backend/    Node.js + Express API
├── docs/
├── scripts/
└── infrastructure/
```

## App Setup

```bash
cd app
flutter pub get
flutter run
```

Environment files live in `app/`:

- `.env`
- `.env.development`
- `.env.production`

Example values:

```env
APP_ENV=development
BASE_URL=http://10.0.2.2:5000/api
SOCKET_URL=http://10.0.2.2:5000
GOOGLE_MAPS_API_KEY=
GEMINI_API_KEY=
GEMINI_MODEL=gemini-1.5-flash
```

For LAN device testing:

```bash
pwsh ./scripts/run_flutter_device.ps1 -PcIpv4 192.168.1.5
```

## Backend Setup

```bash
cd backend
npm install
copy .env.example .env
npm run dev
```

Core expectations:

- `backend/.env` contains MongoDB, JWT, and optional Cloudinary/OpenAI settings.
- backend starts independently from `backend/`.
- API base path stays `/api`.

## Environment Model

Flutter reads runtime env values from `flutter_dotenv` and supports:

- `.env.development`
- `.env.production`
- fallback `.env`

Backend reads `backend/.env` via `dotenv`.

## Validation Commands

App:

```bash
cd app
flutter analyze
flutter test
```

Backend:

```bash
cd backend
npm install
npm test
npm run dev
```

## Production Notes

- No app API base URLs should be hardcoded in feature code.
- Uploaded backend files are written under `backend/uploads/`.
- `helmet`, `cors`, rate limiting, and centralized error handling remain enabled.
- Graceful backend shutdown is wired for `SIGINT` and `SIGTERM`.
