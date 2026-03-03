import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_analysis.freezed.dart';
part 'ai_analysis.g.dart';

/// AI-powered stock analysis result.
@freezed
class AIAnalysis with _$AIAnalysis {
  const factory AIAnalysis({
    required String id,
    required String symbol,
    required String model, // gemini-flash, gemini-pro, gpt-4
    required String type, // basic, pro
    required String signal, // BUY, SELL, HOLD
    required double confidence, // 0-100
    @Default(50) int sceScore, // Stock Comprehensive Evaluation 0-100
    AIAnalysisSections? sections,
    @Default(0) int creditsUsed,
    DateTime? createdAt,
  }) = _AIAnalysis;

  factory AIAnalysis.fromJson(Map<String, dynamic> json) =>
      _$AIAnalysisFromJson(json);
}

/// Sections of an AI analysis report — terminal-style layout.
@freezed
class AIAnalysisSections with _$AIAnalysisSections {
  const factory AIAnalysisSections({
    // 4 summary cards
    String? marketSentiment,    // e.g. "낙관적", "비관적", "중립"
    String? actionStrategy,     // e.g. "적극 매수 - 기술적 지표 상승 전환"
    String? investmentTiming,   // e.g. "현재 매수 적기..."
    String? futureForecast,     // e.g. "단기 목표가 ₩60,000..."
    // 3 tab sections
    String? strategy,           // Detailed trading strategy
    String? risk,               // Risk assessment
    String? trend,              // Trend analysis
    // Summary
    String? summary,
    // Legacy fields (kept for backward compat)
    String? technicalAnalysis,
    String? fundamentalAnalysis,
    String? sentiment,
    String? riskAssessment,
    String? recommendation,
    List<String>? keyPoints,
  }) = _AIAnalysisSections;

  factory AIAnalysisSections.fromJson(Map<String, dynamic> json) =>
      _$AIAnalysisSectionsFromJson(json);
}

/// User's AI credit info.
@freezed
class AICredits with _$AICredits {
  const factory AICredits({
    @Default(3) int remaining,
    @Default(3) int dailyLimit,
    @Default(0) int totalUsed,
    DateTime? resetsAt,
  }) = _AICredits;

  factory AICredits.fromJson(Map<String, dynamic> json) =>
      _$AICreditsFromJson(json);
}
