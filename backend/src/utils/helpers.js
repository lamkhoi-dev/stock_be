/**
 * Utility Helpers
 * Common formatting, timezone, and data transformation functions
 */

/**
 * Get current time in KST (Korea Standard Time, UTC+9)
 * @returns {Date} Date object in KST
 */
export function getKSTDate() {
  return new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Seoul' }));
}

/**
 * Format KST time as HHMMSS string (for KIS API)
 * @returns {string} e.g. "143025"
 */
export function getKSTTimeString() {
  const now = getKSTDate();
  const h = String(now.getHours()).padStart(2, '0');
  const m = String(now.getMinutes()).padStart(2, '0');
  const s = String(now.getSeconds()).padStart(2, '0');
  return `${h}${m}${s}`;
}

/**
 * Format date as YYYYMMDD string (for KIS API)
 * @param {Date} [date] - Date to format (defaults to today KST)
 * @returns {string} e.g. "20260227"
 */
export function formatDateKIS(date) {
  const d = date ? new Date(date) : getKSTDate();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}${m}${day}`;
}

/**
 * Check if KRX market is currently open
 * Market hours: Mon-Fri 09:00-15:30 KST
 * @returns {{ isOpen: boolean, status: string, nextEvent: string }}
 */
export function getMarketStatus() {
  const now = getKSTDate();
  const day = now.getDay(); // 0=Sun, 6=Sat
  const hours = now.getHours();
  const minutes = now.getMinutes();
  const timeNum = hours * 100 + minutes; // e.g. 1425

  // Weekend
  if (day === 0 || day === 6) {
    return { isOpen: false, status: 'CLOSED', nextEvent: 'Opens Monday 09:00 KST' };
  }

  // Before market open
  if (timeNum < 900) {
    return { isOpen: false, status: 'PRE_MARKET', nextEvent: 'Opens today 09:00 KST' };
  }

  // Market hours (09:00 - 15:30)
  if (timeNum >= 900 && timeNum < 1530) {
    return { isOpen: true, status: 'OPEN', nextEvent: 'Closes today 15:30 KST' };
  }

  // After market close
  return { isOpen: false, status: 'CLOSED', nextEvent: 'Opens next business day 09:00 KST' };
}

/**
 * Strip .KS / .KQ suffix from Yahoo-style symbol
 * @param {string} symbol - e.g. "005930.KS" or "005930"
 * @returns {string} "005930"
 */
export function stripSymbolSuffix(symbol) {
  if (!symbol) return '';
  return symbol.replace(/\.(KS|KQ)$/i, '').trim();
}

/**
 * Add .KS suffix for Yahoo Finance API
 * @param {string} symbol - e.g. "005930"
 * @param {string} [market='KOSPI'] - 'KOSPI' or 'KOSDAQ'
 * @returns {string} "005930.KS" or "005930.KQ"
 */
export function addYahooSuffix(symbol, market = 'KOSPI') {
  const clean = stripSymbolSuffix(symbol);
  return market === 'KOSDAQ' ? `${clean}.KQ` : `${clean}.KS`;
}

/**
 * Format number with commas (Korean Won style)
 * @param {number} num
 * @returns {string} e.g. "72,800"
 */
export function formatNumber(num) {
  if (num == null || isNaN(num)) return '0';
  return Number(num).toLocaleString('en-US');
}

/**
 * Sleep utility for throttling
 * @param {number} ms - Milliseconds to sleep
 * @returns {Promise<void>}
 */
export function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Safe parse integer from KIS response
 * KIS often returns numbers as strings
 * @param {string|number} val
 * @returns {number}
 */
export function safeInt(val) {
  if (val == null || val === '') return 0;
  const n = parseInt(val, 10);
  return isNaN(n) ? 0 : n;
}

/**
 * Safe parse float from KIS response
 * @param {string|number} val
 * @returns {number}
 */
export function safeFloat(val) {
  if (val == null || val === '') return 0;
  const n = parseFloat(val);
  return isNaN(n) ? 0 : n;
}
