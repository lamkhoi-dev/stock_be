/**
 * Technical Indicators — Pure Math (No External Dependencies)
 *
 * All functions accept arrays of OHLCV objects and return calculated values.
 * Used to replace Alpha Vantage dependency entirely.
 *
 * Supported:
 *  - SMA  (Simple Moving Average)
 *  - EMA  (Exponential Moving Average)
 *  - RSI  (Relative Strength Index)
 *  - MACD (Moving Average Convergence Divergence)
 *  - Bollinger Bands
 *  - Stochastic Oscillator
 *  - ATR  (Average True Range)
 */

/**
 * Simple Moving Average
 * @param {number[]} values - array of numbers
 * @param {number} period
 * @returns {(number|null)[]} SMA values (null for insufficient data)
 */
export function sma(values, period) {
  const result = [];
  for (let i = 0; i < values.length; i++) {
    if (i < period - 1) {
      result.push(null);
    } else {
      let sum = 0;
      for (let j = i - period + 1; j <= i; j++) {
        sum += values[j];
      }
      result.push(sum / period);
    }
  }
  return result;
}

/**
 * Exponential Moving Average
 * @param {number[]} values - array of numbers
 * @param {number} period
 * @returns {(number|null)[]}
 */
export function ema(values, period) {
  const result = [];
  const k = 2 / (period + 1);

  for (let i = 0; i < values.length; i++) {
    if (i < period - 1) {
      result.push(null);
    } else if (i === period - 1) {
      // Seed with SMA of first `period` values
      let sum = 0;
      for (let j = 0; j < period; j++) sum += values[j];
      result.push(sum / period);
    } else {
      const prev = result[i - 1];
      result.push(values[i] * k + prev * (1 - k));
    }
  }
  return result;
}

/**
 * Relative Strength Index (RSI)
 * @param {number[]} closes - closing prices
 * @param {number} [period=14]
 * @returns {{ values: (number|null)[], current: number|null }}
 */
export function rsi(closes, period = 14) {
  if (closes.length < period + 1) {
    return { values: closes.map(() => null), current: null };
  }

  const changes = [];
  for (let i = 1; i < closes.length; i++) {
    changes.push(closes[i] - closes[i - 1]);
  }

  const result = [null]; // first element has no change

  // Initial average gain/loss (SMA)
  let avgGain = 0;
  let avgLoss = 0;
  for (let i = 0; i < period; i++) {
    if (changes[i] >= 0) avgGain += changes[i];
    else avgLoss += Math.abs(changes[i]);
    result.push(null); // not enough data yet
  }
  avgGain /= period;
  avgLoss /= period;

  // First RSI value
  const firstRS = avgLoss === 0 ? 100 : avgGain / avgLoss;
  result[period] = 100 - 100 / (1 + firstRS);

  // Subsequent values use smoothed averages (Wilder's method)
  for (let i = period; i < changes.length; i++) {
    const gain = changes[i] >= 0 ? changes[i] : 0;
    const loss = changes[i] < 0 ? Math.abs(changes[i]) : 0;
    avgGain = (avgGain * (period - 1) + gain) / period;
    avgLoss = (avgLoss * (period - 1) + loss) / period;
    const rs = avgLoss === 0 ? 100 : avgGain / avgLoss;
    result.push(100 - 100 / (1 + rs));
  }

  return { values: result, current: result[result.length - 1] };
}

/**
 * MACD (Moving Average Convergence Divergence)
 * @param {number[]} closes
 * @param {number} [fastPeriod=12]
 * @param {number} [slowPeriod=26]
 * @param {number} [signalPeriod=9]
 * @returns {{ macd: (number|null)[], signal: (number|null)[], histogram: (number|null)[], current: { macd: number|null, signal: number|null, histogram: number|null } }}
 */
export function macd(closes, fastPeriod = 12, slowPeriod = 26, signalPeriod = 9) {
  const fastEMA = ema(closes, fastPeriod);
  const slowEMA = ema(closes, slowPeriod);

  // MACD line = fast EMA - slow EMA
  const macdLine = fastEMA.map((f, i) => {
    if (f == null || slowEMA[i] == null) return null;
    return f - slowEMA[i];
  });

  // Signal line = EMA of MACD line (skip nulls for EMA seed)
  const validMacd = macdLine.filter((v) => v != null);
  const signalEMA = ema(validMacd, signalPeriod);

  // Map signal values back to original indices
  const signalLine = [];
  let validIdx = 0;
  for (let i = 0; i < macdLine.length; i++) {
    if (macdLine[i] == null) {
      signalLine.push(null);
    } else {
      signalLine.push(signalEMA[validIdx] ?? null);
      validIdx++;
    }
  }

  // Histogram = MACD - Signal
  const histogram = macdLine.map((m, i) => {
    if (m == null || signalLine[i] == null) return null;
    return m - signalLine[i];
  });

  const last = closes.length - 1;
  return {
    macd: macdLine,
    signal: signalLine,
    histogram,
    current: {
      macd: macdLine[last],
      signal: signalLine[last],
      histogram: histogram[last],
    },
  };
}

/**
 * Bollinger Bands
 * @param {number[]} closes
 * @param {number} [period=20]
 * @param {number} [stdDev=2]
 * @returns {{ upper: (number|null)[], middle: (number|null)[], lower: (number|null)[], current: { upper: number|null, middle: number|null, lower: number|null } }}
 */
export function bollingerBands(closes, period = 20, stdDev = 2) {
  const middle = sma(closes, period);
  const upper = [];
  const lower = [];

  for (let i = 0; i < closes.length; i++) {
    if (middle[i] == null) {
      upper.push(null);
      lower.push(null);
    } else {
      // Standard deviation of last `period` closes
      let sumSq = 0;
      for (let j = i - period + 1; j <= i; j++) {
        sumSq += (closes[j] - middle[i]) ** 2;
      }
      const sd = Math.sqrt(sumSq / period);
      upper.push(middle[i] + stdDev * sd);
      lower.push(middle[i] - stdDev * sd);
    }
  }

  const last = closes.length - 1;
  return {
    upper,
    middle,
    lower,
    current: { upper: upper[last], middle: middle[last], lower: lower[last] },
  };
}

/**
 * Stochastic Oscillator (%K / %D)
 * @param {number[]} highs
 * @param {number[]} lows
 * @param {number[]} closes
 * @param {number} [kPeriod=14]
 * @param {number} [dPeriod=3]
 * @returns {{ k: (number|null)[], d: (number|null)[], current: { k: number|null, d: number|null } }}
 */
export function stochastic(highs, lows, closes, kPeriod = 14, dPeriod = 3) {
  const kValues = [];

  for (let i = 0; i < closes.length; i++) {
    if (i < kPeriod - 1) {
      kValues.push(null);
    } else {
      let highestHigh = -Infinity;
      let lowestLow = Infinity;
      for (let j = i - kPeriod + 1; j <= i; j++) {
        if (highs[j] > highestHigh) highestHigh = highs[j];
        if (lows[j] < lowestLow) lowestLow = lows[j];
      }
      const range = highestHigh - lowestLow;
      kValues.push(range === 0 ? 50 : ((closes[i] - lowestLow) / range) * 100);
    }
  }

  // %D = SMA of %K
  const dValues = sma(
    kValues.map((v) => (v == null ? 0 : v)),
    dPeriod,
  );
  // Nullify D where K is null
  for (let i = 0; i < kPeriod - 1 + dPeriod - 1; i++) {
    if (i < dValues.length) dValues[i] = null;
  }

  const last = closes.length - 1;
  return {
    k: kValues,
    d: dValues,
    current: { k: kValues[last], d: dValues[last] },
  };
}

/**
 * Average True Range (ATR)
 * @param {number[]} highs
 * @param {number[]} lows
 * @param {number[]} closes
 * @param {number} [period=14]
 * @returns {{ values: (number|null)[], current: number|null }}
 */
export function atr(highs, lows, closes, period = 14) {
  // True Range
  const tr = [highs[0] - lows[0]]; // first bar: just high-low
  for (let i = 1; i < closes.length; i++) {
    const hl = highs[i] - lows[i];
    const hc = Math.abs(highs[i] - closes[i - 1]);
    const lc = Math.abs(lows[i] - closes[i - 1]);
    tr.push(Math.max(hl, hc, lc));
  }

  // ATR = Wilder's smoothing (like RSI)
  const result = [];
  for (let i = 0; i < closes.length; i++) {
    if (i < period - 1) {
      result.push(null);
    } else if (i === period - 1) {
      let sum = 0;
      for (let j = 0; j < period; j++) sum += tr[j];
      result.push(sum / period);
    } else {
      result.push((result[i - 1] * (period - 1) + tr[i]) / period);
    }
  }

  return { values: result, current: result[result.length - 1] };
}
