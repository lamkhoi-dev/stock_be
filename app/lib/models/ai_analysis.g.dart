// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AIAnalysisImpl _$$AIAnalysisImplFromJson(Map<String, dynamic> json) =>
    _$AIAnalysisImpl(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      model: json['model'] as String,
      type: json['type'] as String,
      signal: json['signal'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      sceScore: (json['sceScore'] as num?)?.toInt() ?? 50,
      sections: json['sections'] == null
          ? null
          : AIAnalysisSections.fromJson(
              json['sections'] as Map<String, dynamic>),
      creditsUsed: (json['creditsUsed'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$AIAnalysisImplToJson(_$AIAnalysisImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'symbol': instance.symbol,
      'model': instance.model,
      'type': instance.type,
      'signal': instance.signal,
      'confidence': instance.confidence,
      'sceScore': instance.sceScore,
      'sections': instance.sections,
      'creditsUsed': instance.creditsUsed,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$AIAnalysisSectionsImpl _$$AIAnalysisSectionsImplFromJson(
        Map<String, dynamic> json) =>
    _$AIAnalysisSectionsImpl(
      marketSentiment: json['marketSentiment'] as String?,
      actionStrategy: json['actionStrategy'] as String?,
      investmentTiming: json['investmentTiming'] as String?,
      futureForecast: json['futureForecast'] as String?,
      strategy: json['strategy'] as String?,
      risk: json['risk'] as String?,
      trend: json['trend'] as String?,
      summary: json['summary'] as String?,
      technicalAnalysis: json['technicalAnalysis'] as String?,
      fundamentalAnalysis: json['fundamentalAnalysis'] as String?,
      sentiment: json['sentiment'] as String?,
      riskAssessment: json['riskAssessment'] as String?,
      recommendation: json['recommendation'] as String?,
      keyPoints: (json['keyPoints'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$AIAnalysisSectionsImplToJson(
        _$AIAnalysisSectionsImpl instance) =>
    <String, dynamic>{
      'marketSentiment': instance.marketSentiment,
      'actionStrategy': instance.actionStrategy,
      'investmentTiming': instance.investmentTiming,
      'futureForecast': instance.futureForecast,
      'strategy': instance.strategy,
      'risk': instance.risk,
      'trend': instance.trend,
      'summary': instance.summary,
      'technicalAnalysis': instance.technicalAnalysis,
      'fundamentalAnalysis': instance.fundamentalAnalysis,
      'sentiment': instance.sentiment,
      'riskAssessment': instance.riskAssessment,
      'recommendation': instance.recommendation,
      'keyPoints': instance.keyPoints,
    };

_$AICreditsImpl _$$AICreditsImplFromJson(Map<String, dynamic> json) =>
    _$AICreditsImpl(
      remaining: (json['remaining'] as num?)?.toInt() ?? 3,
      dailyLimit: (json['dailyLimit'] as num?)?.toInt() ?? 3,
      totalUsed: (json['totalUsed'] as num?)?.toInt() ?? 0,
      plan: json['plan'] as String? ?? 'free',
      resetsAt: json['resetsAt'] == null
          ? null
          : DateTime.parse(json['resetsAt'] as String),
    );

Map<String, dynamic> _$$AICreditsImplToJson(_$AICreditsImpl instance) =>
    <String, dynamic>{
      'remaining': instance.remaining,
      'dailyLimit': instance.dailyLimit,
      'totalUsed': instance.totalUsed,
      'plan': instance.plan,
      'resetsAt': instance.resetsAt?.toIso8601String(),
    };
