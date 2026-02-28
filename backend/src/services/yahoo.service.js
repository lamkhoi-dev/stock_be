/**
 * Yahoo Finance Service (FALLBACK data source)
 * Direct API calls – no npm package required
 *
 * Endpoints:
 *  1. search    — symbol / company name search
 *  2. getQuote  — single stock quote (from chart endpoint)
 *  3. getQuotes — batch quotes
 *  4. getHistory — historical OHLCV (daily + intraday)
 *  5. getNews   — news for a symbol
 *  6. getMarketOverview — batch Korean top stocks
 *  7. health    — connectivity check
 */
import axios from 'axios';
import cacheService from './cache.service.js';
import logger from '../utils/logger.js';

// ─── Constants ───────────────────────────────────────
const YF_CHART = 'https://query1.finance.yahoo.com/v8/finance/chart';
const YF_SEARCH = 'https://query1.finance.yahoo.com/v1/finance/search';

const YF_HEADERS = {
  'User-Agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};

// Cache TTLs (ms)
const TTL = {
  SEARCH: 5 * 60_000,   // 5min
  QUOTE: 5_000,          // 5s — near real-time
  HISTORY_INTRA: 60_000, // 1min
  HISTORY_DAILY: 5 * 60_000, // 5min
  NEWS: 10 * 60_000,     // 10min
  MARKET: 2 * 60_000,    // 2min
};

// Period → Yahoo range + default interval mapping
const PERIOD_CONFIG = {
  '1d':  { range: '1d',  defaultInterval: '5m'  },
  '5d':  { range: '5d',  defaultInterval: '15m' },
  '1w':  { range: '5d',  defaultInterval: '15m' },
  '1m':  { range: '1mo', defaultInterval: '1h'  },
  '3m':  { range: '3mo', defaultInterval: '1d'  },
  '6m':  { range: '6mo', defaultInterval: '1d'  },
  '1y':  { range: '1y',  defaultInterval: '1d'  },
  '2y':  { range: '2y',  defaultInterval: '1wk' },
  '5y':  { range: '5y',  defaultInterval: '1wk' },
};

// Top Korean stocks for market overview
const KR_TOP_STOCKS = [
  '005930.KS', '000660.KS', '035420.KS', '035720.KS',
  '005380.KS', '051910.KS', '006400.KS', '207940.KS',
];
const KR_STOCK_NAMES = {
  '005930.KS': '삼성전자', '000660.KS': 'SK하이닉스', '035420.KS': 'NAVER',
  '035720.KS': '카카오', '005380.KS': '현대차', '051910.KS': 'LG화학',
  '006400.KS': '삼성SDI', '207940.KS': '삼성바이오로직스',
};

// ═══════════════════════════════════════════════════════
//  PUBLIC API
// ═══════════════════════════════════════════════════════

const yahooService = {
  /**
   * Health check — fetch Samsung chart as canary
   */
  async health() {
    const { data } = await axios.get(`${YF_CHART}/005930.KS`, {
      params: { range: '1d', interval: '1d' },
      headers: YF_HEADERS,
      timeout: 8_000,
    });
    const meta = data.chart.result[0].meta;
    return {
      message: 'Yahoo Finance connected (direct API)',
      sample: {
        symbol: meta.symbol,
        name: 'Samsung Electronics',
        price: meta.regularMarketPrice,
        currency: meta.currency,
      },
    };
  },

  // ────────────────────────────────────────────────────
  //  1. Search symbols
  // ────────────────────────────────────────────────────
  async search(query) {
    if (!query) throw new Error('Query "q" is required');

    const cacheKey = `ys_${query}`;
    const cached = cacheService.get(cacheKey, TTL.SEARCH);
    if (cached) return { data: cached, cached: true };

    const { data } = await axios.get(YF_SEARCH, {
      params: { q: query, quotesCount: 15, newsCount: 0, enableFuzzyQuery: true },
      headers: YF_HEADERS,
      timeout: 8_000,
    });

    cacheService.set(cacheKey, data);
    return { data, cached: false };
  },

  // ────────────────────────────────────────────────────
  //  2. Single stock quote (built from chart endpoint)
  // ────────────────────────────────────────────────────
  async getQuote(symbol) {
    const cacheKey = `yq_${symbol}`;
    const cached = cacheService.get(cacheKey, TTL.QUOTE);
    if (cached) return { data: cached, cached: true };

    const { data } = await axios.get(`${YF_CHART}/${symbol}`, {
      params: { range: '5d', interval: '1d', includePrePost: false },
      headers: YF_HEADERS,
      timeout: 8_000,
    });

    const result = data.chart.result[0];
    const meta = result.meta;
    const quotes = result.indicators?.quote?.[0] || {};
    const timestamps = result.timestamp || [];

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
      marketState: meta.marketState,
    };

    cacheService.set(cacheKey, quoteData);
    return { data: quoteData, cached: false };
  },

  // ────────────────────────────────────────────────────
  //  3. Multiple quotes (batch)
  // ────────────────────────────────────────────────────
  async getQuotes(symbols) {
    if (!symbols?.length) throw new Error('symbols param required');

    const results = await Promise.all(
      symbols.map(async (s) => {
        try {
          const { data } = await axios.get(`${YF_CHART}/${s}`, {
            params: { range: '1d', interval: '1d' },
            headers: YF_HEADERS,
            timeout: 6_000,
          });
          const meta = data.chart.result[0].meta;
          return { symbol: meta.symbol, price: meta.regularMarketPrice, currency: meta.currency };
        } catch (e) {
          return { symbol: s, error: e.message };
        }
      }),
    );
    return { data: results, cached: false };
  },

  // ────────────────────────────────────────────────────
  //  4. Historical OHLCV (daily + intraday)
  // ────────────────────────────────────────────────────
  async getHistory(symbol, { period = '6m', interval } = {}) {
    const config = PERIOD_CONFIG[period] || PERIOD_CONFIG['6m'];
    const range = config.range;
    if (!interval) interval = config.defaultInterval;

    const isIntraday = ['1m', '2m', '5m', '15m', '30m', '60m', '90m', '1h'].includes(interval);
    const cacheTTL = isIntraday ? TTL.HISTORY_INTRA : TTL.HISTORY_DAILY;
    const cacheKey = `yh_${symbol}_${range}_${interval}`;
    const cached = cacheService.get(cacheKey, cacheTTL);
    if (cached) return { ...cached, cached: true };

    const { data } = await axios.get(`${YF_CHART}/${symbol}`, {
      params: { range, interval, includePrePost: false },
      headers: YF_HEADERS,
      timeout: 10_000,
    });

    const result = data.chart.result[0];
    const timestamps = result.timestamp || [];
    const quotes = result.indicators.quote[0];
    const adjClose = result.indicators.adjclose?.[0]?.adjclose;
    const exchangeGmtOffset = result.meta.gmtoffset || 32400; // KST = +9h

    // Intraday → raw UTC Unix ts + offset; Daily → YYYY-MM-DD date strings
    const history = timestamps
      .map((t, i) => {
        const entry = {
          time: isIntraday ? t : new Date(t * 1000).toISOString().split('T')[0],
          open: quotes.open[i],
          high: quotes.high[i],
          low: quotes.low[i],
          close: quotes.close[i],
          volume: quotes.volume[i],
        };
        if (adjClose) entry.adjClose = adjClose[i];
        return entry;
      })
      .filter((h) => h.close != null);

    const payload = { data: history, count: history.length, isIntraday, exchangeGmtOffset };
    cacheService.set(cacheKey, payload);
    return { ...payload, cached: false };
  },

  // ────────────────────────────────────────────────────
  //  5. News for a symbol
  // ────────────────────────────────────────────────────
  async getNews(symbol) {
    const cacheKey = `yn_${symbol}`;
    const cached = cacheService.get(cacheKey, TTL.NEWS);
    if (cached) return { data: cached, cached: true };

    const { data } = await axios.get(YF_SEARCH, {
      params: { q: symbol, quotesCount: 0, newsCount: 10 },
      headers: YF_HEADERS,
      timeout: 8_000,
    });

    const news = (data.news || []).map((n) => ({
      title: n.title,
      publisher: n.publisher,
      link: n.link,
      time: n.providerPublishTime,
      thumbnail: n.thumbnail?.resolutions?.[0]?.url,
    }));

    cacheService.set(cacheKey, news);
    return { data: news, cached: false };
  },

  // ────────────────────────────────────────────────────
  //  6. Market Overview — batch Korean top stocks
  // ────────────────────────────────────────────────────
  async getMarketOverview() {
    const cacheKey = 'yf_market_overview';
    const cached = cacheService.get(cacheKey, TTL.MARKET);
    if (cached) return { data: cached, cached: true };

    const BATCH_SIZE = 4;
    const allResults = [];

    for (let i = 0; i < KR_TOP_STOCKS.length; i += BATCH_SIZE) {
      const batch = KR_TOP_STOCKS.slice(i, i + BATCH_SIZE);
      const batchResults = await Promise.allSettled(
        batch.map(async (s) => {
          const { data } = await axios.get(`${YF_CHART}/${s}`, {
            params: { range: '5d', interval: '1d' },
            headers: YF_HEADERS,
            timeout: 6_000,
          });
          const r = data.chart.result[0];
          const meta = r.meta;
          const closes = r.indicators.quote[0].close.filter((c) => c != null);
          const prevClose2 = closes.length >= 2 ? closes[closes.length - 2] : meta.chartPreviousClose;
          const lastClose = closes[closes.length - 1] || meta.regularMarketPrice;
          const change = lastClose - prevClose2;
          const changePct = prevClose2 ? (change / prevClose2) * 100 : 0;
          return {
            symbol: meta.symbol,
            name: KR_STOCK_NAMES[s] || meta.shortName || s,
            price: meta.regularMarketPrice,
            change,
            changePct,
            volume: meta.regularMarketVolume,
            dayHigh: meta.regularMarketDayHigh,
            dayLow: meta.regularMarketDayLow,
            prevClose: prevClose2,
            sparkline: closes.slice(-5),
          };
        }),
      );
      allResults.push(...batchResults);
      if (i + BATCH_SIZE < KR_TOP_STOCKS.length) {
        await new Promise((r) => setTimeout(r, 200));
      }
    }

    const stocks = allResults
      .filter((r) => r.status === 'fulfilled')
      .map((r) => r.value);

    cacheService.set(cacheKey, stocks);
    return { data: stocks, cached: false };
  },
};

export default yahooService;
