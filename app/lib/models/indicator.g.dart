// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indicator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IndicatorResultImpl _$$IndicatorResultImplFromJson(
        Map<String, dynamic> json) =>
    _$IndicatorResultImpl(
      name: json['name'] as String,
      signal: json['signal'] as String,
      values: json['values'] as Map<String, dynamic>?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$IndicatorResultImplToJson(
        _$IndicatorResultImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'signal': instance.signal,
      'values': instance.values,
      'description': instance.description,
    };

_$TechnicalSummaryImpl _$$TechnicalSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$TechnicalSummaryImpl(
      symbol: json['symbol'] as String,
      overallSignal: json['overallSignal'] as String,
      score: (json['score'] as num).toDouble(),
      indicators: (json['indicators'] as List<dynamic>)
          .map((e) => IndicatorResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      calculatedAt: json['calculatedAt'] == null
          ? null
          : DateTime.parse(json['calculatedAt'] as String),
    );

Map<String, dynamic> _$$TechnicalSummaryImplToJson(
        _$TechnicalSummaryImpl instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'overallSignal': instance.overallSignal,
      'score': instance.score,
      'indicators': instance.indicators,
      'calculatedAt': instance.calculatedAt?.toIso8601String(),
    };
