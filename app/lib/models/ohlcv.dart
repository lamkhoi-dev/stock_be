import 'package:freezed_annotation/freezed_annotation.dart';

part 'ohlcv.freezed.dart';
part 'ohlcv.g.dart';

/// OHLCV candle data for charting.
@freezed
class OHLCV with _$OHLCV {
  const factory OHLCV({
    required DateTime date,
    required double open,
    required double high,
    required double low,
    required double close,
    @Default(0) double volume,
  }) = _OHLCV;

  factory OHLCV.fromJson(Map<String, dynamic> json) => _$OHLCVFromJson(json);
}

/// Historical price data response.
@freezed
class PriceHistory with _$PriceHistory {
  const factory PriceHistory({
    required String symbol,
    required String period,
    required List<OHLCV> candles,
  }) = _PriceHistory;

  factory PriceHistory.fromJson(Map<String, dynamic> json) =>
      _$PriceHistoryFromJson(json);
}
