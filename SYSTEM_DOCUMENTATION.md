# 📊 KRX STOCK ANALYSIS — SYSTEM DOCUMENTATION
> **Version:** 2.0.0 (KIS API Integrated)  
> **Ngày cập nhật:** 27/02/2026  
> **Trạng thái:** Test Phase Complete — Ready for Implementation

---

## I. TỔNG QUAN DỰ ÁN

### 1.1 Mục tiêu
Xây dựng hệ thống phân tích chứng khoán thị trường Hàn Quốc (KRX) bao gồm:
- **Flutter App Client** — Ứng dụng di động cho người dùng cuối
- **MERN Web Admin** — Trang quản trị (MongoDB, Express, React, Node.js)
- **Shared Node.js Backend** — Backend dùng chung cho cả App và Web
- **MongoDB** — Cơ sở dữ liệu

### 1.2 Giai đoạn hiện tại
Giai đoạn **Test hoàn tất** — Đã thử nghiệm thành công KIS API là nguồn dữ liệu chính, Yahoo Finance làm fallback. Toàn bộ code test trong `test/` đã chạy ổn định, tham chiếu khi implement chính thức.

### 1.3 Vị trí người dùng
Người dùng ở **Việt Nam** (UTC+7), không có tài khoản chứng khoán Hàn Quốc → chỉ xem dữ liệu, không giao dịch.

---

## II. CẤU TRÚC THƯ MỤC

```
stock_AI_app/
├── requirement.txt                  # Yêu cầu gốc của dự án
├── SYSTEM_DOCUMENTATION.md          # Tài liệu này
├── IMPLEMENTATION_PLAN.md           # Kế hoạch triển khai 15 phase
├── APP_CLIENT_SPEC.md               # Đặc tả Flutter App Client
├── STITCH_PROMPT.md                 # UI Design prompt cho Stitch
└── test/                            # ⭐ Thư mục test (REFERENCE CODE)
    ├── .env                         # Biến môi trường (KIS credentials)
    ├── package.json                 # Dependencies & scripts
    ├── server.js                    # Backend server (~1100 dòng) — KIS + Yahoo + Alpha
    ├── test_kis_api.js              # Script test trực tiếp KIS API (reference)
    └── public/
        └── index.html               # Frontend dashboard (~1160 dòng) — TradingView-style
```

---

## III. NGUỒN DỮ LIỆU API

### 3.1 Tổng quan các nguồn API đã thử

| API | Kết quả | Ghi chú |
|-----|---------|---------|
| **Korea Investment Open API (KIS)** | ✅ **Chính — Đang dùng** | OAuth2 token, 10 endpoints hoạt động tốt |
| **Yahoo Finance Direct API** | ✅ **Phụ — Fallback** | Search, News, backup chart data |
| **yahoo-finance2 (npm package)** | ❌ Không dùng | ESM-only, bị crumb/cookie 429 |
| **Alpha Vantage** | ⚠️ Chỉ demo | Demo key = chỉ IBM, không hỗ trợ KRX |
| **KRX Open API** | ⏳ Chưa đăng ký | Cần SĐT Hàn Quốc |

### 3.2 Combo API hiện tại (Hybrid Strategy)
```
Chính:     KIS Open API              → Giá realtime, OHLCV daily/minute, Investor flow, Rankings, Index
Phụ:       Yahoo Finance Direct API  → Search, News, Fallback chart data (15-20 phút delay cho KRX)
Dự phòng:  Alpha Vantage             → Chỉ khi có paid key (demo chỉ hỗ trợ IBM)
Kế hoạch:  Tự tính Indicators        → RSI, MACD, Stoch, ATR, BB từ OHLCV data KIS
```

### 3.3 KIS Open API (Chi tiết) ⭐

**Base URL:** `https://openapi.koreainvestment.com:9443`

**Credentials (đã xác thực hoạt động):**
```
APP_KEY:    PSsw5JXblDis6LZJ1tSqMbLwUQFOqQLlopQR
APP_SECRET: (lưu trong .env — 160 ký tự)
```

**Authentication — OAuth2 Token:**
| Thuộc tính | Giá trị |
|------------|---------|
| Endpoint | POST `/oauth2/tokenP` |
| Grant type | `client_credentials` |
| Token TTL | ~24 giờ |
| Rate limit phát hành | **1 token / phút** (EGW00133 nếu gọi quá nhanh) |
| Refresh strategy | Auto-refresh 1 giờ trước khi hết hạn |

**Headers cho mọi request:**
```javascript
{
  'Content-Type': 'application/json; charset=utf-8',
  'authorization': `Bearer ${token}`,
  'appkey': APP_KEY,
  'appsecret': APP_SECRET,
  'tr_id': '<transaction_id>',   // Mỗi endpoint có tr_id riêng
  'custtype': 'P',               // P = cá nhân
}
```

**Ký hiệu cổ phiếu:**
- Chỉ dùng **mã 6 chữ số**: `005930` (Samsung), `000660` (SK Hynix)
- **Không dùng** suffix `.KS` / `.KQ` — phải strip trước khi gọi KIS
- `FID_COND_MRKT_DIV_CODE: 'J'` = cổ phiếu thường (주식)

**Rate Limit:**
| Loại | Giới hạn | Xử lý |
|------|----------|-------|
| Token phát hành | 1 lần/phút | Cache token 24h, refresh 1h trước expiry |
| API calls | ~3 calls/giây (ước lượng) | Global throttle 300ms + delay 500ms giữa pagination |
| Pagination | ~6 pages liên tiếp ổn định | Retry 1 lần nếu 500, graceful break nếu fail |

### 3.4 KIS API Endpoints đã test (10 endpoints)

| # | Endpoint (test/) | KIS tr_id | Mô tả | Cache TTL | Trạng thái |
|---|-----------------|-----------|-------|-----------|------------|
| 1 | `/api/kis/health` | — | Kiểm tra token + kết nối | — | ✅ |
| 2 | `/api/kis/price/:symbol` | `FHKST01010100` | Giá realtime + chi tiết (PER, PBR, 52w) | 30s | ✅ |
| 3 | `/api/kis/chart/:symbol` | `FHKST03010100` | OHLCV daily/weekly/monthly | 5 phút | ✅ |
| 4 | `/api/kis/minutechart/:symbol` | `FHKST03010200` | OHLCV phút (intraday) — paginated | 60s | ✅ |
| 5 | `/api/kis/trades/:symbol` | `FHKST01010300` | Lịch sử khớp lệnh (체결) | 15s | ✅ |
| 6 | `/api/kis/ranking/fluctuation` | `FHPST01700000` | Top tăng/giảm (등락률 순위) | 60s | ✅ |
| 7 | `/api/kis/ranking/volume` | `FHPST01710000` | Top khối lượng (거래량 순위) | 60s | ✅ |
| 8 | `/api/kis/investor/:symbol` | `FHKST01010900` | Nhà đầu tư (개인/외국인/기관) | 5 phút | ✅ |
| 9 | `/api/kis/index` | `FHPUP02100000` | Chỉ số KOSPI/KOSDAQ | 30s | ✅ |
| 10 | `/api/kis/market` | (batch `FHKST01010100`) | Tổng quan 8 cổ phiếu top | 2 phút | ✅ |

### 3.5 KIS Response Data — Các trường quan trọng

#### 3.5.1 Price (FHKST01010100 → `data.output`)
| Trường KIS | Ý nghĩa | Kiểu |
|------------|---------|------|
| `hts_kor_isnm` | Tên Hàn (삼성전자) | string |
| `stck_prpr` | Giá hiện tại | int |
| `prdy_vrss` | Thay đổi so với hôm qua | int |
| `prdy_ctrt` | % thay đổi | float |
| `prdy_vrss_sign` | 1=up 2=flat 3=stay 4=down | string |
| `stck_oprc` / `stck_hgpr` / `stck_lwpr` | Open / High / Low | int |
| `stck_sdpr` | Giá đóng cửa hôm qua | int |
| `acml_vol` | Tổng khối lượng | int |
| `acml_tr_pbmn` | Tổng giá trị GD (백만) | int |
| `hts_avls` | Market cap (억) | int |
| `per` / `pbr` / `eps` | PER / PBR / EPS | float/int |
| `stck_dryy_hgpr` / `stck_dryy_lwpr` | 52w High / 52w Low | int |
| `stck_mxpr` / `stck_llam` | Giá trần / Giá sàn | int |

#### 3.5.2 Daily Chart (FHKST03010100 → `data.output2[]`)
| Trường KIS | Ý nghĩa |
|------------|---------|
| `stck_bsop_date` | Ngày (YYYYMMDD) |
| `stck_oprc` | Open |
| `stck_hgpr` | High |
| `stck_lwpr` | Low |
| `stck_clpr` | Close |
| `acml_vol` | Volume |

**Params:**
```javascript
{
  FID_COND_MRKT_DIV_CODE: 'J',
  FID_INPUT_ISCD: '005930',
  FID_INPUT_DATE_1: '20250101',    // Start date
  FID_INPUT_DATE_2: '20260227',    // End date
  FID_PERIOD_DIV_CODE: 'D',       // D=Day, W=Week, M=Month
  FID_ORG_ADJ_PRC: '0',           // 0=adjusted price
}
```

#### 3.5.3 Minute Chart (FHKST03010200 → `data.output2[]`) ⭐ PAGINATED
| Trường KIS | Ý nghĩa |
|------------|---------|
| `stck_cntg_hour` | Thời gian (HHMMSS in KST) |
| `stck_bsop_date` | Ngày (YYYYMMDD) |
| `stck_prpr` | Close |
| `stck_oprc` | Open |
| `stck_hgpr` | High |
| `stck_lwpr` | Low |
| `cntg_vol` | Volume phút |

**Params:**
```javascript
{
  FID_COND_MRKT_DIV_CODE: 'J',
  FID_INPUT_ISCD: '005930',
  FID_INPUT_HOUR_1: '160000',     // Thời gian bắt đầu (xem phần kỹ thuật)
  FID_ETC_CLS_CODE: '',
  FID_PW_DATA_INCU_YN: 'N',      // ⚠️ BẮT BUỘC: 'N' = không tính pre-market
}
```

#### 3.5.4 Investor (FHKST01010900 → `data.output[]`)
| Trường KIS | Ý nghĩa |
|------------|---------|
| `stck_bsop_date` | Ngày |
| `prsn_ntby_qty` | Cá nhân - net mua/bán (주) |
| `frgn_ntby_qty` | Ngoại - net mua/bán |
| `orgn_ntby_qty` | Tổ chức - net mua/bán |
| `prsn_ntby_tr_pbmn` | Cá nhân - net giá trị GD |
| `frgn_ntby_tr_pbmn` | Ngoại - net giá trị GD |
| `orgn_ntby_tr_pbmn` | Tổ chức - net giá trị GD |

> ⚠️ **Lưu ý:** `prsn_shnu_vol` / `prsn_seln_vol` = mua/bán riêng. `ntby_qty` = net (mua - bán).

### 3.6 Yahoo Finance Direct API (Fallback)

**Base URLs:**
- Chart: `https://query1.finance.yahoo.com/v8/finance/chart/{symbol}`
- Search: `https://query1.finance.yahoo.com/v1/finance/search`

**Headers bắt buộc:**
```javascript
{ 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ...' }
```

**Ký hiệu:** KOSPI = `{mã}.KS`, KOSDAQ = `{mã}.KQ`

**Vai trò hiện tại:**
| Chức năng | Nguồn | Lý do |
|-----------|-------|-------|
| Search cổ phiếu | Yahoo | KIS không có search endpoint |
| Tin tức | Yahoo | KIS không có news endpoint |
| Chart data backup | Yahoo | Fallback khi KIS lỗi (delay 15-20 phút) |

### 3.7 Alpha Vantage API (Sẽ loại bỏ)
- Demo key chỉ hỗ trợ IBM. Kế hoạch: self-calc indicators từ KIS OHLCV data.

---

## IV. BACKEND SERVER — `test/server.js` (Reference)

### 4.1 Công nghệ
| Thành phần | Phiên bản | Vai trò |
|------------|-----------|---------|
| Node.js | v22.15.0 | Runtime (ESM modules) |
| Express | ^4.21.0 | Web framework |
| Axios | ^1.7.0 | HTTP client |
| dotenv | ^16.4.0 | Load biến môi trường |
| cors | ^2.8.5 | CORS |

### 4.2 Hệ thống Cache

| Loại dữ liệu | TTL | Cache key pattern |
|---------------|-----|-------------------|
| KIS Price | 30s | `kis_price_{code}` |
| KIS Daily Chart | 5m | `kis_chart_{code}_{period}_{start}_{end}` |
| KIS Minute Chart | 60s | `kis_min_{code}_{time}` |
| KIS Trades | 15s | `kis_trades_{code}` |
| KIS Rankings | 60s | `kis_fluct_{type}`, `kis_vol_rank` |
| KIS Investor | 5m | `kis_investor_{code}` |
| KIS Index | 30s | `kis_index_{code}` |
| KIS Market Overview | 2m | `kis_market_overview` |
| Yahoo Quote | 5s | `yq_{symbol}` |
| Yahoo History | 60s/5m | `yh_{symbol}_{range}_{interval}` |
| Yahoo Search | 5m | `ys_{query}` |
| Yahoo News | 10m | `yn_{symbol}` |

### 4.3 Danh sách API Endpoints (26 endpoints)

#### KIS Endpoints (10) — PRIMARY

| # | Method | Endpoint | KIS tr_id | Mô tả | Cache |
|---|--------|----------|-----------|-------|-------|
| 1 | GET | `/api/kis/health` | — | Token check | — |
| 2 | GET | `/api/kis/price/:symbol` | `FHKST01010100` | Giá + PER/PBR/52w | 30s |
| 3 | GET | `/api/kis/chart/:symbol` | `FHKST03010100` | OHLCV daily/weekly/monthly | 5m |
| 4 | GET | `/api/kis/minutechart/:symbol` | `FHKST03010200` | OHLCV phút (paginated) | 60s |
| 5 | GET | `/api/kis/trades/:symbol` | `FHKST01010300` | Khớp lệnh 30 gần nhất | 15s |
| 6 | GET | `/api/kis/ranking/fluctuation` | `FHPST01700000` | Top tăng/giảm | 60s |
| 7 | GET | `/api/kis/ranking/volume` | `FHPST01710000` | Top khối lượng | 60s |
| 8 | GET | `/api/kis/investor/:symbol` | `FHKST01010900` | Investor flow | 5m |
| 9 | GET | `/api/kis/index` | `FHPUP02100000` | KOSPI/KOSDAQ | 30s |
| 10 | GET | `/api/kis/market` | batch | Overview 8 stocks | 2m |

#### Yahoo Finance Endpoints (7) — FALLBACK

| # | Endpoint | Mô tả |
|---|----------|-------|
| 11-17 | `/api/yahoo/health,search,quote,quotes,history,news,market` | Fallback + Search + News |

#### Alpha Vantage (7) + KRX (2) — LEGACY / PLACEHOLDER

| # | Endpoint | Trạng thái |
|---|----------|------------|
| 18-24 | `/api/alpha/...` | Demo only (sẽ thay bằng self-calc) |
| 25-26 | `/api/krx/...` | Placeholder |

---

## V. KỸ THUẬT ĐÃ TRIỂN KHAI (Test Phase) ⭐

> **QUAN TRỌNG:** Ghi lại tất cả kỹ thuật đã học và triển khai trong `test/`. Khi implement chính thức, **tham chiếu trực tiếp `test/server.js` và `test/public/index.html`**.

### 5.1 KIS Token Management
```
📁 test/server.js — dòng 30-56
```
- Cache token trong `kisToken = { token, expiresAt }`
- Auto-refresh 1h trước hạn: `Date.now() < expiresAt - 3600000`
- Token rate limit: 1/phút — nếu restart server nhanh → `EGW00133`
- Error → throw, caller retry

### 5.2 KIS Rate Limiter & Throttling
```
📁 test/server.js — dòng 61-67
```
- **Global throttle:** `kisThrottle()` — ≥300ms giữa 2 requests
- **Pagination delay:** 500ms giữa pages (tổng ~800ms với throttle)
- **Retry on 500:** 1 retry, 800ms backoff
- **Graceful degradation:** Page N fail → dùng data page 0..N-1
- **Sequential only:** KIS không chịu parallel requests

### 5.3 Minute Chart Pagination ⭐ (Kỹ thuật phức tạp nhất)
```
📁 test/server.js — dòng 553-665
```

**Vấn đề:** KIS trả ~30 records/call, nhưng 1 ngày = ~240 phút.

**Giải pháp:**
1. `FID_INPUT_HOUR_1` = giờ KST hiện tại (market open) hoặc `160000` (ngoài giờ)
2. Lấy 30 records → `stck_cntg_hour` cuối → trừ 1 phút → page tiếp
3. Tối đa 6 pages = ~180 records
4. Deduplicate → sort chronological → filter `close > 0`
5. Timestamp: `HHMMSS` KST + `YYYYMMDD` → ISO `+09:00` → Unix epoch

**Bugs đã fix:**

| Bug | Root Cause | Fix |
|-----|-----------|-----|
| API trả rỗng | Thiếu `FID_PW_DATA_INCU_YN: 'N'` | Thêm param |
| Data hôm qua | Hardcode `155900` | `getKstTimeStr()` realtime |
| Socket hang up | Request quá nhanh | 500ms delay + retry |
| 500 error | KIS rate limit | Retry 1x, graceful break |

**Performance:** ~3.5s/113 records, ~7-8s/240 records. Cached = instant (60s).

### 5.4 Timezone Handling (KST)
```
📁 test/server.js dòng 553-556, test/public/index.html dòng 398
```

| Component | Cách xử lý |
|-----------|------------|
| Server — minute chart | `HHMMSS` + `YYYYMMDD` → ISO `+09:00` → Unix epoch |
| Server — daily chart | `YYYYMMDD` → `YYYY-MM-DD` string |
| Client — intraday | `time + 32400` (kstAdjust) cho lightweight-charts UTC |
| `getKstTimeStr()` | Giờ KST dạng HHMMSS |
| `isKrxMarketHours()` | 9:00-16:00 KST, T2-T6 |

### 5.5 Frontend — AbortController & Stock Switching
```
📁 test/public/index.html — dòng 349, 411, 518-596
```

| Kỹ thuật | Chi tiết |
|----------|---------|
| `loadAbort` + `AbortController` | Cancel pending fetch khi switch stock |
| `loadSeq` sequence counter | Discard stale responses |
| `fetchT(url, ms, signal)` | Timeout + external abort signal |
| Loading spinner | "Loading minute chart..." |
| Quote first strategy | Price (500ms) trước, chart (3.5s) sau |

### 5.6 Frontend — Data Source Toggle
```
📁 test/public/index.html — dòng 503-511
```
- Toggle `dataSource` = `'kis'` (default) / `'yahoo'`
- KIS period map: `{ '1d':'minute', '5d':'D', '1m':'D', ..., '2y':'W', '5y':'M' }`
- 1D → `minutechart` endpoint, 5D+ → `chart` endpoint

### 5.7 Cache Pattern (Migrate to Redis)
```
📁 test/server.js — dòng 78-86
```
```javascript
const cache = new Map();
function getCached(key, ttlMs) {
  const entry = cache.get(key);
  if (entry && Date.now() - entry.time < ttlMs) return entry.data;
  return null;
}
function setCache(key, data) { cache.set(key, { data, time: Date.now() }); }
```

### 5.8 KIS Market Overview Batching
```
📁 test/server.js — dòng 891-940
```
- Sequential calls (KIS rate limit): `for (code) { await kisThrottle(); fetch(); }`
- 8 stocks × 300ms = ~2.4s, cache 2 phút

---

## VI. FRONTEND DASHBOARD — `test/public/index.html` (Reference)

### 6.1 Layout
```
┌─────────────────────────────────────────────────────┐
│ HEADER: Logo | KST Clock | MarketStatus | [KIS|Yahoo]│
├─────────────────────────────────────────────────────┤
│ TICKER BAR: 8 cổ phiếu top (KIS data)               │
├─────────────────────────────────────────────────────┤
│ SEARCH + quick-btns (8 cổ phiếu phổ biến)           │
├──────────────────────────────────┬──────────────────┤
│  CHART AREA (flex)               │  RIGHT PANEL     │
│  • Loading spinner               │  • Price Details  │
│  • Main chart (Candle/Line/...)  │  • 52w/Day Range  │
│  • 5 MA + BB + Volume            │  • Investor Flow  │
│  • RSI / MACD / Stochastic       │  • Tech Summary   │
│                                  │  • Realtime       │
│                                  │  • News           │
│                                  │  • Raw JSON       │
└──────────────────────────────────┴──────────────────┘
```

### 6.2 Tính năng đã implement
- ✅ 4 chart types: Candle, Line, Area, Bar
- ✅ 8 periods: 1D (minute), 5D, 1M, 3M, 6M, 1Y, 2Y, 5Y
- ✅ 5 MA lines + Bollinger Bands + Volume
- ✅ 3 Indicator sub-charts (RSI, MACD, Stochastic)
- ✅ KIS/Yahoo data source toggle
- ✅ Loading spinner + AbortController
- ✅ Investor flow (KIS: 개인/외국인/기관 + 10-day history)
- ✅ Realtime polling 10s
- ✅ Search + News + Ticker bar
- ✅ Technical summary panel
- ✅ Dark theme TradingView-style

### 6.3 CSS Variables
```css
--bg: #0a0e17  --surface: #131722  --surface2: #1e222d  --surface3: #2a2e39
--border: #2a2e39  --text: #d1d4dc  --text2: #787b86  --text3: #4c525e
--green: #26a69a  --red: #ef5350  --blue: #2962ff  --yellow: #ffeb3b
```

---

## VII. BUGS ĐÃ FIX (Lessons Learned)

| # | Bug | Root Cause | Fix |
|---|-----|-----------|-----|
| 1 | yahoo-finance2 crumb/cookie 429 | npm package bị rate limit | Gọi trực tiếp API |
| 2 | KIS API 403/EGW00105 | AppSecret thừa ký tự `16,31` | Copy chính xác |
| 3 | Minute chart rỗng | Thiếu `FID_PW_DATA_INCU_YN: 'N'` | Thêm param |
| 4 | Chart hiện data hôm qua | Hardcode `FID_INPUT_HOUR_1: '155900'` | `getKstTimeStr()` |
| 5 | Socket hang up pagination | Request quá nhanh 300ms | 500ms delay + retry |
| 6 | Investor data toàn 0 | Sai field names | `prsn/frgn/orgn_ntby_qty` |
| 7 | Chart không chuyển stock | fetchT timeout 8s < chart 3.5s | 30s timeout + AbortController |
| 8 | Timezone sai | lightweight-charts UTC | Cộng `exchangeGmtOffset` 32400 |
| 9 | RAM spike / layout tràn | `min-height` CSS | `height: 100vh; overflow: hidden` |

---

## VIII. CHỈ BÁO KỸ THUẬT (Indicators)

| Chỉ báo | Tham số | Overbought/Oversold | Tín hiệu |
|---------|---------|---------------------|-----------|
| **RSI** | 14 | >70 / <30 | Đo sức mạnh giá |
| **MACD** | 12,26,9 | — | MACD > Signal = Bullish |
| **Stochastic** | 5,3,3 | >80 / <20 | %K > %D = Buy |
| **ATR** | 14 | — | Đo biến động |
| **SMA** | 5,10,20,60,120 | — | Giá > SMA = xu hướng tăng |
| **BB** | 20,2σ | Band trên/dưới | Dải biến động |

> **Kế hoạch:** Tự tính từ OHLCV data KIS (Phase 1D) → loại bỏ Alpha Vantage dependency.

---

## IX. HƯỚNG DẪN CHẠY

```bash
cd test/
npm install
node server.js
# → http://localhost:3000
```

> ⚠️ Token rate limit: nếu restart <60s → `EGW00133`. Đợi 60s rồi thử lại.

---

## X. TRẠNG THÁI & TIẾP THEO

### ✅ Hoàn thành
- KIS API 10 endpoints (PRIMARY)
- Yahoo Finance 7 endpoints (FALLBACK)
- Minute chart pagination + retry + graceful degradation
- Daily chart D/W/M
- Investor flow, Rankings, Index (KIS exclusive)
- Token management + rate limit handling
- AbortController + loading UX
- Data source toggle (KIS ↔ Yahoo)
- Full TradingView-style dashboard

### ⚠️ Cần làm khi implement
- [ ] Self-calc RSI/MACD/Stoch/ATR/BB từ OHLCV (Phase 1D)
- [ ] Move KIS credentials to .env
- [ ] Nâng cache lên Redis
- [ ] KIS không có search → vẫn cần Yahoo cho search + news

### 🚀 Bước tiếp: xem `IMPLEMENTATION_PLAN.md`

---

## XI. FILE REFERENCE MAP

| Cần implement | File tham chiếu | Dòng |
|---------------|----------------|------|
| KIS Token management | `test/server.js` | 20-56 |
| KIS Throttle + Rate limit | `test/server.js` | 61-67 |
| Cache pattern | `test/server.js` | 78-86 |
| KIS Price endpoint | `test/server.js` | 451-500 |
| KIS Daily chart | `test/server.js` | 501-550 |
| KIS Minute chart (pagination) | `test/server.js` | 553-665 |
| KIS Trades | `test/server.js` | 670-705 |
| KIS Rankings | `test/server.js` | 705-803 |
| KIS Investor | `test/server.js` | 805-850 |
| KIS Index | `test/server.js` | 851-890 |
| KIS Market batch | `test/server.js` | 891-940 |
| Yahoo endpoints | `test/server.js` | 95-440 |
| Frontend chart rendering | `test/public/index.html` | 770-812 |
| Frontend loadStock (Abort) | `test/public/index.html` | 518-596 |
| Frontend KIS period map | `test/public/index.html` | 545-547 |
| Frontend timezone adjust | `test/public/index.html` | 398, 779 |
| KIS API raw params | `test/test_kis_api.js` | All |

---

## XII. TÀI LIỆU THAM KHẢO

| Nguồn | URL |
|-------|-----|
| **KIS Open API Portal** | https://apiportal.koreainvestment.com/ |
| **KIS API Docs** | https://apiportal.koreainvestment.com/apiservice |
| Yahoo Finance API | `https://query1.finance.yahoo.com/v8/finance/chart/` |
| Alpha Vantage | https://www.alphavantage.co/documentation/ |
| lightweight-charts | https://tradingview.github.io/lightweight-charts/ |
| KRX Open API | https://openapi.krx.co.kr |
