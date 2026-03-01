import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_analysis.dart';
import '../services/api_client.dart';

/// AI analysis state for a single stock.
class AIState {
  const AIState({
    this.basicAnalysis,
    this.proAnalysis,
    this.credits,
    this.isAnalyzing = false,
    this.error,
  });

  final AIAnalysis? basicAnalysis;
  final AIAnalysis? proAnalysis;
  final AICredits? credits;
  final bool isAnalyzing;
  final String? error;

  AIState copyWith({
    AIAnalysis? basicAnalysis,
    AIAnalysis? proAnalysis,
    AICredits? credits,
    bool? isAnalyzing,
    String? error,
  }) {
    return AIState(
      basicAnalysis: basicAnalysis ?? this.basicAnalysis,
      proAnalysis: proAnalysis ?? this.proAnalysis,
      credits: credits ?? this.credits,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error,
    );
  }
}

/// AI provider — manages AI analysis requests and credits.
class AINotifier extends StateNotifier<AIState> {
  AINotifier(this._api) : super(const AIState());
  final ApiClient _api;

  /// Load user's AI credits info.
  Future<void> loadCredits() async {
    try {
      final response = await _api.getAICredits();
      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        state = state.copyWith(
          credits: AICredits(
            remaining: data['basic']?['dailyRemaining'] ?? 0,
            dailyLimit: data['basic']?['dailyLimit'] ?? 3,
            totalUsed: data['stats']?['totalAnalyses'] ?? 0,
          ),
        );
      }
    } catch (_) {
      // Non-critical — credits display is optional
    }
  }

  /// Run basic AI analysis for a stock.
  Future<AIAnalysis?> analyzeBasic(String symbol) async {
    state = state.copyWith(isAnalyzing: true, error: null);
    try {
      final response = await _api.analyzeStock(symbol, level: 'basic');
      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final analysis = AIAnalysis(
          id: data['id'] ?? '',
          symbol: data['symbol'] ?? symbol,
          model: data['model'] ?? 'gemini',
          type: 'basic',
          signal: data['analysis']?['signal'] ?? 'HOLD',
          confidence: (data['analysis']?['confidence'] ?? 50).toDouble(),
          sections: AIAnalysisSections(
            summary: data['analysis']?['summary'],
            technicalAnalysis: data['analysis']?['technicalAnalysis'],
            fundamentalAnalysis: data['analysis']?['fundamentalAnalysis'],
            sentiment: data['analysis']?['sentiment'],
            riskAssessment: data['analysis']?['riskAssessment'],
            recommendation: data['analysis']?['recommendation'],
            keyPoints: (data['analysis']?['keyPoints'] as List<dynamic>?)
                ?.cast<String>(),
          ),
          creditsUsed: data['creditsUsed'] ?? 0,
          createdAt: DateTime.tryParse(data['createdAt'] ?? ''),
        );
        state = state.copyWith(
          basicAnalysis: analysis,
          isAnalyzing: false,
        );
        // Refresh credits after analysis
        loadCredits();
        return analysis;
      }
      state = state.copyWith(
        isAnalyzing: false,
        error: response.data['message'] ?? 'Analysis failed',
      );
      return null;
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, error: e.toString());
      return null;
    }
  }

  /// Run pro AI analysis for a stock.
  Future<AIAnalysis?> analyzePro(String symbol,
      {String model = 'gemini'}) async {
    state = state.copyWith(isAnalyzing: true, error: null);
    try {
      final response =
          await _api.analyzeStock(symbol, level: 'pro', model: model);
      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final analysis = AIAnalysis(
          id: data['id'] ?? '',
          symbol: data['symbol'] ?? symbol,
          model: data['model'] ?? model,
          type: 'pro',
          signal: data['analysis']?['signal'] ?? 'HOLD',
          confidence: (data['analysis']?['confidence'] ?? 50).toDouble(),
          sections: AIAnalysisSections(
            summary: data['analysis']?['summary'],
            technicalAnalysis: data['analysis']?['technicalAnalysis'],
            fundamentalAnalysis: data['analysis']?['fundamentalAnalysis'],
            sentiment: data['analysis']?['sentiment'],
            riskAssessment: data['analysis']?['riskAssessment'],
            recommendation: data['analysis']?['recommendation'],
            keyPoints: (data['analysis']?['keyPoints'] as List<dynamic>?)
                ?.cast<String>(),
          ),
          creditsUsed: data['creditsUsed'] ?? 0,
          createdAt: DateTime.tryParse(data['createdAt'] ?? ''),
        );
        state = state.copyWith(
          proAnalysis: analysis,
          isAnalyzing: false,
        );
        loadCredits();
        return analysis;
      }
      state = state.copyWith(
        isAnalyzing: false,
        error: response.data['message'] ?? 'Analysis failed',
      );
      return null;
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, error: e.toString());
      return null;
    }
  }

  /// Clear analysis state (when leaving stock detail).
  void clear() {
    state = const AIState();
  }
}

/// AI provider instance (not family — shared state with credits).
final aiProvider = StateNotifierProvider<AINotifier, AIState>((ref) {
  return AINotifier(ref.read(apiClientProvider));
});
