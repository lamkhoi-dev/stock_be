/**
 * KIS (Korea Investment & Securities) API Service
 * PRIMARY data source for Korean stock market
 *
 * Endpoints:
 *  1. getPrice      - FHKST01010100 (현재가 시세)
 *  2. getDailyChart - FHKST03010100 (기간별 시세)
 *  3. getMinuteChart - FHKST03010200 (분봉 조회, paginated)
 *  4. getTrades     - FHKST01010300 (체결)
 *  5. getFluctuationRanking - FHPST01700000 (등락률 순위)
 *  6. getVolumeRanking      - FHPST01710000 (거래량 순위)
 *  7. getInvestor   - FHKST01010900 (투자자별 매매동향)
 *  8. getIndex      - FHPUP02100000 (업종 지수)
 *  9. getMarketOverview - batch top stocks
 * 10. health check
 *
 * Known fixes (documented in SYSTEM_DOCUMENTATION.md §VII):
 *  - AppSecret must be raw string (no extra quoting)
 *  - FID_PW_DATA_INCU_YN: 'N' required for minute chart
 *  - Investor fields: prsn/frgn/orgn_ntby_qty (not ntby_vol)
 *  - Timezone: use stck_bsop_date from API, not local date
 *  - Minute chart: sequential pagination with 500ms delay
 */
import axios from 'axios';
import env from '../config/env.js';
import cacheService from './cache.service.js';
import logger from '../utils/logger.js';
import {
  getKSTDate,
  getKSTTimeString,
  formatDateKIS,
  stripSymbolSuffix,
  sleep,
  safeInt,
  safeFloat,
} from '../utils/helpers.js';

// ─── Token Management ────────────────────────────────
let kisToken = { token: '', expiresAt: 0 };

/**
 * Get or refresh KIS OAuth2 access token.
 * Cached for ~24h, refreshes 1h before expiry.
 */
async function getToken() {
  if (kisToken.token && Date.now() < kisToken.expiresAt - 3_600_000) {
    return kisToken.token;
  }

  try {
    const { data } = await axios.post(
      `${env.KIS_BASE_URL}/oauth2/tokenP`,
      {
        grant_type: 'client_credentials',
        appkey: env.KIS_APP_KEY,
        appsecret: env.KIS_APP_SECRET,
      },
      { headers: { 'Content-Type': 'application/json' }, timeout: 10_000 },
    );

    kisToken.token = data.access_token;
    kisToken.expiresAt = Date.now() + (data.expires_in ? data.expires_in * 1000 : 23 * 3_600_000);
    logger.info(`KIS token refreshed, expires: ${new Date(kisToken.expiresAt).toISOString()}`);
    return kisToken.token;
  } catch (err) {
    const msg = err.response?.data?.msg1 || err.message;
    logger.error(`KIS token error: ${msg}`);
    throw new Error(`KIS token failed: ${msg}`);
  }
}

// ─── Request Helpers ─────────────────────────────────

/** Build standard KIS request headers */
function headers(trId) {
  return {
    'Content-Type': 'application/json; charset=utf-8',
    authorization: `Bearer ${kisToken.token}`,
    appkey: env.KIS_APP_KEY,
    appsecret: env.KIS_APP_SECRET,
    tr_id: trId,
    custtype: 'P',
  };
}

/** Rate throttle: max 1 KIS request per 300ms */
let lastCallTs = 0;
async function throttle() {
  const now = Date.now();
  const wait = Math.max(0, 300 - (now - lastCallTs));
  if (wait > 0) await sleep(wait);
  lastCallTs = Date.now();
}

/**
 * Check if KRX market is currently in trading hours (09:00-16:00 KST, Mon-Fri).
 * Extended to 16:00 for after-close auction.
 */
function isMarketHours() {
  const kst = getKSTDate();
  const h = kst.getHours();
  const m = kst.getMinutes();
  const day = kst.getDay();
  if (day === 0 || day === 6) return false;
  const t = h * 60 + m;
  return t >= 540 && t <= 960; // 09:00–16:00
}

// ─── Cache TTL constants (milliseconds) ─────────────
const TTL = {
  PRICE: 30_000,        // 30s  – near real-time
  TRADES: 15_000,       // 15s
  MINUTE: 60_000,       // 1min – intraday
  DAILY: 5 * 60_000,    // 5min
  RANKING: 60_000,      // 1min
  INVESTOR: 5 * 60_000, // 5min
  INDEX: 30_000,        // 30s
  MARKET: 2 * 60_000,   // 2min
};

// ─── Top Korean Stocks (for market overview) ─────────
const TOP_CODES = ['005930', '000660', '035420', '035720', '005380', '051910', '006400', '207940'];
const STOCK_NAMES = {
  '005930': '삼성전자',
  '000660': 'SK하이닉스',
  '035420': 'NAVER',
  '035720': '카카오',
  '005380': '현대차',
  '051910': 'LG화학',
  '006400': '삼성SDI',
  '207940': '삼성바이오로직스',
};

// ═══════════════════════════════════════════════════════
//  PUBLIC API
// ═══════════════════════════════════════════════════════

const kisService = {
  /**
   * Health check — acquire token and confirm connectivity
   */
  async health() {
    const token = await getToken();
    return { message: 'KIS API connected', tokenPreview: token.substring(0, 20) + '...' };
  },

  // ────────────────────────────────────────────────────
  //  1. Current Price (현재가 시세) — FHKST01010100
  // ────────────────────────────────────────────────────
  async getPrice(symbol) {
    const code = stripSymbolSuffix(symbol);
    const cacheKey = `kis_price_${code}`;
    const cached = cacheService.get(cacheKey, TTL.PRICE);
    if (cached) return { data: cached, cached: true };

    await getToken();
    await throttle();

    const { data } = await axios.get(
      `${env.KIS_BASE_URL}/uapi/domestic-stock/v1/quotations/inquire-price`,
      {
        headers: headers('FHKST01010100'),
        params: { FID_COND_MRKT_DIV_CODE: 'J', FID_INPUT_ISCD: code },
        timeout: 8_000,
      },
    );

    if (data.rt_cd !== '0') throw new Error(data.msg1 || 'KIS price API error');

    const o = data.output;
    const priceData = {
      symbol: code,
      name: o.hts_kor_isnm || code,
      price: safeInt(o.stck_prpr),
      change: safeInt(o.prdy_vrss),
      changePct: safeFloat(o.prdy_ctrt),
      changeSign: o.prdy_vrss_sign, // 1=up 2=flat 3=stay 4=down-limit 5=down
      open: safeInt(o.stck_oprc),
      high: safeInt(o.stck_hgpr),
      low: safeInt(o.stck_lwpr),
      prevClose: safeInt(o.stck_sdpr),
      volume: safeInt(o.acml_vol),
      tradingValue: safeInt(o.acml_tr_pbmn),
      marketCap: safeInt(o.hts_avls), // 시가총액(억)
      per: safeFloat(o.per),
      pbr: safeFloat(o.pbr),
      eps: safeInt(o.eps),
      high52w: safeInt(o.stck_dryy_hgpr),
      low52w: safeInt(o.stck_dryy_lwpr),
      upperLimit: safeInt(o.stck_mxpr),
      lowerLimit: safeInt(o.stck_llam),
    };

    cacheService.set(cacheKey, priceData);
    return { data: priceData, cached: false };
  },

  // ────────────────────────────────────────────────────
  //  2. Daily OHLCV (기간별 시세) — FHKST03010100
  // ────────────────────────────────────────────────────
  async getDailyChart(symbol, { period = 'D', startDate, endDate } = {}) {
    const code = stripSymbolSuffix(symbol);
    const periodType = period; // D=Day, W=Week, M=Month, Y=Year

    const end = endDate || formatDateKIS();
    const startDefaults = { D: 180, W: 365, M: 730, Y: 3650 };
    const daysBack = startDefaults[periodType] || 180;
    const start =
      startDate || formatDateKIS(new Date(Date.now() - daysBack * 86_400_000));

    const cacheKey = `kis_chart_${code}_${periodType}_${start}_${end}`;
    const cached = cacheService.get(cacheKey, TTL.DAILY);
    if (cached) return { ...cached, cached: true };

    await getToken();
    await throttle();

    const { data } = await axios.get(
      `${env.KIS_BASE_URL}/uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice`,
      {
        headers: headers('FHKST03010100'),
        params: {
          FID_COND_MRKT_DIV_CODE: 'J',
          FID_INPUT_ISCD: code,
          FID_INPUT_DATE_1: start,
          FID_INPUT_DATE_2: end,
          FID_PERIOD_DIV_CODE: periodType,
          FID_ORG_ADJ_PRC: '0', // 0 = 수정주가 반영
        },
        timeout: 10_000,
      },
    );

    if (data.rt_cd !== '0') throw new Error(data.msg1 || 'KIS chart API error');

    // output2 = array newest→oldest → reverse for chart
    const history = (data.output2 || [])
      .filter((o) => o.stck_bsop_date)
      .reverse()
      .map((o) => ({
        time: `${o.stck_bsop_date.substring(0, 4)}-${o.stck_bsop_date.substring(4, 6)}-${o.stck_bsop_date.substring(6, 8)}`,
        open: safeInt(o.stck_oprc),
        high: safeInt(o.stck_hgpr),
        low: safeInt(o.stck_lwpr),
        close: safeInt(o.stck_clpr),
        volume: safeInt(o.acml_vol),
      }))
      .filter((h) => h.close > 0);

    const result = { data: history, count: history.length, isIntraday: false, periodType };
    cacheService.set(cacheKey, result);
    return { ...result, cached: false };
  },

  // ────────────────────────────────────────────────────
  //  3. Minute Chart (분봉) — FHKST03010200 (paginated)
  // ────────────────────────────────────────────────────
  async getMinuteChart(symbol, { time, maxPages = 6 } = {}) {
    const code = stripSymbolSuffix(symbol);
    const startTime = time || (isMarketHours() ? getKSTTimeString() : '160000');
    const pages = Math.min(maxPages, 10);

    const cacheKey = `kis_min_${code}_${startTime.substring(0, 4)}`;
    const cached = cacheService.get(cacheKey, TTL.MINUTE);
    if (cached) return { ...cached, cached: true };

    // Helper: fetch one page with retry
    const fetchPage = async (pageTime, retries = 1) => {
      for (let attempt = 0; attempt <= retries; attempt++) {
        try {
          await getToken();
          await throttle();
          const { data } = await axios.get(
            `${env.KIS_BASE_URL}/uapi/domestic-stock/v1/quotations/inquire-time-itemchartprice`,
            {
              headers: headers('FHKST03010200'),
              params: {
                FID_COND_MRKT_DIV_CODE: 'J',
                FID_INPUT_ISCD: code,
                FID_INPUT_HOUR_1: pageTime,
                FID_ETC_CLS_CODE: '',
                FID_PW_DATA_INCU_YN: 'N', // IMPORTANT: must be 'N'
              },
              timeout: 8_000,
            },
          );
          if (data.rt_cd === '0') return data;
          if (attempt < retries) {
            await sleep(800);
            continue;
          }
          return data;
        } catch (err) {
          if (attempt < retries) {
            await sleep(800);
            continue;
          }
          throw err;
        }
      }
    };

    // Calculate next pagination time from oldest record
    const getNextTime = (records) => {
      const oldest = records[records.length - 1].stck_cntg_hour;
      if (oldest <= '090100') return null;
      const oldestMin =
        parseInt(oldest.substring(0, 2)) * 60 +
        parseInt(oldest.substring(2, 4));
      const prevMin = oldestMin - 1;
      if (prevMin < 540) return null; // before 09:00
      return (
        String(Math.floor(prevMin / 60)).padStart(2, '0') +
        String(prevMin % 60).padStart(2, '0') +
        '00'
      );
    };

    let allRecords = [];
    let nextTime = startTime;

    // Sequential fetch with 500ms pause between pages
    for (let page = 0; page < pages; page++) {
      try {
        if (page > 0) await sleep(500);
        const data = await fetchPage(nextTime);
        if (data.rt_cd !== '0') {
          if (page === 0) throw new Error(data.msg1 || 'KIS minute chart error');
          break;
        }
        const records = (data.output2 || []).filter(
          (o) => o.stck_cntg_hour && safeInt(o.cntg_vol) > 0,
        );
        if (!records.length) break;
        allRecords.push(...records);
        nextTime = getNextTime(records);
        if (!nextTime) break;
      } catch (pageErr) {
        logger.warn(
          `KIS minutechart page ${page} failed: ${pageErr.message}, using ${allRecords.length} records`,
        );
        break;
      }
    }

    // Deduplicate by time, sort chronologically
    const seen = new Set();
    const unique = allRecords.filter((o) => {
      if (seen.has(o.stck_cntg_hour)) return false;
      seen.add(o.stck_cntg_hour);
      return true;
    });
    unique.sort((a, b) => a.stck_cntg_hour.localeCompare(b.stck_cntg_hour));

    const history = unique
      .map((o) => {
        const h = o.stck_cntg_hour; // HHMMSS in KST
        // Use actual date from API (stck_bsop_date), NOT local date
        const d = o.stck_bsop_date || formatDateKIS();
        const dateStr = `${d.substring(0, 4)}-${d.substring(4, 6)}-${d.substring(6, 8)}T${h.substring(0, 2)}:${h.substring(2, 4)}:${h.substring(4, 6)}+09:00`;
        const ts = Math.floor(new Date(dateStr).getTime() / 1000);
        return {
          time: ts,
          timeStr: `${h.substring(0, 2)}:${h.substring(2, 4)}`,
          open: safeInt(o.stck_oprc),
          high: safeInt(o.stck_hgpr),
          low: safeInt(o.stck_lwpr),
          close: safeInt(o.stck_prpr),
          volume: safeInt(o.cntg_vol),
        };
      })
      .filter((h) => h.close > 0);

    const result = {
      data: history,
      count: history.length,
      isIntraday: true,
      exchangeGmtOffset: 32400,
      pages: Math.ceil(allRecords.length / 30),
    };
    cacheService.set(cacheKey, result);
    return { ...result, cached: false };
  },

  // ────────────────────────────────────────────────────
  //  4. Trade Executions (체결) — FHKST01010300
  // ────────────────────────────────────────────────────
  async getTrades(symbol) {
    const code = stripSymbolSuffix(symbol);
    const cacheKey = `kis_trades_${code}`;
    const cached = cacheService.get(cacheKey, TTL.TRADES);
    if (cached) return { data: cached, cached: true };

    await getToken();
    await throttle();

    const { data } = await axios.get(
      `${env.KIS_BASE_URL}/uapi/domestic-stock/v1/quotations/inquire-ccnl`,
      {
        headers: headers('FHKST01010300'),
        params: { FID_COND_MRKT_DIV_CODE: 'J', FID_INPUT_ISCD: code },
        timeout: 8_000,
      },
    );

    if (data.rt_cd !== '0') throw new Error(data.msg1 || 'KIS trades API error');

    const trades = (data.output || []).slice(0, 30).map((o) => ({
      time: o.stck_cntg_hour
        ? `${o.stck_cntg_hour.substring(0, 2)}:${o.stck_cntg_hour.substring(2, 4)}:${o.stck_cntg_hour.substring(4, 6)}`
        : '',
      price: safeInt(o.stck_prpr),
      change: safeInt(o.prdy_vrss),
      volume: safeInt(o.cntg_vol),
      accVolume: safeInt(o.acml_vol),
    }));

    cacheService.set(cacheKey, trades);
    return { data: trades, cached: false };
  },

  // ────────────────────────────────────────────────────
  //  5. Fluctuation Ranking (등락률 순위) — FHPST01700000
  // ────────────────────────────────────────────────────
  async getFluctuationRanking(type = '0') {
    // type: 0=전체, 1=상승, 2=보합, 3=하락, 4=상한, 5=하한
    const cacheKey = `kis_fluct_${type}`;
    const cached = cacheService.get(cacheKey, TTL.RANKING);
    if (cached) return { data: cached, cached: true };

    await getToken();
    await throttle();

    const { data } = await axios.get(
      `${env.KIS_BASE_URL}/uapi/domestic-stock/v1/ranking/fluctuation`,
      {
        headers: headers('FHPST01700000'),
        params: {
          fid_cond_mrkt_div_code: 'J',
          fid_cond_scr_div_code: '20170',
          fid_input_iscd: '0000',
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
        timeout: 8_000,
      },
    );

    if (data.rt_cd !== '0') throw new Error(data.msg1 || 'KIS ranking API error');

    const stocks = (data.output || []).slice(0, 30).map((o) => ({
      rank: safeInt(o.data_rank),
      symbol: o.stck_shrn_iscd || '',
      name: o.hts_kor_isnm || '',
      price: safeInt(o.stck_prpr),
      change: safeInt(o.prdy_vrss),
      changePct: safeFloat(o.prdy_ctrt),
      volume: safeInt(o.acml_vol),
      tradingValue: safeInt(o.acml_tr_pbmn),
    }));

    cacheService.set(cacheKey, stocks);
    return { data: stocks, cached: false };
  },

  // ────────────────────────────────────────────────────
  //  6. Volume Ranking (거래량 순위) — FHPST01710000
  // ────────────────────────────────────────────────────
  async getVolumeRanking() {
    const cacheKey = 'kis_vol_rank';
    const cached = cacheService.get(cacheKey, TTL.RANKING);
    if (cached) return { data: cached, cached: true };

    await getToken();
    await throttle();

    const { data } = await axios.get(
      `${env.KIS_BASE_URL}/uapi/domestic-stock/v1/quotations/volume-rank`,
      {
        headers: headers('FHPST01710000'),
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
        timeout: 8_000,
      },
    );

    if (data.rt_cd !== '0') throw new Error(data.msg1 || 'KIS volume ranking API error');

    const stocks = (data.output || []).slice(0, 30).map((o) => ({
      rank: safeInt(o.data_rank),
      symbol: o.mksc_shrn_iscd || '',
      name: o.hts_kor_isnm || '',
      price: safeInt(o.stck_prpr),
      change: safeInt(o.prdy_vrss),
      changePct: safeFloat(o.prdy_ctrt),
      volume: safeInt(o.acml_vol),
      tradingValue: safeInt(o.acml_tr_pbmn),
    }));

    cacheService.set(cacheKey, stocks);
    return { data: stocks, cached: false };
  },

  // ────────────────────────────────────────────────────
  //  7. Investor Data (투자자별 매매동향) — FHKST01010900
  // ────────────────────────────────────────────────────
  async getInvestor(symbol) {
    const code = stripSymbolSuffix(symbol);
    const cacheKey = `kis_investor_${code}`;
    const cached = cacheService.get(cacheKey, TTL.INVESTOR);
    if (cached) return { data: cached, cached: true };

    await getToken();
    await throttle();

    const { data } = await axios.get(
      `${env.KIS_BASE_URL}/uapi/domestic-stock/v1/quotations/inquire-investor`,
      {
        headers: headers('FHKST01010900'),
        params: { FID_COND_MRKT_DIV_CODE: 'J', FID_INPUT_ISCD: code },
        timeout: 8_000,
      },
    );

    if (data.rt_cd !== '0') throw new Error(data.msg1 || 'KIS investor API error');

    // Fields: prsn=개인, frgn=외국인, orgn=기관 — use _ntby_qty (NOT _ntby_vol)
    const rows = (data.output || []).filter(
      (o) => o.prsn_ntby_qty || o.frgn_ntby_qty || o.orgn_ntby_qty,
    );
    const latest = rows[0] || {};

    const investors = [
      {
        name: '개인 (Individual)',
        buyVolume: safeInt(latest.prsn_shnu_vol),
        sellVolume: safeInt(latest.prsn_seln_vol),
        netVolume: safeInt(latest.prsn_ntby_qty),
        netAmount: safeInt(latest.prsn_ntby_tr_pbmn),
      },
      {
        name: '외국인 (Foreign)',
        buyVolume: safeInt(latest.frgn_shnu_vol),
        sellVolume: safeInt(latest.frgn_seln_vol),
        netVolume: safeInt(latest.frgn_ntby_qty),
        netAmount: safeInt(latest.frgn_ntby_tr_pbmn),
      },
      {
        name: '기관 (Institution)',
        buyVolume: safeInt(latest.orgn_shnu_vol),
        sellVolume: safeInt(latest.orgn_seln_vol),
        netVolume: safeInt(latest.orgn_ntby_qty),
        netAmount: safeInt(latest.orgn_ntby_tr_pbmn),
      },
    ];

    // Daily history for trend (last 10 days)
    const history = rows.slice(0, 10).map((o) => ({
      date: o.stck_bsop_date || '',
      price: safeInt(o.stck_clpr),
      prsn: safeInt(o.prsn_ntby_qty),
      frgn: safeInt(o.frgn_ntby_qty),
      orgn: safeInt(o.orgn_ntby_qty),
    }));

    const result = { investors, history, date: latest.stck_bsop_date || '' };
    cacheService.set(cacheKey, result);
    return { data: result, cached: false };
  },

  // ────────────────────────────────────────────────────
  //  8. Market Index (업종 지수) — FHPUP02100000
  // ────────────────────────────────────────────────────
  async getIndex(indexCode = '0001') {
    // 0001=KOSPI, 1001=KOSDAQ
    const cacheKey = `kis_index_${indexCode}`;
    const cached = cacheService.get(cacheKey, TTL.INDEX);
    if (cached) return { data: cached, cached: true };

    await getToken();
    await throttle();

    const { data } = await axios.get(
      `${env.KIS_BASE_URL}/uapi/domestic-stock/v1/quotations/inquire-index-price`,
      {
        headers: headers('FHPUP02100000'),
        params: { FID_COND_MRKT_DIV_CODE: 'U', FID_INPUT_ISCD: indexCode },
        timeout: 8_000,
      },
    );

    if (data.rt_cd !== '0') throw new Error(data.msg1 || 'KIS index API error');

    const o = data.output;
    const indexData = {
      code: indexCode,
      name: indexCode === '0001' ? 'KOSPI' : indexCode === '1001' ? 'KOSDAQ' : indexCode,
      price: safeFloat(o?.bstp_nmix_prpr),
      change: safeFloat(o?.bstp_nmix_prdy_vrss),
      changePct: safeFloat(o?.bstp_nmix_prdy_ctrt),
      open: safeFloat(o?.bstp_nmix_oprc),
      high: safeFloat(o?.bstp_nmix_hgpr),
      low: safeFloat(o?.bstp_nmix_lwpr),
      volume: safeInt(o?.acml_vol),
      tradingValue: safeInt(o?.acml_tr_pbmn),
    };

    cacheService.set(cacheKey, indexData);
    return { data: indexData, cached: false };
  },

  // ────────────────────────────────────────────────────
  //  9. Market Overview — batch top Korean stocks
  // ────────────────────────────────────────────────────
  async getMarketOverview() {
    const cacheKey = 'kis_market_overview';
    const cached = cacheService.get(cacheKey, TTL.MARKET);
    if (cached) return { data: cached, cached: true };

    await getToken();

    const results = [];
    for (const code of TOP_CODES) {
      try {
        await throttle();
        const { data } = await axios.get(
          `${env.KIS_BASE_URL}/uapi/domestic-stock/v1/quotations/inquire-price`,
          {
            headers: headers('FHKST01010100'),
            params: { FID_COND_MRKT_DIV_CODE: 'J', FID_INPUT_ISCD: code },
            timeout: 6_000,
          },
        );
        if (data.rt_cd === '0') {
          const o = data.output;
          results.push({
            symbol: code,
            name: STOCK_NAMES[code] || o.hts_kor_isnm || code,
            price: safeInt(o.stck_prpr),
            change: safeInt(o.prdy_vrss),
            changePct: safeFloat(o.prdy_ctrt),
            volume: safeInt(o.acml_vol),
            dayHigh: safeInt(o.stck_hgpr),
            dayLow: safeInt(o.stck_lwpr),
            prevClose: safeInt(o.stck_sdpr),
          });
        }
      } catch {
        // Skip failed individual stock
      }
    }

    cacheService.set(cacheKey, results);
    return { data: results, cached: false };
  },
};

export default kisService;
