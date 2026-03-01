import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock.freezed.dart';
part 'stock.g.dart';

/// Core stock info — used in lists and search results.
@freezed
class Stock with _$Stock {
  const factory Stock({
    required String symbol,
    required String name,
    String? englishName,
    String? exchange, // KOSPI or KOSDAQ
    String? sector,
    String? industry,
    double? marketCap,
    double? per, // P/E ratio
    double? pbr, // P/B ratio
    double? eps,
    double? dividendYield,
    Quote? quote,
  }) = _Stock;

  factory Stock.fromJson(Map<String, dynamic> json) => _$StockFromJson(json);
}

/// Real-time or latest quote data.
@freezed
class Quote with _$Quote {
  const factory Quote({
    required String symbol,
    @Default(0) double currentPrice,
    @Default(0) double change,
    @Default(0) double changePercent,
    @Default(0) double open,
    @Default(0) double high,
    @Default(0) double low,
    @Default(0) double previousClose,
    @Default(0) double volume,
    @Default(0) double value, // 거래대금
    String? marketStatus, // OPEN, CLOSED, PRE_MARKET, etc.
    DateTime? timestamp,
  }) = _Quote;

  factory Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);
}
