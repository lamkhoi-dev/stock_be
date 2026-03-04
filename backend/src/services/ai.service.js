/**
 * AI Service
 * Stock analysis using Gemini (primary) and Groq (backup)
 *
 * Models:
 *  - Gemini 2.0 Flash: Basic analysis (fast, free-tier friendly)
 *  - Gemini 2.0 Pro: Pro analysis (detailed, credit-based)
 *  - Groq Llama 3.3 70B: Backup (fast inference, 10 credits)
 *
 * Credit system:
 *  - Free: 3 basic analyses/day (reset 00:00 KST)
 *  - Pro: unlimited basic + credit-based pro
 *    - Gemini Pro = 10 credits
 *    - Groq Llama = 10 credits
 */
import { GoogleGenerativeAI } from '@google/generative-ai';
import OpenAI from 'openai';
import env from '../config/env.js';
import kisService from './kis.service.js';
import indicatorsService from './indicators.service.js';
import cacheService from './cache.service.js';
import logger from '../utils/logger.js';
import { stripSymbolSuffix } from '../utils/helpers.js';

// ─── Retry Helper ────────────────────────────────────

/**
 * Retry an async function with exponential backoff.
 * @param {Function} fn - Async function to retry
 * @param {number} [maxRetries=2] - Max retry attempts (total calls = maxRetries + 1)
 * @param {number} [baseDelay=1000] - Base delay in ms before first retry
 * @returns {Promise<*>}
 */
async function withRetry(fn, maxRetries = 2, baseDelay = 1000) {
  let lastError;
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;
      if (attempt < maxRetries) {
        const delay = baseDelay * Math.pow(2, attempt);
        logger.warn(`Retry ${attempt + 1}/${maxRetries} after ${delay}ms: ${err.message}`);
        await new Promise(r => setTimeout(r, delay));
      }
    }
  }
  throw lastError;
}

// ─── AI Client Initialization ────────────────────────

let geminiClient = null;
let groqClient = null;

function getGemini() {
  const key = process.env.GEMINI_API_KEY || env.GEMINI_API_KEY;
  if (!geminiClient && key && !key.includes('your_')) {
    geminiClient = new GoogleGenerativeAI(key);
  }
  return geminiClient;
}

function getGroq() {
  const key = process.env.GROQ_API_KEY || env.GROQ_API_KEY;
  if (!groqClient && key && !key.includes('your_')) {
    groqClient = new OpenAI({
      apiKey: key,
      baseURL: 'https://api.groq.com/openai/v1',
    });
  }
  return groqClient;
}

/**
 * Reinitialize AI clients (called when admin updates API keys at runtime).
 */
export function reinitializeClients() {
  geminiClient = null;
  groqClient = null;
  // Next call to getGemini()/getGroq() will create fresh clients with new keys
  logger.info('AI clients reinitialized with updated API keys', { source: 'ai.service' });
}

// ─── Prompt Templates ────────────────────────────────

function buildBasicPrompt(symbol, stockData, indicators) {
  return `You are a Korean stock market analyst AI. Analyze the following stock data and provide a structured terminal-style analysis in English.

Stock: ${symbol} (${stockData.name || symbol})
Current Price: ₩${stockData.price?.toLocaleString()}
Change: ${stockData.change > 0 ? '+' : ''}${stockData.change?.toLocaleString()} (${stockData.changePct > 0 ? '+' : ''}${stockData.changePct}%)
Volume: ${stockData.volume?.toLocaleString()}
Open: ₩${stockData.open?.toLocaleString()}
High: ₩${stockData.high?.toLocaleString()}
Low: ₩${stockData.low?.toLocaleString()}
52-week High: ₩${stockData.high52w?.toLocaleString()}
52-week Low: ₩${stockData.low52w?.toLocaleString()}
PER: ${stockData.per}
PBR: ${stockData.pbr}

Technical Indicators:
- RSI(14): ${indicators.rsi?.value} (${indicators.rsi?.signal})
- MACD: ${indicators.macd?.macd} / Signal: ${indicators.macd?.signal} / Histogram: ${indicators.macd?.histogram} (${indicators.macd?.trend})
- Stochastic K: ${indicators.stochastic?.k} D: ${indicators.stochastic?.d} (${indicators.stochastic?.signal})
- Bollinger Band Position: ${indicators.bollingerBands?.position}% (Lower: ₩${indicators.bollingerBands?.lower?.toLocaleString()}, Upper: ₩${indicators.bollingerBands?.upper?.toLocaleString()})
- Overall Signal: ${indicators.summary?.overall}

Provide your analysis in the following JSON format (respond ONLY with valid JSON, no markdown). ALL text values MUST be in English:
{
  "signal": "strong_buy|buy|hold|sell|strong_sell",
  "confidence": <number 0-100>,
  "sceScore": <number 0-100, Stock Comprehensive Evaluation score based on technical + fundamental factors>,
  "marketSentiment": "<1-2 word sentiment label in English, e.g. Bullish, Bearish, Neutral, Cautious>",
  "actionStrategy": "<action recommendation in English, e.g. Buy - technical indicators turning bullish, or Hold - wait for confirmation>",
  "investmentTiming": "<specific entry/exit timing advice in English, 2-3 sentences>",
  "futureForecast": "<short-term price forecast in English with target price ranges, 2-3 sentences>",
  "strategy": "<detailed trading strategy in English, 3-5 sentences covering entry points, position sizing, stop-loss>",
  "risk": "<risk assessment in English, 3-5 sentences covering key risk factors and mitigation>",
  "trend": "<trend analysis in English, 3-5 sentences covering current trend, momentum, support/resistance levels>",
  "summary": "<executive summary paragraph in English, 3-5 sentences>"
}`;
}

function buildProPrompt(symbol, stockData, indicators, historyBars) {
  const recentBars = historyBars.slice(-30).map(b =>
    `${b.time}: O=${b.open} H=${b.high} L=${b.low} C=${b.close} V=${b.volume}`
  ).join('\n');

  return `You are an expert Korean stock market analyst AI. Provide a comprehensive professional analysis in English.

═══ Stock Information ═══
Stock: ${symbol} (${stockData.name || symbol})
Current Price: ₩${stockData.price?.toLocaleString()}
Change: ${stockData.change > 0 ? '+' : ''}${stockData.change?.toLocaleString()} (${stockData.changePct > 0 ? '+' : ''}${stockData.changePct}%)
Volume: ${stockData.volume?.toLocaleString()}, Trading Value: ₩${stockData.tradingValue?.toLocaleString()}
Market Cap: ₩${stockData.marketCap?.toLocaleString()}억
PER: ${stockData.per} | PBR: ${stockData.pbr} | EPS: ₩${stockData.eps?.toLocaleString()}
52W High: ₩${stockData.high52w?.toLocaleString()} | 52W Low: ₩${stockData.low52w?.toLocaleString()}

═══ Technical Indicators ═══
RSI(14): ${indicators.rsi?.value} (${indicators.rsi?.signal})
MACD: ${indicators.macd?.macd} / Signal: ${indicators.macd?.signal} / Hist: ${indicators.macd?.histogram} (${indicators.macd?.trend})
Stochastic: K=${indicators.stochastic?.k} D=${indicators.stochastic?.d} (${indicators.stochastic?.signal})
BB Position: ${indicators.bollingerBands?.position}% (₩${indicators.bollingerBands?.lower?.toLocaleString()} ~ ₩${indicators.bollingerBands?.upper?.toLocaleString()})
ATR: ${indicators.atr?.value}
SMA20: ₩${indicators.movingAverages?.sma20?.toLocaleString()} | SMA50: ₩${indicators.movingAverages?.sma50?.toLocaleString()} | SMA200: ₩${indicators.movingAverages?.sma200?.toLocaleString()}
MA Signals: ${JSON.stringify(indicators.movingAverages?.signals)}
Overall Signal: ${indicators.summary?.overall} (Score: ${indicators.summary?.score})

═══ Recent 30-Day OHLCV ═══
${recentBars}

Provide a DETAILED professional analysis in the following JSON format (respond ONLY with valid JSON, no markdown). ALL text values MUST be in English:
{
  "signal": "strong_buy|buy|hold|sell|strong_sell",
  "confidence": <number 0-100>,
  "sceScore": <number 0-100, Stock Comprehensive Evaluation score based on technical + fundamental + momentum factors>,
  "marketSentiment": "<1-2 word sentiment label in English, e.g. Very Bullish, Bearish, Neutral, Cautious>",
  "actionStrategy": "<specific action recommendation in English with brief detail, e.g. Strong Buy - technical indicators turning bullish>",
  "investmentTiming": "<investment timing advice in English, 2-3 sentences with specific entry/exit points>",
  "futureForecast": "<short/mid-term forecast in English with price targets, 2-3 sentences>",
  "strategy": "<detailed trading strategy in English, 5-8 sentences covering entry points, position sizing, stop-loss, take-profit levels>",
  "risk": "<comprehensive risk assessment in English, 5-8 sentences covering market risk, sector risk, company-specific risk, mitigation strategies>",
  "trend": "<detailed trend analysis in English, 5-8 sentences covering current trend direction, momentum strength, volume confirmation, support/resistance levels, MA crossovers, chart patterns>",
  "summary": "<executive summary in English, 4-6 sentences covering overall assessment>",
  "keyLevels": {
    "support": [<support level 1>, <support level 2>],
    "resistance": [<resistance level 1>, <resistance level 2>]
  },
  "targets": {
    "upside": <target price if bullish>,
    "downside": <target price if bearish>
  },
  "timeframe": "<recommended investment timeframe in English>"
}`;
}

// ─── AI Analysis Functions ───────────────────────────

/**
 * Basic analysis using Gemini Flash
 * @param {string} symbol
 * @returns {Promise<Object>} Analysis result
 */
async function analyzeBasic(symbol) {
  return withRetry(async () => {
    const startTime = Date.now();
    const code = stripSymbolSuffix(symbol);

    // Fetch stock data and indicators (sequential to avoid KIS rate limit issues)
    const priceResult = await kisService.getPrice(code);
    const indicatorResult = await indicatorsService.getAll(code);

    const stockData = priceResult.data;
    const indicators = indicatorResult.data;
    const prompt = buildBasicPrompt(code, stockData, indicators);

    let analysisText;
    let modelUsed = 'gemini';
    let tokensUsed = 0;

    // Try Gemini Flash first
    const gemini = getGemini();
    if (gemini) {
      try {
      const model = gemini.getGenerativeModel({ model: 'gemini-2.0-flash' });
      const result = await model.generateContent(prompt);
      const response = result.response;
      analysisText = response.text();
      tokensUsed = response.usageMetadata?.totalTokenCount || 0;
    } catch (err) {
      logger.warn(`Gemini Flash failed: ${err.message}, trying Groq fallback`);
      geminiClient = null; // Reset for retry later
    }
  }

  // Fallback to Groq (Llama 3.3 70B)
  if (!analysisText) {
    const groq = getGroq();
    if (!groq) {
      throw new Error('No AI provider available. Please configure GEMINI_API_KEY or GROQ_API_KEY.');
    }
    try {
      const completion = await groq.chat.completions.create({
        model: 'llama-3.3-70b-versatile',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.3,
        max_tokens: 1500,
      });
      analysisText = completion.choices[0]?.message?.content;
      tokensUsed = completion.usage?.total_tokens || 0;
      modelUsed = 'groq';
    } catch (err) {
      throw new Error(`All AI providers failed. Last error: ${err.message}`);
    }
  }

  // Parse JSON response
  const parsed = parseAIResponse(analysisText);
  const processingTime = Date.now() - startTime;

  return {
    symbol: code,
    stockName: stockData.name || code,
    level: 'basic',
    model: modelUsed,
    analysis: {
      signal: parsed.signal || 'neutral',
      confidence: parsed.confidence || 50,
      sceScore: parsed.sceScore || 50,
      marketSentiment: parsed.marketSentiment || '',
      actionStrategy: parsed.actionStrategy || '',
      investmentTiming: parsed.investmentTiming || '',
      futureForecast: parsed.futureForecast || '',
      summary: parsed.summary || '',
      strategy: parsed.strategy || '',
      risk: parsed.risk || '',
      trend: parsed.trend || '',
      keyLevels: {
        support: parsed.keyLevels?.support || (parsed.support ? [parsed.support] : []),
        resistance: parsed.keyLevels?.resistance || (parsed.resistance ? [parsed.resistance] : []),
      },
    },
    inputData: {
      price: stockData.price,
      change: stockData.change,
      changePercent: stockData.changePct,
      volume: stockData.volume,
      indicators: {
        rsi: indicators.rsi?.value,
        macd: indicators.macd?.macd,
        stochK: indicators.stochastic?.k,
      },
    },
    processingTimeMs: processingTime,
    tokensUsed,
    creditsUsed: 0, // Basic = free
  };
  }, 2, 1500); // retry up to 2 times, 1.5s base delay
}

/**
 * Pro analysis using Gemini Pro or GPT-4
 * @param {string} symbol
 * @param {string} [preferredModel='gemini'] - 'gemini' or 'openai'
 * @returns {Promise<Object>} Detailed analysis
 */
async function analyzePro(symbol, preferredModel = 'gemini') {
  return withRetry(async () => {
    const startTime = Date.now();
    const code = stripSymbolSuffix(symbol);

    // Fetch comprehensive data (sequential to avoid KIS rate limit issues)
    const priceResult = await kisService.getPrice(code);
    const indicatorResult = await indicatorsService.getAll(code);
    const chartResult = await kisService.getDailyChart(code, { period: 'D' });

  const stockData = priceResult.data;
  const indicators = indicatorResult.data;
  const historyBars = chartResult.data || [];
  const prompt = buildProPrompt(code, stockData, indicators, historyBars);

  let analysisText;
  let modelUsed = preferredModel;
  let tokensUsed = 0;
  let creditsUsed = 10; // Both Gemini Pro and Groq = 10 credits

  if (preferredModel === 'gemini' || !getGroq()) {
    const gemini = getGemini();
    if (gemini) {
      try {
        const model = gemini.getGenerativeModel({ model: 'gemini-2.0-pro' });
        const result = await model.generateContent(prompt);
        const response = result.response;
        analysisText = response.text();
        tokensUsed = response.usageMetadata?.totalTokenCount || 0;
        modelUsed = 'gemini';
        creditsUsed = 10;
      } catch (err) {
        logger.warn(`Gemini Pro failed: ${err.message}, trying Groq`);
        geminiClient = null;
      }
    }
  }

  if (!analysisText) {
    const groq = getGroq();
    if (!groq) {
      throw new Error('No AI provider available for Pro analysis.');
    }
    try {
      const completion = await groq.chat.completions.create({
        model: 'llama-3.3-70b-versatile',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.3,
        max_tokens: 4000,
      });
      analysisText = completion.choices[0]?.message?.content;
      tokensUsed = completion.usage?.total_tokens || 0;
      modelUsed = 'groq';
      creditsUsed = 10;
    } catch (err) {
      throw new Error(`All AI providers failed. Last error: ${err.message}`);
    }
  }

  // Parse JSON response
  const parsed = parseAIResponse(analysisText);
  const processingTime = Date.now() - startTime;

  return {
    symbol: code,
    stockName: stockData.name || code,
    level: 'pro',
    model: modelUsed,
    analysis: {
      signal: parsed.signal || 'neutral',
      confidence: parsed.confidence || 50,
      sceScore: parsed.sceScore || 50,
      marketSentiment: parsed.marketSentiment || '',
      actionStrategy: parsed.actionStrategy || '',
      investmentTiming: parsed.investmentTiming || '',
      futureForecast: parsed.futureForecast || '',
      summary: parsed.summary || '',
      strategy: parsed.strategy || '',
      risk: parsed.risk || '',
      trend: parsed.trend || '',
      keyLevels: {
        support: parsed.keyLevels?.support || [],
        resistance: parsed.keyLevels?.resistance || [],
      },
      targets: {
        upside: parsed.targets?.upside || null,
        downside: parsed.targets?.downside || null,
      },
    },
    timeframe: parsed.timeframe || '',
    inputData: {
      price: stockData.price,
      change: stockData.change,
      changePercent: stockData.changePct,
      volume: stockData.volume,
      indicators: {
        rsi: indicators.rsi?.value,
        macd: indicators.macd?.macd,
        stochK: indicators.stochastic?.k,
      },
    },
    processingTimeMs: processingTime,
    tokensUsed,
    creditsUsed,
  };
  }, 2, 1500); // retry up to 2 times, 1.5s base delay
}

// ─── Response Parser ─────────────────────────────────

/**
 * Parse AI text response into structured JSON.
 * Handles cases where AI wraps JSON in markdown code blocks.
 */
function parseAIResponse(text) {
  if (!text) return {};

  try {
    // Remove markdown code fences if present
    let cleaned = text.trim();
    if (cleaned.startsWith('```json')) cleaned = cleaned.slice(7);
    else if (cleaned.startsWith('```')) cleaned = cleaned.slice(3);
    if (cleaned.endsWith('```')) cleaned = cleaned.slice(0, -3);
    cleaned = cleaned.trim();

    return JSON.parse(cleaned);
  } catch (err) {
    logger.warn(`AI response parse failed: ${err.message}`);
    // Return as plain summary
    return {
      signal: 'neutral',
      confidence: 50,
      summary: text.substring(0, 500),
    };
  }
}

// ─── Credit Check Helpers ────────────────────────────

/**
 * Check if user can perform analysis and get credits info
 * @param {Object} user - Mongoose User document
 * @param {string} level - 'basic' or 'pro'
 * @param {string} [model='gemini']
 * @returns {{ allowed: boolean, reason?: string, creditsNeeded: number, creditsRemaining: number }}
 */
function checkCredits(user, level, model = 'gemini') {
  const plan = user.subscription?.plan || 'free';

  if (level === 'basic') {
    if (plan === 'pro') {
      return { allowed: true, creditsNeeded: 0, creditsRemaining: Infinity };
    }

    // Free user: 3 basic/day
    const now = new Date();
    const resetAt = user.subscription?.aiCreditsResetAt;
    let usedToday = user.subscription?.aiCreditsUsedToday || 0;

    // Reset if new day (KST)
    if (!resetAt || now.toDateString() !== new Date(resetAt).toDateString()) {
      usedToday = 0;
    }

    const remaining = Math.max(0, 3 - usedToday);
    if (remaining <= 0) {
      return {
        allowed: false,
        reason: 'Daily basic analysis limit reached (3/day). Upgrade to Pro for unlimited.',
        creditsNeeded: 0,
        creditsRemaining: 0,
      };
    }

    return { allowed: true, creditsNeeded: 0, creditsRemaining: remaining - 1 };
  }

  // Pro analysis — requires pro plan, but unlimited (no credit deduction)
  if (plan !== 'pro') {
    return {
      allowed: false,
      reason: 'Pro analysis requires Pro subscription.',
      creditsNeeded: 0,
      creditsRemaining: 0,
    };
  }

  // Pro plan = unlimited pro analysis
  return {
    allowed: true,
    creditsNeeded: 0,
    creditsRemaining: Infinity,
  };
}

// ─── Exports ─────────────────────────────────────────

const aiService = {
  analyzeBasic,
  analyzePro,
  checkCredits,
};

export default aiService;
