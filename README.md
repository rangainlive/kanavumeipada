# KanavuMeipada 🎓

A mobile app for competitive exam aspirants combining AI-powered question generation, gamified daily streaks, and a peer-challenge economy with real prize pools.

**Status:** Phase 1 ✅ Complete — Foundation & Authentication

## What's Built (Phase 1)

### ✅ Mobile App (Flutter)
- **Project structure** with Riverpod state management
- **Theme system** (light/dark mode)
- **Authentication flow:**
  - Phone number input screen with country code selector
  - OTP verification screen with 6-digit input
  - Profile setup screen (name, email, exam target, state)
  - Timer-based OTP resend functionality
- **Router setup** with GoRouter for seamless navigation
- **Responsive UI** with Material 3 design

### ✅ Backend API (Node.js + Fastify)
- **Authentication routes:**
  - `POST /api/auth/request-otp` — Request one-time password
  - `POST /api/auth/verify-otp` — Verify OTP and create/login user
  - `POST /api/auth/profile` — Update user profile
  - `GET /api/auth/me` — Get current authenticated user
  - `POST /api/auth/refresh` — Refresh JWT token
- **JWT-based authentication** with 7-day expiry
- **Firebase Auth integration** (OTP delivery)
- **User service** with transactional wallet support
- **Middleware** for route protection via JWT

### ✅ Database (PostgreSQL)
15 tables with complete schema:
- **Users** — Profile, coins, XP
- **User Streaks** — Daily streak tracking
- **Subjects & Chapters** — Course content
- **Questions & Options** — MCQs with ratings
- **Tests & Attempts** — Test sessions and scoring
- **Challenges** — User-created paid tests
- **Feed Posts** — Social wall content
- **Wallet Transactions** — Coin history
- **Achievements** — Badges and rewards

All tables have proper indexes, constraints, and foreign keys.

### ✅ Infrastructure
- **Docker Compose** for local development
- **PostgreSQL 16** (auto-initialized schema)
- **Redis 7** (for caching, leaderboards, sessions)
- **Health checks** on all services

## Project Structure

```
kanavumeipada/
├── app/                              # Flutter mobile app
│   ├── lib/
│   │   ├── core/
│   │   │   ├── theme/app_theme.dart                    # Light/dark themes
│   │   │   ├── router/app_router.dart                  # GoRouter setup
│   │   │   └── constants/app_constants.dart            # App-wide constants
│   │   ├── features/
│   │   │   └── auth/
│   │   │       ├── screens/
│   │   │       │   ├── phone_input_screen.dart        # Phone entry UI
│   │   │       │   ├── otp_screen.dart                # OTP verification UI
│   │   │       │   ├── profile_setup_screen.dart      # Profile completion UI
│   │   │       │   └── auth_screen.dart               # Redirect screen
│   │   │       └── providers/
│   │   │           └── auth_provider.dart             # Riverpod state management
│   │   ├── features/{feed,content,test_engine,...}    # TODO: Implement in Phase 2
│   │   └── shared/{widgets,utils,models}              # Reusable components
│   ├── pubspec.yaml                                    # Flutter dependencies
│   └── .env                                            # Environment variables
├── backend/                          # Node.js + Fastify API
│   ├── src/
│   │   ├── index.ts                                   # Server entry point
│   │   ├── middleware/
│   │   │   └── auth.middleware.ts                    # JWT verification
│   │   ├── routes/
│   │   │   └── auth.routes.ts                        # Auth endpoints
│   │   ├── services/
│   │   │   ├── firebase.service.ts                   # Firebase Auth wrapper
│   │   │   ├── jwt.service.ts                        # JWT generation/verification
│   │   │   └── user.service.ts                       # User CRUD + wallet logic
│   │   ├── types/
│   │   │   └── auth.ts                               # TypeScript types
│   │   └── db/
│   │       └── init.sql                              # Full database schema
│   ├── package.json                                   # Node dependencies
│   ├── tsconfig.json                                  # TypeScript config
│   └── .env                                           # Environment variables
├── admin/                           # React admin panel (TODO: Phase 4)
├── docker-compose.yml               # PostgreSQL + Redis setup
├── PLAN.md                          # Full product & business plan
├── SETUP.md                         # Development setup guide
└── README.md                        # This file
```

## Quick Start

### 1. Start Services
```bash
# Start PostgreSQL + Redis
docker-compose up -d

# Verify
docker-compose ps
```

### 2. Run Backend
```bash
cd backend
npm install
npm run dev
# Server runs on http://localhost:3000
```

### 3. Run Flutter App
```bash
cd app
flutter pub get
flutter run
# Open on device/emulator
```

### 4. Test Authentication
```bash
# Request OTP
curl -X POST http://localhost:3000/api/auth/request-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+919876543210"}'

# Response includes OTP in dev mode:
# {"message": "OTP sent successfully", "otp": "123456", ...}

# Verify OTP
curl -X POST http://localhost:3000/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+919876543210",
    "otp": "123456"
  }'

# Response: token, refreshToken, user object
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter + Dart, Riverpod, GoRouter, Hive/Isar |
| Backend | Node.js, Fastify, TypeScript |
| Database | PostgreSQL 16 (serverless: Neon), Redis 7 (serverless: Upstash) |
| Auth | Firebase Phone Auth + JWT |
| State Management | Riverpod (Flutter), PostgreSQL transactions |
| Deployment | Docker, Fly.io (backend), App Store/Play Store (mobile) |

## API Documentation

### Auth Endpoints

#### Request OTP
```
POST /api/auth/request-otp
Content-Type: application/json

{
  "phone": "+919876543210"  // International format
}

Response (200):
{
  "message": "OTP sent successfully",
  "requestId": "req_1234567890",
  "otp": "123456"  // Only in development
}
```

#### Verify OTP
```
POST /api/auth/verify-otp
Content-Type: application/json

{
  "phone": "+919876543210",
  "otp": "123456"
}

Response (200):
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

#### Update Profile
```
POST /api/auth/profile
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Ranga",
  "email": "ranga@example.com",  // Optional
  "examTarget": "UPSC",
  "state": "Tamil Nadu",
  "language": "en"  // Optional
}

Response (200):
{
  "message": "Profile updated successfully",
  "user": {...}  // Updated user object
}
```

#### Get Current User
```
GET /api/auth/me
Authorization: Bearer {token}

Response (200):
{
  "user": {
    "id": "uuid",
    "phone": "+919876543210",
    "name": "Ranga",
    "email": "ranga@example.com",
    "examTarget": "UPSC",
    "state": "Tamil Nadu",
    "coinsBalance": 0,
    "xp": 0,
    ...
  }
}
```

#### Refresh Token
```
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGc..."
}

Response (200):
{
  "token": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "expiresIn": "7d"
}
```

## Database Schema Highlights

### Users Table
- UUID primary key
- Phone-based authentication (unique, indexed)
- Coins & XP for gamification
- Exam target & state for personalization

### User Streaks
- Current/longest streak tracking
- Last activity date for reset logic
- 1-to-1 relationship with users

### Tests & Questions
- Hierarchical: Subject → Chapter → Questions
- Support for AI-generated questions (flagged in DB)
- Community rating system (helpful/flagged)

### Challenges
- Creator-participant model
- Prize pool funding from entry fees
- Status workflow: draft → active → closed → distributed

### Feed Posts
- Polymorphic posts (test, challenge, achievement, result share)
- Like/comment support
- Indexed on timestamp for feed ordering

### Wallet Transactions
- Atomic operations with transaction blocks
- Balance enforcement (prevent overspend)
- Detailed type & reference tracking

## Environment Variables

### Backend (.env)
```
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/kanavumeipada
REDIS_URL=redis://localhost:6379
JWT_SECRET=dev-secret-change-in-production
FIREBASE_PROJECT_ID=kanavumeipada
```

### Flutter (.env)
```
FLUTTER_ENV=development
API_BASE_URL=http://localhost:3000/api
FIREBASE_PROJECT_ID=kanavumeipada
```

## Testing

### Backend Health
```bash
curl http://localhost:3000/health
# Response: {"status": "ok", "database": "connected", ...}
```

### Flutter Tests
```bash
# Unit tests
flutter test

# Integration tests (requires running app)
flutter drive --target=test_driver/app.dart
```

## Security Checklist

- [x] JWT token-based authentication
- [x] Password-less (OTP) login
- [x] HTTP-only tokens (handled by client)
- [x] Parameterized SQL queries (SQL injection prevention)
- [x] CORS configured
- [x] Input validation (Zod schemas)
- [ ] Rate limiting on OTP requests (TODO)
- [ ] Razorpay webhook signature verification (TODO)
- [ ] Wallet race condition testing (TODO)

## Performance Targets

| Operation | Target | Status |
|-----------|--------|--------|
| Phone OTP request | <500ms | ✅ |
| OTP verification | <500ms | ✅ |
| Load feed (10 posts) | <800ms | Pending |
| Submit test answer | <300ms | Pending |
| Generate 10 questions (AI) | 8–12s | Pending |

## What's Next (Phase 2)

- [ ] Community Feed backend (posts, likes, comments)
- [ ] Feed UI with real-time post cards
- [ ] Content module (chapters, offline reader)
- [ ] Basic test engine (MCQ cards, timer, results)
- [ ] On-device AI question generation (Gemma 2B)
- [ ] Streak tracking synchronization

## Contributing

Refer to [PLAN.md](PLAN.md) for architecture decisions and [SETUP.md](SETUP.md) for development workflow.

## License

MIT

## Contact

For questions or feedback, reach out to [your-email].

---

**Last Updated:** July 1, 2026 — Phase 1 Complete ✅
