// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StockImpl _$$StockImplFromJson(Map<String, dynamic> json) => _$StockImpl(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      englishName: json['englishName'] as String?,
      exchange: json['exchange'] as String?,
      sector: json['sector'] as String?,
      industry: json['industry'] as String?,
      marketCap: (json['marketCap'] as num?)?.toDouble(),
      per: (json['per'] as num?)?.toDouble(),
      pbr: (json['pbr'] as num?)?.toDouble(),
      eps: (json['eps'] as num?)?.toDouble(),
      dividendYield: (json['dividendYield'] as num?)?.toDouble(),
      quote: json['quote'] == null
          ? null
          : Quote.fromJson(json['quote'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$StockImplToJson(_$StockImpl instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'name': instance.name,
      'englishName': instance.englishName,
      'exchange': instance.exchange,
      'sector': instance.sector,
      'industry': instance.industry,
      'marketCap': instance.marketCap,
      'per': instance.per,
      'pbr': instance.pbr,
      'eps': instance.eps,
      'dividendYield': instance.dividendYield,
      'quote': instance.quote,
    };

_$QuoteImpl _$$QuoteImplFromJson(Map<String, dynamic> json) => _$QuoteImpl(
      symbol: json['symbol'] as String,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0,
      change: (json['change'] as num?)?.toDouble() ?? 0,
      changePercent: (json['changePercent'] as num?)?.toDouble() ?? 0,
      open: (json['open'] as num?)?.toDouble() ?? 0,
      high: (json['high'] as num?)?.toDouble() ?? 0,
      low: (json['low'] as num?)?.toDouble() ?? 0,
      previousClose: (json['previousClose'] as num?)?.toDouble() ?? 0,
      volume: (json['volume'] as num?)?.toDouble() ?? 0,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      marketStatus: json['marketStatus'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$QuoteImplToJson(_$QuoteImpl instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'currentPrice': instance.currentPrice,
      'change': instance.change,
      'changePercent': instance.changePercent,
      'open': instance.open,
      'high': instance.high,
      'low': instance.low,
      'previousClose': instance.previousClose,
      'volume': instance.volume,
      'value': instance.value,
      'marketStatus': instance.marketStatus,
      'timestamp': instance.timestamp?.toIso8601String(),
    };
