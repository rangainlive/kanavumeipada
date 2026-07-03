# KanavuMeipada — Setup & Running Guide

## Project Structure

```
kanavumeipada/
├── app/                    # Flutter mobile app
│   ├── lib/
│   │   ├── core/          # theme, router, constants
│   │   ├── features/      # auth, feed, content, test_engine, etc.
│   │   └── shared/        # widgets, utils, models
│   ├── pubspec.yaml       # Flutter dependencies
│   └── .env               # Environment variables
├── backend/               # Node.js + Fastify API
│   ├── src/
│   │   ├── routes/        # API routes (auth, tests, challenges, feed, wallet)
│   │   ├── services/      # Business logic (Firebase, JWT, User, etc.)
│   │   ├── jobs/          # Background jobs (BullMQ)
│   │   ├── db/            # Database schema, migrations
│   │   ├── middleware/    # Auth middleware
│   │   └── types/         # TypeScript type definitions
│   ├── package.json       # Node.js dependencies
│   ├── tsconfig.json      # TypeScript config
│   └── .env               # Environment variables
├── admin/                 # React admin panel (TODO)
├── docker-compose.yml     # Local dev environment (PostgreSQL + Redis)
├── PLAN.md               # Full product plan
└── SETUP.md              # This file

```

## Quick Start — Local Development

### Prerequisites
- Flutter SDK 3.12+
- Node.js 18+
- Docker & Docker Compose
- Git

### 1. Database & Cache Setup

```bash
# Start PostgreSQL and Redis containers
docker-compose up -d

# Verify containers are running
docker-compose ps

# Check database is ready
docker-compose logs postgres
```

The database schema is automatically initialized from `backend/src/db/init.sql`.

Verify connection:
```bash
psql -h localhost -U postgres -d kanavumeipada -c "SELECT version();"
```

### 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Verify TypeScript setup
npx tsc --version

# Create .env file (copy from template)
cp .env.example .env  # or edit .env with your settings
```

**Backend environment variables (.env):**
```
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/kanavumeipada
REDIS_URL=redis://localhost:6379
JWT_SECRET=dev-secret-key-change-in-production
FIREBASE_PROJECT_ID=kanavumeipada
```

### 3. Backend Running

```bash
# Development mode (with auto-reload)
npm run dev

# Output should show:
# 🚀 Server running at http://0.0.0.0:3000

# Test health endpoint
curl http://localhost:3000/health
```

**Expected response:**
```json
{
  "status": "ok",
  "database": "connected",
  "timestamp": "2026-07-01T12:34:56.789Z"
}
```

### 4. Flutter App Setup

```bash
cd app

# Install dependencies
flutter pub get

# Run on Android emulator or connected device
flutter run

# Or specific device:
flutter run -d all  # Shows available devices
```

**Current state:** App shows placeholder screens; auth/feed screens are scaffolding.

## API Endpoints (Implemented)

### Authentication
- `POST /api/auth/request-otp` — Request phone OTP
- `POST /api/auth/verify-otp` — Verify OTP, create/login user
- `POST /api/auth/profile` — Update user profile
- `GET /api/auth/me` — Get current user (requires auth)
- `POST /api/auth/refresh` — Refresh JWT token

**Example request (Verify OTP):**
```bash
curl -X POST http://localhost:3000/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+919876543210",
    "otp": "123456"
  }'
```

**Response:**
```json
{
  "token": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "expiresIn": "7d",
  "user": {
    "id": "uuid",
    "phone": "+919876543210",
    "name": null,
    "isProfileComplete": false
  }
}
```

## Development Workflow

### Making code changes

**Backend:**
```bash
# Automatic reload on file changes
npm run dev

# Build TypeScript
npm run build

# Errors appear in terminal immediately
```

**Flutter:**
```bash
# Hot reload (press 'r' in terminal)
# Changes appear in app in ~1 second

# Full restart (press 'R' in terminal)
```

### Adding database migrations

1. Edit `backend/src/db/init.sql` to add new tables/columns
2. Restart PostgreSQL container to apply:
   ```bash
   docker-compose down
   docker-compose up -d
   ```
3. Or manually run SQL:
   ```bash
   psql -h localhost -U postgres -d kanavumeipada -f backend/src/db/init.sql
   ```

### Debugging

**Backend:**
- Logs print to terminal in real-time
- HTTP requests logged with method, path, response time
- Errors include stack traces

**Flutter:**
- Run with `-v` flag for verbose logs:
  ```bash
  flutter run -v
  ```

## What's Implemented (Phase 1)

✅ **Flutter**
- Project structure with Riverpod + Go Router
- Theme (light/dark mode)
- Constants & type definitions
- Placeholder screens for Auth and Feed

✅ **Backend**
- Fastify + PostgreSQL + Redis setup
- Complete database schema (15 tables)
- JWT + Firebase Auth integration
- User service with coin wallet logic
- Auth routes: OTP, verification, profile, token refresh

✅ **Database**
- 15 tables with proper relationships
- Indexes on frequently queried columns
- Transaction support for atomic operations (wallet)
- UUID primary keys throughout

✅ **Docker**
- PostgreSQL 16 Alpine
- Redis 7 Alpine
- Auto-initialization on container start
- Health checks

## Next Steps (Phase 2)

1. **Flutter Auth UI** — Phone input, OTP verification, profile setup
2. **Community Feed** — Post creation, likes, comments (backend + Flutter UI)
3. **Content Module** — Chapters, subjects, chapter reader (offline-first)
4. **AI Integration** — Gemma 2B question generation on-device

## Troubleshooting

**Port 3000/5432/6379 already in use?**
```bash
# Find process using port
lsof -i :3000  # Backend
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis

# Kill process (optional)
kill -9 <PID>
```

**PostgreSQL not starting?**
```bash
# Check logs
docker-compose logs postgres

# Remove and recreate
docker-compose down -v
docker-compose up -d
```

**Package install failing?**
```bash
# Clear cache
npm cache clean --force
flutter pub cache repair

# Retry install
npm install
flutter pub get
```

**"Cannot connect to database"?**
```bash
# Verify container is running
docker-compose ps

# Check connection string in .env matches container name
# Should be: postgres:5432 (not localhost:5432)
```

## Architecture Decisions

1. **On-device AI over API**: Gemma 2B runs on Flutter, zero API cost at scale
2. **PostgreSQL + Redis**: Proven stack for competitive exam apps
3. **Fastify over Express**: 2-3x faster, TypeScript-first, minimal overhead
4. **Riverpod over Provider**: Better async support, less boilerplate
5. **JWT + Firebase**: Leverage Firebase free tier + custom JWT for refresh

## Performance Targets

- Auth OTP → Verify: <500ms
- Load feed (10 posts): <800ms  
- Submit test answer: <300ms
- Generate 10 questions: 8–12s (on-device AI)

## Security Checklist

- [ ] Change JWT_SECRET in production
- [ ] Enable HTTPS in production
- [ ] Set CORS_ORIGIN to specific domains
- [ ] Implement rate limiting on `/api/auth/request-otp`
- [ ] Verify Razorpay webhook signatures
- [ ] Audit database for SQL injection (using parameterized queries — ✅ done)
- [ ] Test wallet double-spend prevention
