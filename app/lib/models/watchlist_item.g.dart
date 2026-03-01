// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watchlist_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WatchlistItemImpl _$$WatchlistItemImplFromJson(Map<String, dynamic> json) =>
    _$WatchlistItemImpl(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      englishName: json['englishName'] as String?,
      exchange: json['exchange'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      addedAt: json['addedAt'] == null
          ? null
          : DateTime.parse(json['addedAt'] as String),
      currentPrice: (json['currentPrice'] as num?)?.toDouble(),
      change: (json['change'] as num?)?.toDouble(),
      changePercent: (json['changePercent'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$WatchlistItemImplToJson(_$WatchlistItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'symbol': instance.symbol,
      'name': instance.name,
      'englishName': instance.englishName,
      'exchange': instance.exchange,
      'order': instance.order,
      'addedAt': instance.addedAt?.toIso8601String(),
      'currentPrice': instance.currentPrice,
      'change': instance.change,
      'changePercent': instance.changePercent,
    };
