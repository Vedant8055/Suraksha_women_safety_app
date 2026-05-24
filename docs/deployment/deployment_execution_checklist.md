# Deployment Execution Checklist

## 1. Backend Production Environment
- Set `NODE_ENV=production`
- Set `PORT` from platform
- Set `MONGODB_URI` (production database)
- Set `JWT_SECRET` (strong random)
- Set `JWT_REFRESH_SECRET` (different strong random)
- Set `JWT_EXPIRES_IN=15m`
- Set `JWT_REFRESH_EXPIRES_IN=30d`
- Set `CLIENT_ORIGINS` to production frontend domains
- Set rate limit values (`AUTH_RATE_LIMIT_*`, `API_RATE_LIMIT_*`)

## 2. Backend Runtime Verification
- Verify `GET /health` returns `200`
- Verify `GET /ready` returns `200` after DB connect
- Verify `POST /api/auth/login` works with valid credentials
- Verify `POST /api/auth/refresh` rotates refresh token
- Verify Socket.IO authentication works with JWT

## 3. Render Deployment
- Use [render.yaml](/C:/Users/Vedant%20Kulkarni/StudioProjects/Suraksha_women_safety_app/infrastructure/render.yaml)
- Set secret env vars in Render dashboard (never commit real secrets)
- Confirm service healthcheck path `/health`

## 4. Railway Deployment
- Use [railway.json](/C:/Users/Vedant%20Kulkarni/StudioProjects/Suraksha_women_safety_app/infrastructure/railway.json)
- Configure environment variables in Railway project settings
- Confirm deployment healthcheck path `/health`

## 5. Android Real Device Configuration
- Use LAN IPv4 backend URL, not `localhost`/`127.0.0.1`
- Run:
  - `.\scripts\run_flutter_device.ps1 -PcIpv4 <YOUR_PC_IPV4> -FlavorEnv development`

## 6. Security Go-Live Gates
- Confirm no production secrets in git history
- Enforce least-privilege Firebase rules before release
- Confirm CORS only allows approved client origins
- Confirm rate limiting triggers on abuse tests
- Confirm audit logs capture auth success/failure events

## 7. Rollback Plan
- Keep previous stable backend image/version tagged
- Revert to prior deployment if `/health` fails post-release
- Rotate JWT secrets immediately if a leak is suspected
