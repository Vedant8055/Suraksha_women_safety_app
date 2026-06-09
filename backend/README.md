# Suraksha Backend

## Run Locally

```bash
cd backend
npm install
copy .env.example .env
npm run dev
```

The backend is now fully independent from the Flutter app folder structure.

## Scripts

- `npm run dev` starts `nodemon src/server.js`
- `npm start` starts the production server
- `npm test` runs backend tests

## Required Environment Variables

- `MONGO_URI`
- `JWT_SECRET`
- `JWT_REFRESH_SECRET`

Useful optional values:

- `CLIENT_ORIGINS`
- `REQUEST_TIMEOUT_MS`
- `OPENAI_API_KEY`
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`
- `FCM_SERVICE_ACCOUNT_JSON`

## Runtime Notes

- API routes are mounted under `/api`
- uploads are written under `backend/uploads/`
- graceful shutdown handles `SIGINT` and `SIGTERM`
- CORS and Helmet remain enabled
