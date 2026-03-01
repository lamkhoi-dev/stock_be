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
    AIAnalysisSections? sections,
    @Default(0) int creditsUsed,
    DateTime? createdAt,
  }) = _AIAnalysis;

  factory AIAnalysis.fromJson(Map<String, dynamic> json) =>
      _$AIAnalysisFromJson(json);
}

/// Sections of an AI analysis report.
@freezed
class AIAnalysisSections with _$AIAnalysisSections {
  const factory AIAnalysisSections({
    String? summary,
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
