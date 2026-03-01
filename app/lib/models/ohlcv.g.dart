// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ohlcv.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OHLCVImpl _$$OHLCVImplFromJson(Map<String, dynamic> json) => _$OHLCVImpl(
      date: DateTime.parse(json['date'] as String),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$$OHLCVImplToJson(_$OHLCVImpl instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'open': instance.open,
      'high': instance.high,
      'low': instance.low,
      'close': instance.close,
      'volume': instance.volume,
    };

_$PriceHistoryImpl _$$PriceHistoryImplFromJson(Map<String, dynamic> json) =>
    _$PriceHistoryImpl(
      symbol: json['symbol'] as String,
      period: json['period'] as String,
      candles: (json['candles'] as List<dynamic>)
          .map((e) => OHLCV.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$PriceHistoryImplToJson(_$PriceHistoryImpl instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'period': instance.period,
      'candles': instance.candles,
    };
