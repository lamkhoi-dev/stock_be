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

// ─── AI Client Initialization ────────────────────────

let geminiClient = null;
let groqClient = null;

function getGemini() {
  if (!geminiClient && env.GEMINI_API_KEY && !env.GEMINI_API_KEY.includes('your_')) {
    geminiClient = new GoogleGenerativeAI(env.GEMINI_API_KEY);
  }
  return geminiClient;
}

function getGroq() {
  if (!groqClient && env.GROQ_API_KEY && !env.GROQ_API_KEY.includes('your_')) {
    groqClient = new OpenAI({
      apiKey: env.GROQ_API_KEY,
      baseURL: 'https://api.groq.com/openai/v1',
    });
  }
  return groqClient;
}

// ─── Prompt Templates ────────────────────────────────

function buildBasicPrompt(symbol, stockData, indicators) {
  return `You are a Korean stock market analyst AI. Analyze the following stock data and provide a concise analysis in Korean.

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

Provide your analysis in the following JSON format (respond ONLY with valid JSON, no markdown):
{
  "signal": "strong_buy|buy|hold|sell|strong_sell",
  "confidence": <number 0-100>,
  "summary": "<2-3 sentence summary in Korean>",
  "trend": "<current trend description in Korean>",
  "support": <number - key support price>,
  "resistance": <number - key resistance price>,
  "recommendation": "<specific action recommendation in Korean>"
}`;
}

function buildProPrompt(symbol, stockData, indicators, historyBars) {
  const recentBars = historyBars.slice(-30).map(b =>
    `${b.time}: O=${b.open} H=${b.high} L=${b.low} C=${b.close} V=${b.volume}`
  ).join('\n');

  return `You are an expert Korean stock market analyst AI. Provide a comprehensive professional analysis in Korean.

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

Provide a DETAILED professional analysis in the following JSON format (respond ONLY with valid JSON, no markdown):
{
  "signal": "strong_buy|buy|hold|sell|strong_sell",
  "confidence": <number 0-100>,
  "summary": "<executive summary 3-5 sentences in Korean>",
  "technicalAnalysis": "<detailed technical analysis in Korean, 200+ words, covering trend, momentum, volume, support/resistance, chart patterns>",
  "fundamentalAnalysis": "<fundamental valuation analysis in Korean, 100+ words, covering PER/PBR/EPS relative to sector>",
  "riskAssessment": "<risk factors and mitigation in Korean, 100+ words>",
  "keyLevels": {
    "support": [<support level 1>, <support level 2>],
    "resistance": [<resistance level 1>, <resistance level 2>]
  },
  "targets": {
    "upside": <target price if bullish>,
    "downside": <target price if bearish>
  },
  "strategy": "<specific trading strategy recommendation in Korean, including entry/exit points and position sizing>",
  "timeframe": "<recommended investment timeframe in Korean>"
}`;
}

// ─── AI Analysis Functions ───────────────────────────

/**
 * Basic analysis using Gemini Flash
 * @param {string} symbol
 * @returns {Promise<Object>} Analysis result
 */
async function analyzeBasic(symbol) {
  const startTime = Date.now();
  const code = stripSymbolSuffix(symbol);

  // Fetch stock data and indicators in parallel
  const [priceResult, indicatorResult] = await Promise.all([
    kisService.getPrice(code),
    indicatorsService.getAll(code),
  ]);

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
        max_tokens: 500,
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
      summary: parsed.summary || '',
      technicalAnalysis: parsed.trend || '',
      keyLevels: {
        support: parsed.support ? [parsed.support] : [],
        resistance: parsed.resistance ? [parsed.resistance] : [],
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
}

/**
 * Pro analysis using Gemini Pro or GPT-4
 * @param {string} symbol
 * @param {string} [preferredModel='gemini'] - 'gemini' or 'openai'
 * @returns {Promise<Object>} Detailed analysis
 */
async function analyzePro(symbol, preferredModel = 'gemini') {
  const startTime = Date.now();
  const code = stripSymbolSuffix(symbol);

  // Fetch comprehensive data
  const [priceResult, indicatorResult, chartResult] = await Promise.all([
    kisService.getPrice(code),
    indicatorsService.getAll(code),
    kisService.getDailyChart(code, { period: 'D' }),
  ]);

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
      summary: parsed.summary || '',
      technicalAnalysis: parsed.technicalAnalysis || '',
      fundamentalAnalysis: parsed.fundamentalAnalysis || '',
      riskAssessment: parsed.riskAssessment || '',
      keyLevels: {
        support: parsed.keyLevels?.support || [],
        resistance: parsed.keyLevels?.resistance || [],
      },
      targets: {
        upside: parsed.targets?.upside || null,
        downside: parsed.targets?.downside || null,
      },
    },
    strategy: parsed.strategy || '',
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

  // Pro analysis
  if (plan !== 'pro') {
    return {
      allowed: false,
      reason: 'Pro analysis requires Pro subscription.',
      creditsNeeded: model === 'openai' ? 20 : 10,
      creditsRemaining: 0,
    };
  }

  const creditsNeeded = 10; // Both Gemini and Groq = 10 credits
  const currentCredits = user.subscription?.credits || 0;

  if (currentCredits < creditsNeeded) {
    return {
      allowed: false,
      reason: `Insufficient credits. Need ${creditsNeeded}, have ${currentCredits}.`,
      creditsNeeded,
      creditsRemaining: currentCredits,
    };
  }

  return {
    allowed: true,
    creditsNeeded,
    creditsRemaining: currentCredits - creditsNeeded,
  };
}

// ─── Exports ─────────────────────────────────────────

const aiService = {
  analyzeBasic,
  analyzePro,
  checkCredits,
};

export default aiService;
