/**
 * Technical Indicators Service
 * Combines KIS chart data + pure-math indicators
 * Replaces Alpha Vantage entirely (no API key needed)
 */
import kisService from './kis.service.js';
import cacheService from './cache.service.js';
import { rsi, macd, bollingerBands, stochastic, atr, sma, ema } from '../utils/indicators.js';
import { stripSymbolSuffix } from '../utils/helpers.js';
import logger from '../utils/logger.js';

const TTL = 5 * 60_000; // 5 min cache for computed indicators

const indicatorsService = {
  /**
   * Calculate all technical indicators for a symbol
   * @param {string} symbol - e.g. "005930" or "005930.KS"
   * @param {object} [opts]
   * @param {string} [opts.period='D'] - Chart period (D/W/M)
   * @param {number} [opts.rsiPeriod=14]
   * @param {number} [opts.macdFast=12]
   * @param {number} [opts.macdSlow=26]
   * @param {number} [opts.macdSignal=9]
   * @param {number} [opts.bbPeriod=20]
   * @param {number} [opts.bbStdDev=2]
   * @param {number} [opts.stochK=14]
   * @param {number} [opts.stochD=3]
   * @param {number} [opts.atrPeriod=14]
   */
  async getAll(symbol, opts = {}) {
    const code = stripSymbolSuffix(symbol);
    const period = opts.period || 'D';
    const cacheKey = `ind_all_${code}_${period}`;
    const cached = cacheService.get(cacheKey, TTL);
    if (cached) return { data: cached, cached: true };

    // Fetch daily chart (need enough data for slowest indicator: ~60 bars min)
    const chartResult = await kisService.getDailyChart(code, { period });
    const bars = chartResult.data;

    if (!bars || bars.length < 30) {
      throw new Error(`Insufficient chart data (${bars?.length || 0} bars) for indicator calculation`);
    }

    const closes = bars.map((b) => b.close);
    const highs = bars.map((b) => b.high);
    const lows = bars.map((b) => b.low);

    // Calculate all indicators
    const rsiResult = rsi(closes, opts.rsiPeriod || 14);
    const macdResult = macd(closes, opts.macdFast || 12, opts.macdSlow || 26, opts.macdSignal || 9);
    const bbResult = bollingerBands(closes, opts.bbPeriod || 20, opts.bbStdDev || 2);
    const stochResult = stochastic(highs, lows, closes, opts.stochK || 14, opts.stochD || 3);
    const atrResult = atr(highs, lows, closes, opts.atrPeriod || 14);

    // Moving averages
    const sma20 = sma(closes, 20);
    const sma50 = sma(closes, 50);
    const sma200 = sma(closes, 200);
    const ema12 = ema(closes, 12);
    const ema26 = ema(closes, 26);

    const lastIdx = closes.length - 1;
    const currentPrice = closes[lastIdx];

    const result = {
      symbol: code,
      barsUsed: bars.length,
      currentPrice,
      lastDate: bars[lastIdx].time,

      rsi: {
        value: rsiResult.current != null ? Math.round(rsiResult.current * 100) / 100 : null,
        signal: rsiResult.current > 70 ? 'OVERBOUGHT' : rsiResult.current < 30 ? 'OVERSOLD' : 'NEUTRAL',
        period: opts.rsiPeriod || 14,
      },

      macd: {
        macd: macdResult.current.macd != null ? Math.round(macdResult.current.macd * 100) / 100 : null,
        signal: macdResult.current.signal != null ? Math.round(macdResult.current.signal * 100) / 100 : null,
        histogram: macdResult.current.histogram != null ? Math.round(macdResult.current.histogram * 100) / 100 : null,
        trend: macdResult.current.histogram > 0 ? 'BULLISH' : macdResult.current.histogram < 0 ? 'BEARISH' : 'NEUTRAL',
      },

      bollingerBands: {
        upper: bbResult.current.upper != null ? Math.round(bbResult.current.upper) : null,
        middle: bbResult.current.middle != null ? Math.round(bbResult.current.middle) : null,
        lower: bbResult.current.lower != null ? Math.round(bbResult.current.lower) : null,
        position: bbResult.current.upper != null
          ? Math.round(((currentPrice - bbResult.current.lower) / (bbResult.current.upper - bbResult.current.lower)) * 100)
          : null, // 0=at lower, 100=at upper
      },

      stochastic: {
        k: stochResult.current.k != null ? Math.round(stochResult.current.k * 100) / 100 : null,
        d: stochResult.current.d != null ? Math.round(stochResult.current.d * 100) / 100 : null,
        signal: stochResult.current.k > 80 ? 'OVERBOUGHT' : stochResult.current.k < 20 ? 'OVERSOLD' : 'NEUTRAL',
      },

      atr: {
        value: atrResult.current != null ? Math.round(atrResult.current) : null,
        pct: atrResult.current != null && currentPrice > 0
          ? Math.round((atrResult.current / currentPrice) * 10000) / 100 // as percentage
          : null,
      },

      movingAverages: {
        sma20: sma20[lastIdx] != null ? Math.round(sma20[lastIdx]) : null,
        sma50: sma50[lastIdx] != null ? Math.round(sma50[lastIdx]) : null,
        sma200: sma200[lastIdx] != null ? Math.round(sma200[lastIdx]) : null,
        ema12: ema12[lastIdx] != null ? Math.round(ema12[lastIdx]) : null,
        ema26: ema26[lastIdx] != null ? Math.round(ema26[lastIdx]) : null,
        trend: (sma20[lastIdx] > sma50[lastIdx] && sma50[lastIdx] > (sma200[lastIdx] || 0))
          ? 'UPTREND'
          : (sma20[lastIdx] < sma50[lastIdx]) ? 'DOWNTREND' : 'SIDEWAYS',
      },

      // Overall signal summary
      summary: _computeSummary({
        rsi: rsiResult.current,
        macdHist: macdResult.current.histogram,
        stochK: stochResult.current.k,
        bbPosition: bbResult.current.upper != null
          ? ((currentPrice - bbResult.current.lower) / (bbResult.current.upper - bbResult.current.lower)) * 100
          : 50,
        sma20: sma20[lastIdx],
        sma50: sma50[lastIdx],
        currentPrice,
      }),
    };

    cacheService.set(cacheKey, result);
    return { data: result, cached: false };
  },

  /**
   * Get indicator history (for charting overlay data)
   * Returns arrays aligned with the chart bars
   */
  async getHistory(symbol, opts = {}) {
    const code = stripSymbolSuffix(symbol);
    const period = opts.period || 'D';
    const cacheKey = `ind_hist_${code}_${period}`;
    const cached = cacheService.get(cacheKey, TTL);
    if (cached) return { data: cached, cached: true };

    const chartResult = await kisService.getDailyChart(code, { period });
    const bars = chartResult.data;
    if (!bars || bars.length < 20) {
      throw new Error('Insufficient data for indicator history');
    }

    const closes = bars.map((b) => b.close);
    const highs = bars.map((b) => b.high);
    const lows = bars.map((b) => b.low);

    const rsiVals = rsi(closes, 14).values;
    const macdResult = macd(closes, 12, 26, 9);
    const bbResult = bollingerBands(closes, 20, 2);
    const sma20 = sma(closes, 20);
    const sma50 = sma(closes, 50);

    // Build aligned arrays
    const result = bars.map((bar, i) => ({
      time: bar.time,
      close: bar.close,
      rsi: rsiVals[i] != null ? Math.round(rsiVals[i] * 100) / 100 : null,
      macd: macdResult.macd[i] != null ? Math.round(macdResult.macd[i] * 100) / 100 : null,
      macdSignal: macdResult.signal[i] != null ? Math.round(macdResult.signal[i] * 100) / 100 : null,
      macdHist: macdResult.histogram[i] != null ? Math.round(macdResult.histogram[i] * 100) / 100 : null,
      bbUpper: bbResult.upper[i] != null ? Math.round(bbResult.upper[i]) : null,
      bbMiddle: bbResult.middle[i] != null ? Math.round(bbResult.middle[i]) : null,
      bbLower: bbResult.lower[i] != null ? Math.round(bbResult.lower[i]) : null,
      sma20: sma20[i] != null ? Math.round(sma20[i]) : null,
      sma50: sma50[i] != null ? Math.round(sma50[i]) : null,
    }));

    cacheService.set(cacheKey, result);
    return { data: result, cached: false };
  },
};

/**
 * Compute a simple overall signal from individual indicators
 * @returns {{ signal: string, confidence: number, details: string[] }}
 */
function _computeSummary({ rsi: rsiVal, macdHist, stochK, bbPosition, sma20, sma50, currentPrice }) {
  let bullish = 0;
  let bearish = 0;
  let total = 0;
  const details = [];

  // RSI
  if (rsiVal != null) {
    total++;
    if (rsiVal > 70) { bearish++; details.push('RSI overbought'); }
    else if (rsiVal < 30) { bullish++; details.push('RSI oversold (potential buy)'); }
    else if (rsiVal > 50) { bullish += 0.5; details.push('RSI above 50 (mild bullish)'); }
    else { bearish += 0.5; details.push('RSI below 50 (mild bearish)'); }
  }

  // MACD
  if (macdHist != null) {
    total++;
    if (macdHist > 0) { bullish++; details.push('MACD bullish'); }
    else { bearish++; details.push('MACD bearish'); }
  }

  // Stochastic
  if (stochK != null) {
    total++;
    if (stochK > 80) { bearish++; details.push('Stochastic overbought'); }
    else if (stochK < 20) { bullish++; details.push('Stochastic oversold'); }
    else if (stochK > 50) bullish += 0.5;
    else bearish += 0.5;
  }

  // Bollinger position
  if (bbPosition != null) {
    total++;
    if (bbPosition > 90) { bearish++; details.push('Near upper Bollinger Band'); }
    else if (bbPosition < 10) { bullish++; details.push('Near lower Bollinger Band'); }
    else bullish += 0.3; // neutral
  }

  // SMA trend
  if (sma20 != null && sma50 != null) {
    total++;
    if (currentPrice > sma20 && sma20 > sma50) { bullish++; details.push('Price above SMAs (uptrend)'); }
    else if (currentPrice < sma20 && sma20 < sma50) { bearish++; details.push('Price below SMAs (downtrend)'); }
    else { details.push('Mixed SMA signals'); }
  }

  const score = total > 0 ? (bullish - bearish) / total : 0; // -1 to +1
  const confidence = total > 0 ? Math.round((Math.max(bullish, bearish) / total) * 100) : 0;

  let signal;
  if (score > 0.3) signal = 'BUY';
  else if (score < -0.3) signal = 'SELL';
  else signal = 'HOLD';

  return { signal, confidence, score: Math.round(score * 100) / 100, details };
}

export default indicatorsService;
