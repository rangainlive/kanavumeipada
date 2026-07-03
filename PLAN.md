# KanavuMeipada — Competitive Exam Prep Mobile App
## Full Product & Engineering Plan

---

## Context

A mobile application for competitive exam aspirants that combines AI-powered test generation,
gamified daily streaks, and a peer-challenge economy. Students upload or select chapter content;
on-device AI generates fresh MCQs every session so the same content never grows stale.
A "Challenge Arena" lets any user monetize their knowledge by publishing paid tests — creator
earnings scale with participation volume and community rating, aligning creator incentives with
question quality.

---

## 1. Product Vision

| Pillar | Description |
|---|---|
| Learn | Chapter-based study with AI-generated MCQs |
| Streak | Daily gamified practice to build habits |
| Compete | Peer challenges with wallet-based entry fees and prize pools |
| Social | Community feed to share results, challenges, and achievements |

Target users: Students preparing for UPSC, TNPSC, SSC, Banking (PO/Clerk), NEET, JEE, etc.
Primary market: India (Tamil Nadu regional focus first, then pan-India).

---

## 2. Tech Stack

### Mobile App
- **Flutter** (Dart) — single codebase for Android + iOS, best performance for quiz/game UIs
- **Riverpod** — state management (async, testable)
- **Hive + Isar** — local offline storage (chapters, cached questions, streak data)
- **go_router** — declarative navigation

### On-Device AI (Question Generation)
- **Google MediaPipe LLM Inference API** with **Gemma 2B** (runs entirely on-device, no API cost)
- Fallback: **llama.cpp** via Flutter FFI with **Phi-3 Mini 4K** (3.8B, INT4 quantized ~2GB)
- Input: chapter text (max ~2000 tokens); Output: structured JSON with question + 4 options + correct index
- Prompt engineering layer handles subject-specific formatting (science vs. history vs. math)

### Backend
- **Node.js + Fastify** — REST API (faster than Express, schema-first)
- **Neon PostgreSQL** — serverless relational DB (auto-scales, upgrade-button scaling)
- **Upstash Redis** — serverless leaderboard sorted sets, session cache, rate limiting
- **Socket.io** — real-time live challenge scoreboards
- **BullMQ** — background jobs (prize distribution, streak resets, AI moderation queue)
- **Firebase** — push notifications (FCM), Google/Apple SSO

### Infrastructure
- **Docker + Docker Compose** for local dev
- **Fly.io** — cloud deploy (multi-region, auto-scale, single `fly deploy` command)
- **Cloudflare R2** — chapter content (PDF/text) and image storage (no egress fees)
- **Cloudflare CDN** — free global edge cache

### Payment / Wallet
- **Razorpay** — Indian UPI, cards, net banking for wallet top-up
- Virtual coin system (₹1 = 10 coins internally) — decouples display from actual currency

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                        │
│  ┌──────────┐  ┌───────────┐  ┌──────────────────┐  │
│  │  Feed    │  │  Test     │  │  Challenge       │  │
│  │ (Home)   │  │  Engine   │  │  Arena           │  │
│  └────┬─────┘  └─────┬─────┘  └────────┬─────────┘  │
│       │              │                  │             │
│  ┌────▼──────────────▼──────────────────▼──────────┐ │
│  │          On-Device AI (Gemma 2B)                │ │
│  │          Question Generator                     │ │
│  └─────────────────────────────────────────────────┘ │
│       │              │                  │             │
│  ┌────▼──────────────▼──────────────────▼──────────┐ │
│  │          Local Cache (Hive/Isar)                │ │
│  └─────────────────────────────────────────────────┘ │
└──────────────────────┬──────────────────────────────┘
                       │ HTTPS REST + WebSocket
┌──────────────────────▼──────────────────────────────┐
│              Node.js + Fastify (Fly.io)              │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │  Auth    │  │  Test    │  │  Wallet &        │   │
│  │  Service │  │  Service │  │  Challenge Svc   │   │
│  └────┬─────┘  └────┬─────┘  └────────┬─────────┘   │
│  ┌────▼─────────────▼──────────────────▼──────────┐  │
│  │  Neon PostgreSQL │ Upstash Redis │ BullMQ Jobs  │  │
│  └────────────────────────────────────────────────┘  │
│              Cloudflare R2 (Storage)                 │
└─────────────────────────────────────────────────────┘
```

---

## 4. Database Schema (PostgreSQL)

```sql
-- Users & Auth
users (id, phone, email, name, avatar_url, coins_balance, xp, created_at)
user_streaks (user_id, current_streak, longest_streak, last_activity_date)
user_follows (follower_id, followee_id, created_at)

-- Content
subjects (id, name, icon, exam_category)
chapters (id, subject_id, title, order_index, content_text, content_url)

-- AI-Generated Questions
questions (id, chapter_id, text, difficulty, source, created_by_user_id, ai_generated, approved)
options (id, question_id, text, is_correct)
question_ratings (question_id, user_id, helpful, flagged)

-- Tests & Attempts
tests (id, chapter_id, creator_id, type[practice|challenge|daily|official], time_limit_sec,
       question_count, title, description, published_at, target_exam, target_state)
test_questions (test_id, question_id, position)
test_attempts (id, test_id, user_id, started_at, completed_at, score, total_questions)
attempt_answers (attempt_id, question_id, selected_option_id, time_taken_ms, correct)

-- Challenge Arena
challenges (id, test_id, creator_id, entry_fee_coins, prize_pool_coins, max_participants,
            start_at, end_at, status[draft|active|closed|distributed])
challenge_participants (challenge_id, user_id, attempt_id, rank, prize_won_coins, joined_at)

-- Wallet
wallet_transactions (id, user_id, type[topup|entry_fee|prize|creator_reward|platform_fee|refund],
                     amount_coins, reference_id, created_at)
payment_orders (id, user_id, razorpay_order_id, amount_inr, status, created_at)

-- Community Feed
feed_posts (id, user_id, post_type, ref_id, ref_type[test|challenge|achievement],
            body_text, created_at, likes_count, comments_count)
post_likes (post_id, user_id, created_at)
post_comments (id, post_id, user_id, text, created_at)

-- Achievements
achievements (id, key, name, description, icon, xp_reward, coins_reward)
user_achievements (user_id, achievement_id, unlocked_at)
```

---

## 5. Module-by-Module Plan

### 5.1 Authentication
- Phone OTP via Firebase Auth (primary — covers users without email)
- Google SSO (secondary)
- JWT issued by backend after Firebase token verification
- Profile setup: name, exam target, state, language preference

### 5.2 Content Module
- **Subject → Chapter** tree displayed as cards
- Chapter detail screen: scrollable text reader + "Generate Test" FAB
- Admin/creator upload: paste text OR upload PDF (extracted server-side via `pdf-parse`)
- Chapters stored in Cloudflare R2; text content cached locally in Hive for offline use
- Community can contribute chapters (moderation queue before publish)

### 5.3 On-Device AI Question Generator

**Flow:**
1. User taps "Generate Test" on a chapter
2. App extracts chapter text from local cache
3. Feeds it to Gemma 2B with structured prompt:
   ```
   You are an MCQ question generator for competitive exams.
   Given the following chapter text, generate {N} multiple choice questions.
   Each question must have exactly 4 options. Mark the correct one.
   Output as JSON array: [{question, options:[{text,correct}], difficulty}]

   Chapter text: {chapter_text}
   ```
4. Parse JSON response; validate (4 options, exactly 1 correct)
5. Display questions immediately for practice OR submit to server for challenge use
6. Server-side: generated questions flagged as `ai_generated=true`, pending community rating

**Fallback:** If device can't run Gemma 2B (low RAM), call backend which runs same model server-side.

**Difficulty tagging:** Second AI pass on same model — given question text, rate difficulty 1–5.

### 5.4 Test Engine
- Question card with 4 option tiles
- Timer (circular countdown), skip/flag for review
- Submit → Results screen: score, correct/wrong breakdown, time per question
- Explanation panel (AI-generated explanation for wrong answers, lazy-loaded)
- Performance chart: accuracy by topic over time

### 5.5 Daily Streak System

**Rules:**
- Complete ≥1 test per day → streak +1
- Miss a day → streak resets to 0
- Streak shields (earned via XP): protect against 1 missed day/week

**Milestones:**
- 7 days → 50 coins
- 30 days → 300 coins + badge
- 100 days → 1,000 coins + exclusive avatar frame

**Gamification layer:**
- XP earned per test (score-weighted), Level system (1–100)
- Daily challenge: server auto-generates themed MCQ set at midnight — bonus XP for first 500 completions

### 5.6 Challenge Arena

**Creator Flow:**
1. Select subject + chapter → Generate question set (AI or pick from bank, min 5 questions)
2. Set: entry fee (10–10,000 coins), time limit, max participants (optional cap), duration (1h–7 days)
3. Preview → Publish → Share link/code → Auto-post to community feed

**Participant Flow:**
1. Browse challenge in community feed OR enter challenge code
2. See: creator name, chapter, entry fee, current participants, prize pool, deadline
3. Pay entry fee → coins deducted → attempt test once (re-attempts not allowed)
4. Live leaderboard visible after submission (Socket.io real-time)

**Prize Distribution (runs automatically when challenge closes):**
```
Total Pool = entry_fee × participant_count

Platform cut        = 15% of Total Pool
Creator reward      = 10% + rating_bonus (up to 5%) of Total Pool
                      rating_bonus = avg_test_rating × 1%  (5-star avg → +5%)
Participant prizes  = remaining 70–75%

Prize tiers:
  Rank 1   → 40% of participant_prizes
  Rank 2   → 25%
  Rank 3   → 15%
  Rank 4–10 → split remaining 20% equally
```

**Refund rule:** If a challenge gets <3 participants at close time → full refund to all, no creator reward (prevents fake-account farming).

### 5.7 Wallet System
- Coins balance displayed in app header at all times
- Top-up flow: select pack → Razorpay checkout → webhook confirms → coins credited
- Transaction history with type filters
- Withdrawal: NOT supported in v1 (coins are one-way, spendable only in-app — avoids RBI regulations)
- Anti-fraud: rate limiting on challenge creation, BullMQ background job flags suspicious patterns

### 5.8 Community Feed (Social Wall — Default Home Screen)

A Facebook-style scrollable timeline as the first screen after login.

**What appears in the feed:**

| Post Type | Who Creates | What it Shows |
|---|---|---|
| Official Test | Admin | "New Mock Test: Indian History Ch.5 — Take it now" + CTA |
| Challenge | Any user | "Ranga created a ₹50 challenge on Polity — 12 joined" + Join |
| Result Share | Any user | "Anita scored 95% on Constitution Basics — Beat her!" |
| Achievement | System (auto) | "Priya hit a 30-day streak" |
| Leaderboard Post | System (weekly) | "This week's top scorer in TNPSC: Karthik" |

**Feed mechanics:**
- Chronological by default; engagement-ranked feed as optional toggle
- Like / React (fire emoji for streaks, trophy for high scores, etc.)
- Comment on posts (text, max 280 chars; no nested replies in v1)
- Share post: generates deep link → WhatsApp/Telegram share sheet
- "Join Challenge" / "Take Test" CTA embedded directly in the post card
- Two tabs: **Following** (people you follow) and **Global** (everyone)

**Auto-post triggers:**
- Admin publishes official test → auto-post to global feed
- User publishes a challenge → auto-post to their followers' feed + global
- User taps "Share my score" on results screen → post to feed

### 5.9 Admin Panel (Web — React + Tailwind)

**Test Creator:**
- Admin picks subject → chapter → hand-picks or AI-generates questions
- Sets metadata: title, description, time limit, difficulty, exam category
- Publishes as **Official Test** (free for all users, no entry fee)
- Schedules publish date/time (e.g., weekly mock exam every Sunday)
- Targets audience: all users, specific exam category, or specific state

**Official Test vs User Challenge:**

| | Official Test (Admin) | User Challenge |
|---|---|---|
| Created by | Admin | Any user |
| Entry fee | Free | Coins |
| Availability | Pushed to all/targeted users | Browse feed or invite code |
| Prize | XP + coins (admin-funded) | Prize pool from entry fees |
| Badge | Gold "Official" badge | None |
| Frequency | Scheduled | Anytime |

**Other admin tools:**
- Approve/reject community-submitted chapters and questions
- View flagged questions (community reports)
- Monitor wallet transactions, refund disputes
- Ban/suspend users, view audit logs

---

## 6. Folder Structure

```
kanavumeipada/
├── app/                          # Flutter mobile app
│   ├── lib/
│   │   ├── core/                 # theme, router, DI, constants
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── feed/             # social wall, post cards, like/comment
│   │   │   ├── content/          # subjects, chapters, reader
│   │   │   ├── test_engine/      # MCQ UI, timer, results
│   │   │   ├── ai_generator/     # MediaPipe/llama.cpp wrapper
│   │   │   ├── streak/           # streak logic, achievements
│   │   │   ├── challenge/        # arena, create, participate
│   │   │   └── wallet/           # balance, top-up, history
│   │   └── shared/               # widgets, utils, models
│   └── test/
├── backend/                      # Node.js + Fastify API
│   ├── src/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── jobs/                 # BullMQ workers
│   │   ├── db/                   # migrations, seed, queries
│   │   └── middleware/
│   └── Dockerfile
├── admin/                        # React admin panel
└── docker-compose.yml
```

---

## 7. Phased Roadmap

### Phase 1 — Foundation (Weeks 1–6)
- [ ] Flutter project setup (folder structure, router, theme, DI)
- [ ] Backend: Fastify + Neon PostgreSQL schema + migrations
- [ ] Auth: Firebase phone OTP + JWT + profile setup screen
- [ ] Community Feed (Home screen): scrollable post wall, post cards, like/comment/share
- [ ] Feed auto-post on: admin test publish, user challenge publish, result share
- [ ] Follow system: Following tab vs. Global tab
- [ ] Content module: subjects tree, chapter reader, local Hive cache (offline)
- [ ] Basic test engine: static question set, timer, results screen
- [ ] Admin panel: test creator UI (pick chapter → add questions → publish as Official Test)
- [ ] Official Test broadcast: push notification + feed card when admin publishes
- [ ] Deep link sharing: tapping shared URL opens the test directly in-app
- [ ] Daily streak tracking (local + server sync)
- [ ] Streak milestone achievements

### Phase 2 — AI Integration (Weeks 7–10)
- [ ] Integrate MediaPipe LLM Inference (Gemma 2B) in Flutter
- [ ] Question generation prompt engineering + JSON parsing + validation
- [ ] Server-side fallback endpoint (same model, for low-end devices)
- [ ] Community question rating UI (thumbs up / report)
- [ ] AI explanation for wrong answers (lazy-loaded)
- [ ] Difficulty auto-tagging via second AI pass

### Phase 3 — Challenge Arena (Weeks 11–16)
- [ ] Challenge creation flow (question selection, fee/duration settings, publish)
- [ ] Wallet UI + Razorpay integration + coin pack tiers
- [ ] Challenge participation + single-attempt enforcement (DB-level lock)
- [ ] Live leaderboard via Socket.io (updates throttled to every 10 seconds)
- [ ] Prize distribution BullMQ job (runs at challenge close time)
- [ ] Creator earnings dashboard
- [ ] Anti-fraud: refund job for challenges with <3 participants

### Phase 4 — Polish & Launch (Weeks 17–20)
- [ ] Push notifications: FCM for streak reminders, challenge close alerts, prize distributed
- [ ] Onboarding flow: exam selection, state, language preference
- [ ] Admin panel: moderation queue, flagged content, wallet oversight
- [ ] Performance profiling: Dart DevTools + Gemma 2B memory benchmarks on mid-range device
- [ ] Security audit: JWT expiry, Razorpay webhook signature verification, wallet race conditions
- [ ] Google Play submission (Android first)
- [ ] App Store submission (iOS — requires Mac)

---

## 8. Key Technical Decisions & Risks

| Risk | Mitigation |
|---|---|
| Gemma 2B too slow on mid-range Android (Snapdragon 680) | INT4 quant gives ~2–3s per question; show spinner + pre-cache a batch; fallback to server |
| Wallet fraud (multi-account challenge farming) | Device fingerprint + phone OTP binding + refund rule for <3 participants |
| Question quality from AI | Community rating + admin moderation queue; auto-reject malformed or duplicate JSON |
| Real-money regulation (India / RBI) | Keep coins non-withdrawable initially; consult CA/lawyer before adding P2P payouts |
| Socket.io scale for live leaderboards | Redis pub/sub adapter on Upstash; push updates every 10s, not on every submission |
| Feed performance at 10K+ posts/day | Fanout-on-write for followed feeds; global feed via Redis sorted set — no SQL query |

---

## 9. Scalable Tech Stack — User-Growth Migration Path

Every upgrade is a dashboard button click or one CLI command — never a code rewrite.

### Infrastructure by User Count

| Users | Backend | Database | Cache | Storage | Monthly Cost (INR) |
|---|---|---|---|---|---|
| 0–1,000 | Railway (1 worker) | **Neon PostgreSQL** free tier | Upstash free | Cloudflare R2 free | **₹0–800** |
| 1K–10K | Railway (2 workers) | Neon Launch ($19/mo) | Upstash Pay-per-use | R2 (~$1/mo) | **₹2,000–4,500** |
| 10K–100K | **Fly.io** (multi-region) | Neon Scale ($69/mo) | Upstash Pro | R2 | **₹8,000–18,000** |
| 100K–1M | **AWS ECS + ALB** | **AWS Aurora Serverless v2** | **AWS ElastiCache** | R2 / S3 | **₹40,000–1,50,000** |
| 1M+ | Kubernetes (EKS) | Aurora + Read replicas | Redis Cluster | S3 + CloudFront | Custom |

**Why Neon PostgreSQL?**
- Serverless — scales to zero when idle (no idle cost during off-hours)
- Storage grows automatically — just click "Upgrade Plan", zero downtime
- DB branching — create a branch per feature branch, like Git for your database
- 100% standard PostgreSQL — no driver changes, no query changes, ever

**Why Fly.io at 10K+ users?**
- Runs containers in multiple regions — Chennai, Delhi, Mumbai users all get <50ms response
- Auto-scales workers on CPU/memory — pay only for what runs
- `fly scale count 4` to add workers; `fly regions add sin` to add Singapore — done

### Easy Upgrade Checklist

1. **DB storage full?** → Upgrade Neon plan in dashboard (zero downtime)
2. **Backend slow under load?** → `fly scale count 4` (add workers in 30 seconds)
3. **Redis slow?** → Upgrade Upstash tier (same connection string, no code change)
4. **Need multi-region?** → `fly regions add sin` (Singapore), `fly regions add bom` (Mumbai)
5. **At 100K users?** → `pg_dump` from Neon → import to AWS Aurora (standard PostgreSQL, works out of the box)

---

## 10. Monetization Roadmap

### Phase 1 — Launch Revenue (Months 1–6)

> **India pricing reality check:** Your users are mostly tier-2/tier-3 city students earning ₹0–15,000/month.
> Testbook charges ₹249–999/month; Adda247 ₹299–799/month. To beat them, you need to be cheaper
> AND offer something they don't (AI + real prize money back). The challenge economy makes
> spending feel like investing — users aren't just spending coins, they're competing to win them back.

**Coin Pack Pricing (India-first):**

| Pack | Price | Coins | Per coin |
|---|---|---|---|
| Starter | ₹10 | 120 coins | Low barrier — first-time buy |
| Value | ₹29 | 350 coins | Most popular |
| Pro | ₹49 | 650 coins | Best value |
| Power | ₹99 | 1,400 coins | Serious players |
| Champion | ₹199 | 3,000 coins | Top challengers |

> **Why ₹10 starter pack?** A ₹10 pack removes the first payment hesitation completely.
> Once a user has spent ₹10 and won ₹15 back, they'll buy the ₹29 pack next.
> UPI makes ₹10 payments painless — no friction.

**Challenge Entry Fee Range:**

| Challenge Type | Entry Fee | Prize Pool (at 10 players) | Feels like |
|---|---|---|---|
| Free practice | 0 coins | No prize | Just for fun |
| Micro | 20 coins (₹1.4) | 170 coins (₹12) | Chai money |
| Small | 50 coins (₹3.6) | 425 coins (₹30) | Low stakes |
| Standard | 100 coins (₹7) | 850 coins (₹60) | A movie ticket |
| Premium | 500 coins (₹36) | 4,250 coins (₹300) | Serious money |

> Starting at ₹1.4 entry means even a broke student can play. The prize feeling makes it sticky.
> At ₹7 entry fee, winning ₹60 back feels like a lottery win — very motivating.

| Stream | How | Estimate |
|---|---|---|
| Coin pack sales | Users buy coins to enter challenges | ₹30–60/paying user/month avg |
| Challenge platform cut | 15% of every challenge prize pool | Scales with challenge volume |
| **Target at 500 active users** | | **₹12,000–30,000/month** |

### Phase 2 — Premium Subscription (Months 4–8)

**"Scholar Pro" — ₹79/month or ₹599/year (₹50/month)**

> Priced 68% cheaper than Testbook, 74% cheaper than Adda247.
> Students can justify ₹79/month easily — that's 2 cups of chai per day.
> The annual ₹599 plan = ₹50/month — competes with no one on price.

| Feature | Free | Scholar Pro |
|---|---|---|
| AI question generation | 5/day | Unlimited |
| Ads between tests | Yes | No ads |
| Challenge creation | 1 active at a time | 5 active simultaneously |
| Analytics | Basic score | Full weak-area heatmap |
| Streak shield | 0/week | 2/week |
| Avatar frame | Default | Exclusive Pro frames |
| Official test early access | No | Yes (24hr early) |

Target: ₹79 × 500 Pro users = **₹39,500/month recurring**
Annual plan: ₹599 × 200 annual users = **₹1,19,800 upfront** (6-month equivalent)

### Phase 3 — Ad Revenue (Months 6–12)

> Free users see ads — but only between tests, never inside. This funds the free tier
> and makes Pro feel worth it. Indian AdMob RPM is low (₹30–80 per 1,000 impressions)
> so ads alone won't sustain you — treat it as supplemental, not primary.

- Google AdMob interstitial after every 3rd test (never inside tests)
- Native sponsored posts in the community feed (education brands — Doubt, Testbook, coaching institutes)
- At 5,000 DAU: **₹15,000–40,000/month** (realistic Indian RPM)

### Phase 4 — B2B: Coaching Institute Accounts (Months 9–18)

| Plan | Price | What They Get |
|---|---|---|
| Institute Starter | ₹2,999/month | 1 admin, 200 students, private branded tests |
| Institute Pro | ₹7,999/month | 3 admins, 1,000 students, analytics dashboard |
| Institute Enterprise | Custom | Unlimited, white-label app, API access |

Students join via institute code; institute admin sees per-student analytics.
Target: 10 institutes × ₹4,000 avg = **₹40,000/month B2B recurring**

### Phase 5 — Sponsored Tests & Partnerships (Months 12+)

| Stream | Revenue Model |
|---|---|
| Sponsored Official Test | Brand pays ₹5,000–20,000 to publish branded test in feed |
| Coaching brand partnership | Test appears in challenge feed with their logo — rev-share |
| Job portal referral | Partner with Naukri/LinkedIn — ₹50–200 per referred hire |
| Proctored certificate | Mock exam + shareable certificate for ₹199–499 |

### Phase 6 — White-Label SaaS (Months 18+)

License to other state PSC apps (Kerala PSC, Karnataka PSC, etc.):
- ₹50,000–1,50,000 one-time setup + ₹10,000–30,000/month SaaS fee
- ~2 days work to deploy a new branded instance

### Revenue Projection

| Month | Active Users | Monthly Revenue | Key Stream |
|---|---|---|---|
| 3 | 200 | ₹8,000–15,000 | Coins + challenges |
| 6 | 1,000 | ₹50,000–80,000 | + Pro subscription |
| 12 | 5,000 | ₹2,00,000–3,50,000 | + Ads + B2B |
| 18 | 20,000 | ₹8,00,000–15,00,000 | + Sponsorships + white-label |
| 24 | 50,000+ | ₹25,00,000+ | All streams mature |

---

## 11. Developer Cost Estimation (INR)

### One-Time Setup Costs

| Item | Cost | Notes |
|---|---|---|
| Google Play Developer account | ₹1,700 (~$25) | One-time, permanent |
| Apple Developer account | ₹8,200/year (~$99) | Only if shipping iOS |
| Domain name (`.com` or `.in`) | ₹800–1,500/year | Namecheap / GoDaddy |
| Mac for iOS builds | ₹60,000+ | Mac Mini M2; skip if Android-only first |
| Mac in Cloud (alternative) | ₹2,500/month | MacStadium / GitHub Actions macOS runner |
| **One-time total (Android-only launch)** | **~₹2,500–4,000** | |
| **One-time total (Android + iOS)** | **~₹70,000–75,000** | If buying Mac |

### Monthly Infrastructure Costs

#### Early Stage (0–500 users)

| Service | Free Tier | Paid Start | Notes |
|---|---|---|---|
| Fly.io (Node.js backend) | $5 free credit/month | ₹400–1,600/month | |
| Neon PostgreSQL | 512 MB free | ₹1,600/month (Launch plan) | |
| Upstash Redis | 10K cmd/day free | ₹0–400/month | |
| Cloudflare R2 | 10 GB free | ₹0–400/month | $0.015/GB after |
| Firebase Auth | 10K users free | ₹0 | |
| Firebase FCM (push) | Completely free | ₹0 | Always free |
| **Total at launch** | **₹0** | **₹2,000–4,000/month** | after free tiers |

#### Growth Stage (500–5,000 users)

| Service | Monthly Cost |
|---|---|
| Backend compute (2 Fly.io workers) | ₹1,600–3,200 |
| Neon PostgreSQL (Scale plan) | ₹4,000–6,000 |
| Upstash Redis | ₹400–800 |
| Cloudflare R2 (~50 GB) | ₹600 |
| **Total** | **₹6,600–10,600/month** |

### AI / ML Costs

| Approach | Cost | Notes |
|---|---|---|
| On-device Gemma 2B (MediaPipe) | **₹0 forever** | Runs on user's phone — recommended |
| Server-side fallback | Included in compute above | Only triggered for low-end phones |
| Cloud LLM API (avoid) | ₹8–80 per 1,000 questions | Too expensive at scale |

> On-device AI = zero marginal cost per question. This is the biggest cost advantage of the entire architecture.

### Payment / Transaction Costs

| Item | Cost |
|---|---|
| Razorpay per transaction | 2% + GST (~2.36%) of top-up amount |
| User buys ₹100 coin pack | You receive ₹97.64 |
| Monthly minimum | ₹0 (pay-as-you-go) |

### Development Tooling

All free: VS Code, Flutter SDK, Android Studio, Xcode (on Mac), GitHub (free private repos), Postman, Figma starter.

### Total Monthly Burn Summary

| Stage | Users | Monthly Cost | Note |
|---|---|---|---|
| Launch | 0–100 | **₹0** | Free tiers cover everything |
| Early growth | 100–500 | **₹2,000–4,000** | |
| Growth | 500–5,000 | **₹6,600–10,600** | |
| Scale | 5,000–20,000 | **₹20,000–40,000** | Upgrade DB + add workers |

### Break-Even Estimate (Revised — India Realistic Pricing)

**Conservative scenario (500 active users):**
- 30% buy a coin pack avg ₹29 = 150 users × ₹29 × 97.64% = **₹4,248**
- 10% on Scholar Pro ₹79 = 50 users × ₹79 = **₹3,950**
- Challenge platform cut (15% of pool) on 100 challenges/month × 10 users × 50 coins avg entry = **₹525**
- Monthly infra: ~**₹2,000–4,000**
- **Net at 500 users: ~₹4,000–6,000/month** ← small but covers infra + validates model

**Growth scenario (2,000 active users):**
- 35% buy packs avg ₹35 = 700 × ₹35 × 97.64% = **₹23,920**
- 15% Pro = 300 × ₹79 = **₹23,700**
- Ad revenue = **₹8,000–15,000**
- Challenge platform cuts = **₹10,000–20,000**
- Monthly infra: ~**₹5,000–8,000**
- **Net at 2,000 users: ~₹52,000–74,000/month** ← business becomes real

**Key insight:** The challenge economy is self-funding — users deposit coins, platform keeps 15%.
The platform earns even if nobody buys a Pro subscription. That's the unique strength of this model
vs. pure subscription apps like Testbook.

### If You Hire Help (Optional)

| Role | Cost |
|---|---|
| Flutter developer (freelance, India) | ₹500–1,500/hr or ₹40,000–80,000/month |
| Node.js backend developer | ₹400–1,200/hr or ₹35,000–70,000/month |
| UI/UX designer (Figma) | ₹15,000–40,000 for full design system |
| Full project outsourced to agency | ₹3,00,000–8,00,000 total |
| **Solo developer (you do everything)** | **₹0 salary + 4–5 months time** |

---

## 12. Verification Plan

- **Unit tests**: Question JSON parser, prize distribution formula, streak date logic
- **Integration tests**: Full flow — wallet deduct → test attempt → prize distribute (test DB)
- **AI output validation**: Automated test suite of 50 chapter samples; assert JSON validity, 4 options, 1 correct
- **Manual testing**: Android emulator (API 33) + real mid-range device (Snapdragon 680 target)
- **Load test**: k6 script simulating 100 concurrent challenge participants submitting at the same time
- **Security**: Razorpay webhook with invalid signatures must be rejected; wallet must not allow double-spend under concurrent requests
