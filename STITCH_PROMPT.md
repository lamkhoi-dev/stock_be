# 🎨 KRX STOCK ANALYSIS — STITCH UI PROMPT

## PROMPT (copy toàn bộ phần dưới vào Stitch)

---

Design a premium Korean Stock Market Analysis mobile app called **"KRX Analysis"**. This is a professional finance/investment app for analyzing stocks on the Korea Exchange (KOSPI & KOSDAQ). The app targets international investors who want real-time Korean stock prices, advanced charts, technical indicators, AI-powered analysis, and market news — all in a beautifully designed mobile experience.

**Multi-language support:** The app supports 3 languages — **English** (default), **Vietnamese (Tiếng Việt)**, and **Korean (한국어)**. Design the UI with **English as the primary language** for all labels, buttons, navigation, headers. Stock names always show dual: Korean name + English name (e.g. "삼성전자 Samsung Electronics"). The design should accommodate text length variations across languages.

### DESIGN PHILOSOPHY
- **Premium & Trustworthy** — Think Bloomberg meets Robinhood. Clean, data-dense but not cluttered.
- **Dark-first design** (like TradingView) with an optional light mode.
- **International with Korean market focus** — Currency in ₩ (KRW), stock names dual (Korean + English), exchange badges (KOSPI/KOSDAQ). UI labels in English.
- **Data-rich cards** — Every stock card shows: logo/icon, name (Korean + English), exchange badge, mini sparkline chart (5-day), current price, price change (₩ and %), volume.
- **Color-coded prices** — Green (#22C55E) for gains, Red (#EF4444) for losses, consistent across all screens.
- **Smooth transitions** — Subtle animations on page transitions, card taps, and data loading (shimmer skeletons).

---

### DESIGN SYSTEM

#### Colors — Dark Theme (Primary)
```
Background:        #0B0D17  (deep navy-black)
Surface/Cards:     #141620  (elevated dark)  
Surface Hover:     #1C1F2E  (subtle lift)
Border:            #2A2D3A  (soft separator)
Text Primary:      #E8EAED  (crisp white-gray)
Text Secondary:    #8B8FA3  (muted)
Text Tertiary:     #4E5263  (disabled/hint)
Accent/Primary:    #3B82F6  (vibrant blue — buttons, active tabs, links)
Price Up:          #22C55E  (green — stock gains, bullish signals)
Price Down:        #EF4444  (red — stock losses, bearish signals)  
Price Neutral:     #8B8FA3  (gray — no change)
Chart Line:        #3B82F6  (blue line charts)
Volume Up:         rgba(34,197,94,0.4)  (semi-transparent green)
Volume Down:       rgba(239,68,68,0.4)  (semi-transparent red)
Gold/Premium:      #F59E0B  (Pro badge, AI premium features)
```

#### Colors — Light Theme
```
Background:        #F8F9FB
Surface/Cards:     #FFFFFF
Border:            #E5E7EB
Text Primary:      #111827
Text Secondary:    #6B7280
Accent:            #2563EB
(Same green/red for prices)
```

#### Typography
- **Font:** Inter or Pretendard (supports Korean hangul beautifully)
- **Headline Large:** 28px, Bold — Index values, main stock price on detail
- **Headline Medium:** 22px, SemiBold — Section titles
- **Title:** 17px, SemiBold — Stock names, card headers
- **Body:** 15px, Regular — Price values, descriptions
- **Caption:** 12px, Medium — Exchange badges, timestamps, labels
- **Mono:** JetBrains Mono or SF Mono — Prices, numbers, chart axis labels

#### Spacing & Radius
- **Card radius:** 16px  
- **Button radius:** 12px  
- **Input radius:** 12px  
- **Card padding:** 16px  
- **Section gap:** 24px  
- **List item gap:** 12px

#### Component Tokens
- **Stock Card:** Surface background, 16px radius, subtle border, inner flex layout (logo | name+exchange | sparkline | price+change)
- **Price Badge:** Rounded 8px, green/red background at 12% opacity, colored text
- **Tab Bar:** Pill-shaped active indicator with accent color, smooth slide animation
- **Bottom Navigation:** 4 tabs — 홈(Home), 검색(Search), 관심(Watchlist), 설정(Settings). Active = accent blue + filled icon, Inactive = gray + outline icon.
- **Market Status Chip:** Dot indicator (green pulse = OPEN, gray = CLOSED) + text

---

### KEY SCREENS TO DESIGN

#### SCREEN 1: HOME (홈) — Main Dashboard

The home screen is a vertically scrollable dashboard with 5 distinct sections:

**Section A: Market Status Header** (sticky top)
- App logo "KRX" with Korean flag subtle accent
- Search bar (tap → navigates to Search screen): "Search stocks..." with search icon and filter icon
- Notification bell icon with badge

**Section B: Market Index Card** (hero section)
- Large card showing KOSPI index: "KOSPI", price "2,645.32" in large green/red text
- Change: "+13.00 (+0.49%)"
- Mini area chart (smooth gradient fill) showing 1-week performance
- Period selector pills below chart: Day / Week / Month / Year / All (Week active by default)
- Secondary row: KOSDAQ index "872.15 ▼0.12%" in smaller format

**Section C: Market Overview** (horizontal scroll)
- Section header: "Popular Stocks" with "See All" link
- Horizontally scrolling stock cards (card width ~160px):
  - Company icon/logo placeholder (colored circle with first letter)
  - Stock name dual: "삼성전자" (Korean) + "Samsung" (English subtitle, smaller)
  - Exchange badge: "KOSPI" in tiny pill
  - Mini sparkline chart (5-day, green or red gradient)
  - Price: "₩57,400"  
  - Change: "+350 (+0.61%)" or "▲0.61%" in green

**Section D: Watchlist Preview** (vertical list)
- Section header: "Watchlist" with "See All"
- 3-5 stock items in list format, each showing:
  - Company icon (colored circle)
  - Name + Exchange badge
  - Mini sparkline (last 5 days)
  - Price (right-aligned, large)
  - Change amount + percentage (green/red text)
- Subtle dividers between items

**Section E: Most Active / Top Movers** (tabs)
- Tab toggle: "Top Gainers" | "Top Losers"
- List of 5 stocks with rank number, same card format as Section D
- Each with green (top gainers) or red (top losers) percentage badges

**Bottom Navigation Bar:**
- 4 tabs with icons + English labels
- Home — house icon, ACTIVE (accent blue)
- Search — magnifying glass
- Watchlist — star
- Settings — gear
- Floating subtle blur backdrop behind nav bar

---

#### SCREEN 2: STOCK DETAIL (종목 상세) — Most Complex Screen

This is the core screen — accessed by tapping any stock card.

**Header Bar:**
- Back arrow, Stock symbol "005930.KS", Watchlist star toggle ★, Share icon, More menu ⋮
- Below: Stock name "삼성전자" + "Samsung Electronics"
- Exchange badge "KOSPI" + Currency "KRW" + 🇰🇷 flag
- **Large price:** "₩57,400" (green if up, red if down)
- **Change:** "▲ ₩350 (+0.61%)" with colored badge
- **Updated time:** "14:25 KST" in caption text

**Tab Bar:** 4 tabs with smooth sliding underline indicator
- **Chart** — DEFAULT active tab
- **Info**
- **AI Analysis** — with tiny ✨ sparkle icon
- **News**

**Tab: 차트 (Chart):**

Period selector row — horizontal pills:
`[1D] [5D] [1M] [3M] [6M] [1Y] [2Y] [5Y]`
Active period has accent blue background.

Chart type icons row:
`[🕯 Candle] [📈 Line] [△ Area] [| Bar]`
Small icon buttons, active one is highlighted.

**Main Chart Area** (takes ~45% of screen height):
- Professional candlestick chart with volume histogram below
- Green candles (up) / Red candles (down)
- Volume bars in corresponding colors at bottom
- Touch crosshair showing price/time tooltip
- Pinch to zoom, horizontal scroll supported
- Grid lines subtle (#1C1F2E)

**Overlay Toggle Chips** (below chart):
`[MA ▼] [BB] [VOL ✓]`
- MA dropdown: checkboxes for MA5, MA10, MA20, MA60, MA120 (with color dots: orange, blue, pink, purple, cyan)
- BB: Bollinger Bands toggle
- VOL: Volume toggle (on by default)

**Indicator Sub-Charts** (collapsible section):
- Section header: "Technical Indicators" with collapse/expand chevron
- **RSI (14):** Mini line chart, purple line, horizontal reference lines at 70 and 30 (dashed red/green), current value badge "62.5"
- **MACD (12,26,9):** Blue line (MACD) + Orange line (Signal) + colored histogram bars, values shown
- **Stochastic (5,3,3):** Blue (%K) + Red (%D) lines, reference lines at 80 and 20

**Technical Summary Card** (below indicators):
- Compact grid showing signals:
  ```
  RSI(14)    62.5     ● Neutral
  MACD       245.3    ● Bullish  (green dot)
  Stoch %K   72.4     ● Neutral
  ATR(14)    1,250    ● Med Vol
  SMA 20     Above    ● Bullish  (green dot)
  SMA 60     Above    ● Bullish  (green dot)
  ```

---

#### SCREEN 3: ALL STOCKS LIST

**Top bar:**
- Hamburger or back icon
- Search bar: "Search stocks..." with filter icon

**Filter Row:**
- Market filter pills: `[All] [KOSPI] [KOSDAQ]`
- Sort dropdown: "Sort: Change % ▼"

**Stock List:**
- Full-width list items, each containing:
  - Company icon (colored circle with letter/logo)
  - Stock name (Korean + English) + Exchange badge (tiny pill: "KOSPI" or "KOSDAQ")
  - Mini sparkline chart in the middle (5-day, ~80px wide, green or red fill)
  - Right side: Price (bold) + Change (green/red text with +/- prefix)
- Subtle divider between items
- Infinite scroll with loading indicator at bottom
- Pull-to-refresh

**Sample data to show:**
```
삼성전자    KOSPI    [sparkline↗]    ₩57,400    +350 (+0.61%)
SK하이닉스  KOSPI    [sparkline↘]    ₩213,500   -2,500 (-1.16%)
NAVER      KOSPI    [sparkline↗]    ₩198,000   +1,500 (+0.76%)
카카오      KOSPI    [sparkline↘]    ₩42,300    -450 (-1.05%)
현대차      KOSPI    [sparkline→]    ₩225,000   +500 (+0.22%)
LG화학      KOSPI    [sparkline↗]    ₩380,000   +12,000 (+3.26%)
삼성SDI     KOSPI    [sparkline↘]    ₩412,500   -7,500 (-1.79%)
삼성바이오   KOSPI    [sparkline↗]    ₩780,000   +15,000 (+1.96%)
```

---

#### SCREEN 4: LOGIN / WELCOME

**Clean centered layout:**
- Top: App logo — stylized stock chart icon with subtle Korean flag accent, modern and minimal
- App name: **"KRX Analysis"** in elegant typography
- Tagline: "Korean Stock AI Analysis" in secondary text
- Language selector: small pill group at top → [EN] [VI] [KO]

**Login form:**
- Email input field with envelope icon
- Password input field with lock icon + show/hide toggle
- "Login" primary button — full width, accent blue, 12px radius, bold white text
- Divider: "──── or ────"
- "Continue with Google" — outlined button with Google icon
- "Continue with Apple" — dark button with Apple icon (iOS only)

**Bottom links:**
- "Forgot password?" — accent blue text link
- "Don't have an account? Sign up" — accent blue text link

---

### DESIGN NOTES & REQUIREMENTS

1. **All prices in Korean Won (₩)**: Use comma separators (₩57,400), not decimal for KRW
2. **English UI labels** as default. Stock names always dual: Korean name (삼성전자) + English subtitle (Samsung Electronics). The app supports 3 languages (EN/VI/KO) but design screens in English
3. **Sparkline charts**: Simple, smooth area charts with gradient fill — green gradient for uptrend, red gradient for downtrend
4. **Company icons**: Circular with the first character of company name, using distinct background colors per company (Samsung=blue, SK=red, NAVER=green, etc.)
5. **No trading features**: This is analysis-only. No buy/sell buttons. Focus on data visualization and analysis.
6. **Professional finance aesthetic**: Dense but organized data, like Bloomberg Terminal adapted for mobile
7. **Responsive**: Design at 390px width (iPhone 14/15 standard)
8. **Status bar**: Light content on dark background
9. **Loading states**: Use shimmer/skeleton placeholders matching card shapes
10. **Pro badge**: Gold ✨ accent for premium features (AI Pro analysis)

### ADDITIONAL COMPONENT NEEDS
- **Shimmer skeleton** for loading cards and lists
- **Empty state illustration** for empty watchlist (star icon + "Add stocks to your watchlist")
- **Error state** with retry button
- **Pull-to-refresh indicator** styled in accent blue
- **Toast/Snackbar** for actions (added to watchlist, removed, etc.)
- **Badge indicator** for notification bell
- **Floating action button** (optional) for quick AI analysis on Stock Detail

---

> **Theme:** Dark mode primary. Professional finance. Korean market data, international UI (English default, supports Vietnamese & Korean). Data-dense but beautiful. TradingView-inspired charts area. Clean card-based layout for lists. Smooth animations and transitions. Green for gains, red for losses — consistent throughout.
