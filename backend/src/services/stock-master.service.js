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
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import AdmZip from 'adm-zip';
import iconv from 'iconv-lite';
import KRX_STOCKS from '../data/krx-stocks.js';
import logger from '../utils/logger.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CACHE_FILE = path.join(__dirname, '../data/krx-master-cache.json');

const KOSPI_URL = 'https://new.real.download.dws.co.kr/common/master/kospi_code.mst.zip';
const KOSDAQ_URL = 'https://new.real.download.dws.co.kr/common/master/kosdaq_code.mst.zip';

const CACHE_TTL = 24 * 60 * 60 * 1000; // 24 hours
const DOWNLOAD_TIMEOUT = 30_000; // 30s per file

// Build English name map from our dictionary
const enNameMap = new Map();
for (const s of KRX_STOCKS) {
  enNameMap.set(s.symbol, s.nameEn);
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

    if (!/^\d{6}$/.test(shortCode)) continue;

    // Parse sector from fixed-width tail
    const part2 = line.substring(line.length - tailLen);
    const sectorLarge = part2.substring(3, 7).trim();

    if (SKIP_SECTORS.has(sectorLarge)) continue;

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
    if (cached.stocks?.length > 100 && (Date.now() - cached.timestamp) < CACHE_TTL) {
      return cached.stocks;
    }
  } catch { /* ignore */ }
  return null;
}

function saveToCacheFile(stocks) {
  try {
    fs.writeFileSync(CACHE_FILE, JSON.stringify({ stocks, timestamp: Date.now() }));
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
      // Refresh in background if cache is older than 12h
      const cacheAge = Date.now() - JSON.parse(fs.readFileSync(CACHE_FILE, 'utf-8')).timestamp;
      if (cacheAge > CACHE_TTL / 2) {
        this.refresh().catch(() => {});
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
