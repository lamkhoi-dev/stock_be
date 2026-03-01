import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import axios from 'axios';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;
const ALPHA_KEY = process.env.ALPHA_VANTAGE_KEY || 'demo';
const KRX_KEY = process.env.KRX_API_KEY || '';

// ==========================================
//  KIS (Korea Investment) API CONFIG
// ==========================================
const KIS_BASE = 'https://openapi.koreainvestment.com:9443';
const KIS_APP_KEY = process.env.KIS_APP_KEY || 'PSsw5JXblDis6LZJ1tSqMbLwUQFOqQLlopQR';
const KIS_APP_SECRET = process.env.KIS_APP_SECRET || '0xg6RH037SyXviB49SxYRjSihI6rnWnOfPdDmPGO83blrJddgPVtyYFM3r5JFo50qobhCX0hG1EUIGDUOvcUUDcIrYakX5L3Y+HAQWEDFhv02/SeIQvcTznbhCjhgKnpJFoHaHSiqiN4vDSgwgXV5yGhuZCmHabSf/d9YNK/VSppa+EtS6E=';

// Token management
let kisToken = { token: '', expiresAt: 0 };

async function getKisToken() {
  // Return cached token if still valid (refresh 1h before expiry)
  if (kisToken.token && Date.now() < kisToken.expiresAt - 3600000) {
    return kisToken.token;
  }
  try {
    const { data } = await axios.post(`${KIS_BASE}/oauth2/tokenP`, {
      grant_type: 'client_credentials',
      appkey: KIS_APP_KEY,
      appsecret: KIS_APP_SECRET,
    }, { headers: { 'Content-Type': 'application/json' }, timeout: 10000 });

    kisToken.token = data.access_token;
    // Token valid for ~24h, parse expires_in or default 23h
    kisToken.expiresAt = Date.now() + (data.expires_in ? data.expires_in * 1000 : 23 * 3600000);
    console.log(`  [KIS] Token refreshed, expires: ${new Date(kisToken.expiresAt).toLocaleString()}`);
    return kisToken.token;
  } catch (err) {
    console.error('  [KIS] Token error:', err.response?.data || err.message);
    throw new Error('KIS token failed: ' + (err.response?.data?.msg1 || err.message));
  }
}

function kisHeaders(trId) {
  return {
    'Content-Type': 'application/json; charset=utf-8',
    'authorization': `Bearer ${kisToken.token}`,
    'appkey': KIS_APP_KEY,
    'appsecret': KIS_APP_SECRET,
    'tr_id': trId,
    'custtype': 'P',
  };
}

// Rate limiter: max 1 KIS request per 300ms
let lastKisCall = 0;
async function kisThrottle() {
  const now = Date.now();
  const wait = Math.max(0, 300 - (now - lastKisCall));
  if (wait > 0) await new Promise(r => setTimeout(r, wait));
  lastKisCall = Date.now();
}

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ==========================================
// Simple in-memory cache (save API quota)
// ==========================================
const cache = new Map();

function getCached(key, ttlMs) {
  const entry = cache.get(key);
  if (entry && Date.now() - entry.time < ttlMs) return entry.data;
  return null;
}

function setCache(key, data) {
  cache.set(key, { data, time: Date.now() });
}

// Common headers for Yahoo Finance direct API calls
const YF_HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
};
const YF_CHART = 'https://query1.finance.yahoo.com/v8/finance/chart';
const YF_SEARCH = 'https://query1.finance.yahoo.com/v1/finance/search';

// ==========================================
//  YAHOO FINANCE ENDPOINTS (Direct API)
// ==========================================

// Health check
app.get('/api/yahoo/health', async (req, res) => {
  try {
    const { data } = await axios.get(`${YF_CHART}/005930.KS`, {
      params: { range: '1d', interval: '1d' },
      headers: YF_HEADERS
    });
    const meta = data.chart.result[0].meta;
    res.json({
      success: true,
      message: 'Yahoo Finance connected (direct API)',
      sample: {
        symbol: meta.symbol,
        name: 'Samsung Electronics',
        price: meta.regularMarketPrice,
        currency: meta.currency
      }
    });
  } catch (err) {
    res.json({ success: false, error: err.response?.status === 429 ? 'Rate limited' : err.message });
  }
});

// Search stocks
app.get('/api/yahoo/search', async (req, res) => {
  try {
    const q = req.query.q;
    if (!q) return res.json({ success: false, error: 'Query "q" is required' });

    const cacheKey = `ys_${q}`;
    const cached = getCached(cacheKey, 5 * 60 * 1000);
    if (cached) return res.json({ success: true, data: cached, cached: true });

    const { data } = await axios.get(YF_SEARCH, {
      params: { q, quotesCount: 15, newsCount: 0, enableFuzzyQuery: true },
      headers: YF_HEADERS
    });
    setCache(cacheKey, data);
    res.json({ success: true, data });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// Single stock quote (extracted from chart endpoint - more reliable than v7/v10)
app.get('/api/yahoo/quote/:symbol', async (req, res) => {
  try {
    const symbol = req.params.symbol;
    const cacheKey = `yq_${symbol}`;
    const cached = getCached(cacheKey, 5 * 1000); // 5 sec for near-realtime
    if (cached) return res.json({ success: true, data: cached, cached: true });

    const { data } = await axios.get(`${YF_CHART}/${symbol}`, {
      params: { range: '5d', interval: '1d', includePrePost: false },
      headers: YF_HEADERS,
      timeout: 8000
    });

    const result = data.chart.result[0];
    const meta = result.meta;
    const quotes = result.indicators?.quote?.[0] || {};
    const timestamps = result.timestamp || [];

    // Build quote-like response from chart data
    const lastIdx = timestamps.length - 1;
    const prevIdx = lastIdx > 0 ? lastIdx - 1 : 0;
    const currentClose = quotes.close?.[lastIdx] || meta.regularMarketPrice;
    const prevClose = quotes.close?.[prevIdx] || meta.chartPreviousClose || meta.previousClose;
    const change = currentClose - prevClose;
    const changePct = prevClose ? (change / prevClose) * 100 : 0;

    const quoteData = {
      symbol: meta.symbol,
      shortName: meta.shortName || meta.symbol,
      longName: meta.longName || '',
      currency: meta.currency,
      exchange: meta.exchangeName,
      fullExchangeName: meta.fullExchangeName || meta.exchangeName,
      regularMarketPrice: meta.regularMarketPrice,
      regularMarketChange: change,
      regularMarketChangePercent: changePct,
      regularMarketOpen: quotes.open?.[lastIdx],
      regularMarketDayHigh: quotes.high?.[lastIdx],
      regularMarketDayLow: quotes.low?.[lastIdx],
      regularMarketVolume: quotes.volume?.[lastIdx],
      regularMarketPreviousClose: meta.chartPreviousClose || prevClose,
      regularMarketTime: meta.regularMarketTime,
      marketCap: null,
      fiftyTwoWeekHigh: meta.fiftyTwoWeekHigh,
      fiftyTwoWeekLow: meta.fiftyTwoWeekLow,
      marketState: meta.marketState
    };

    setCache(cacheKey, quoteData);
    res.json({ success: true, data: quoteData });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// Multiple quotes
app.get('/api/yahoo/quotes', async (req, res) => {
  try {
    const symbols = (req.query.symbols || '').split(',').filter(Boolean);
    if (!symbols.length) return res.json({ success: false, error: 'symbols param required' });

    const results = await Promise.all(
      symbols.map(async (s) => {
        try {
          const { data } = await axios.get(`${YF_CHART}/${s}`, {
            params: { range: '1d', interval: '1d' },
            headers: YF_HEADERS
          });
          const meta = data.chart.result[0].meta;
          return { symbol: meta.symbol, price: meta.regularMarketPrice, currency: meta.currency };
        } catch (e) {
          return { symbol: s, error: e.message };
        }
      })
    );
    res.json({ success: true, data: results });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// Historical OHLCV (supports both daily and intraday)
app.get('/api/yahoo/history/:symbol', async (req, res) => {
  try {
    const symbol = req.params.symbol;
    const period = req.query.period || '6m';
    let interval = req.query.interval;

    // Map period to Yahoo range format + default interval
    const periodConfig = {
      '1d':  { range: '1d',  defaultInterval: '5m'  },
      '5d':  { range: '5d',  defaultInterval: '15m' },
      '1w':  { range: '5d',  defaultInterval: '15m' },
      '1m':  { range: '1mo', defaultInterval: '1h'  },
      '3m':  { range: '3mo', defaultInterval: '1d'  },
      '6m':  { range: '6mo', defaultInterval: '1d'  },
      '1y':  { range: '1y',  defaultInterval: '1d'  },
      '2y':  { range: '2y',  defaultInterval: '1wk' },
      '5y':  { range: '5y',  defaultInterval: '1wk' }
    };
    const config = periodConfig[period] || periodConfig['6m'];
    const range = config.range;
    if (!interval) interval = config.defaultInterval;

    // Determine if intraday
    const isIntraday = ['1m', '2m', '5m', '15m', '30m', '60m', '90m', '1h'].includes(interval);

    // Shorter cache for intraday data
    const cacheTTL = isIntraday ? 60 * 1000 : 5 * 60 * 1000;
    const cacheKey = `yh_${symbol}_${range}_${interval}`;
    const cached = getCached(cacheKey, cacheTTL);
    if (cached) return res.json({ success: true, data: cached.data, count: cached.count, isIntraday: cached.isIntraday, exchangeGmtOffset: cached.exchangeGmtOffset, cached: true });

    const { data } = await axios.get(`${YF_CHART}/${symbol}`, {
      params: { range, interval, includePrePost: false },
      headers: YF_HEADERS
    });

    const result = data.chart.result[0];
    const timestamps = result.timestamp || [];
    const quotes = result.indicators.quote[0];
    const adjClose = result.indicators.adjclose?.[0]?.adjclose;
    const exchangeGmtOffset = result.meta.gmtoffset || 32400; // KST = +9h = 32400

    // For intraday: return RAW UTC Unix timestamps + exchangeGmtOffset
    //   → Client will adjust for display in KST regardless of browser timezone
    // For daily: return 'YYYY-MM-DD' date strings (timezone-independent)
    const history = timestamps.map((t, i) => {
      const entry = {
        time: isIntraday ? t : new Date(t * 1000).toISOString().split('T')[0],
        open: quotes.open[i],
        high: quotes.high[i],
        low: quotes.low[i],
        close: quotes.close[i],
        volume: quotes.volume[i]
      };
      if (adjClose) entry.adjClose = adjClose[i];
      return entry;
    }).filter(h => h.close != null);

    const result2 = { data: history, count: history.length, isIntraday, exchangeGmtOffset };
    setCache(cacheKey, result2);
    res.json({ success: true, ...result2 });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// ==========================================
//  ALPHA VANTAGE ENDPOINTS
// ==========================================
const ALPHA_BASE = 'https://www.alphavantage.co/query';

// Health check
app.get('/api/alpha/health', async (req, res) => {
  try {
    const url = `${ALPHA_BASE}?function=GLOBAL_QUOTE&symbol=IBM&apikey=${ALPHA_KEY}`;
    const { data } = await axios.get(url);
    if (data['Error Message'] || data['Note']) {
      return res.json({ success: false, error: data['Error Message'] || data['Note'] });
    }
    res.json({
      success: true,
      message: 'Alpha Vantage connected',
      keyType: ALPHA_KEY === 'demo' ? 'demo (only US stocks)' : 'custom key'
    });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// Alpha Vantage symbol search
app.get('/api/alpha/search', async (req, res) => {
  try {
    const q = req.query.q;
    const url = `${ALPHA_BASE}?function=SYMBOL_SEARCH&keywords=${encodeURIComponent(q)}&apikey=${ALPHA_KEY}`;
    const { data } = await axios.get(url);
    res.json({ success: true, data });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// RSI indicator
app.get('/api/alpha/rsi/:symbol', async (req, res) => {
  try {
    const symbol = req.params.symbol;
    const cacheKey = `ar_${symbol}`;
    const cached = getCached(cacheKey, 60 * 60 * 1000); // 1h cache
    if (cached) return res.json({ success: true, data: cached, cached: true });

    const url = `${ALPHA_BASE}?function=RSI&symbol=${symbol}&interval=daily&time_period=14&series_type=close&apikey=${ALPHA_KEY}`;
    const { data } = await axios.get(url);

    if (data['Error Message']) return res.json({ success: false, error: data['Error Message'] });
    if (data['Note']) return res.json({ success: false, error: 'Rate limited (25 req/day free tier)', rateLimited: true });
    if (data['Information']) return res.json({ success: false, error: data['Information'] });

    setCache(cacheKey, data);
    res.json({ success: true, data });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// MACD indicator
app.get('/api/alpha/macd/:symbol', async (req, res) => {
  try {
    const symbol = req.params.symbol;
    const cacheKey = `am_${symbol}`;
    const cached = getCached(cacheKey, 60 * 60 * 1000);
    if (cached) return res.json({ success: true, data: cached, cached: true });

    const url = `${ALPHA_BASE}?function=MACD&symbol=${symbol}&interval=daily&series_type=close&apikey=${ALPHA_KEY}`;
    const { data } = await axios.get(url);

    if (data['Error Message']) return res.json({ success: false, error: data['Error Message'] });
    if (data['Note']) return res.json({ success: false, error: 'Rate limited (25 req/day free tier)', rateLimited: true });
    if (data['Information']) return res.json({ success: false, error: data['Information'] });

    setCache(cacheKey, data);
    res.json({ success: true, data });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// Bollinger Bands
app.get('/api/alpha/bbands/:symbol', async (req, res) => {
  try {
    const symbol = req.params.symbol;
    const cacheKey = `ab_${symbol}`;
    const cached = getCached(cacheKey, 60 * 60 * 1000);
    if (cached) return res.json({ success: true, data: cached, cached: true });

    const url = `${ALPHA_BASE}?function=BBANDS&symbol=${symbol}&interval=daily&time_period=20&series_type=close&nbdevup=2&nbdevdn=2&apikey=${ALPHA_KEY}`;
    const { data } = await axios.get(url);

    if (data['Error Message']) return res.json({ success: false, error: data['Error Message'] });
    if (data['Note']) return res.json({ success: false, error: 'Rate limited (25 req/day free tier)', rateLimited: true });
    if (data['Information']) return res.json({ success: false, error: data['Information'] });

    setCache(cacheKey, data);
    res.json({ success: true, data });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// Stochastic Oscillator
app.get('/api/alpha/stoch/:symbol', async (req, res) => {
  try {
    const symbol = req.params.symbol;
    const cacheKey = `as_${symbol}`;
    const cached = getCached(cacheKey, 60 * 60 * 1000);
    if (cached) return res.json({ success: true, data: cached, cached: true });

    const { data } = await axios.get(ALPHA_BASE, {
      params: { function: 'STOCH', symbol, interval: 'daily', apikey: ALPHA_KEY }
    });
    if (data['Error Message']) return res.json({ success: false, error: data['Error Message'] });
    if (data['Note'] || data['Information']) return res.json({ success: false, error: 'Rate limited', rateLimited: true });

    setCache(cacheKey, data);
    res.json({ success: true, data });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// Average True Range
app.get('/api/alpha/atr/:symbol', async (req, res) => {
  try {
    const symbol = req.params.symbol;
    const cacheKey = `at_${symbol}`;
    const cached = getCached(cacheKey, 60 * 60 * 1000);
    if (cached) return res.json({ success: true, data: cached, cached: true });

    const { data } = await axios.get(ALPHA_BASE, {
      params: { function: 'ATR', symbol, interval: 'daily', time_period: 14, apikey: ALPHA_KEY }
    });
    if (data['Error Message']) return res.json({ success: false, error: data['Error Message'] });
    if (data['Note'] || data['Information']) return res.json({ success: false, error: 'Rate limited', rateLimited: true });

    setCache(cacheKey, data);
    res.json({ success: true, data });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// ==========================================
//  KIS (Korea Investment) API ENDPOINTS
// ==========================================

// KIS Health check + token
app.get('/api/kis/health', async (req, res) => {
  try {
    const token = await getKisToken();
    res.json({ success: true, message: 'KIS API connected', tokenPreview: token.substring(0, 20) + '...' });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// KIS Current Price (주식현재가 시세) - FHKST01010100
app.get('/api/kis/price/:symbol', async (req, res) => {
  try {
    const code = req.params.symbol.replace(/\.(KS|KQ)$/i, ''); // Strip .KS/.KQ suffix
    const cacheKey = `kis_price_${code}`;
    const cached = getCached(cacheKey, 30 * 1000); // 30s cache
    if (cached) return res.json({ success: true, data: cached, source: 'kis', cached: true });

    await getKisToken();
    await kisThrottle();

    const { data } = await axios.get(`${KIS_BASE}/uapi/domestic-stock/v1/quotations/inquire-price`, {
      headers: kisHeaders('FHKST01010100'),
      params: { FID_COND_MRKT_DIV_CODE: 'J', FID_INPUT_ISCD: code },
      timeout: 8000
    });

    if (data.rt_cd !== '0') return res.json({ success: false, error: data.msg1 || 'KIS API error' });

    const o = data.output;
    const priceData = {
      symbol: code,
      name: o.hts_kor_isnm || code,
      price: parseInt(o.stck_prpr) || 0,
      change: parseInt(o.prdy_vrss) || 0,
      changePct: parseFloat(o.prdy_ctrt) || 0,
      changeSign: o.prdy_vrss_sign, // 1=up 2=flat 3=stay 4=down limit 5=down
      open: parseInt(o.stck_oprc) || 0,
      high: parseInt(o.stck_hgpr) || 0,
      low: parseInt(o.stck_lwpr) || 0,
      prevClose: parseInt(o.stck_sdpr) || 0,
      volume: parseInt(o.acml_vol) || 0,
      tradingValue: parseInt(o.acml_tr_pbmn) || 0,
      marketCap: parseInt(o.hts_avls) || 0, // 시가총액(억)
      per: parseFloat(o.per) || 0,
      pbr: parseFloat(o.pbr) || 0,
      eps: parseInt(o.eps) || 0,
      high52w: parseInt(o.stck_dryy_hgpr) || 0,
      low52w: parseInt(o.stck_dryy_lwpr) || 0,
      upperLimit: parseInt(o.stck_mxpr) || 0,
      lowerLimit: parseInt(o.stck_llam) || 0,
    };

    setCache(cacheKey, priceData);
    res.json({ success: true, data: priceData, source: 'kis' });
  } catch (err) {
    res.json({ success: false, error: err.message, source: 'kis' });
  }
});

// KIS Daily OHLCV (기간별시세) - FHKST03010100
app.get('/api/kis/chart/:symbol', async (req, res) => {
  try {
    const code = req.params.symbol.replace(/\.(KS|KQ)$/i, '');
    const periodType = req.query.period || 'D'; // D=Day, W=Week, M=Month, Y=Year
    const endDate = req.query.endDate || new Date().toISOString().slice(0, 10).replace(/-/g, '');
    // Default start date based on period
    const startDefaults = { D: 180, W: 365, M: 730, Y: 3650 };
    const daysBack = startDefaults[periodType] || 180;
    const startDate = req.query.startDate || new Date(Date.now() - daysBack * 86400000).toISOString().slice(0, 10).replace(/-/g, '');

    const cacheKey = `kis_chart_${code}_${periodType}_${startDate}_${endDate}`;
    const cached = getCached(cacheKey, 5 * 60 * 1000);
    if (cached) return res.json({ success: true, ...cached, source: 'kis', cached: true });

    await getKisToken();
    await kisThrottle();

    const { data } = await axios.get(`${KIS_BASE}/uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice`, {
      headers: kisHeaders('FHKST03010100'),
      params: {
        FID_COND_MRKT_DIV_CODE: 'J',
        FID_INPUT_ISCD: code,
        FID_INPUT_DATE_1: startDate,
        FID_INPUT_DATE_2: endDate,
        FID_PERIOD_DIV_CODE: periodType,
        FID_ORG_ADJ_PRC: '0', // 0=수정주가 반영, 1=미반영
      },
      timeout: 10000
    });

    if (data.rt_cd !== '0') return res.json({ success: false, error: data.msg1 });

    // output2 = array of OHLCV, most recent first → reverse for chart
    const history = (data.output2 || []).filter(o => o.stck_bsop_date).reverse().map(o => ({
      time: `${o.stck_bsop_date.substring(0, 4)}-${o.stck_bsop_date.substring(4, 6)}-${o.stck_bsop_date.substring(6, 8)}`,
      open: parseInt(o.stck_oprc) || 0,
      high: parseInt(o.stck_hgpr) || 0,
      low: parseInt(o.stck_lwpr) || 0,
      close: parseInt(o.stck_clpr) || 0,
      volume: parseInt(o.acml_vol) || 0,
    })).filter(h => h.close > 0);

    const result = { data: history, count: history.length, isIntraday: false, periodType };
    setCache(cacheKey, result);
    res.json({ success: true, ...result, source: 'kis' });
  } catch (err) {
    res.json({ success: false, error: err.message, source: 'kis' });
  }
});

// KIS Minute Candles (분봉조회) - FHKST03010200
// Paginated: API returns ~30 records per call, we make multiple calls for full day
function getKstTimeStr() {
  const kst = new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Seoul' }));
  return String(kst.getHours()).padStart(2, '0') + String(kst.getMinutes()).padStart(2, '0') + '00';
}
function isKrxMarketHours() {
  const kst = new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Seoul' }));
  const h = kst.getHours(), m = kst.getMinutes(), day = kst.getDay();
  if (day === 0 || day === 6) return false;
  const t = h * 60 + m;
  return t >= 540 && t <= 960; // 9:00 ~ 16:00 (include after-close auction)
}

app.get('/api/kis/minutechart/:symbol', async (req, res) => {
  try {
    const code = req.params.symbol.replace(/\.(KS|KQ)$/i, '');
    // Use current KST time during market hours, or market close time otherwise
    const startTime = req.query.time || (isKrxMarketHours() ? getKstTimeStr() : '160000');
    const maxPages = Math.min(parseInt(req.query.pages) || 6, 10);
    const cacheKey = `kis_min_${code}_${startTime.substring(0, 4)}`;
    const cached = getCached(cacheKey, 60 * 1000); // 60s cache for intraday
    if (cached) return res.json({ success: true, ...cached, source: 'kis', cached: true });

    // Helper: fetch one page of minute data with retry
    const fetchPage = async (time, retries = 1) => {
      for (let attempt = 0; attempt <= retries; attempt++) {
        try {
          await getKisToken();
          await kisThrottle();
          const { data } = await axios.get(`${KIS_BASE}/uapi/domestic-stock/v1/quotations/inquire-time-itemchartprice`, {
            headers: kisHeaders('FHKST03010200'),
            params: {
              FID_COND_MRKT_DIV_CODE: 'J',
              FID_INPUT_ISCD: code,
              FID_INPUT_HOUR_1: time,
              FID_ETC_CLS_CODE: '',
              FID_PW_DATA_INCU_YN: 'N',
            },
            timeout: 8000
          });
          if (data.rt_cd === '0') return data;
          if (attempt < retries) { await new Promise(r => setTimeout(r, 800)); continue; }
          return data; // Return error response on last attempt
        } catch (err) {
          if (attempt < retries) { await new Promise(r => setTimeout(r, 800)); continue; }
          throw err;
        }
      }
    };

    // Calculate next pagination time from records
    const getNextTime = (records) => {
      const oldest = records[records.length - 1].stck_cntg_hour;
      if (oldest <= '090100') return null;
      const oldestMin = parseInt(oldest.substring(0, 2)) * 60 + parseInt(oldest.substring(2, 4));
      const prevMin = oldestMin - 1;
      if (prevMin < 540) return null;
      return String(Math.floor(prevMin / 60)).padStart(2, '0') + String(prevMin % 60).padStart(2, '0') + '00';
    };

    let allRecords = [];
    let nextTime = startTime;

    // Sequential fetch with 500ms between pages (+ 300ms from kisThrottle = ~800ms total)
    for (let page = 0; page < maxPages; page++) {
      try {
        if (page > 0) await new Promise(r => setTimeout(r, 500));
        const data = await fetchPage(nextTime);
        if (data.rt_cd !== '0') {
          if (page === 0) return res.json({ success: false, error: data.msg1 });
          break;
        }
        const records = (data.output2 || []).filter(o => o.stck_cntg_hour && parseInt(o.cntg_vol) > 0);
        if (!records.length) break;
        allRecords.push(...records);
        nextTime = getNextTime(records);
        if (!nextTime) break;
      } catch (pageErr) {
        console.log(`[KIS minutechart] Page ${page} failed: ${pageErr.message}, using ${allRecords.length} records`);
        break;
      }
    }

    // Deduplicate by time and sort chronologically
    const seen = new Set();
    const unique = allRecords.filter(o => {
      if (seen.has(o.stck_cntg_hour)) return false;
      seen.add(o.stck_cntg_hour);
      return true;
    });

    // Sort chronologically (API returns newest first)
    unique.sort((a, b) => a.stck_cntg_hour.localeCompare(b.stck_cntg_hour));

    const history = unique.map(o => {
      const h = o.stck_cntg_hour; // HHMMSS in KST
      const d = o.stck_bsop_date || new Date().toISOString().slice(0, 10).replace(/-/g, ''); // Use actual date from API
      const dateStr = `${d.substring(0, 4)}-${d.substring(4, 6)}-${d.substring(6, 8)}T${h.substring(0, 2)}:${h.substring(2, 4)}:${h.substring(4, 6)}+09:00`;
      const ts = Math.floor(new Date(dateStr).getTime() / 1000);
      return {
        time: ts,
        timeStr: `${h.substring(0, 2)}:${h.substring(2, 4)}`,
        open: parseInt(o.stck_oprc) || 0,
        high: parseInt(o.stck_hgpr) || 0,
        low: parseInt(o.stck_lwpr) || 0,
        close: parseInt(o.stck_prpr) || 0,
        volume: parseInt(o.cntg_vol) || 0,
      };
    }).filter(h => h.close > 0);

    const result = { data: history, count: history.length, isIntraday: true, exchangeGmtOffset: 32400, pages: Math.ceil(allRecords.length / 30) };
    setCache(cacheKey, result);
    res.json({ success: true, ...result, source: 'kis' });
  } catch (err) {
    res.json({ success: false, error: err.message, source: 'kis' });
  }
});

// KIS Trade Execution (체결) - FHKST01010300
app.get('/api/kis/trades/:symbol', async (req, res) => {
  try {
    const code = req.params.symbol.replace(/\.(KS|KQ)$/i, '');
    const cacheKey = `kis_trades_${code}`;
    const cached = getCached(cacheKey, 15 * 1000);
    if (cached) return res.json({ success: true, data: cached, source: 'kis', cached: true });

    await getKisToken();
    await kisThrottle();

    const { data } = await axios.get(`${KIS_BASE}/uapi/domestic-stock/v1/quotations/inquire-ccnl`, {
      headers: kisHeaders('FHKST01010300'),
      params: { FID_COND_MRKT_DIV_CODE: 'J', FID_INPUT_ISCD: code },
      timeout: 8000
    });

    if (data.rt_cd !== '0') return res.json({ success: false, error: data.msg1 });

    const trades = (data.output || []).slice(0, 30).map(o => ({
      time: o.stck_cntg_hour ? `${o.stck_cntg_hour.substring(0, 2)}:${o.stck_cntg_hour.substring(2, 4)}:${o.stck_cntg_hour.substring(4, 6)}` : '',
      price: parseInt(o.stck_prpr) || 0,
      change: parseInt(o.prdy_vrss) || 0,
      volume: parseInt(o.cntg_vol) || 0,
      accVolume: parseInt(o.acml_vol) || 0,
    }));

    setCache(cacheKey, trades);
    res.json({ success: true, data: trades, source: 'kis' });
  } catch (err) {
    res.json({ success: false, error: err.message, source: 'kis' });
  }
});

// KIS Top Gainers/Losers (등락률 순위) - FHPST01700000
app.get('/api/kis/ranking/fluctuation', async (req, res) => {
  try {
    const type = req.query.type || '0'; // 0=전체, 1=상승, 2=보합, 3=하락, 4=상한, 5=하한
    const cacheKey = `kis_fluct_${type}`;
    const cached = getCached(cacheKey, 60 * 1000);
    if (cached) return res.json({ success: true, data: cached, source: 'kis', cached: true });

    await getKisToken();
    await kisThrottle();

    const { data } = await axios.get(`${KIS_BASE}/uapi/domestic-stock/v1/ranking/fluctuation`, {
      headers: kisHeaders('FHPST01700000'),
      params: {
        fid_cond_mrkt_div_code: 'J',
        fid_cond_scr_div_code: '20170',
        fid_input_iscd: '0000', // 전체
        fid_rank_sort_cls_code: type,
        fid_input_cnt_1: '0',
        fid_prc_cls_code: '0',
        fid_input_price_1: '',
        fid_input_price_2: '',
        fid_vol_cnt: '',
        fid_trgt_cls_code: '0',
        fid_trgt_exls_cls_code: '0',
        fid_div_cls_code: '0',
        fid_rsfl_rate1: '',
        fid_rsfl_rate2: '',
      },
      timeout: 8000
    });

    if (data.rt_cd !== '0') return res.json({ success: false, error: data.msg1 });

    const stocks = (data.output || []).slice(0, 30).map(o => ({
      rank: parseInt(o.data_rank) || 0,
      symbol: o.stck_shrn_iscd || '',
      name: o.hts_kor_isnm || '',
      price: parseInt(o.stck_prpr) || 0,
      change: parseInt(o.prdy_vrss) || 0,
      changePct: parseFloat(o.prdy_ctrt) || 0,
      volume: parseInt(o.acml_vol) || 0,
      tradingValue: parseInt(o.acml_tr_pbmn) || 0,
    }));

    setCache(cacheKey, stocks);
    res.json({ success: true, data: stocks, source: 'kis' });
  } catch (err) {
    res.json({ success: false, error: err.message, source: 'kis' });
  }
});

// KIS Volume Ranking (거래량 순위) - FHPST01710000
app.get('/api/kis/ranking/volume', async (req, res) => {
  try {
    const cacheKey = 'kis_vol_rank';
    const cached = getCached(cacheKey, 60 * 1000);
    if (cached) return res.json({ success: true, data: cached, source: 'kis', cached: true });

    await getKisToken();
    await kisThrottle();

    const { data } = await axios.get(`${KIS_BASE}/uapi/domestic-stock/v1/quotations/volume-rank`, {
      headers: kisHeaders('FHPST01710000'),
      params: {
        FID_COND_MRKT_DIV_CODE: 'J',
        FID_COND_SCR_DIV_CODE: '20171',
        FID_INPUT_ISCD: '0000',
        FID_DIV_CLS_CODE: '0',
        FID_BLNG_CLS_CODE: '0',
        FID_TRGT_CLS_CODE: '111111111',
        FID_TRGT_EXLS_CLS_CODE: '000000',
        FID_INPUT_PRICE_1: '',
        FID_INPUT_PRICE_2: '',
        FID_VOL_CNT: '',
        FID_INPUT_DATE_1: '',
      },
      timeout: 8000
    });

    if (data.rt_cd !== '0') return res.json({ success: false, error: data.msg1 });

    const stocks = (data.output || []).slice(0, 30).map(o => ({
      rank: parseInt(o.data_rank) || 0,
      symbol: o.mksc_shrn_iscd || '',
      name: o.hts_kor_isnm || '',
      price: parseInt(o.stck_prpr) || 0,
      change: parseInt(o.prdy_vrss) || 0,
      changePct: parseFloat(o.prdy_ctrt) || 0,
      volume: parseInt(o.acml_vol) || 0,
      tradingValue: parseInt(o.acml_tr_pbmn) || 0,
    }));

    setCache(cacheKey, stocks);
    res.json({ success: true, data: stocks, source: 'kis' });
  } catch (err) {
    res.json({ success: false, error: err.message, source: 'kis' });
  }
});

// KIS Investor Data (투자자별 매매동향) - FHKST01010900
app.get('/api/kis/investor/:symbol', async (req, res) => {
  try {
    const code = req.params.symbol.replace(/\.(KS|KQ)$/i, '');
    const cacheKey = `kis_investor_${code}`;
    const cached = getCached(cacheKey, 5 * 60 * 1000);
    if (cached) return res.json({ success: true, data: cached, source: 'kis', cached: true });

    await getKisToken();
    await kisThrottle();

    const { data } = await axios.get(`${KIS_BASE}/uapi/domestic-stock/v1/quotations/inquire-investor`, {
      headers: kisHeaders('FHKST01010900'),
      params: { FID_COND_MRKT_DIV_CODE: 'J', FID_INPUT_ISCD: code },
      timeout: 8000
    });

    if (data.rt_cd !== '0') return res.json({ success: false, error: data.msg1 });

    // Data is per-date with columns per investor type (prsn=Individual, frgn=Foreign, orgn=Institution)
    // Use most recent day that has data (today's row is often empty during trading hours)
    const rows = (data.output || []).filter(o => o.prsn_ntby_qty || o.frgn_ntby_qty || o.orgn_ntby_qty);
    const latest = rows[0] || {};
    const investors = [
      { name: '개인 (Individual)', buyVolume: parseInt(latest.prsn_shnu_vol) || 0, sellVolume: parseInt(latest.prsn_seln_vol) || 0, netVolume: parseInt(latest.prsn_ntby_qty) || 0, netAmount: parseInt(latest.prsn_ntby_tr_pbmn) || 0 },
      { name: '외국인 (Foreign)',   buyVolume: parseInt(latest.frgn_shnu_vol) || 0, sellVolume: parseInt(latest.frgn_seln_vol) || 0, netVolume: parseInt(latest.frgn_ntby_qty) || 0, netAmount: parseInt(latest.frgn_ntby_tr_pbmn) || 0 },
      { name: '기관 (Institution)', buyVolume: parseInt(latest.orgn_shnu_vol) || 0, sellVolume: parseInt(latest.orgn_seln_vol) || 0, netVolume: parseInt(latest.orgn_ntby_qty) || 0, netAmount: parseInt(latest.orgn_ntby_tr_pbmn) || 0 },
    ];

    // Also include daily history for trend
    const history = rows.slice(0, 10).map(o => ({
      date: o.stck_bsop_date || '',
      price: parseInt(o.stck_clpr) || 0,
      prsn: parseInt(o.prsn_ntby_qty) || 0,
      frgn: parseInt(o.frgn_ntby_qty) || 0,
      orgn: parseInt(o.orgn_ntby_qty) || 0,
    }));

    const result = { investors, history, date: latest.stck_bsop_date || '' };
    setCache(cacheKey, result);
    res.json({ success: true, data: result, source: 'kis' });
  } catch (err) {
    res.json({ success: false, error: err.message, source: 'kis' });
  }
});

// KIS Market Index (업종지수) - FHPUP02100000  
app.get('/api/kis/index', async (req, res) => {
  try {
    const indexCode = req.query.code || '0001'; // 0001=KOSPI, 1001=KOSDAQ
    const cacheKey = `kis_index_${indexCode}`;
    const cached = getCached(cacheKey, 30 * 1000);
    if (cached) return res.json({ success: true, data: cached, source: 'kis', cached: true });

    await getKisToken();
    await kisThrottle();

    const { data } = await axios.get(`${KIS_BASE}/uapi/domestic-stock/v1/quotations/inquire-index-price`, {
      headers: kisHeaders('FHPUP02100000'),
      params: { FID_COND_MRKT_DIV_CODE: 'U', FID_INPUT_ISCD: indexCode },
      timeout: 8000
    });

    if (data.rt_cd !== '0') return res.json({ success: false, error: data.msg1 });

    const o = data.output;
    const indexData = {
      code: indexCode,
      name: indexCode === '0001' ? 'KOSPI' : indexCode === '1001' ? 'KOSDAQ' : indexCode,
      price: parseFloat(o?.bstp_nmix_prpr) || 0,
      change: parseFloat(o?.bstp_nmix_prdy_vrss) || 0,
      changePct: parseFloat(o?.bstp_nmix_prdy_ctrt) || 0,
      open: parseFloat(o?.bstp_nmix_oprc) || 0,
      high: parseFloat(o?.bstp_nmix_hgpr) || 0,
      low: parseFloat(o?.bstp_nmix_lwpr) || 0,
      volume: parseInt(o?.acml_vol) || 0,
      tradingValue: parseInt(o?.acml_tr_pbmn) || 0,
    };

    setCache(cacheKey, indexData);
    res.json({ success: true, data: indexData, source: 'kis' });
  } catch (err) {
    res.json({ success: false, error: err.message, source: 'kis' });
  }
});

// KIS Market Overview - batch top Korean stocks from KIS
app.get('/api/kis/market', async (req, res) => {
  try {
    const cacheKey = 'kis_market_overview';
    const cached = getCached(cacheKey, 2 * 60 * 1000);
    if (cached) return res.json({ success: true, data: cached, source: 'kis', cached: true });

    await getKisToken();

    const topCodes = ['005930','000660','035420','035720','005380','051910','006400','207940'];
    const names = {
      '005930':'삼성전자','000660':'SK하이닉스','035420':'NAVER','035720':'카카오',
      '005380':'현대차','051910':'LG화학','006400':'삼성SDI','207940':'삼성바이오로직스'
    };

    const results = [];
    for (const code of topCodes) {
      try {
        await kisThrottle();
        const { data } = await axios.get(`${KIS_BASE}/uapi/domestic-stock/v1/quotations/inquire-price`, {
          headers: kisHeaders('FHKST01010100'),
          params: { FID_COND_MRKT_DIV_CODE: 'J', FID_INPUT_ISCD: code },
          timeout: 6000
        });
        if (data.rt_cd === '0') {
          const o = data.output;
          results.push({
            symbol: code,
            name: names[code] || o.hts_kor_isnm || code,
            price: parseInt(o.stck_prpr) || 0,
            change: parseInt(o.prdy_vrss) || 0,
            changePct: parseFloat(o.prdy_ctrt) || 0,
            volume: parseInt(o.acml_vol) || 0,
            dayHigh: parseInt(o.stck_hgpr) || 0,
            dayLow: parseInt(o.stck_lwpr) || 0,
            prevClose: parseInt(o.stck_sdpr) || 0,
          });
        }
      } catch (e) { /* skip failed */ }
    }

    setCache(cacheKey, results);
    res.json({ success: true, data: results, source: 'kis' });
  } catch (err) {
    res.json({ success: false, error: err.message, source: 'kis' });
  }
});

// ==========================================
//  YAHOO FINANCE - NEWS
// ==========================================
app.get('/api/yahoo/news/:symbol', async (req, res) => {
  try {
    const symbol = req.params.symbol;
    const cacheKey = `yn_${symbol}`;
    const cached = getCached(cacheKey, 10 * 60 * 1000);
    if (cached) return res.json({ success: true, data: cached, cached: true });

    const { data } = await axios.get(YF_SEARCH, {
      params: { q: symbol, quotesCount: 0, newsCount: 10 },
      headers: YF_HEADERS
    });
    const news = (data.news || []).map(n => ({
      title: n.title,
      publisher: n.publisher,
      link: n.link,
      time: n.providerPublishTime,
      thumbnail: n.thumbnail?.resolutions?.[0]?.url
    }));
    setCache(cacheKey, news);
    res.json({ success: true, data: news });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// ==========================================
//  MARKET OVERVIEW - Batch Korean stocks
// ==========================================
const KR_TOP_STOCKS = [
  '005930.KS','000660.KS','035420.KS','035720.KS','005380.KS',
  '051910.KS','006400.KS','207940.KS'
];
const KR_STOCK_NAMES = {
  '005930.KS':'삼성전자','000660.KS':'SK하이닉스','035420.KS':'NAVER','035720.KS':'카카오',
  '005380.KS':'현대차','051910.KS':'LG화학','006400.KS':'삼성SDI','003670.KQ':'포스코퓨처엠',
  '055550.KS':'신한지주','105560.KS':'KB금융','068270.KS':'셀트리온','033780.KS':'KT&G',
  '032830.KS':'삼성생명','028260.KS':'삼성물산','207940.KS':'삼성바이오로직스','034730.KS':'SK'
};

app.get('/api/yahoo/market', async (req, res) => {
  try {
    const cacheKey = 'market_overview';
    const cached = getCached(cacheKey, 2 * 60 * 1000); // 2 min cache
    if (cached) return res.json({ success: true, data: cached, cached: true });

    // Batch requests 4 at a time to avoid rate limiting
    const BATCH_SIZE = 4;
    const allResults = [];
    for (let i = 0; i < KR_TOP_STOCKS.length; i += BATCH_SIZE) {
      const batch = KR_TOP_STOCKS.slice(i, i + BATCH_SIZE);
      const batchResults = await Promise.allSettled(
        batch.map(async (s) => {
          const { data } = await axios.get(`${YF_CHART}/${s}`, {
            params: { range: '5d', interval: '1d' },
            headers: YF_HEADERS,
            timeout: 6000
          });
          const r = data.chart.result[0];
          const meta = r.meta;
          const closes = r.indicators.quote[0].close.filter(c => c != null);
          const prevClose = closes.length >= 2 ? closes[closes.length - 2] : meta.chartPreviousClose;
          const lastClose = closes[closes.length - 1] || meta.regularMarketPrice;
          const change = lastClose - prevClose;
          const changePct = prevClose ? (change / prevClose * 100) : 0;
          return {
            symbol: meta.symbol, name: KR_STOCK_NAMES[s] || meta.shortName || s,
            price: meta.regularMarketPrice, change, changePct,
            volume: meta.regularMarketVolume, dayHigh: meta.regularMarketDayHigh,
            dayLow: meta.regularMarketDayLow, prevClose,
            sparkline: closes.slice(-5)
          };
        })
      );
      allResults.push(...batchResults);
      // Small delay between batches
      if (i + BATCH_SIZE < KR_TOP_STOCKS.length) await new Promise(r => setTimeout(r, 200));
    }

    const stocks = allResults.filter(r => r.status === 'fulfilled').map(r => r.value);
    setCache(cacheKey, stocks);
    res.json({ success: true, data: stocks });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// ==========================================
//  KRX OPEN API ENDPOINTS
// ==========================================

app.get('/api/krx/health', (req, res) => {
  if (!KRX_KEY) {
    return res.json({
      success: false,
      configured: false,
      message: 'KRX API key not configured',
      instructions: [
        '1. Go to https://openapi.krx.co.kr',
        '2. Register for an account',
        '3. Apply for API access (may require Korean phone/email)',
        '4. Add key to .env: KRX_API_KEY=your_key'
      ]
    });
  }
  res.json({ success: true, configured: true, message: 'KRX API key configured' });
});

app.get('/api/krx/ohlcv', async (req, res) => {
  if (!KRX_KEY) {
    return res.json({
      success: false,
      error: 'KRX API key not configured. Register at https://openapi.krx.co.kr'
    });
  }
  try {
    const { symbol, startDate, endDate } = req.query;
    // KRX Open API endpoint (adjust based on actual API docs after registration)
    const url = 'https://openapi.krx.co.kr/contents/OPP/USES/service/OPPUSES002_S2.cmd';
    const { data } = await axios.get(url, {
      params: {
        AUTH_KEY: KRX_KEY,
        ISU_CD: symbol,
        ST_DD: startDate,
        ED_DD: endDate,
        prdCd: 'STK'
      }
    });
    res.json({ success: true, data });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// ==========================================
//  START SERVER
// ==========================================

app.listen(PORT, async () => {
  console.log('');
  console.log('  ╔═══════════════════════════════════════════════╗');
  console.log('  ║  🇰🇷 Korean Stock API Test Dashboard           ║');
  console.log('  ╠═══════════════════════════════════════════════╣');
  console.log(`  ║  🌐 http://localhost:${PORT}                      ║`);
  console.log('  ║                                               ║');
  console.log('  ║  📊 Yahoo Finance  : Direct API (no npm pkg)  ║');
  console.log(`  ║  📈 Alpha Vantage  : ${ALPHA_KEY === 'demo' ? 'Demo mode (get key!)   ' : 'Custom key ✓          '}  ║`);
  console.log('  ║  🏛️  KIS Open API   : Initializing...          ║');
  console.log('  ║                                               ║');
  console.log('  ║  Open browser → http://localhost:' + PORT + '          ║');
  console.log('  ╚═══════════════════════════════════════════════╝');
  console.log('');

  // Pre-warm KIS token
  try {
    await getKisToken();
    console.log('  ✅ KIS API token acquired successfully');
  } catch (e) {
    console.log('  ⚠️  KIS API token failed:', e.message);
  }
});
