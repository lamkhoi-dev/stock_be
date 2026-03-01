import 'package:freezed_annotation/freezed_annotation.dart';

part 'watchlist_item.freezed.dart';
part 'watchlist_item.g.dart';

/// Watchlist item — a stock the user is tracking.
@freezed
class WatchlistItem with _$WatchlistItem {
  const factory WatchlistItem({
    required String id,
    required String symbol,
    required String name,
    String? englishName,
    String? exchange,
    @Default(0) int order,
    DateTime? addedAt,
    // Live data (populated at runtime)
    double? currentPrice,
    double? change,
    double? changePercent,
  }) = _WatchlistItem;

  factory WatchlistItem.fromJson(Map<String, dynamic> json) =>
      _$WatchlistItemFromJson(json);
}
