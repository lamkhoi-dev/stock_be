/**
 * Stock Search Service
 * Hybrid search: local KRX dictionary + Yahoo Finance fallback.
 *
 * Search logic:
 *  - If query is numeric → match stock codes (startsWith > contains)
 *  - If query has Korean chars → match Korean names
 *  - If query is Latin → match English names + Korean names containing Latin chars
 *  - Results are scored and sorted by relevance
 *  - Yahoo fallback fills gaps for stocks not in dictionary
 */
import stockMasterService from './stock-master.service.js';
import cacheService from './cache.service.js';
import logger from '../utils/logger.js';

// ─── Helpers ─────────────────────────────────────────

const HAS_KOREAN = /[\uAC00-\uD7AF\u3130-\u318F]/;
const IS_NUMERIC = /^\d+$/;

/**
 * Normalize string for comparison — lowercase + trim
 */
function norm(s) {
  return (s || '').toLowerCase().trim();
}

/**
 * Calculate relevance score (higher = better match)
 */
function scoreMatch(stock, query) {
  const q = norm(query);
  const code = stock.symbol;
  const ko = norm(stock.nameKo);
  const en = norm(stock.nameEn);
  let score = 0;

  // ── Code matching ──
  if (code === q) return 100;         // exact code
  if (code.startsWith(q)) score = Math.max(score, 90); // code prefix
  else if (code.includes(q)) score = Math.max(score, 80); // code contains

  // ── Korean name matching ──
  if (ko === q) return 95;            // exact Korean name
  if (ko.startsWith(q)) score = Math.max(score, 85);
  else if (ko.includes(q)) score = Math.max(score, 70);

  // ── English name matching ──
  if (en === q) return 95;            // exact English name
  const enWords = en.split(/[\s\-&]+/);
  const firstWord = enWords[0] || '';
  if (firstWord === q) score = Math.max(score, 88);       // first word exact match
  else if (en.startsWith(q)) score = Math.max(score, 85);
  else if (enWords.some((w) => w.startsWith(q))) score = Math.max(score, 75); // word prefix
  else if (en.includes(q)) score = Math.max(score, 65);

  return score;
}

// ─── Public API ──────────────────────────────────────

const stockSearchService = {
  /**
   * Search local KRX dictionary.
   * Returns sorted array of matching stocks with scores.
   */
  searchLocal(query) {
    if (!query || query.trim().length === 0) return [];

    const q = norm(query);
    const results = [];

    const stocks = stockMasterService.getAllStocks();
    for (const stock of stocks) {
      const score = scoreMatch(stock, q);
      if (score > 0) {
        results.push({ ...stock, score });
      }
    }

    // Sort by score descending, then by symbol ascending for tie-breaking
    results.sort((a, b) => b.score - a.score || a.symbol.localeCompare(b.symbol));

    return results.slice(0, 20);
  },

  /**
   * Hybrid search: local first, then Yahoo Finance fallback.
   * Returns unified result format.
   */
  async searchHybrid(query, yahooService) {
    if (!query || query.trim().length === 0) {
      return { data: [], source: 'none' };
    }

    const cacheKey = `search_hybrid_${norm(query)}`;
    const cached = cacheService.get(cacheKey, 3 * 60_000); // 3min cache
    if (cached) return { data: cached, cached: true, source: 'cache' };

    // 1. Search local dictionary
    const localResults = this.searchLocal(query);
    const localFormatted = localResults.map((s) => ({
      symbol: s.symbol,
      nameKo: s.nameKo,
      nameEn: s.nameEn,
      exchange: s.market,
      source: 'local',
      score: s.score,
    }));

    // 2. If local results are good enough (>= 5 results or exact match), skip Yahoo
    if (localFormatted.length >= 5 || (localFormatted.length > 0 && localFormatted[0].score >= 90)) {
      cacheService.set(cacheKey, localFormatted);
      return { data: localFormatted, cached: false, source: 'local' };
    }

    // 3. Also fetch from Yahoo for more results
    let yahooResults = [];
    try {
      const yahooResp = await yahooService.search(query);
      const yahooData = yahooResp.data;
      const quotes = yahooData?.quotes || [];

      // Filter to Korean stocks only (exchanges: KSC = KOSPI, KOE = KOSDAQ)
      const koreanQuotes = quotes.filter(
        (q) =>
          q.exchDisp === 'Korea' ||
          q.exchange === 'KSC' ||
          q.exchange === 'KOE' ||
          (q.symbol && (q.symbol.endsWith('.KS') || q.symbol.endsWith('.KQ'))),
      );

      yahooResults = koreanQuotes.map((q) => {
        let symbol = q.symbol || '';
        let exchange = 'KOSPI';
        if (symbol.endsWith('.KQ') || q.exchange === 'KOE') {
          exchange = 'KOSDAQ';
          symbol = symbol.replace('.KQ', '');
        } else if (symbol.endsWith('.KS') || q.exchange === 'KSC') {
          exchange = 'KOSPI';
          symbol = symbol.replace('.KS', '');
        }
        return {
          symbol,
          nameKo: q.shortname || q.longname || '',
          nameEn: q.longname || q.shortname || '',
          exchange,
          source: 'yahoo',
          score: 50, // Yahoo results get a base score
        };
      });
    } catch (err) {
      logger.warn('Yahoo search fallback failed:', err.message);
    }

    // 4. Merge: local results first, then Yahoo results (dedup by symbol)
    const seen = new Set(localFormatted.map((r) => r.symbol));
    const merged = [...localFormatted];

    for (const yr of yahooResults) {
      if (!seen.has(yr.symbol)) {
        seen.add(yr.symbol);
        merged.push(yr);
      }
    }

    // Limit to 20 results
    const final20 = merged.slice(0, 20);
    cacheService.set(cacheKey, final20);
    return { data: final20, cached: false, source: 'hybrid' };
  },
};

export default stockSearchService;
