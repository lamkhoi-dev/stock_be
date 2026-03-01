import 'package:freezed_annotation/freezed_annotation.dart';

part 'indicator.freezed.dart';
part 'indicator.g.dart';

/// Technical indicator result.
@freezed
class IndicatorResult with _$IndicatorResult {
  const factory IndicatorResult({
    required String name, // RSI, MACD, SMA, etc.
    required String signal, // BUY, SELL, HOLD, NEUTRAL
    Map<String, dynamic>? values, // indicator-specific values
    String? description,
  }) = _IndicatorResult;

  factory IndicatorResult.fromJson(Map<String, dynamic> json) =>
      _$IndicatorResultFromJson(json);
}

/// Full technical analysis summary.
@freezed
class TechnicalSummary with _$TechnicalSummary {
  const factory TechnicalSummary({
    required String symbol,
    required String overallSignal, // BUY, SELL, HOLD
    required double score, // -100 to +100
    required List<IndicatorResult> indicators,
    DateTime? calculatedAt,
  }) = _TechnicalSummary;

  factory TechnicalSummary.fromJson(Map<String, dynamic> json) =>
      _$TechnicalSummaryFromJson(json);
}
