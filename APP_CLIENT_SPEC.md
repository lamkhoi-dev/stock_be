# 📱 KRX STOCK ANALYSIS — APP CLIENT SPECIFICATION
> **Version:** 1.0.0  
> **Ngày tạo:** 25/02/2026  
> **Platform:** Flutter (iOS + Android)  
> **Backend:** Node.js (Express) + MongoDB  
> **Tham chiếu:** requirement.txt, SYSTEM_DOCUMENTATION.md

---

## I. TỔNG QUAN APP

### 1.1 Mô tả
Ứng dụng di động phân tích chứng khoán thị trường Hàn Quốc (KRX — KOSPI & KOSDAQ), cung cấp dữ liệu giá realtime, biểu đồ kỹ thuật chuyên sâu, chỉ báo phân tích, tin tức, và phân tích AI.

### 1.2 Đối tượng người dùng
- Nhà đầu tư cá nhân quan tâm thị trường Hàn Quốc
- Không yêu cầu tài khoản chứng khoán (chỉ xem & phân tích, không giao dịch)

### 1.3 Hai chế độ sử dụng

| | **Free** | **Pro (AI)** |
|---|----------|-------------|
| Xem danh sách cổ phiếu | ✅ | ✅ |
| Tìm kiếm cổ phiếu | ✅ | ✅ |
| Biểu đồ giá (Candle/Line/Area/Bar) | ✅ | ✅ |
| Dữ liệu OHLCV + Volume | ✅ | ✅ |
| Moving Averages (MA5–MA120) | ✅ | ✅ |
| Bollinger Bands | ✅ | ✅ |
| RSI / MACD / Stochastic charts | ✅ | ✅ |
| Watchlist (tối đa) | 10 mã | Không giới hạn |
| Tin tức cổ phiếu | ✅ | ✅ |
| Realtime polling | 30 giây | 10 giây |
| Phân tích AI cơ bản | ✅ (3 lượt/ngày) | ✅ Không giới hạn |
| Phân tích AI Pro (chi tiết) | ❌ | ✅ (tính phí/lượt) |
| Tín hiệu kỹ thuật tổng hợp | Cơ bản | Chi tiết + AI nhận xét |

### 1.4 Hệ thống đa ngôn ngữ (i18n)
App hỗ trợ **3 ngôn ngữ** đầy đủ, người dùng chọn trong Settings:

| Ngôn ngữ | Locale | Mặc định |
|----------|--------|----------|
| **English** | `en` | ✅ Default |
| **Tiếng Việt** | `vi` | — |
| **한국어 (Korean)** | `ko` | — |

- Tất cả UI labels, buttons, messages đều có bản dịch 3 ngôn ngữ
- Tên cổ phiếu: Luôn hiển thị tên Hàn + tên Anh + mã (삼성전자 Samsung Electronics 005930)
- Ngôn ngữ mặc định theo locale thiết bị, fallback = English
- Dùng `flutter_localizations` + `intl` + ARB files

---

## II. KIẾN TRÚC KỸ THUẬT

### 2.1 Stack

```
┌──────────────────────────┐
│     Flutter App Client   │  Dart / Flutter
│     (iOS + Android)      │
└────────────┬─────────────┘
             │ REST API + WebSocket
┌────────────┴─────────────┐
│    Node.js Backend       │  Express.js
│    (Shared API Server)   │
├──────────────────────────┤
│    MongoDB               │  User data, Watchlist, Logs
├──────────────────────────┤
│    External APIs         │
│    ├─ KIS Open API ⭐    │  PRIMARY: Price, OHLCV, Investor, Rankings, Index
│    ├─ Yahoo Finance      │  FALLBACK: Search, News, Backup chart (15-20m delay)
│    └─ KRX Open API*      │  Tùy chọn / dự phòng (nếu có key)
├──────────────────────────┤
│    AI Services           │
│    ├─ Google Gemini      │  Phân tích AI
│    └─ OpenAI GPT         │  Phân tích AI (backup)
└──────────────────────────┘
* Tùy chọn / dự phòng
```

### 2.2 Data Flow

```
KIS Open API (PRIMARY)     Yahoo Finance (FALLBACK)
       │                          │
       └───────────┬───────────┘
                   │
                   ▼
             Node.js Backend ──► MongoDB (cache + user data)
                   │
                   ├── REST API ──► Flutter App (request/response)
                   └── WebSocket ─► Flutter App (realtime price push)
```

### 2.3 Nguồn dữ liệu (đã kiểm chứng)

| Dữ liệu | Nguồn | Phương thức |
|----------|-------|-------------|
| Giá realtime + PER/PBR/52w | **KIS Open API** (PRIMARY) | REST via Backend |
| OHLCV daily/weekly/monthly | **KIS Open API** (FHKST03010100) | REST via Backend |
| OHLCV intraday (phút) | **KIS Open API** (FHKST03010200 — paginated) | REST via Backend |
| Investor flow (개인/외국인/기관) | **KIS Open API** (FHKST01010900) | REST via Backend |
| Top tăng/giảm + Top khối lượng | **KIS Open API** (Rankings) | REST via Backend |
| Chỉ số KOSPI/KOSDAQ | **KIS Open API** (FHPUP02100000) | REST via Backend |
| Market Overview (8 stocks) | **KIS Open API** (batch) | REST via Backend |
| Khớp lệnh realtime | **KIS Open API** (FHKST01010300) | REST via Backend |
| Tìm kiếm cổ phiếu | Yahoo Finance Search API | REST (KIS không có search) |
| Tin tức | Yahoo Finance Search API | REST (KIS không có news) |
| Quote realtime (fallback) | Yahoo Finance Direct API | Fallback khi KIS lỗi (delay 15-20m) |
| RSI, MACD, Stochastic, ATR, BB | **Tự tính từ OHLCV KIS** tại Backend | REST |
| SMA (5/10/20/60/120) | **Tự tính từ OHLCV KIS** tại Client | Local |
| Market Overview | **KIS Open API** (batch 8 stocks) | REST |
| Phân tích AI | Google Gemini / OpenAI | REST via Backend |

> **Ghi chú:** 
> - **KIS Open API là nguồn chính** — Giá realtime, OHLCV, Investor flow, Rankings, Index. Đã test ổn định 10 endpoints trong `test/server.js`.
> - **Yahoo Finance là fallback** — Dùng cho Search (đặc thù) + News (đặc thù) + backup chart khi KIS lỗi.
> - Các chỉ báo kỹ thuật (RSI, MACD, Stochastic, ATR, Bollinger Bands) sẽ được **tự tính toán** từ dữ liệu OHLCV của KIS tại backend, không phụ thuộc Alpha Vantage.
> - Tham chiếu kỹ thuật chi tiết: `SYSTEM_DOCUMENTATION.md` Section V.

---

## III. MÀN HÌNH & CHỨC NĂNG CHI TIẾT

---

### SCREEN 1: SPLASH SCREEN

**Route:** `/splash`

| Thành phần | Chi tiết |
|------------|----------|
| Logo | 🇰🇷 KRX Stock Analysis |
| Loading indicator | Circular progress |
| Logic | Kiểm tra token → có token hợp lệ → Home, không → Login |
| Thời gian | Tối đa 2 giây |

---

### SCREEN 2: ĐĂNG KÝ / ĐĂNG NHẬP

**Route:** `/auth`  
**Yêu cầu:** requirement II.1.1

#### 2A. Màn hình Đăng nhập (`/auth/login`)

| Trường | Kiểu | Validation |
|--------|------|------------|
| Email | TextInput (email) | Required, email format |
| Mật khẩu | TextInput (password) | Required, min 8 ký tự |

| Nút | Hành động |
|-----|-----------|
| **Đăng nhập** | POST `/api/auth/login` → Lưu JWT → Navigate Home |
| **Đăng nhập Google** | OAuth2 Google → POST `/api/auth/google` |
| **Đăng nhập Apple** | Apple Sign In (iOS only) → POST `/api/auth/apple` |
| **Quên mật khẩu** | Navigate → `/auth/forgot` |
| **Đăng ký** | Navigate → `/auth/register` |

**Xử lý lỗi:**
- Email không tồn tại → "Tài khoản không tồn tại"
- Sai mật khẩu → "Mật khẩu không đúng"
- Tài khoản bị block → "Tài khoản đã bị khóa. Liên hệ admin."
- Lỗi mạng → "Không thể kết nối server"

#### 2B. Màn hình Đăng ký (`/auth/register`)

| Trường | Kiểu | Validation |
|--------|------|------------|
| Họ tên | TextInput | Required, 2–50 ký tự |
| Email | TextInput (email) | Required, email format, chưa đăng ký |
| Mật khẩu | TextInput (password) | Required, min 8, có chữ hoa + số |
| Xác nhận mật khẩu | TextInput (password) | Phải khớp mật khẩu |

| Nút | Hành động |
|-----|-----------|
| **Đăng ký** | POST `/api/auth/register` → Gửi email xác thực → Navigate Login |

**Flow sau đăng ký:**
1. Gửi verification email
2. Hiển thị "Kiểm tra email để xác thực tài khoản"
3. User click link email → tài khoản active
4. Đăng nhập lại

#### 2C. Quên mật khẩu (`/auth/forgot`)

| Trường | Hành động |
|--------|-----------|
| Email | Nhập email → POST `/api/auth/forgot-password` |
| | Gửi link reset qua email → Đặt lại mật khẩu |

---

### SCREEN 3: HOME (Trang chủ)

**Route:** `/home`  
**Yêu cầu:** requirement II.2.1

**Layout:**

```
┌─────────────────────────────────────┐
│  AppBar: KRX Analysis  [🔍] [👤]   │
├─────────────────────────────────────┤
│  ▸ TRẠNG THÁI THỊ TRƯỜNG           │
│  KST 14:25:30  ● MARKET OPEN       │
│  KOSPI 2,645.32 ▲0.45%             │
│  KOSDAQ 872.15 ▼0.12%              │
├─────────────────────────────────────┤
│  ▸ MARKET OVERVIEW (ScrollH)        │
│  ┌──────┐ ┌──────┐ ┌──────┐       │
│  │삼성전자│ │SK하이닉스│ │NAVER│ ...  │
│  │₩57,400│ │₩213,500│ │₩198K│       │
│  │▲0.3% │ │▼1.2% │ │▲0.8%│       │
│  └──────┘ └──────┘ └──────┘       │
├─────────────────────────────────────┤
│  ▸ WATCHLIST (nếu đã đăng nhập)     │
│  ┌─────────────────────────────┐   │
│  │ ★ 005930 삼성전자  ₩57,400  │   │
│  │   ▲350 (+0.61%)   Vol 12M  │   │
│  ├─────────────────────────────┤   │
│  │ ★ 000660 SK하이닉스 ₩213,500│   │
│  │   ▼2,500 (-1.16%) Vol 5.2M │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  ▸ TOP TĂNG / TOP GIẢM  [Tab]      │
│  ┌─────────────────────────────┐   │
│  │ 1. ABC.KS  ₩12,300  ▲29.8% │   │
│  │ 2. DEF.KS  ₩8,700   ▲15.2% │   │
│  │ ...                         │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  ▸ TIN TỨC MỚI NHẤT               │
│  ┌─────────────────────────────┐   │
│  │ 📰 Samsung Q4 earnings...   │   │
│  │ Korea Herald · 2h ago       │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  BottomNav: [🏠Home] [🔍Search]    │
│  [📋Watchlist] [⚙Settings]         │
└─────────────────────────────────────┘
```

#### Chi tiết từng section:

**3.1 Trạng thái thị trường**
| Dữ liệu | Nguồn | Cập nhật |
|----------|-------|----------|
| Giờ KST | Tính từ client (Asia/Seoul timezone) | Mỗi giây |
| Market status | Tính logic: T2-T6, 9:00-15:30 KST = OPEN | Mỗi giây |
| KOSPI index | KIS Open API (`0001` — FHPUP02100000) | Mỗi 30s (Free) / 10s (Pro) |
| KOSDAQ index | KIS Open API (`1001` — FHPUP02100000) | Mỗi 30s (Free) / 10s (Pro) |

**3.2 Market Overview**
- Horizontal scroll, hiển thị 8 cổ phiếu Hàn Quốc hàng đầu
- Mỗi card: Tên + Giá + % thay đổi (xanh tăng / đỏ giảm)
- Tap → Navigate Stock Detail
- Data: GET `/api/stocks/market-overview`

**3.3 Watchlist Preview**
- Hiển thị tối đa 5 cổ phiếu đã lưu (xem thêm → tab Watchlist)
- Mỗi item: Symbol + Tên + Giá + Thay đổi + Volume
- Swipe left → Xóa khỏi watchlist
- Tap → Navigate Stock Detail
- Yêu cầu đăng nhập

**3.4 Top tăng / Top giảm**
- Tab toggle: "Top tăng" | "Top giảm"
- Hiển thị top 10 cổ phiếu tăng/giảm mạnh nhất trong ngày
- Mỗi item: Rank + Symbol + Tên + Giá + % thay đổi
- Data: GET `/api/stocks/top-movers`

**3.5 Tin tức mới nhất**
- 5 tin tức mới nhất liên quan thị trường Hàn Quốc
- Mỗi item: Tiêu đề + Nguồn + Thời gian
- Tap → Mở WebView hoặc external browser
- Data: GET `/api/news/latest`

---

### SCREEN 4: TÌM KIẾM CỔ PHIẾU

**Route:** `/search`  
**Yêu cầu:** requirement II.2.2

```
┌─────────────────────────────────────┐
│  ← Back    🔍 [Tìm kiếm...]        │
├─────────────────────────────────────┤
│  ▸ TÌM KIẾM GẦN ĐÂY               │
│  005930 삼성전자  ✕                  │
│  035420 NAVER    ✕                  │
├─────────────────────────────────────┤
│  ▸ PHỔ BIẾN                         │
│  삼성전자 · SK하이닉스 · NAVER       │
│  카카오 · 현대차 · LG화학            │
├─────────────────────────────────────┤
│  (Khi nhập text → kết quả realtime) │
│  ┌─────────────────────────────┐   │
│  │ 005930.KS  삼성전자  🇰🇷     │   │
│  │ Samsung Electronics  KOSPI  │   │
│  ├─────────────────────────────┤   │
│  │ 005935.KS  삼성전자우        │   │
│  │ Samsung Elec Pref   KOSPI   │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

| Tính năng | Chi tiết |
|-----------|----------|
| Input | Debounce 300ms, tối thiểu 1 ký tự |
| Hỗ trợ tìm | Mã (005930), Tên Hàn (삼성전자), Tên Anh (Samsung) |
| Kết quả | Tối đa 15 kết quả, ưu tiên .KS/.KQ |
| Đánh dấu | 🇰🇷 cho cổ phiếu KRX, hiển thị sàn (KOSPI/KOSDAQ) |
| Lịch sử | Lưu 10 cổ phiếu tìm gần đây (local storage) |
| API | GET `/api/stocks/search?q={keyword}` |

---

### SCREEN 5: DANH SÁCH CỔ PHIẾU

**Route:** `/stocks`  
**Yêu cầu:** requirement II.2.1

```
┌─────────────────────────────────────┐
│  Danh sách cổ phiếu    [🔍] [⚙]   │
├─────────────────────────────────────┤
│  [KOSPI] [KOSDAQ] [Tất cả]  [Lọc▼] │
├─────────────────────────────────────┤
│  Sắp xếp: [Giá ▼] [% ▼] [Vol ▼]   │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │ 005930  삼성전자              │   │
│  │ ₩57,400  ▲350 (+0.61%)     │   │
│  │ Vol: 12,345,678  Cap: 343조  │   │
│  │ ┌────────────────────────┐  │   │
│  │ │ Mini sparkline chart   │  │   │
│  │ └────────────────────────┘  │   │
│  │                        [★]  │   │
│  ├─────────────────────────────┤   │
│  │ 000660  SK하이닉스           │   │
│  │ ...                         │   │
│  └─────────────────────────────┘   │
│        (Infinite scroll)           │
└─────────────────────────────────────┘
```

| Tính năng | Chi tiết |
|-----------|----------|
| Filter sàn | KOSPI (.KS) / KOSDAQ (.KQ) / Tất cả |
| Sắp xếp | Giá, % thay đổi, Volume, Market Cap (asc/desc) |
| Mỗi item hiển thị | Symbol, Tên Hàn, Giá, Thay đổi (₩ + %), Volume, Market Cap, Mini sparkline (5 ngày) |
| Nút Watchlist | ★ toggle — thêm/xóa khỏi watchlist |
| Pagination | Infinite scroll, load 20 items/page |
| Pull to refresh | Cập nhật giá mới nhất |
| Tap | Navigate → Stock Detail |
| API | GET `/api/stocks/list?market=KOSPI&sort=change_pct&order=desc&page=1&limit=20` |

---

### SCREEN 6: CHI TIẾT CỔ PHIẾU (STOCK DETAIL) ⭐

**Route:** `/stock/:symbol`  
**Yêu cầu:** requirement II.4.1, II.4.2  
**Đây là màn hình chính, chứa nhiều data nhất — tương đương web test dashboard**

```
┌─────────────────────────────────────┐
│  ← Back  005930.KS  [★] [🔔] [⋮]  │
├─────────────────────────────────────┤
│  삼성전자  Samsung Electronics       │
│  KOSPI · KRW · 🇰🇷                  │
│                                     │
│  ₩57,400                            │
│  ▲ ₩350 (+0.61%)                   │
│  Updated: 14:25 KST                │
├─────────────────────────────────────┤
│  [Tab: Chart | Info | AI Analysis | News]  │
└─────────────────────────────────────┘
```

#### TAB 6A: 차트 (Chart) — Tab mặc định

```
┌─────────────────────────────────────┐
│  Period: [1D][5D][1M][3M][6M][1Y]  │
│          [2Y][5Y]                   │
├─────────────────────────────────────┤
│  Type: [🕯Candle] [📈Line]         │
│        [📊Area]  [📉Bar]           │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │    MAIN PRICE CHART         │   │
│  │    (TradingView style)      │   │
│  │    + Volume bars below      │   │
│  │                             │   │
│  │  MA5 MA10 MA20 MA60 MA120   │   │
│  └─────────────────────────────┘   │
│                                     │
│  Overlays: [MA▼] [BB] [Vol ✓]      │
├─────────────────────────────────────┤
│  ▸ INDICATORS  [접기/펼치기]         │
│  ┌─────────────────────────────┐   │
│  │  RSI (14)                   │   │
│  │  ████████████░░░  62.5      │   │
│  │  ── 70 (overbought)        │   │
│  │  ── 30 (oversold)          │   │
│  ├─────────────────────────────┤   │
│  │  MACD (12,26,9)             │   │
│  │  MACD: 245.3  Signal: 198.7│   │
│  │  Histogram ████▓▓░░         │   │
│  ├─────────────────────────────┤   │
│  │  Stochastic (5,3,3)         │   │
│  │  %K: 72.4  %D: 68.1        │   │
│  │  ── 80 (overbought)        │   │
│  │  ── 20 (oversold)          │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  ▸ TECHNICAL SUMMARY                │
│  ┌─────────────────────────────┐   │
│  │ RSI (14)    62.5    Neutral │   │
│  │ MACD        245.3   Bullish │   │
│  │ Stoch %K    72.4    Neutral │   │
│  │ ATR (14)    1,250   Vol.Med │   │
│  │ SMA 5       ₩57,350  Above │   │
│  │ SMA 20      ₩56,800  Above │   │
│  │ SMA 60      ₩55,200  Above │   │
│  │ SMA 120     ₩53,100  Above │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Chart chính — Dữ liệu & Tính năng:**

| Tính năng | Chi tiết |
|-----------|----------|
| **Thư viện chart** | `fl_chart` hoặc `syncfusion_flutter_charts` hoặc custom TradingView WebView |
| **4 loại biểu đồ** | Candlestick (mặc định), Line, Area, Bar |
| **9 chu kỳ** | 1D (5m), 5D (15m), 1M (1h), 3M (1d), 6M (1d), 1Y (1d), 2Y (1w), 5Y (1w) |
| **Moving Averages** | MA5 (cam), MA10 (xanh), MA20 (hồng), MA60 (tím), MA120 (cyan) — toggle bật/tắt |
| **Bollinger Bands** | SMA(20) ± 2σ — toggle overlay |
| **Volume** | Histogram bên dưới chart, xanh (tăng) / đỏ (giảm) — toggle |
| **Crosshair** | Touch & hold → hiển thị giá/thời gian tại vị trí |
| **Pinch to zoom** | Zoom in/out trên trục thời gian |
| **Scroll horizontal** | Kéo trái/phải để xem lịch sử |
| **Auto-fit** | Double tap → fit toàn bộ dữ liệu vào view |

**Indicator sub-charts (collapsible):**

| Indicator | Params | Chart lines | Reference lines |
|-----------|--------|-------------|-----------------|
| **RSI** | period=14 | RSI line (tím) | 70 (đỏ nhạt), 30 (xanh nhạt) |
| **MACD** | fast=12, slow=26, signal=9 | MACD (xanh), Signal (cam), Histogram (xanh/đỏ) |
| **Stochastic** | %K=5, smooth=3, %D=3 | %K (xanh), %D (đỏ) | 80 (đỏ nhạt), 20 (xanh nhạt) |

**Công thức tính toán (tại Backend từ OHLCV):**

```
RSI(14):
  gain = avg(positive_changes, 14)
  loss = avg(negative_changes, 14)
  RS = gain / loss
  RSI = 100 - (100 / (1 + RS))

MACD(12,26,9):
  MACD_line = EMA(close, 12) - EMA(close, 26)
  Signal = EMA(MACD_line, 9)
  Histogram = MACD_line - Signal

Stochastic(5,3,3):
  %K_raw = (close - lowest_low(5)) / (highest_high(5) - lowest_low(5)) × 100
  %K = SMA(%K_raw, 3)
  %D = SMA(%K, 3)

ATR(14):
  TR = max(high-low, |high-prev_close|, |low-prev_close|)
  ATR = SMA(TR, 14)

Bollinger Bands(20,2):
  Middle = SMA(close, 20)
  Upper = Middle + 2 × StdDev(close, 20)
  Lower = Middle - 2 × StdDev(close, 20)
```

**Technical Summary — Bảng tổng hợp tín hiệu:**

| Indicator | Giá trị | Tín hiệu | Logic |
|-----------|---------|-----------|-------|
| RSI(14) | 0–100 | Oversold / Neutral / Overbought | <30 = Buy, 30–70 = Neutral, >70 = Sell |
| MACD | number | Bullish / Bearish | MACD > Signal = Bullish |
| Stoch %K | 0–100 | Oversold / Neutral / Overbought | <20 = Buy, 20–80 = Neutral, >80 = Sell |
| ATR(14) | number | Low / Medium / High volatility | So sánh với ATR trung bình |
| SMA 5/20/60/120 | ₩price | Above / Below | Giá > SMA = Above (bullish) |

**API calls cho Tab Chart:**
```
GET /api/stocks/:symbol/history?period=1d     → OHLCV data
GET /api/stocks/:symbol/indicators            → RSI, MACD, Stoch, ATR (tính sẵn)
```

#### TAB 6B: 정보 (Thông tin)

```
┌─────────────────────────────────────┐
│  ▸ GIÁ HIỆN TẠI                    │
│  ┌──────────┬──────────┐           │
│  │ Open     │ ₩57,100  │           │
│  │ High     │ ₩57,600  │           │
│  │ Low      │ ₩56,900  │           │
│  │ Prev Close│₩57,050  │           │
│  │ Volume   │ 12,345K  │           │
│  │ Market Cap│ 343.2조  │           │
│  └──────────┴──────────┘           │
├─────────────────────────────────────┤
│  ▸ 52-WEEK RANGE                    │
│  ₩48,200 ═══════●════ ₩72,300      │
│           Current: ₩57,400          │
├─────────────────────────────────────┤
│  ▸ DAY RANGE                        │
│  ₩56,900 ════════●═══ ₩57,600      │
├─────────────────────────────────────┤
│  ▸ THÔNG TIN GIAO DỊCH             │
│  ┌──────────┬──────────┐           │
│  │ Currency │ KRW      │           │
│  │ Exchange │ KOSPI    │           │
│  │ Market   │ OPEN/CLOSED│          │
│  │ Updated  │ 14:25 KST│           │
│  └──────────┴──────────┘           │
├─────────────────────────────────────┤
│  ▸ REALTIME PRICE                   │
│  [▶ Start Polling]                  │
│  14:25:30  ₩57,400  +0.61%  live   │
│  14:25:20  ₩57,350  +0.53%  live   │
│  14:25:10  ₩57,400  +0.61%  cache  │
│  ...                                │
└─────────────────────────────────────┘
```

| Dữ liệu | Trường API | Format |
|----------|-----------|--------|
| Open | `regularMarketOpen` | ₩ + comma separated |
| High | `regularMarketDayHigh` | ₩ + comma separated |
| Low | `regularMarketDayLow` | ₩ + comma separated |
| Prev Close | `regularMarketPreviousClose` | ₩ + comma separated |
| Volume | `regularMarketVolume` | Rút gọn (K/M) |
| Market Cap | `marketCap` | Rút gọn (억/조) |
| 52w High | `fiftyTwoWeekHigh` | ₩ |
| 52w Low | `fiftyTwoWeekLow` | ₩ |
| Currency | `currency` | Text |
| Exchange | `fullExchangeName` | Text |
| Updated | `regularMarketTime` | KST format |

**Realtime Polling:**
- Free: mỗi 30 giây
- Pro: mỗi 10 giây
- Toggle Start/Stop
- Hiển thị log giá realtime (max 50 entries)
- Tự động cập nhật giá trên header

**API:**
```
GET /api/stocks/:symbol/quote       → Quote data
WebSocket /ws/price/:symbol         → Realtime push (Pro)
```

#### TAB 6C: AI 분석 (Phân tích AI)

**Yêu cầu:** requirement II.5.1

```
┌─────────────────────────────────────┐
│  ▸ PHÂN TÍCH AI                     │
│                                     │
│  [🤖 Phân tích cơ bản] [Free]      │
│  ┌─────────────────────────────┐   │
│  │ 📊 Phân tích 삼성전자        │   │
│  │                             │   │
│  │ Xu hướng: TĂNG (Bullish)    │   │
│  │                             │   │
│  │ • RSI ở mức 62.5 (Neutral)  │   │
│  │   chưa quá mua/bán          │   │
│  │ • MACD cắt lên Signal line  │   │
│  │   → Tín hiệu tích cực      │   │
│  │ • Giá trên MA20 & MA60      │   │
│  │   → Xu hướng trung hạn tốt │   │
│  │                             │   │
│  │ Khuyến nghị: HOLD           │   │
│  │ Mức hỗ trợ: ₩56,200        │   │
│  │ Mức kháng cự: ₩59,000      │   │
│  │                             │   │
│  │ ⚠️ Lưu ý: Đây chỉ là phân  │   │
│  │ tích tham khảo, không phải  │   │
│  │ lời khuyên đầu tư.         │   │
│  └─────────────────────────────┘   │
│                                     │
│  Còn 2/3 lượt miễn phí hôm nay     │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  [🧠 Phân tích Pro] [🔒 Pro Only]  │
│  ┌─────────────────────────────┐   │
│  │ Bao gồm phân tích cơ bản + │   │
│  │ • Phân tích volume profile  │   │
│  │ • So sánh với sector        │   │
│  │ • Dự báo giá ngắn hạn      │   │
│  │ • Chiến lược entry/exit     │   │
│  │ • Risk assessment           │   │
│  │                             │   │
│  │ 💎 Nâng cấp Pro             │   │
│  │ 500 credits = ₩5,000       │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Phân tích AI — Hai cấp độ:**

| | **Cơ bản (Free)** | **Pro** |
|---|---|---|
| **AI Model** | Google Gemini Flash | Google Gemini Pro / GPT-4 |
| **Input gửi AI** | Giá hiện tại + RSI + MACD + SMA signals | Toàn bộ OHLCV 6 tháng + tất cả indicators + volume profile + sector data |
| **Output** | Xu hướng + Khuyến nghị ngắn + Hỗ trợ/Kháng cự | Phân tích chi tiết 5 mục + Dự báo + Chiến lược + Risk |
| **Giới hạn** | 3 lượt/ngày | Không giới hạn (tính phí credit) |
| **Tốc độ** | 2–5 giây | 5–15 giây |
| **Giá** | Miễn phí | Credit system (xem Section VIII) |

**AI Prompt Template (Backend):**

```
Cơ bản:
"Phân tích cổ phiếu {symbol} ({name}) trên sàn KRX.
 Giá: {price} KRW, Thay đổi: {change}%
 RSI(14): {rsi}, MACD: {macd}, Signal: {signal}
 SMA20: {sma20}, SMA60: {sma60}
 Cho nhận xét ngắn gọn về xu hướng và khuyến nghị."

Pro:
"Phân tích chuyên sâu cổ phiếu {symbol} ({name}).
 [Gửi kèm toàn bộ OHLCV 6 tháng + indicators]
 Phân tích: 1) Trend, 2) Volume, 3) Support/Resistance,
 4) Dự báo ngắn hạn, 5) Risk/Reward, 6) Entry/Exit strategy."
```

**API:**
```
POST /api/ai/analyze
Body: { symbol, level: "basic"|"pro" }
Response: { analysis: "...", model: "gemini-flash", credits_used: 0|10 }
```

#### TAB 6D: 뉴스 (Tin tức)

```
┌─────────────────────────────────────┐
│  ▸ TIN TỨC 삼성전자                 │
│  ┌─────────────────────────────┐   │
│  │ 📰 Samsung posts record...  │   │
│  │ Korea Herald · 2h trước     │   │
│  ├─────────────────────────────┤   │
│  │ 📰 SK Hynix & Samsung...   │   │
│  │ Reuters · 5h trước          │   │
│  ├─────────────────────────────┤   │
│  │ 📰 반도체 업종 전망...       │   │
│  │ 한국경제 · 1일 전            │   │
│  └─────────────────────────────┘   │
│                                     │
│  (Tối đa 15 tin · Pull to refresh)  │
└─────────────────────────────────────┘
```

| Tính năng | Chi tiết |
|-----------|----------|
| Số lượng | Tối đa 15 tin |
| Hiển thị | Tiêu đề + Nguồn + Thời gian tương đối |
| Thumbnail | Hiển thị nếu có |
| Tap | Mở link gốc trong WebView hoặc external browser |
| Pull to refresh | Tải lại tin mới |
| API | GET `/api/stocks/:symbol/news` |

---

### SCREEN 7: WATCHLIST

**Route:** `/watchlist`  
**Yêu cầu:** requirement II.3.1, II.3.2

```
┌─────────────────────────────────────┐
│  Watchlist (5 mã)      [✏️ Sửa]    │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │ ★ 005930  삼성전자           │   │
│  │ ₩57,400  ▲350 (+0.61%)     │   │
│  │ Vol: 12.3M  Cap: 343조      │   │
│  │ ┌────────────────────────┐  │   │
│  │ │ Mini 5-day sparkline   │  │   │
│  │ └────────────────────────┘  │   │
│  ├─────────────────────────────┤   │
│  │ ★ 000660  SK하이닉스        │   │
│  │ ₩213,500  ▼2,500 (-1.16%)  │   │
│  │ Vol: 5.2M  Cap: 155조       │   │
│  │ ┌────────────────────────┐  │   │
│  │ │ Mini 5-day sparkline   │  │   │
│  │ └────────────────────────┘  │   │
│  └─────────────────────────────┘   │
│                                     │
│  Sắp xếp: [Thêm gần đây] [% ▲▼]   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  + Thêm cổ phiếu            │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

| Tính năng | Free | Pro |
|-----------|------|-----|
| Số lượng tối đa | 10 mã | Không giới hạn |
| Thêm/xóa | ★ toggle trên Stock Detail hoặc Stock List | Tương tự |
| Sắp xếp | Thêm gần đây, % thay đổi, Alphabet | + Custom drag order |
| Sparkline | 5 ngày gần nhất | 5 ngày gần nhất |
| Chế độ sửa | Swipe left → Delete | Swipe left → Delete |
| Đồng bộ | Lưu MongoDB (theo user account) | Tương tự |
| Pull to refresh | Cập nhật giá tất cả | Tương tự |

**API:**
```
GET    /api/watchlist                → Lấy danh sách watchlist
POST   /api/watchlist/:symbol       → Thêm vào watchlist
DELETE /api/watchlist/:symbol       → Xóa khỏi watchlist
PUT    /api/watchlist/reorder       → Sắp xếp lại (Pro)
```

---

### SCREEN 8: CÀI ĐẶT & TÀI KHOẢN

**Route:** `/settings`  
**Yêu cầu:** requirement II.1.2

```
┌─────────────────────────────────────┐
│  Cài đặt                           │
├─────────────────────────────────────┤
│  ▸ TÀI KHOẢN                       │
│  ┌─────────────────────────────┐   │
│  │ 👤 Nguyễn Văn An             │   │
│  │ an@email.com                 │   │
│  │ Free Plan                    │   │
│  │ [Chỉnh sửa thông tin]       │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  ▸ GÓI DỊCH VỤ                     │
│  ┌─────────────────────────────┐   │
│  │ 🆓 Free Plan (hiện tại)     │   │
│  │ 💎 Nâng cấp Pro →           │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  ▸ CÀI ĐẶT CHUNG                   │
│  Ngôn ngữ          [English ▼]      │
│  (English / Tiếng Việt / 한국어)     │
│  Dark/Light mode    [🌙 ▼]          │
│  Realtime interval  [30s ▼]         │
│  Thông báo giá      [ON/OFF]        │
│  Chart mặc định     [Candle ▼]      │
├─────────────────────────────────────┤
│  ▸ AI CREDITS (Pro)                 │
│  Còn lại: 350 credits              │
│  [Mua thêm credits]                │
├─────────────────────────────────────┤
│  ▸ KHÁC                             │
│  Về ứng dụng                        │
│  Điều khoản sử dụng                 │
│  Chính sách bảo mật                 │
│  Đăng xuất                          │
└─────────────────────────────────────┘
```

#### 8.1 Chỉnh sửa thông tin (`/settings/profile`)

| Trường | Cho phép sửa | Validation |
|--------|-------------|------------|
| Họ tên | ✅ | 2–50 ký tự |
| Email | ❌ (chỉ xem) | — |
| Avatar | ✅ | Upload ảnh, max 2MB |
| Đổi mật khẩu | ✅ | Nhập mật khẩu cũ + mới |

**API:**
```
GET    /api/user/profile              → Lấy thông tin
PUT    /api/user/profile              → Cập nhật thông tin
PUT    /api/user/change-password      → Đổi mật khẩu
POST   /api/user/upload-avatar        → Upload avatar
```

---

## IV. NAVIGATION STRUCTURE

### 4.1 Bottom Navigation Bar (4 tabs)

| Tab | Icon | Tên (EN / VI / KO) | Route |
|-----|------|-----|-------|
| 1 | 🏠 | Home / Trang chủ / 홈 | `/home` |
| 2 | 🔍 | Search / Tìm kiếm / 검색 | `/search` → `/stocks` |
| 3 | ⭐ | Watchlist / Danh sách theo dõi / 관심 | `/watchlist` |
| 4 | ⚙️ | Settings / Cài đặt / 설정 | `/settings` |

### 4.2 Navigation Flow

```
Splash → Auth (nếu chưa login) → Home
                                    │
         ┌──────────────────────────┼──────────────────┐
         │                          │                  │
    Home Tab                   Search Tab          Watchlist Tab
         │                          │                  │
    ├─ Market Overview             Search Input         List
    ├─ Watchlist Preview           Stock List           │
    ├─ Top Movers                  │                   │
    └─ News                        │                   │
         │                          │                  │
         └───────── TAP STOCK ──────┴──────────────────┘
                        │
                  Stock Detail
                  ├─ Chart Tab (mặc định)
                  ├─ Info Tab
                  ├─ AI Tab
                  └─ News Tab
```

---

## V. BACKEND API ENDPOINTS (Full)

### 5.1 Authentication

| Method | Endpoint | Mô tả | Auth |
|--------|----------|-------|------|
| POST | `/api/auth/register` | Đăng ký | No |
| POST | `/api/auth/login` | Đăng nhập (email/password) | No |
| POST | `/api/auth/google` | Đăng nhập Google OAuth | No |
| POST | `/api/auth/apple` | Đăng nhập Apple (iOS) | No |
| POST | `/api/auth/forgot-password` | Gửi email reset password | No |
| POST | `/api/auth/reset-password` | Đặt lại mật khẩu | No |
| POST | `/api/auth/verify-email` | Xác thực email | No |
| POST | `/api/auth/refresh-token` | Refresh JWT | Token |

### 5.2 User

| Method | Endpoint | Mô tả | Auth |
|--------|----------|-------|------|
| GET | `/api/user/profile` | Lấy profile | JWT |
| PUT | `/api/user/profile` | Cập nhật profile | JWT |
| PUT | `/api/user/change-password` | Đổi mật khẩu | JWT |
| POST | `/api/user/upload-avatar` | Upload avatar | JWT |
| GET | `/api/user/subscription` | Xem gói hiện tại | JWT |

### 5.3 Stocks

| Method | Endpoint | Mô tả | Auth |
|--------|----------|-------|------|
| GET | `/api/stocks/search?q=` | Tìm kiếm cổ phiếu | No |
| GET | `/api/stocks/list?market=&sort=&page=` | Danh sách cổ phiếu | No |
| GET | `/api/stocks/market-overview` | 8 cổ phiếu top KRX | No |
| GET | `/api/stocks/top-movers` | Top tăng/giảm | No |
| GET | `/api/stocks/:symbol/quote` | Quote realtime | No |
| GET | `/api/stocks/:symbol/history?period=` | OHLCV lịch sử | No |
| GET | `/api/stocks/:symbol/indicators` | RSI, MACD, Stoch, ATR (tính sẵn) | No |
| GET | `/api/stocks/:symbol/news` | Tin tức | No |

### 5.4 Watchlist

| Method | Endpoint | Mô tả | Auth |
|--------|----------|-------|------|
| GET | `/api/watchlist` | Lấy watchlist | JWT |
| POST | `/api/watchlist/:symbol` | Thêm cổ phiếu | JWT |
| DELETE | `/api/watchlist/:symbol` | Xóa cổ phiếu | JWT |
| PUT | `/api/watchlist/reorder` | Sắp xếp lại | JWT |

### 5.5 AI Analysis

| Method | Endpoint | Mô tả | Auth |
|--------|----------|-------|------|
| POST | `/api/ai/analyze` | Phân tích AI | JWT |
| GET | `/api/ai/history` | Lịch sử phân tích | JWT |
| GET | `/api/ai/credits` | Số credit còn lại | JWT |

### 5.6 News

| Method | Endpoint | Mô tả | Auth |
|--------|----------|-------|------|
| GET | `/api/news/latest` | Tin tức mới nhất (chung) | No |

### 5.7 WebSocket

| Event | Hướng | Mô tả |
|-------|-------|-------|
| `subscribe` | Client → Server | Đăng ký nhận realtime cho symbol |
| `unsubscribe` | Client → Server | Hủy đăng ký |
| `price_update` | Server → Client | Push giá mới (Pro: 10s, Free: 30s) |
| `market_status` | Server → Client | Thông báo mở/đóng cửa sàn |

---

## VI. MONGODB DATA MODELS

### 6.1 User

```javascript
{
  _id: ObjectId,
  email: String,              // unique, indexed
  passwordHash: String,       // bcrypt
  name: String,
  avatar: String,             // URL
  provider: "local"|"google"|"apple",
  emailVerified: Boolean,
  role: "user"|"admin",
  subscription: {
    plan: "free"|"pro",
    expiresAt: Date|null,
    credits: Number            // AI credits remaining
  },
  settings: {
    language: "en"|"vi"|"ko",     // default: "en"
    theme: "dark"|"light",
    defaultChartType: "candle"|"line"|"area"|"bar",
    realtimeInterval: 10000|30000,
    notifications: Boolean
  },
  isBlocked: Boolean,
  lastLoginAt: Date,
  createdAt: Date,
  updatedAt: Date
}
```

### 6.2 Watchlist

```javascript
{
  _id: ObjectId,
  userId: ObjectId,           // ref: User, indexed
  symbol: String,             // "005930.KS"
  name: String,               // "삼성전자"
  order: Number,              // Thứ tự hiển thị
  addedAt: Date
}
```

### 6.3 AIAnalysis

```javascript
{
  _id: ObjectId,
  userId: ObjectId,           // ref: User, indexed
  symbol: String,
  level: "basic"|"pro",
  model: "gemini-flash"|"gemini-pro"|"gpt-4",
  prompt: String,             // Prompt gửi AI
  analysis: String,           // Kết quả phân tích
  inputData: {                // Snapshot data tại thời điểm phân tích
    price: Number,
    change: Number,
    rsi: Number,
    macd: Number,
    signal: Number,
    sma20: Number,
    sma60: Number
  },
  creditsUsed: Number,
  createdAt: Date
}
```

### 6.4 SystemLog

```javascript
{
  _id: ObjectId,
  level: "error"|"warn"|"info",
  source: "backend"|"api"|"auth"|"ai",
  message: String,
  stack: String,              // Error stack trace
  meta: Object,               // Additional context
  userId: ObjectId|null,
  createdAt: Date             // TTL index: auto-delete after 14 days
}
```

---

## VII. XỬ LÝ TIMEZONE

### Quy tắc chung
- **Server:** Lưu trữ & truyền Unix timestamps (UTC)
- **Client:** Hiển thị theo KST (Asia/Seoul, UTC+9)
- **Chart (intraday):** Thêm `exchangeGmtOffset` (32400) vào raw timestamp
- **Chart (daily):** Dùng date string `YYYY-MM-DD` (không phụ thuộc timezone)
- **Giờ thị trường:** KRX mở cửa 9:00–15:30 KST, T2-T6

```dart
// Flutter: Hiển thị giờ KST
String formatKST(int unixTimestamp) {
  final kst = DateTime.fromMillisecondsSinceEpoch(
    unixTimestamp * 1000
  ).toUtc().add(Duration(hours: 9));
  return DateFormat('HH:mm:ss').format(kst);
}
```

---

## VIII. HỆ THỐNG CREDIT (AI Pro)

### 8.1 Bảng giá

| Gói | Credits | Giá (KRW) | Giá/credit |
|-----|---------|-----------|------------|
| Starter | 100 | ₩1,000 | ₩10 |
| Standard | 500 | ₩5,000 | ₩10 |
| Premium | 2,000 | ₩15,000 | ₩7.5 |

### 8.2 Chi phí mỗi phân tích

| Loại | Credits | AI Model |
|------|---------|----------|
| Basic (Free tier) | 0 | Gemini Flash |
| Pro Analysis | 10 | Gemini Pro |
| Pro Analysis (GPT-4) | 20 | GPT-4 |

### 8.3 Business Logic

```
Free user:
  - 3 basic analyses / day (reset lúc 00:00 KST)
  - Không dùng được Pro analysis

Pro user:
  - Unlimited basic analyses
  - Pro analysis = trừ credits
  - Credits không có hạn sử dụng
  - Thông báo khi < 50 credits
```

---

## IX. DARK / LIGHT THEME

### 9.1 Dark Theme (Mặc định)

```dart
// Giống web test dashboard
backgroundColor:      Color(0xFF0A0E17)   // --bg
surfaceColor:         Color(0xFF131722)   // --surface
borderColor:          Color(0xFF2A2E39)   // --border
textPrimary:          Color(0xFFD1D4DC)   // --text
textSecondary:        Color(0xFF787B86)   // --text2
accentBlue:           Color(0xFF2962FF)   // --blue
priceUp:              Color(0xFF26A69A)   // --green
priceDown:            Color(0xFFEF5350)   // --red
```

### 9.2 Light Theme

```dart
backgroundColor:      Color(0xFFF5F5F5)
surfaceColor:         Color(0xFFFFFFFF)
borderColor:          Color(0xFFE0E0E0)
textPrimary:          Color(0xFF1A1A2E)
textSecondary:        Color(0xFF666666)
accentBlue:           Color(0xFF2962FF)
priceUp:              Color(0xFF26A69A)
priceDown:            Color(0xFFEF5350)
```

---

## X. ERROR HANDLING & UX

### 10.1 Trạng thái Loading

| Màn hình | Loading UX |
|----------|-----------|
| Stock List | Skeleton shimmer cards |
| Chart | Chart area shimmer + "Loading..." |
| Quote | Giá hiện "—" + shimmer |
| AI Analysis | Typing animation "AI đang phân tích..." |
| News | Skeleton list items |

### 10.2 Trạng thái Empty

| Trường hợp | Hiển thị |
|-------------|---------|
| Search không kết quả | 🔍 "Không tìm thấy kết quả" |
| Watchlist trống | ⭐ "Thêm cổ phiếu vào danh sách theo dõi" + nút |
| News không có | 📰 "Chưa có tin tức" |
| AI chưa phân tích | 🤖 "Nhấn để bắt đầu phân tích" |

### 10.3 Trạng thái Error

| Lỗi | Hiển thị | Hành động |
|-----|---------|-----------|
| Không có mạng | Banner "Không có kết nối internet" | Dùng cached data nếu có |
| API timeout (>8s) | "Tải dữ liệu thất bại" | Nút "Thử lại" |
| 429 Rate limited | "Quá nhiều request, thử lại sau" | Auto retry sau 30s |
| Token expired | Silent refresh → nếu fail → Login | Auto |
| Server 500 | "Lỗi server, thử lại sau" | Nút "Thử lại" |

---

## XI. PUSH NOTIFICATIONS (Tùy chọn)

| Loại | Mô tả | User setting |
|------|-------|-------------|
| Price alert | Giá cổ phiếu trong watchlist vượt ngưỡng đặt | ON/OFF + set threshold |
| Market open/close | Thông báo mở/đóng cửa KRX | ON/OFF |
| AI insight | Tín hiệu kỹ thuật đáng chú ý | Pro only |

---

## XII. FLUTTER PACKAGE RECOMMENDATIONS

| Package | Mục đích |
|---------|----------|
| `flutter_riverpod` hoặc `bloc` | State management |
| `dio` | HTTP client |
| `web_socket_channel` | WebSocket |
| `fl_chart` hoặc `syncfusion_flutter_charts` | Charts |
| `go_router` | Navigation |
| `hive` hoặc `shared_preferences` | Local storage |
| `flutter_secure_storage` | JWT token storage |
| `google_sign_in` | Google OAuth |
| `sign_in_with_apple` | Apple Sign In |
| `firebase_messaging` | Push notifications |
| `shimmer` | Loading skeleton |
| `cached_network_image` | Image cache |
| `intl` | Date/number formatting |
| `flutter_localizations` | i18n — 3 ngôn ngữ (en, vi, ko) |
| `easy_localization` hoặc `slang` | Quản lý bản dịch ARB/JSON |

---

## XIII. TỔNG KẾT API CALLS PER SCREEN

| Màn hình | API calls khi load | Realtime |
|----------|-------------------|----------|
| Home | market-overview(1) + watchlist(1) + top-movers(1) + news(1) = **4** | index price (KOSPI/KOSDAQ) mỗi 30s |
| Search | search(1) per keystroke (debounce 300ms) | — |
| Stock List | list(1) per page | — |
| Stock Detail - Chart | quote(1) + history(1) + indicators(1) = **3** | price mỗi 10-30s |
| Stock Detail - Info | quote(1) = **1** (đã có từ Chart) | price mỗi 10-30s |
| Stock Detail - AI | analyze(1) = **1** | — |
| Stock Detail - News | news(1) = **1** | — |
| Watchlist | watchlist(1) + quotes(1, batch) = **2** | price batch mỗi 30s |
| Settings | profile(1) + subscription(1) = **2** | — |

---

## XIV. BẢO MẬT

| Aspect | Implementation |
|--------|---------------|
| Auth | JWT (access token 15min + refresh token 7d) |
| Password | bcrypt hash, salt rounds=10 |
| API | HTTPS only, CORS whitelist |
| Token storage | `flutter_secure_storage` (Keychain iOS / Keystore Android) |
| Rate limiting | 100 req/min per user, 20 req/min for AI |
| Input validation | Server-side validation tất cả endpoints |
| AI prompt injection | Sanitize user input trước khi gửi AI |
