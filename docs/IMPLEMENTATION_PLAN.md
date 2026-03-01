# 🚀 KRX STOCK ANALYSIS — IMPLEMENTATION PLAN
> **Version:** 2.0.0 (Granular)  
> **Ngày tạo:** 25/02/2026  
> **Tham chiếu:** requirement.txt, SYSTEM_DOCUMENTATION.md, APP_CLIENT_SPEC.md

---

## I. TỔNG QUAN PLAN

### 1.1 Mục tiêu cuối cùng
Hoàn thiện 3 sản phẩm:
1. **Flutter App Client** — iOS + Android
2. **Node.js Backend** — Shared API server + MongoDB
3. **MERN Web Admin** — Quản trị viên

### 1.2 Phương pháp tiếp cận

```
Hiện có (test/):
  ✅ KIS Open API — 10 endpoints (PRIMARY: price, chart, minute, investor, rankings, index)
  ✅ Yahoo Finance Direct API — 7 endpoints (FALLBACK: search, news, backup chart)
  ✅ Web Dashboard prototype (index.html) — TradingView-style, AbortController
  ✅ In-memory cache, timezone handling (KST), rate limiting, minute chart pagination
  ❌ Indicators trống → sẽ tự tính từ OHLCV data KIS

Cần làm:
  → Tách & nâng cấp Backend (MongoDB, Auth, WebSocket, tự tính indicators)
  → Migrate KIS service (token mgmt, throttle, pagination) + Yahoo fallback
  → Flutter App (8 màn hình + 4 tabs Stock Detail)
  → Web Admin (React — MERN)

⭐ Tham chiếu: test/server.js (~1100 dòng) + test/public/index.html (~1160 dòng)
   Xem chi tiết kỹ thuật: SYSTEM_DOCUMENTATION.md Section V
```

### 1.3 Chia thành 15 PHASE (chi tiết)

| Phase | Tên | Mô tả | Ước lượng |
|-------|-----|-------|-----------|
| **0** | Project Setup | Monorepo, config, env | 0.5 ngày |
| **1A** | DB & Models | MongoDB connection + 4 Mongoose models | 0.5 ngày |
| **1B** | Auth System | Register, Login, JWT, Google/Apple OAuth | 1 ngày |
| **1C** | KIS + Yahoo Service | Migrate KIS (primary) + Yahoo (fallback) → service classes | 1 ngày |
| **1D** | Self-Calc Indicators | RSI, MACD, Stoch, ATR, BB từ OHLCV | 1 ngày |
| **1E** | Stock API Routes | RESTful routes (search, quote, history, list, indicators) | 0.5 ngày |
| **2A** | WebSocket | Realtime price push (ws) | 0.5 ngày |
| **2B** | AI Integration | Gemini/OpenAI + credit system | 1 ngày |
| **2C** | User & Watchlist API | Profile CRUD, watchlist CRUD, email service | 0.5 ngày |
| **2D** | Admin API | User mgmt, config, logs endpoints | 0.5 ngày |
| **3A** | Flutter Init | Project, dependencies, theme, routes | 0.5 ngày |
| **3B** | Flutter Core | Models, providers, API client, WebSocket client | 1 ngày |
| **4A** | UI: Auth + Splash | Splash, Login, Register, Forgot screens | 0.5 ngày |
| **4B** | UI: Home + Search | Home (5 sections), Search, Stock List | 1.5 ngày |
| **4C** | UI: Stock Detail | ⭐ Chart tab (candle+indicators), Info, AI, News tabs | 2 ngày |
| **4D** | UI: Watchlist + Settings | Watchlist, Settings, Profile edit | 0.5 ngày |
| **5A** | Integration: Data | Connect screens → API (stocks, quotes, history) | 1 ngày |
| **5B** | Integration: Charts | Live OHLCV → charts, indicators rendering | 1.5 ngày |
| **5C** | Integration: User Features | Auth flow, Watchlist, AI, WebSocket realtime | 1 ngày |
| **6A** | Admin Setup | Vite + React + TailwindCSS + auth | 0.5 ngày |
| **6B** | Admin Pages | Users, Config, Logs, Dashboard, CSV export | 1.5 ngày |
| **7A** | Testing | Unit tests (indicators), integration tests (auth flow) | 1 ngày |
| **7B** | Polish & Deploy | Performance, push notifications, deploy | 1 ngày |
| | **TỔNG** | | **~19 ngày** |

### 1.4 Dependency Map

```
Phase 0 ─────────────────────────────────────────────────────
    │
    ├──► 1A (DB) ──► 1B (Auth) ──► 2C (User/Watchlist)
    │       │                          │
    │       │                    2D (Admin API) ──► 6A ──► 6B
    │       │
    ├──► 1C (KIS+Yahoo) ──► 1D (Indicators) ──► 1E (Routes)
    │                                          │
    │                                    2A (WebSocket)
    │                                          │
    │                                    2B (AI)
    │
    └──► 3A (Flutter Init) ──► 3B (Core)
                                  │
                            ┌─────┼─────────┐
                            │     │          │
                          4A    4B ──► 4C    4D
                            │     │    │     │
                            └─────┼────┘─────┘
                                  │
                            ┌─────┼─────┐
                            │     │     │
                          5A    5B    5C
                            │     │     │
                            └─────┼─────┘
                                  │
                            7A ──► 7B
```

**Parallel tracks:**
- **Backend track:** 0 → 1A → 1B → 1C (KIS+Yahoo) → 1D → 1E → 2A/2B/2C/2D
- **Flutter track:** 0 → 3A → 3B → 4A/4B/4C/4D → 5A/5B/5C
- **Admin track:** 2D → 6A → 6B (sau khi Backend APIs xong)
- **Phases 4A-4D** có thể làm song song (khác screen)
- **Phases 5A/5B/5C** có thể làm song song (khác feature)

---

## II. CẤU TRÚC THƯ MỤC CHÍNH THỨC

```
stock_AI_app/
├── docs/                           # Tài liệu
│   ├── requirement.txt
│   ├── SYSTEM_DOCUMENTATION.md
│   ├── APP_CLIENT_SPEC.md
│   └── IMPLEMENTATION_PLAN.md      # File này
│
├── backend/                        # Node.js Backend (Shared)
│   ├── package.json
│   ├── .env
│   ├── .env.example
│   ├── src/
│   │   ├── app.js                  # Express app setup
│   │   ├── server.js               # Entry point (HTTP + WebSocket)
│   │   ├── config/
│   │   │   ├── db.js               # MongoDB connection
│   │   │   ├── env.js              # Environment variables
│   │   │   └── cors.js             # CORS config
│   │   ├── models/                 # Mongoose models
│   │   │   ├── User.js
│   │   │   ├── Watchlist.js
│   │   │   ├── AIAnalysis.js
│   │   │   └── SystemLog.js
│   │   ├── routes/                 # Express routes
│   │   │   ├── auth.routes.js
│   │   │   ├── user.routes.js
│   │   │   ├── stocks.routes.js
│   │   │   ├── watchlist.routes.js
│   │   │   ├── ai.routes.js
│   │   │   ├── news.routes.js
│   │   │   └── admin.routes.js
│   │   ├── controllers/            # Route handlers
│   │   │   ├── auth.controller.js
│   │   │   ├── user.controller.js
│   │   │   ├── stocks.controller.js
│   │   │   ├── watchlist.controller.js
│   │   │   ├── ai.controller.js
│   │   │   ├── news.controller.js
│   │   │   └── admin.controller.js
│   │   ├── services/               # Business logic
│   │   │   ├── kis.service.js      # ⭐ KIS Open API (PRIMARY — từ test/server.js)
│   │   │   ├── yahoo.service.js    # Yahoo Finance API (FALLBACK — search, news)
│   │   │   ├── indicators.service.js  # Tự tính RSI/MACD/Stoch/ATR/BB từ KIS OHLCV
│   │   │   ├── ai.service.js       # Google Gemini / OpenAI
│   │   │   ├── cache.service.js    # In-memory + Redis (optional)
│   │   │   ├── email.service.js    # Gửi email xác thực
│   │   │   └── websocket.service.js # WebSocket handler
│   │   ├── middleware/
│   │   │   ├── auth.middleware.js   # JWT verify
│   │   │   ├── rateLimiter.js      # Rate limiting
│   │   │   ├── validate.js         # Input validation
│   │   │   └── errorHandler.js     # Global error handler
│   │   └── utils/
│   │       ├── indicators.js       # Pure math: RSI, MACD, Stoch, ATR, BB
│   │       ├── helpers.js          # Format, timezone, etc.
│   │       └── logger.js           # Winston / SystemLog
│   └── tests/                      # Jest tests
│
├── app/                            # Flutter App Client
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart                # MaterialApp + Theme + Router
│   │   ├── config/
│   │   │   ├── theme.dart          # Dark/Light theme
│   │   │   ├── constants.dart      # API URLs, colors, etc.
│   │   │   ├── routes.dart         # GoRouter config
│   │   │   └── env.dart            # Environment
│   │   ├── models/                 # Data models (freezed/json_serializable)
│   │   │   ├── user.dart
│   │   │   ├── stock.dart
│   │   │   ├── quote.dart
│   │   │   ├── ohlcv.dart
│   │   │   ├── indicator.dart
│   │   │   ├── ai_analysis.dart
│   │   │   ├── news.dart
│   │   │   └── watchlist_item.dart
│   │   ├── providers/              # Riverpod providers
│   │   │   ├── auth_provider.dart
│   │   │   ├── stock_provider.dart
│   │   │   ├── watchlist_provider.dart
│   │   │   ├── ai_provider.dart
│   │   │   ├── settings_provider.dart
│   │   │   └── websocket_provider.dart
│   │   ├── services/               # API clients
│   │   │   ├── api_client.dart     # Dio base config
│   │   │   ├── auth_service.dart
│   │   │   ├── stock_service.dart
│   │   │   ├── watchlist_service.dart
│   │   │   ├── ai_service.dart
│   │   │   └── websocket_service.dart
│   │   ├── screens/                # 8 màn hình
│   │   │   ├── splash/
│   │   │   │   └── splash_screen.dart
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   └── forgot_password_screen.dart
│   │   │   ├── home/
│   │   │   │   ├── home_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── market_status_widget.dart
│   │   │   │       ├── market_overview_widget.dart
│   │   │   │       ├── watchlist_preview_widget.dart
│   │   │   │       ├── top_movers_widget.dart
│   │   │   │       └── latest_news_widget.dart
│   │   │   ├── search/
│   │   │   │   └── search_screen.dart
│   │   │   ├── stock_list/
│   │   │   │   ├── stock_list_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       └── stock_list_item.dart
│   │   │   ├── stock_detail/
│   │   │   │   ├── stock_detail_screen.dart
│   │   │   │   └── tabs/
│   │   │   │       ├── chart_tab.dart          # ⭐ Main
│   │   │   │       ├── info_tab.dart
│   │   │   │       ├── ai_tab.dart
│   │   │   │       └── news_tab.dart
│   │   │   ├── watchlist/
│   │   │   │   └── watchlist_screen.dart
│   │   │   └── settings/
│   │   │       ├── settings_screen.dart
│   │   │       └── profile_edit_screen.dart
│   │   └── widgets/                # Shared widgets
│   │       ├── stock_card.dart
│   │       ├── price_text.dart
│   │       ├── sparkline_chart.dart
│   │       ├── candlestick_chart.dart  # Custom chart widget
│   │       ├── indicator_chart.dart
│   │       ├── shimmer_loading.dart
│   │       ├── error_widget.dart
│   │       ├── empty_state.dart
│   │       └── bottom_nav_bar.dart
│   ├── assets/
│   │   ├── images/
│   │   └── fonts/
│   └── test/
│
├── admin/                          # MERN Web Admin
│   ├── package.json
│   ├── src/
│   │   ├── App.jsx
│   │   ├── main.jsx
│   │   ├── api/                    # Axios instances
│   │   ├── components/             # React components
│   │   ├── pages/                  # Admin pages
│   │   │   ├── LoginPage.jsx
│   │   │   ├── DashboardPage.jsx
│   │   │   ├── UsersPage.jsx
│   │   │   ├── UserDetailPage.jsx
│   │   │   ├── ConfigPage.jsx
│   │   │   └── LogsPage.jsx
│   │   ├── hooks/
│   │   └── utils/
│   └── vite.config.js
│
└── test/                           # Giữ lại test prototype (reference)
    ├── server.js
    ├── public/index.html
    └── ...
```

---

## III. PHASE 0 — PROJECT SETUP (1 ngày)

### Task 0.1: Khởi tạo monorepo structure

```bash
# Tạo cấu trúc chính
mkdir -p backend/src/{config,models,routes,controllers,services,middleware,utils}
mkdir -p backend/tests
mkdir -p app/  # Flutter project
mkdir -p admin/src/{api,components,pages,hooks,utils}
mkdir -p docs/
```

### Task 0.2: Backend package.json & dependencies

```json
{
  "name": "krx-stock-backend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "nodemon src/server.js",
    "start": "node src/server.js",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.21.0",
    "mongoose": "^8.0.0",
    "axios": "^1.7.0",
    "cors": "^2.8.5",
    "dotenv": "^16.4.0",
    "jsonwebtoken": "^9.0.0",
    "bcryptjs": "^2.4.3",
    "express-rate-limit": "^7.0.0",
    "express-validator": "^7.0.0",
    "ws": "^8.16.0",
    "nodemailer": "^6.9.0",
    "multer": "^1.4.5-lts.1",
    "winston": "^3.11.0",
    "@google/generative-ai": "^0.21.0",
    "openai": "^4.0.0",
    "google-auth-library": "^9.0.0",
    "helmet": "^7.1.0",
    "compression": "^1.7.4"
  },
  "devDependencies": {
    "nodemon": "^3.0.0",
    "jest": "^29.0.0"
  }
}
```

### Task 0.3: Backend .env

```env
# Server
PORT=5000
NODE_ENV=development

# MongoDB
MONGODB_URI=mongodb://localhost:27017/krx_stock

# JWT
JWT_SECRET=your_super_secret_jwt_key_change_me
JWT_REFRESH_SECRET=your_refresh_secret_key_change_me
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# KIS Open API (PRIMARY)
KIS_APP_KEY=PSsw5JXblDis6LZJ1tSqMbLwUQFOqQLlopQR
KIS_APP_SECRET=your_160char_secret_here
KIS_BASE_URL=https://openapi.koreainvestment.com:9443

# Yahoo Finance (FALLBACK — no key needed, direct API)
# Just use User-Agent header for Yahoo requests

# Alpha Vantage (deprecated — self-calc from KIS OHLCV)
ALPHA_VANTAGE_KEY=demo

# Google Gemini AI
GEMINI_API_KEY=your_gemini_key

# OpenAI (backup)
OPENAI_API_KEY=your_openai_key

# Email (SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Frontend URLs (CORS)
APP_URL=http://localhost:3000
ADMIN_URL=http://localhost:5173
```

### Task 0.4: Di chuyển docs

```bash
# Move docs vào thư mục docs/
mv requirement.txt docs/
mv SYSTEM_DOCUMENTATION.md docs/
mv APP_CLIENT_SPEC.md docs/
mv IMPLEMENTATION_PLAN.md docs/
```

### Task 0.5: Flutter project init

```bash
flutter create --org com.krxstock --project-name krx_stock_app app
cd app
# Add dependencies to pubspec.yaml (xem Phase 3)
```

### Task 0.6: Admin project init

```bash
cd admin
npm create vite@latest . -- --template react
# Thêm dependencies (xem Phase 6)
```

### ✅ Deliverables Phase 0:
- [x] Monorepo structure đầy đủ
- [x] Backend package.json + .env
- [x] Flutter project initialized
- [x] Admin project initialized
- [x] Docs organized

---

## IV. PHASE 1 — BACKEND CORE (3–4 ngày)

> **Mục tiêu:** Xây dựng backend chính thức với MongoDB, authentication, **KIS Open API service (primary)** + Yahoo Finance (fallback) — reuse từ test/, và **tự tính indicators từ KIS OHLCV data**.

---

### Task 1.1: MongoDB Connection & Models (0.5 ngày)

#### 1.1.1 `config/db.js` — Mongoose connection

```javascript
// mongoose.connect(MONGODB_URI), retry logic, event listeners
```

#### 1.1.2 Mongoose Models (4 models)

| Model | File | Fields chính | Indexes |
|-------|------|-------------|---------|
| **User** | `models/User.js` | email, passwordHash, name, avatar, provider, subscription, settings, isBlocked | `email` (unique) |
| **Watchlist** | `models/Watchlist.js` | userId, symbol, name, order, addedAt | `userId + symbol` (compound unique) |
| **AIAnalysis** | `models/AIAnalysis.js` | userId, symbol, level, model, analysis, inputData, creditsUsed | `userId`, `createdAt` |
| **SystemLog** | `models/SystemLog.js` | level, source, message, stack, meta, userId | `createdAt` (TTL 14 days) |

---

### Task 1.2: Authentication System (1 ngày)

#### 1.2.1 Routes & Controllers

| Endpoint | Logic |
|----------|-------|
| `POST /api/auth/register` | Validate → hash password → create User → send verification email → return success |
| `POST /api/auth/login` | Find user → compare password → check blocked → generate JWT pair → return tokens |
| `POST /api/auth/google` | Verify Google ID token → find/create user → generate JWT pair |
| `POST /api/auth/apple` | Verify Apple token → find/create user → generate JWT pair |
| `POST /api/auth/forgot-password` | Find user → generate reset token → send email |
| `POST /api/auth/reset-password` | Verify reset token → hash new password → update |
| `POST /api/auth/verify-email` | Verify token → set emailVerified=true |
| `POST /api/auth/refresh-token` | Verify refresh token → generate new JWT pair |

#### 1.2.2 Middleware

```javascript
// auth.middleware.js
// 1. Extract Bearer token from header
// 2. Verify JWT
// 3. Find user from DB (hoặc cache)
// 4. Check isBlocked
// 5. Attach user to req.user
// 6. Optional: requireAdmin middleware
```

#### 1.2.3 JWT Strategy

```
Access Token:  15 min TTL, chứa { userId, email, role, plan }
Refresh Token: 7 day TTL, chứa { userId }
Storage (App): flutter_secure_storage (Keychain/Keystore)
Refresh flow:  Access expired → auto call /refresh-token → retry original request
```

---

### Task 1.3: KIS + Yahoo Service — Migrate & Upgrade (1 ngày)

> **Tái sử dụng** logic từ `test/server.js` → tách thành `services/kis.service.js` (primary) + `services/yahoo.service.js` (fallback)
> 
> ⭐ **Tham chiếu:** `test/server.js` dòng 20-940 — tất cả KIS endpoints đã test ổn định
> Xem chi tiết kỹ thuật: `SYSTEM_DOCUMENTATION.md` Section V (Kỹ thuật đã triển khai)

#### 1.3.1 `services/kis.service.js` ⭐ PRIMARY

```javascript
// Migrate từ test/server.js (dòng 20-940):
class KISService {
  constructor(cacheService) {
    this.token = null;          // { token, expiresAt } — auto refresh 1h trước hạn
    this.lastCallTime = 0;      // Global throttle 300ms
  }
  
  // Token management (test/server.js dòng 30-56)
  async getToken()                       // OAuth2 tokenP, cache 24h, rate limit 1/min
  async kisThrottle()                    // 300ms giữa requests (dòng 61-67)
  
  // 10 KIS endpoints (PRIMARY data source)
  async getPrice(code)                   // FHKST01010100 — giá + PER/PBR/52w (30s cache)
  async getDailyChart(code, period, start, end)  // FHKST03010100 — OHLCV D/W/M (5m cache)
  async getMinuteChart(code)             // FHKST03010200 — OHLCV phút, PAGINATED (60s cache)
  async getTrades(code)                  // FHKST01010300 — khớp lệnh (15s cache)
  async getRankingFluctuation(type)      // FHPST01700000 — top tăng/giảm (60s cache)
  async getRankingVolume()               // FHPST01710000 — top khối lượng (60s cache)
  async getInvestor(code)                // FHKST01010900 — investor flow (5m cache)
  async getIndex(code)                   // FHPUP02100000 — KOSPI/KOSDAQ (30s cache)
  async getMarketOverview()              // Batch 8 stocks (2m cache)
  async healthCheck()                    // Token + connectivity check
  
  // Pagination helper (test/server.js dòng 553-665)
  async _fetchMinutePages(code, startTime, maxPages=6)  // 500ms delay, retry, dedupe
}
```

> **Kỹ thuật quan trọng khi migrate KIS:**
> - Token rate limit: 1/phút → cache token, refresh 1h trước hạn
> - Global throttle: ≥300ms giữa requests
> - Minute chart pagination: 500ms delay giữa pages, retry 1x on 500, graceful partial data
> - Symbol format: Chỉ dùng mã 6 số (005930), KHÔNG dùng .KS/.KQ
> - Param bắt buộc: `FID_PW_DATA_INCU_YN: 'N'` cho minute chart
> - Field names investor: `prsn_ntby_qty`, `frgn_ntby_qty`, `orgn_ntby_qty`

#### 1.3.2 `services/yahoo.service.js` (FALLBACK)

```javascript
// Migrate từ test/server.js (dòng 95-440):
class YahooService {
  constructor(cacheService) { ... }
  
  async search(query)                    // → KIS không có search → Yahoo bắt buộc
  async getNews(symbol)                  // → KIS không có news → Yahoo bắt buộc
  async getHistory(symbol, period)       // → Fallback chart khi KIS lỗi (delay 15-20 phút)
  async getQuote(symbol)                 // → Fallback price khi KIS lỗi
  async getMarketOverview()              // → Fallback market overview
}
```

#### 1.3.3 `services/cache.service.js`

```javascript
// Migrate cache từ test/server.js (dòng 78-86) → class-based
class CacheService {
  get(key, ttlMs)
  set(key, data)
  invalidate(key)
  clear()
  // Future: upgrade to Redis
}
```

#### 1.3.4 Stocks Routes (mới) — KIS Primary + Yahoo Fallback

| Endpoint cũ (test) | Endpoint mới | Nguồn | Thay đổi |
| `/api/kis/price/:symbol` | `/api/stocks/:symbol/quote` | **KIS** (primary) | RESTful, 30s cache |
| `/api/kis/chart/:symbol` | `/api/stocks/:symbol/history?period=` | **KIS** D/W/M | RESTful, 5m cache |
| `/api/kis/minutechart/:symbol` | `/api/stocks/:symbol/history?period=1d` | **KIS** minute | Paginated, 60s cache |
| `/api/kis/trades/:symbol` | `/api/stocks/:symbol/trades` | **KIS** | 15s cache |
| `/api/kis/investor/:symbol` | `/api/stocks/:symbol/investor` | **KIS** exclusive | 5m cache |
| `/api/kis/ranking/fluctuation` | `/api/stocks/top-movers` | **KIS** | 60s cache |
| `/api/kis/ranking/volume` | `/api/stocks/top-volume` | **KIS** | 60s cache |
| `/api/kis/index` | `/api/stocks/index` | **KIS** | 30s cache |
| `/api/kis/market` | `/api/stocks/market-overview` | **KIS** batch | 2m cache |
| `/api/yahoo/search` | `/api/stocks/search?q=` | **Yahoo** (KIS không có) | Rename |
| `/api/yahoo/news/:symbol` | `/api/stocks/:symbol/news` | **Yahoo** (KIS không có) | RESTful |
| — (NEW) | `/api/stocks/list?market=&sort=&page=` | **KIS** rankings | Phân trang |
| — (NEW) | `/api/stocks/:symbol/indicators` | **Self-calc từ KIS OHLCV** | Tự tính |

---

### Task 1.4: ⭐ TỰ TÍNH INDICATORS (1 ngày) — Critical

> **Đây là task quan trọng nhất** — Loại bỏ phụ thuộc Alpha Vantage, tự tính RSI/MACD/Stochastic/ATR/Bollinger Bands từ **OHLCV data KIS** (daily chart endpoint `FHKST03010100`).

#### 1.4.1 `utils/indicators.js` — Pure Math Functions

```javascript
/**
 * Pure calculation functions — không phụ thuộc API
 * Input: mảng OHLCV từ Yahoo Finance
 * Output: mảng giá trị indicators
 */

// ─── RSI (Relative Strength Index) ───────────────────
export function calcRSI(closes, period = 14) {
  // 1. Tính price changes: changes[i] = closes[i] - closes[i-1]
  // 2. Tách gains (positive) và losses (negative)
  // 3. First avg gain/loss = SMA(gains/losses, period)
  // 4. Subsequent: (prev_avg * (period-1) + current) / period  (Wilder smoothing)
  // 5. RS = avgGain / avgLoss
  // 6. RSI = 100 - (100 / (1 + RS))
  // Return: [{ time, value: rsi_value }, ...]
}

// ─── EMA (Exponential Moving Average) ────────────────
export function calcEMA(data, period) {
  // multiplier = 2 / (period + 1)
  // EMA[0] = SMA(data, period) — seed
  // EMA[i] = (data[i] - EMA[i-1]) * multiplier + EMA[i-1]
}

// ─── MACD (Moving Average Convergence Divergence) ────
export function calcMACD(closes, fastPeriod = 12, slowPeriod = 26, signalPeriod = 9) {
  // 1. EMA_fast = EMA(closes, 12)
  // 2. EMA_slow = EMA(closes, 26)
  // 3. MACD_line = EMA_fast - EMA_slow
  // 4. Signal_line = EMA(MACD_line, 9)
  // 5. Histogram = MACD_line - Signal_line
  // Return: [{ time, macd, signal, histogram }, ...]
}

// ─── Stochastic Oscillator ───────────────────────────
export function calcStochastic(highs, lows, closes, kPeriod = 5, kSmooth = 3, dPeriod = 3) {
  // 1. %K_raw = (close - lowest_low(kPeriod)) / (highest_high(kPeriod) - lowest_low(kPeriod)) * 100
  // 2. %K = SMA(%K_raw, kSmooth)
  // 3. %D = SMA(%K, dPeriod)
  // Return: [{ time, k, d }, ...]
}

// ─── ATR (Average True Range) ────────────────────────
export function calcATR(highs, lows, closes, period = 14) {
  // TR = max(high-low, |high-prevClose|, |low-prevClose|)
  // ATR = Wilder smoothing of TR over period
  // Return: [{ time, value: atr_value }, ...]
}

// ─── Bollinger Bands ─────────────────────────────────
export function calcBollingerBands(closes, period = 20, stdDev = 2) {
  // Middle = SMA(closes, period)
  // StdDev = sqrt(sum((close - mean)^2) / period)
  // Upper = Middle + stdDev * StdDev
  // Lower = Middle - stdDev * StdDev
  // Return: [{ time, upper, middle, lower }, ...]
}

// ─── SMA (Simple Moving Average) ─────────────────────
export function calcSMA(data, period) {
  // Simple sliding window average
  // Return: [{ time, value }, ...]
}
```

#### 1.4.2 `services/indicators.service.js`

```javascript
class IndicatorsService {
  constructor(yahooService, cacheService) { ... }
  
  async getIndicators(symbol) {
    // 1. Lấy 200+ ngày OHLCV từ KIS daily chart (enough for MA120 + MACD warmup)
    //    → kisService.getDailyChart(code, 'D', startDate, endDate)
    //    Fallback: yahooService.getHistory(symbol, '1y') nếu KIS lỗi
    // 2. Tính tất cả indicators:
    //    - RSI(14)
    //    - MACD(12, 26, 9)
    //    - Stochastic(5, 3, 3)
    //    - ATR(14)
    //    - Bollinger Bands(20, 2)
    // 3. Cache kết quả (TTL: 5 phút intraday, 1 giờ daily)
    // 4. Return object chứa tất cả
    return {
      rsi: [...],      // [{ time, value }]
      macd: [...],     // [{ time, macd, signal, histogram }]
      stochastic: [...], // [{ time, k, d }]
      atr: [...],      // [{ time, value }]
      bollingerBands: [...], // [{ time, upper, middle, lower }]
      summary: {       // Technical summary (dùng giá trị cuối)
        rsi: { value: 62.5, signal: 'Neutral' },
        macd: { value: 245, signal: 'Bullish', histogram: 46.3 },
        stochastic: { k: 72.4, d: 68.1, signal: 'Neutral' },
        atr: { value: 1250, signal: 'Medium' },
        sma: {
          sma5: { value: 57350, signal: 'Above' },
          sma20: { value: 56800, signal: 'Above' },
          sma60: { value: 55200, signal: 'Above' },
          sma120: { value: 53100, signal: 'Above' }
        }
      }
    }
  }
}
```

#### 1.4.3 Logic tính indicators — Data flow

```
Client request: GET /api/stocks/005930.KS/indicators
                ↓
StocksController.getIndicators()
                ↓
IndicatorsService.getIndicators('005930.KS')
                ↓
  ┌─ CacheService.get('ind_005930.KS') → HIT? return cached
  │
  └─ MISS:
     ↓
     KISService.getDailyChart('005930', 'D', start, end)  ← Lấy ~250 ngày OHLCV từ KIS
     ↓
     { timestamps, opens, highs, lows, closes, volumes }
     ↓
     ┌─ calcRSI(closes, 14)
     ├─ calcMACD(closes, 12, 26, 9)
     ├─ calcStochastic(highs, lows, closes, 5, 3, 3)
     ├─ calcATR(highs, lows, closes, 14)
     ├─ calcBollingerBands(closes, 20, 2)
     └─ calcSMA(closes, [5,10,20,60,120])
     ↓
     CacheService.set('ind_005930.KS', result)  ← Cache 5 phút
     ↓
     return result
```

---

### Task 1.5: User & Watchlist Routes (0.5 ngày)

#### User Routes

```
GET    /api/user/profile           → Lấy profile (từ JWT)
PUT    /api/user/profile           → Cập nhật name, avatar, settings
PUT    /api/user/change-password   → Đổi mật khẩu
POST   /api/user/upload-avatar     → Upload ảnh (multer)
GET    /api/user/subscription      → Xem plan + credits
```

#### Watchlist Routes

```
GET    /api/watchlist              → Lấy danh sách (theo userId)
POST   /api/watchlist/:symbol      → Thêm (kiểm tra Free max 10)
DELETE /api/watchlist/:symbol      → Xóa
PUT    /api/watchlist/reorder      → Sắp xếp lại (Pro only)
```

---

### Task 1.6: Rate Limiting & Error Handler (0.5 ngày)

```javascript
// Rate limiter config:
// - General: 100 req/min per IP
// - Auth: 10 req/min per IP (login/register)
// - AI: 20 req/min per user
// - Stocks: 200 req/min per IP

// Global error handler:
// - Mongoose validation errors → 400
// - JWT errors → 401
// - Not found → 404
// - Rate limit → 429
// - Internal → 500
// - Log all errors to SystemLog collection
```

---

### ✅ Deliverables Phase 1:
- [x] MongoDB connected + 4 models
- [x] Full authentication (register, login, Google, Apple, forgot password)
- [x] JWT middleware (access + refresh tokens)
- [x] **KIS Open API service** (primary — migrated from test/, 10 endpoints)
- [x] Yahoo Finance service (fallback — search, news)
- [x] **Indicators self-calculated** (RSI, MACD, Stoch, ATR, BB, SMA — từ KIS OHLCV)
- [x] Stocks API (search, quote, history, indicators, news, market-overview, list, top-movers)
- [x] User profile & watchlist CRUD
- [x] Rate limiting + global error handler
- [x] Cache service

---

## V. PHASE 2 — BACKEND ADVANCED (2–3 ngày)

### Task 2.1: WebSocket Server (0.5 ngày)

```javascript
// websocket.service.js
// Sử dụng 'ws' package
// Flow:
// 1. Client connect → authenticate (send JWT in first message)
// 2. Client send: { type: 'subscribe', symbol: '005930.KS' }
// 3. Server poll KIS API (primary) mỗi interval:
//    - Free users: 30s
//    - Pro users: 10s
// 4. Server push: { type: 'price_update', symbol, price, change, volume, time }
// 5. Client send: { type: 'unsubscribe', symbol }
// 6. Server broadcast: { type: 'market_status', status: 'OPEN'|'CLOSED' }

// Optimization:
// - Group subscriptions → batch KIS API calls (sequential, 300ms throttle)
// - Chỉ poll khi market OPEN (9:00-15:30 KST T2-T6)
// - Nếu market CLOSED → poll mỗi 5 phút (kiểm tra thay đổi after-hours)
// - KIS rate limit: max ~3 calls/s → batch carefully
```

### Task 2.2: AI Integration (1 ngày)

#### 2.2.1 `services/ai.service.js`

```javascript
class AIService {
  constructor() {
    this.geminiFlash = ...;  // Gemini 2.0 Flash (tốc độ cao, free tier)
    this.geminiPro = ...;    // Gemini 2.0 Pro (chi tiết hơn)
    this.openai = ...;       // GPT-4 (backup / premium)
  }
  
  async analyzeBasic(symbol, stockData) {
    // Input: giá hiện tại + RSI + MACD + SMA signals
    // Model: Gemini Flash
    // Output: Xu hướng + Khuyến nghị + Hỗ trợ/Kháng cự
    // Latency: 2-5s
  }
  
  async analyzePro(symbol, stockData) {
    // Input: 6 tháng OHLCV + tất cả indicators + volume profile
    // Model: Gemini Pro hoặc GPT-4
    // Output: 5 mục phân tích chi tiết + Dự báo + Strategy + Risk
    // Latency: 5-15s
  }
}
```

#### 2.2.2 AI Routes

```
POST /api/ai/analyze      Body: { symbol, level: "basic"|"pro" }
  → Kiểm tra quota (free: 3/ngày, pro: check credits)
  → Lấy stock data + indicators
  → Gọi AI service
  → Lưu AIAnalysis document
  → Trừ credits nếu pro
  → Return analysis

GET  /api/ai/history       → Lịch sử phân tích (phân trang)
GET  /api/ai/credits       → Số credits còn lại
```

### Task 2.3: Credit System (0.5 ngày)

```javascript
// Credit logic:
// - Free user: 3 basic analyses/day, reset 00:00 KST
// - Pro user: unlimited basic + credit-based pro
// - Credits deducted per analysis:
//   - Basic = 0 credits
//   - Pro (Gemini Pro) = 10 credits
//   - Pro (GPT-4) = 20 credits
// - Low credit warning: < 50 credits
// - Purchase packages (payment integration later):
//   - 100 credits = ₩1,000
//   - 500 credits = ₩5,000
//   - 2000 credits = ₩15,000
```

### Task 2.4: Admin Routes (0.5 ngày)

```
GET    /api/admin/users?page=&search=       → Danh sách users (phân trang)
GET    /api/admin/users/:id                  → Chi tiết user
PUT    /api/admin/users/:id/block            → Block/Unblock user
PUT    /api/admin/users/:id/subscription     → Thay đổi plan
GET    /api/admin/config                     → Lấy system config
PUT    /api/admin/config                     → Cập nhật system config
GET    /api/admin/logs?level=&source=&page=  → Xem logs (phân trang + filter)
GET    /api/admin/logs/export                → Export CSV
GET    /api/admin/stats                      → Dashboard stats
```

### Task 2.5: Email Service (0.5 ngày)

```javascript
// Dùng Nodemailer + Gmail SMTP (hoặc SendGrid)
// Templates:
// 1. Verification email — link xác thực (expires 24h)
// 2. Reset password — link đặt lại mật khẩu (expires 1h)
// 3. Welcome email — sau khi xác thực
// 4. Low credits notification
```

---

### ✅ Deliverables Phase 2:
- [x] WebSocket server (realtime price push)
- [x] AI service (Gemini Flash + Pro + GPT-4 fallback)
- [x] Credit system (free, pro, quota tracking)
- [x] Admin API endpoints
- [x] Email service (verification, reset password)
- [x] Complete backend — sẵn sàng cho Flutter & Admin

---

## VI. PHASE 3 — FLUTTER FOUNDATION (1–2 ngày)

### Task 3.1: pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
    
  # State Management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  
  # Networking
  dio: ^5.4.0
  web_socket_channel: ^2.4.0
  
  # Navigation
  go_router: ^14.0.0
  
  # Charts (⭐ Key dependency)
  fl_chart: ^0.68.0
  # hoặc syncfusion_flutter_charts (richer features, free community license)
  
  # Local Storage
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0
  
  # Auth
  google_sign_in: ^6.2.0
  sign_in_with_apple: ^6.1.0
  
  # UI
  shimmer: ^3.0.0
  cached_network_image: ^3.3.0
  
  # Utils
  intl: ^0.19.0
  flutter_localizations:
    sdk: flutter
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  
  # Push Notifications (optional Phase 7)
  firebase_messaging: ^14.0.0
  firebase_core: ^2.0.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
```

### Task 3.2: App Theme (`config/theme.dart`)

```dart
// Dark Theme (default — match web dashboard)
static final darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Color(0xFF0A0E17),
  colorScheme: ColorScheme.dark(
    surface: Color(0xFF131722),
    primary: Color(0xFF2962FF),
    // ...
  ),
  // Custom colors extension:
  // priceUp: Color(0xFF26A69A)
  // priceDown: Color(0xFFEF5350)
);

// Light Theme
static final lightTheme = ThemeData(
  brightness: Brightness.light,
  // ...
);
```

### Task 3.3: Navigation (`config/routes.dart`)

```dart
final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    // Check auth state → redirect to login if needed
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
    GoRoute(path: '/auth/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/auth/register', builder: (_, __) => RegisterScreen()),
    GoRoute(path: '/auth/forgot', builder: (_, __) => ForgotPasswordScreen()),
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child), // BottomNavBar
      routes: [
        GoRoute(path: '/home', builder: (_, __) => HomeScreen()),
        GoRoute(path: '/search', builder: (_, __) => SearchScreen()),
        GoRoute(path: '/watchlist', builder: (_, __) => WatchlistScreen()),
        GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),
      ],
    ),
    GoRoute(path: '/stock/:symbol', builder: (_, state) => 
      StockDetailScreen(symbol: state.pathParameters['symbol']!)),
    GoRoute(path: '/stocks', builder: (_, __) => StockListScreen()),
    GoRoute(path: '/settings/profile', builder: (_, __) => ProfileEditScreen()),
  ],
);
```

### Task 3.4: API Client (`services/api_client.dart`)

```dart
// Dio base configuration:
// - baseUrl: 'http://YOUR_SERVER:5000/api'
// - interceptors:
//   1. AuthInterceptor: attach JWT to headers
//   2. RefreshInterceptor: auto refresh token on 401
//   3. LogInterceptor: log requests in debug mode
//   4. TimeoutInterceptor: 8s default timeout
```

### Task 3.5: Data Models (freezed)

```dart
// 8 core models with freezed + json_serializable:
// - User, Stock, Quote, OHLCV, Indicator, AIAnalysis, News, WatchlistItem
// Run: dart run build_runner build
```

### Task 3.6: Riverpod Providers (shell)

```dart
// Khởi tạo providers cơ bản:
// - authProvider (AuthNotifier)
// - stockProvider 
// - watchlistProvider
// - settingsProvider
// - websocketProvider
```

---

### ✅ Deliverables Phase 3:
- [x] Flutter project configured with all dependencies
- [x] Dark/Light theme matching web dashboard
- [x] GoRouter navigation (all routes)
- [x] Dio API client with interceptors
- [x] 8 data models (freezed)
- [x] Core Riverpod providers
- [x] Ready for screen implementation

---

## VII. PHASE 4 — FLUTTER SCREENS (4–5 ngày)

> **Workflow Stitch + Code:**
> 1. User mô tả giao diện → tạo Stitch prompt → Stitch tạo UI components
> 2. Dùng MCP Figma để review → Copilot code theo Stitch output
> 3. Stitch tập trung vào: Layout, Components, Visual design
> 4. Copilot code: Logic, State, API calls, Chart library integration

---

### Task 4.1: Shared Widgets (0.5 ngày)

| Widget | Mô tả | Approach |
|--------|-------|----------|
| `BottomNavBar` | 4 tabs (Home/Search/Watchlist/Settings) | **Stitch** |
| `StockCard` | Card hiển thị 1 cổ phiếu (symbol, name, price, change) | **Stitch** |
| `PriceText` | Widget hiển thị giá + % (xanh/đỏ) | **Stitch** |
| `SparklineChart` | Mini chart 5 ngày (dùng trong list) | **fl_chart** code |
| `ShimmerLoading` | Skeleton loading effect | **shimmer** package |
| `ErrorWidget` | Error state with retry button | **Stitch** |
| `EmptyState` | Empty state with illustration | **Stitch** |

### Task 4.2: Screen 1 — Splash (0.25 ngày)

| Phần | Approach |
|------|----------|
| Logo + loading animation | **Stitch** (UI) |
| Auth check logic | Code (check JWT → navigate) |

### Task 4.3: Screen 2 — Auth (Login/Register/Forgot) (0.5 ngày)

| Phần | Approach |
|------|----------|
| Login form layout | **Stitch** |
| Register form layout | **Stitch** |
| Forgot password layout | **Stitch** |
| Social login buttons | **Stitch** |
| Validation logic | Code |
| API calls | Code |

### Task 4.4: Screen 3 — Home (1 ngày) ⭐

| Section | Approach |
|---------|----------|
| AppBar + Market Status | **Stitch** + Code (real-time clock) |
| Market Overview (horizontal scroll cards) | **Stitch** (card UI) + Code (data) |
| Watchlist Preview (list) | **Stitch** (item UI) + Code (data) |
| Top Movers (tabs + list) | **Stitch** + Code |
| Latest News section | **Stitch** + Code |
| Pull-to-refresh | Code |

### Task 4.5: Screen 4 — Search (0.5 ngày)

| Phần | Approach |
|------|----------|
| Search bar + recent + popular | **Stitch** |
| Search result item | **Stitch** |
| Debounce search logic | Code |
| History storage (Hive) | Code |

### Task 4.6: Screen 5 — Stock List (0.5 ngày)

| Phần | Approach |
|------|----------|
| Filter tabs (KOSPI/KOSDAQ) + sort | **Stitch** |
| List item with sparkline | **Stitch** (layout) + **fl_chart** (sparkline) |
| Infinite scroll | Code |

### Task 4.7: Screen 6 — Stock Detail ⭐⭐ (2 ngày — phức tạp nhất)

#### Tab A: Chart (1.5 ngày)

| Phần | Approach |
|------|----------|
| Header (symbol, price, change) | **Stitch** |
| Period selector (9 buttons) | **Stitch** |
| Chart type selector (4 buttons) | **Stitch** |
| **Main candlestick/line/area/bar chart** | **fl_chart** or custom Widget (code-heavy) |
| **Volume histogram** | **fl_chart** code |
| Overlay toggles (MA/BB/Vol) | **Stitch** + Code |
| **MA lines overlay** (5 MAs) | Code (fl_chart line series) |
| **Bollinger Bands overlay** | Code (fl_chart line series) |
| **RSI sub-chart** | Code (fl_chart line chart) |
| **MACD sub-chart** | Code (fl_chart combo: line + histogram) |
| **Stochastic sub-chart** | Code (fl_chart line chart) |
| Touch crosshair | Code (fl_chart touch response) |
| Pinch zoom / scroll | Code (gesture detector + fl_chart) |
| Technical Summary table | **Stitch** |

> **Lựa chọn Chart Library:**
> 
> | Option | Pros | Cons |
> |--------|------|------|
> | **fl_chart** | Free, popular, good perf | Candlestick chưa built-in, cần custom |
> | **syncfusion_flutter_charts** | Candlestick built-in, rich features | Community license (free ≤$1M rev) |
> | **interactive_viewer + WebView** | Dùng lightweight-charts (giống web test) | Bridge complexity |
> | **candlesticks** (package) | Simple candlestick | Limited features |
>
> **Đề xuất:** Dùng `syncfusion_flutter_charts` cho candlestick + indicators (feature-rich nhất, free community license). Hoặc custom với `fl_chart` nếu muốn full control.
>
> **Alternative:** Embed lightweight-charts (TradingView) trong WebView — giống hệt web test dashboard, ít code.

#### Tab B: Info (0.25 ngày)

| Phần | Approach |
|------|----------|
| Price details grid | **Stitch** |
| 52-week / Day range bars | **Stitch** + Code |
| Realtime polling log | Code |

#### Tab C: AI Analysis (0.25 ngày)

| Phần | Approach |
|------|----------|
| Basic analysis card | **Stitch** |
| Pro analysis card (locked) | **Stitch** |
| AI typing animation | Code (animated text) |
| Quota display | **Stitch** + Code |

#### Tab D: News (0.25 ngày)

| Phần | Approach |
|------|----------|
| News list items | **Stitch** |
| WebView / external link | Code |

### Task 4.8: Screen 7 — Watchlist (0.5 ngày)

| Phần | Approach |
|------|----------|
| Watchlist item (giống stock card + sparkline) | **Stitch** |
| Swipe to delete | Code (Dismissible) |
| Sort options | **Stitch** |
| Empty state | **Stitch** |

### Task 4.9: Screen 8 — Settings (0.5 ngày)

| Phần | Approach |
|------|----------|
| Account section | **Stitch** |
| Plan section + upgrade CTA | **Stitch** |
| Settings toggles | **Stitch** |
| Credits display | **Stitch** |
| Profile edit screen | **Stitch** |

---

### ✅ Deliverables Phase 4:
- [x] All 8 screens with UI (Stitch + Code)
- [x] All shared widgets
- [x] Chart implementation (candlestick + indicators)
- [x] Navigation working end-to-end

---

## VIII. PHASE 5 — FLUTTER INTEGRATION (3–4 ngày)

> **Kết nối tất cả screens với backend API + realtime.**

### Task 5.1: Auth Integration (0.5 ngày)

```dart
// AuthProvider:
// - login() → API call → store JWT → navigate Home
// - register() → API call → show verification message
// - googleSignIn() → Google SDK → API call → store JWT
// - logout() → clear storage → navigate Login
// - autoLogin() → check stored JWT → refresh if needed
```

### Task 5.2: Stock Data Integration (1 ngày)

```dart
// StockProvider / services:
// - fetchMarketOverview() → Home screen ticker (KIS /market)
// - fetchTopMovers() → Home screen (KIS rankings)
// - searchStocks(query) → Search screen (Yahoo — KIS không có search)
// - fetchStockList(market, sort, page) → Stock List (KIS rankings)
// - fetchQuote(symbol) → Stock Detail header (KIS price)
// - fetchHistory(symbol, period) → Chart data (KIS daily/minute)
// - fetchIndicators(symbol) → RSI/MACD/Stoch charts (self-calc từ KIS OHLCV)
// - fetchInvestor(symbol) → Investor flow tab (KIS exclusive)
// - fetchNews(symbol) → News tab (Yahoo — KIS không có news)
```

### Task 5.3: Chart Data Binding (1 ngày)

```dart
// Bind API data → chart widgets:
// - OHLCV từ KIS (primary) → Candlestick/Line/Area/Bar chart
// - Volume từ KIS → Volume histogram
// - MA calculations → line overlays (tính tại client từ closes)
// - RSI data (self-calc từ KIS OHLCV) → RSI sub-chart
// - MACD data (self-calc) → MACD sub-chart  
// - Stochastic data (self-calc) → Stochastic sub-chart
// - Bollinger Bands (self-calc) → BB overlay on main chart
//
// Timezone handling (tham chiếu test/public/index.html dòng 398, 779):
// - Intraday (KIS minute): time = rawTimestamp + exchangeGmtOffset (32400)
// - Daily (KIS daily): date string 'YYYY-MM-DD'
// - KIS trả HHMMSS (KST) + YYYYMMDD → convert to Unix epoch + gmtOffset
```

### Task 5.4: WebSocket Integration (0.5 ngày)

```dart
// WebSocketProvider:
// - connect(token) → authenticate
// - subscribe(symbol) → nhận price updates
// - unsubscribe(symbol)
// - onPriceUpdate → cập nhật UI (header price, chart last candle, polling log)
// - onMarketStatus → cập nhật market status badge
// - reconnect logic (exponential backoff)
```

### Task 5.5: Watchlist Integration (0.5 ngày)

```dart
// WatchlistProvider:
// - fetchWatchlist() → list from MongoDB
// - addToWatchlist(symbol) → POST + optimistic update
// - removeFromWatchlist(symbol) → DELETE + optimistic update
// - reorderWatchlist(newOrder) → PUT (Pro only)
// - isFavorite(symbol) → check local state
```

### Task 5.6: AI Analysis Integration (0.5 ngày)

```dart
// AIProvider:
// - analyzeBasic(symbol) → POST /api/ai/analyze { level: 'basic' }
// - analyzePro(symbol, model) → POST /api/ai/analyze { level: 'pro' }
// - fetchHistory() → GET /api/ai/history
// - fetchCredits() → GET /api/ai/credits
// - Check quota: free user 3/day, show remaining count
```

### Task 5.7: Offline & Error Handling (0.5 ngày)

```dart
// - Connectivity check → show banner nếu offline
// - Use cached data khi offline (Hive)
// - Retry logic cho network errors
// - Error states cho từng screen section
// - Loading shimmer states
```

---

### ✅ Deliverables Phase 5:
- [x] All screens connected to live API
- [x] Charts display live data (OHLCV + indicators)
- [x] WebSocket realtime working
- [x] Watchlist CRUD working
- [x] AI analysis working (basic + pro)
- [x] Offline handling + error states
- [x] **Flutter App fully functional**

---

## IX. PHASE 6 — WEB ADMIN (3–4 ngày)

### Task 6.1: Admin Setup — Vite + React (0.5 ngày)

```bash
# Stack: React + Vite + TailwindCSS + React Router + Axios
# UI library: shadcn/ui hoặc Ant Design (admin-friendly)
cd admin
npm install react-router-dom axios @tanstack/react-query tailwindcss
```

### Task 6.2: Admin Auth (0.5 ngày)

```
- Login page (admin only — kiểm tra role === 'admin')
- JWT storage (localStorage)
- Route guard (redirect if not admin)
- Auto refresh token
```

### Task 6.3: Dashboard Stats (0.5 ngày)

```
Hiển thị:
- Tổng users (active / blocked)
- Tổng AI analyses hôm nay
- Revenue từ credits
- Active WebSocket connections
- API health status
```

### Task 6.4: User Management (1 ngày)

```
Trang Users:
- Bảng danh sách users (phân trang, search, filter)
- Columns: Name, Email, Plan, Credits, Status, Last Login, Created
- Actions: View Detail / Block / Unblock

Trang User Detail:
- Profile info
- Subscription info (plan, credits, expiry)
- Watchlist
- AI analysis history
- Activity log
- Actions: Block/Unblock, change plan, add credits
```

### Task 6.5: System Config (0.5 ngày)

```
Trang Config:
- Toggle features: AI Analysis ON/OFF, Registration ON/OFF
- Maintenance mode
- Realtime intervals (Free / Pro)
- AI credit pricing
- Max watchlist size (Free)
- API rate limits
```

### Task 6.6: Logs & Monitoring (0.5 ngày)

```
Trang Logs:
- Bảng logs (phân trang)
- Filter: level (error/warn/info), source (backend/api/auth/ai), date range
- Search message
- Log detail modal
- Export CSV button
```

### Task 6.7: Charts & Visualizations (0.5 ngày)

```
Dashboard charts:
- User growth (line chart)
- AI usage per day (bar chart)
- API calls per endpoint (pie chart)
- Error rate (line chart)
- Library: recharts hoặc @tremor/react
```

---

### ✅ Deliverables Phase 6:
- [x] Admin login + route guard
- [x] Dashboard with stats
- [x] User management (list + detail + block/unblock)
- [x] System config page
- [x] Logs viewer + CSV export
- [x] **Web Admin fully functional**

---

## X. PHASE 7 — POLISH & DEPLOY (2–3 ngày)

### Task 7.1: Testing (1 ngày)

```
Backend:
- Unit tests cho indicators.js (math correctness)
- Integration tests cho auth flow
- API endpoint tests

Flutter:
- Widget tests cho key screens
- Integration test cho login → home → stock detail flow

Admin:
- Component tests cơ bản
```

### Task 7.2: Performance Optimization (0.5 ngày)

```
Backend:
- MongoDB indexes (ensure compound indexes)
- Redis cache (upgrade from in-memory nếu cần)
- Compression middleware (gzip)
- Response pagination consistency

Flutter:
- Image caching (cached_network_image)
- List virtualization (ListView.builder)
- Chart performance (limit data points)
- Lazy loading of tabs
```

### Task 7.3: Push Notifications (0.5 ngày — optional)

```
- Firebase Cloud Messaging setup
- Price alert (user-defined threshold)
- Market open/close notification
- AI insight notification (Pro)
- Notification settings (per-type toggle)
```

### Task 7.4: Deployment (0.5 ngày)

```
Backend:
- MongoDB Atlas (cloud) hoặc self-hosted
- Deploy backend: Railway / Render / VPS (PM2)
- Environment variables
- SSL/HTTPS

Flutter:
- Build APK/AAB (Android)
- Build IPA (iOS — requires Mac)
- App signing

Admin:
- Build static → deploy cùng backend hoặc Vercel/Netlify
```

### Task 7.5: Final Checklist (0.5 ngày)

```
- [ ] Tất cả API endpoints hoạt động
- [ ] JWT auth flow complete (register → verify → login → refresh)
- [ ] Charts hiển thị đúng (candle, line, area, bar + 5 MAs + BB)
- [ ] Indicators tính đúng (RSI, MACD, Stoch, ATR)
- [ ] WebSocket realtime working
- [ ] AI analysis working (basic + pro)
- [ ] Watchlist CRUD working
- [ ] Timezone KST đúng trên chart
- [ ] Dark/Light theme
- [ ] i18n đa ngôn ngữ (en default, vi, ko) — ARB files + flutter_localizations
- [ ] Loading/Error/Empty states
- [ ] Admin: user management working
- [ ] Admin: system config working
- [ ] Admin: logs + export working
- [ ] Rate limiting working
- [ ] Security: HTTPS, CORS, sanitize
```

---

### ✅ Deliverables Phase 7:
- [x] Tests passing
- [x] Performance optimized
- [x] Push notifications (optional)
- [x] Deployed and accessible
- [x] **PROJECT COMPLETE**

---

## XI. WORKFLOW STITCH + COPILOT

### 11.1 Cách làm việc

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  User mô tả │ ──► │ Copilot tạo  │ ──► │ Stitch tạo   │
│  giao diện   │     │ Stitch prompt│     │ UI components │
└─────────────┘     └──────────────┘     └──────┬───────┘
                                                 │
                                                 ▼
                    ┌──────────────┐     ┌──────────────┐
                    │ Copilot code │ ◄── │ MCP Figma    │
                    │ Flutter logic│     │ review design│
                    └──────────────┘     └──────────────┘
```

### 11.2 Stitch tạo gì

| Stitch tạo | Copilot code |
|------------|-------------|
| Layout composition | Business logic |
| Color scheme, typography | State management (Riverpod) |
| Button/Card/Input components | API integration (Dio) |
| Navigation bars | Chart library (fl_chart / syncfusion) |
| Icons, spacing | WebSocket handling |
| Responsive breakpoints | Data binding |
| Animations (visual) | Gesture handling |
| Theme tokens | Cache, offline |

### 11.3 Stitch prompts sẽ cover

Khi user mô tả giao diện, Copilot sẽ tạo Stitch prompts cho:

1. **App Shell** — BottomNavBar + AppBar + Theme
2. **Auth Screens** — Login / Register / Forgot Password
3. **Home Screen** — Market Status + Cards + Lists
4. **Search Screen** — Search bar + Results + History
5. **Stock List Screen** — Filters + Sorted list + Sparkline
6. **Stock Detail Screen** — Header + Tab bar + Sub-sections
7. **Watchlist Screen** — Swipeable list
8. **Settings Screen** — Sections + Toggles

Mỗi prompt sẽ bao gồm:
- **Visual description** (layout, colors, spacing)
- **Component list** (buttons, inputs, cards...)
- **Responsive notes**
- **Dark theme colors** (matching web dashboard)
- **Korean text examples** (삼성전자, ₩57,400...)

---

## XII. DEPENDENCY MAP & CRITICAL PATH

```
Phase 0 (Setup)
    │
    ├──► Phase 1 (Backend Core) ──────────────────────────┐
    │        │                                             │
    │        ├──► Phase 2 (Backend Advanced)               │
    │        │        │                                    │
    │        │        └──► Phase 6 (Web Admin) ───────────►│
    │        │                                             │
    └──► Phase 3 (Flutter Foundation)                      │
             │                                             │
             └──► Phase 4 (Flutter Screens — Stitch) ──────│
                      │                                    │
                      └──► Phase 5 (Flutter Integration)───┤
                                                           │
                                                    Phase 7 (Polish)
```

**Critical Path:** 0 → 1 → 3 → 4 → 5 → 7

**Parallel work possible:**
- Phase 2 (Backend Advanced) + Phase 3 (Flutter Foundation)
- Phase 4 (Flutter Screens) + Phase 6 (Web Admin)

---

## XIII. RISK & MITIGATION

| Risk | Impact | Mitigation |
|------|--------|-----------|
| KIS API token rate limit | 🟡 Medium | Cache token 24h, refresh 1h trước hạn, handle EGW00133 |
| KIS API request rate limit | 🟡 Medium | Global 300ms throttle + 500ms pagination delay (đã test ổn) |
| KIS minute chart pagination timeout | 🟡 Medium | Retry 1x, graceful partial data, 60s cache |
| Yahoo Finance API bị block | 🟡 Medium (fallback only) | Chỉ dùng cho search + news, cache aggressive |
| fl_chart thiếu candlestick | 🟡 Medium | Dùng syncfusion hoặc WebView + lightweight-charts |
| Google Gemini quota limit | 🟡 Medium | Fallback sang OpenAI, rate limit AI requests |
| MongoDB connection issues | 🟡 Medium | Connection retry, in-memory cache fallback |
| Apple Sign In chỉ test trên iOS | 🟢 Low | iOS-only feature, Android skip |
| Payment integration (credits) | 🟢 Low | Phase sau, ban đầu admin add credits thủ công |

---

## XIV. TỔNG KẾT

| Metric | Value |
|--------|-------|
| **Tổng phases** | 8 (0–7) |
| **Tổng tasks** | ~40 tasks |
| **Ước lượng thời gian** | 19–26 ngày |
| **Backend endpoints** | 30+ (10 KIS primary + 7 Yahoo fallback + 13 app-specific) |
| **Flutter screens** | 8 screens + 4 tabs |
| **MongoDB models** | 4 |
| **Chart features** | 4 types + 5 MAs + BB + RSI + MACD + Stoch |
| **Admin pages** | 6 |

### Bước tiếp theo:
1. ✅ Plan này đã hoàn thành
2. ⏳ User mô tả giao diện → Copilot tạo Stitch prompts
3. ⏳ Stitch tạo UI components  
4. ⏳ MCP Figma review → Copilot code
5. ⏳ Bắt đầu Phase 0 + Phase 1

---

> **Ghi chú:** File này sẽ được cập nhật theo tiến độ thực tế. Mỗi task hoàn thành sẽ được đánh dấu ✅.
