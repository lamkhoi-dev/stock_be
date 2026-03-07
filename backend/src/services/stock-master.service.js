/**
 * Stock Master Service
 * Downloads and parses KIS master files (KOSPI + KOSDAQ) to get ALL listed stocks.
 * ~2500 real stocks (excl. ETFs, preferred shares, SPACs).
 *
 * Flow:
 *  1. On first request → try JSON cache file → if stale, download fresh
 *  2. Download .mst.zip from KIS → parse cp949 fixed-width → extract symbol+nameKo+market
 *  3. Merge with krx-stocks.js for English names
 *  4. Save to JSON cache for fast restarts
 *  5. Fallback to dictionary if download fails
 */
import https from 'https';
import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import AdmZip from 'adm-zip';
import iconv from 'iconv-lite';
import KRX_STOCKS from '../data/krx-stocks.js';
import logger from '../utils/logger.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CACHE_FILE = path.join(__dirname, '../data/krx-master-cache.json');
const EN_CACHE_FILE = path.join(__dirname, '../data/krx-english-names.json');

const KOSPI_URL = 'https://new.real.download.dws.co.kr/common/master/kospi_code.mst.zip';
const KOSDAQ_URL = 'https://new.real.download.dws.co.kr/common/master/kosdaq_code.mst.zip';

const CACHE_TTL = 24 * 60 * 60 * 1000; // 24 hours
const CACHE_VERSION = 2; // Bump when parseMst logic changes
const DOWNLOAD_TIMEOUT = 30_000; // 30s per file

// Build English name map from our dictionary
const enNameMap = new Map();
for (const s of KRX_STOCKS) {
  enNameMap.set(s.symbol, s.nameEn);
}

// Load cached English names from Yahoo
function loadEnglishNameCache() {
  try {
    if (!fs.existsSync(EN_CACHE_FILE)) return;
    const data = JSON.parse(fs.readFileSync(EN_CACHE_FILE, 'utf-8'));
    if (data.names) {
      for (const [sym, name] of Object.entries(data.names)) {
        if (name && !enNameMap.has(sym)) enNameMap.set(sym, name);
      }
      logger.info(`Loaded ${Object.keys(data.names).length} cached English names`);
    }
  } catch { /* ignore */ }
}
loadEnglishNameCache();

// Fetch English name from Yahoo Finance search
function fetchYahooEnglishName(symbol) {
  return new Promise((resolve) => {
    const suffix = symbol.match(/^\d/) ? '.KS' : '';
    const url = `https://query1.finance.yahoo.com/v1/finance/search?q=${encodeURIComponent(symbol)}&quotesCount=3&newsCount=0&enableFuzzyQuery=false`;
    const timer = setTimeout(() => resolve(null), 8000);
    https.get(url, {
      headers: { 'User-Agent': 'Mozilla/5.0' },
      rejectUnauthorized: false,
    }, (res) => {
      let d = '';
      res.on('data', (c) => d += c);
      res.on('end', () => {
        clearTimeout(timer);
        try {
          const j = JSON.parse(d);
          const match = j.quotes?.find((q) =>
            q.symbol === `${symbol}.KS` || q.symbol === `${symbol}.KQ` || q.symbol === symbol
          );
          resolve(match?.longname || match?.shortname || null);
        } catch { resolve(null); }
      });
      res.on('error', () => { clearTimeout(timer); resolve(null); });
    }).on('error', () => { clearTimeout(timer); resolve(null); });
  });
}

// Background: fetch English names for stocks missing them
async function enrichEnglishNames() {
  if (!allStocks) return;
  const missing = allStocks.filter((s) => !s.nameEn && /^\d{6}$/.test(s.symbol));
  if (missing.length === 0) return;

  logger.info(`Fetching English names for ${missing.length} stocks from Yahoo...`);
  const batchSize = 5;
  const delay = (ms) => new Promise((r) => setTimeout(r, ms));
  let fetched = 0;
  const newNames = {};

  for (let i = 0; i < missing.length; i += batchSize) {
    const batch = missing.slice(i, i + batchSize);
    const results = await Promise.allSettled(
      batch.map((s) => fetchYahooEnglishName(s.symbol))
    );
    for (let j = 0; j < batch.length; j++) {
      const name = results[j].status === 'fulfilled' ? results[j].value : null;
      if (name) {
        batch[j].nameEn = name;
        enNameMap.set(batch[j].symbol, name);
        if (stockMap) {
          const entry = stockMap.get(batch[j].symbol);
          if (entry) entry.nameEn = name;
        }
        newNames[batch[j].symbol] = name;
        fetched++;
      }
    }
    if (i + batchSize < missing.length) await delay(500);
  }

  // Save to cache
  if (fetched > 0) {
    try {
      let existing = {};
      try { existing = JSON.parse(fs.readFileSync(EN_CACHE_FILE, 'utf-8')).names || {}; } catch { /* ignore */ }
      const merged = { ...existing, ...newNames };
      fs.writeFileSync(EN_CACHE_FILE, JSON.stringify({ names: merged, timestamp: Date.now() }));
    } catch { /* ignore */ }
    logger.info(`Fetched ${fetched} English names from Yahoo, saved to cache`);
  }
}

let allStocks = null;
let stockMap = null;
let initPromise = null;

// ─── Internal helpers ────────────────────────────────

function downloadBuffer(url) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Download timeout')), DOWNLOAD_TIMEOUT);
    https.get(url, { rejectUnauthorized: false }, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        clearTimeout(timer);
        downloadBuffer(res.headers.location).then(resolve).catch(reject);
        return;
      }
      const chunks = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => { clearTimeout(timer); resolve(Buffer.concat(chunks)); });
      res.on('error', (err) => { clearTimeout(timer); reject(err); });
    }).on('error', (err) => { clearTimeout(timer); reject(err); });
  });
}

// Sector codes for ETFs, preferred shares, SPACs — skip these
const SKIP_SECTORS = new Set(['000', '0100', '0101', '0000', '0001', '0002']);

function parseMst(buffer, market, tailLen) {
  const text = iconv.decode(buffer, 'euc-kr');
  const lines = text.split('\n');
  const stocks = [];

  for (const line of lines) {
    if (!line || line.length < tailLen + 20) continue;

    const part1 = line.substring(0, line.length - tailLen);
    const shortCode = part1.substring(0, 9).trim();
    const korName = part1.substring(21).trim();

    if (!/^[A-Z]{0,2}\d{4,6}$/.test(shortCode)) continue;

    // Parse sector from fixed-width tail
    const part2 = line.substring(line.length - tailLen);
    const sectorLarge = part2.substring(3, 7).trim();

    // Allow alpha-prefix codes (ETNs like Q500072) through sector filter
    if (SKIP_SECTORS.has(sectorLarge) && /^\d/.test(shortCode)) continue;

    stocks.push({
      symbol: shortCode,
      nameKo: korName,
      nameEn: enNameMap.get(shortCode) || '',
      market,
    });
  }
  return stocks;
}

function loadFromCacheFile() {
  try {
    if (!fs.existsSync(CACHE_FILE)) return null;
    const cached = JSON.parse(fs.readFileSync(CACHE_FILE, 'utf-8'));
    if (cached.version !== CACHE_VERSION) return null; // Invalidate old cache format
    if (cached.stocks?.length > 100 && (Date.now() - cached.timestamp) < CACHE_TTL) {
      return cached.stocks;
    }
  } catch { /* ignore */ }
  return null;
}

function saveToCacheFile(stocks) {
  try {
    fs.writeFileSync(CACHE_FILE, JSON.stringify({ stocks, timestamp: Date.now(), version: CACHE_VERSION }));
  } catch (err) {
    logger.warn('Failed to write master cache file:', err.message);
  }
}

function useFallbackDictionary() {
  allStocks = KRX_STOCKS.map((s) => ({
    symbol: s.symbol,
    nameKo: s.nameKo,
    nameEn: s.nameEn,
    market: s.market,
  }));
  stockMap = new Map(allStocks.map((s) => [s.symbol, s]));
  logger.warn(`Using fallback dictionary: ${allStocks.length} stocks`);
}

// ─── Public API ──────────────────────────────────────

const stockMasterService = {
  /**
   * Initialize — call once on startup. Safe to call multiple times.
   */
  async init() {
    if (initPromise) return initPromise;
    initPromise = this._doInit();
    return initPromise;
  },

  async _doInit() {
    // 1. Try JSON cache first (fast)
    const cached = loadFromCacheFile();
    if (cached) {
      allStocks = cached;
      stockMap = new Map(allStocks.map((s) => [s.symbol, s]));
      logger.info(`Stock master loaded from cache: ${allStocks.length} stocks`);
      // Apply cached English names
      for (const s of allStocks) {
        if (!s.nameEn && enNameMap.has(s.symbol)) s.nameEn = enNameMap.get(s.symbol);
      }
      // Refresh in background if cache is older than 12h
      const cacheAge = Date.now() - JSON.parse(fs.readFileSync(CACHE_FILE, 'utf-8')).timestamp;
      if (cacheAge > CACHE_TTL / 2) {
        this.refresh().catch(() => {});
      }
      // Enrich English names in background if many are missing
      const missingEn = allStocks.filter((s) => !s.nameEn && /^\d{6}$/.test(s.symbol)).length;
      if (missingEn > 100) {
        enrichEnglishNames().catch(() => {});
      }
      return;
    }

    // 2. Download fresh
    await this.refresh();
  },

  /**
   * Download fresh master files from KIS
   */
  async refresh() {
    try {
      logger.info('Downloading KIS master files...');

      const [kospiZipBuf, kosdaqZipBuf] = await Promise.all([
        downloadBuffer(KOSPI_URL),
        downloadBuffer(KOSDAQ_URL),
      ]);

      const kospiZip = new AdmZip(kospiZipBuf);
      const kosdaqZip = new AdmZip(kosdaqZipBuf);

      const kospiEntry = kospiZip.getEntries().find((e) => e.entryName.endsWith('.mst'));
      const kosdaqEntry = kosdaqZip.getEntries().find((e) => e.entryName.endsWith('.mst'));

      if (!kospiEntry || !kosdaqEntry) throw new Error('MST entries not found in ZIP');

      const kospiStocks = parseMst(kospiEntry.getData(), 'KOSPI', 228);
      const kosdaqStocks = parseMst(kosdaqEntry.getData(), 'KOSDAQ', 222);

      allStocks = [...kospiStocks, ...kosdaqStocks];
      stockMap = new Map(allStocks.map((s) => [s.symbol, s]));

      saveToCacheFile(allStocks);

      logger.info(
        `Stock master refreshed: ${allStocks.length} stocks (KOSPI: ${kospiStocks.length}, KOSDAQ: ${kosdaqStocks.length})`,
      );

      // Enrich English names in background
      enrichEnglishNames().catch(() => {});
    } catch (err) {
      logger.error('Failed to download master files:', err.message);
      if (!allStocks) {
        useFallbackDictionary();
      }
    }
  },

  /** Get all stocks */
  getAllStocks() {
    return allStocks || [];
  },

  /** Get single stock by symbol */
  getStock(symbol) {
    return stockMap?.get(symbol) || null;
  },

  /** Total count */
  getCount() {
    return allStocks?.length || 0;
  },

  /** Whether master data is loaded */
  isReady() {
    return allStocks !== null && allStocks.length > 0;
  },
};

export default stockMasterService;
