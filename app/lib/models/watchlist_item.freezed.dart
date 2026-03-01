// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'watchlist_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WatchlistItem _$WatchlistItemFromJson(Map<String, dynamic> json) {
  return _WatchlistItem.fromJson(json);
}

/// @nodoc
mixin _$WatchlistItem {
  String get id => throw _privateConstructorUsedError;
  String get symbol => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get englishName => throw _privateConstructorUsedError;
  String? get exchange => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  DateTime? get addedAt =>
      throw _privateConstructorUsedError; // Live data (populated at runtime)
  double? get currentPrice => throw _privateConstructorUsedError;
  double? get change => throw _privateConstructorUsedError;
  double? get changePercent => throw _privateConstructorUsedError;

  /// Serializes this WatchlistItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WatchlistItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WatchlistItemCopyWith<WatchlistItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WatchlistItemCopyWith<$Res> {
  factory $WatchlistItemCopyWith(
          WatchlistItem value, $Res Function(WatchlistItem) then) =
      _$WatchlistItemCopyWithImpl<$Res, WatchlistItem>;
  @useResult
  $Res call(
      {String id,
      String symbol,
      String name,
      String? englishName,
      String? exchange,
      int order,
      DateTime? addedAt,
      double? currentPrice,
      double? change,
      double? changePercent});
}

/// @nodoc
class _$WatchlistItemCopyWithImpl<$Res, $Val extends WatchlistItem>
    implements $WatchlistItemCopyWith<$Res> {
  _$WatchlistItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WatchlistItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? symbol = null,
    Object? name = null,
    Object? englishName = freezed,
    Object? exchange = freezed,
    Object? order = null,
    Object? addedAt = freezed,
    Object? currentPrice = freezed,
    Object? change = freezed,
    Object? changePercent = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      englishName: freezed == englishName
          ? _value.englishName
          : englishName // ignore: cast_nullable_to_non_nullable
              as String?,
      exchange: freezed == exchange
          ? _value.exchange
          : exchange // ignore: cast_nullable_to_non_nullable
              as String?,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      addedAt: freezed == addedAt
          ? _value.addedAt
          : addedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      currentPrice: freezed == currentPrice
          ? _value.currentPrice
          : currentPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      change: freezed == change
          ? _value.change
          : change // ignore: cast_nullable_to_non_nullable
              as double?,
      changePercent: freezed == changePercent
          ? _value.changePercent
          : changePercent // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WatchlistItemImplCopyWith<$Res>
    implements $WatchlistItemCopyWith<$Res> {
  factory _$$WatchlistItemImplCopyWith(
          _$WatchlistItemImpl value, $Res Function(_$WatchlistItemImpl) then) =
      __$$WatchlistItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String symbol,
      String name,
      String? englishName,
      String? exchange,
      int order,
      DateTime? addedAt,
      double? currentPrice,
      double? change,
      double? changePercent});
}

/// @nodoc
class __$$WatchlistItemImplCopyWithImpl<$Res>
    extends _$WatchlistItemCopyWithImpl<$Res, _$WatchlistItemImpl>
    implements _$$WatchlistItemImplCopyWith<$Res> {
  __$$WatchlistItemImplCopyWithImpl(
      _$WatchlistItemImpl _value, $Res Function(_$WatchlistItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of WatchlistItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? symbol = null,
    Object? name = null,
    Object? englishName = freezed,
    Object? exchange = freezed,
    Object? order = null,
    Object? addedAt = freezed,
    Object? currentPrice = freezed,
    Object? change = freezed,
    Object? changePercent = freezed,
  }) {
    return _then(_$WatchlistItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      englishName: freezed == englishName
          ? _value.englishName
          : englishName // ignore: cast_nullable_to_non_nullable
              as String?,
      exchange: freezed == exchange
          ? _value.exchange
          : exchange // ignore: cast_nullable_to_non_nullable
              as String?,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      addedAt: freezed == addedAt
          ? _value.addedAt
          : addedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      currentPrice: freezed == currentPrice
          ? _value.currentPrice
          : currentPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      change: freezed == change
          ? _value.change
          : change // ignore: cast_nullable_to_non_nullable
              as double?,
      changePercent: freezed == changePercent
          ? _value.changePercent
          : changePercent // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WatchlistItemImpl implements _WatchlistItem {
  const _$WatchlistItemImpl(
      {required this.id,
      required this.symbol,
      required this.name,
      this.englishName,
      this.exchange,
      this.order = 0,
      this.addedAt,
      this.currentPrice,
      this.change,
      this.changePercent});

  factory _$WatchlistItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$WatchlistItemImplFromJson(json);

  @override
  final String id;
  @override
  final String symbol;
  @override
  final String name;
  @override
  final String? englishName;
  @override
  final String? exchange;
  @override
  @JsonKey()
  final int order;
  @override
  final DateTime? addedAt;
// Live data (populated at runtime)
  @override
  final double? currentPrice;
  @override
  final double? change;
  @override
  final double? changePercent;

  @override
  String toString() {
    return 'WatchlistItem(id: $id, symbol: $symbol, name: $name, englishName: $englishName, exchange: $exchange, order: $order, addedAt: $addedAt, currentPrice: $currentPrice, change: $change, changePercent: $changePercent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WatchlistItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.englishName, englishName) ||
                other.englishName == englishName) &&
            (identical(other.exchange, exchange) ||
                other.exchange == exchange) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.addedAt, addedAt) || other.addedAt == addedAt) &&
            (identical(other.currentPrice, currentPrice) ||
                other.currentPrice == currentPrice) &&
            (identical(other.change, change) || other.change == change) &&
            (identical(other.changePercent, changePercent) ||
                other.changePercent == changePercent));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, symbol, name, englishName,
      exchange, order, addedAt, currentPrice, change, changePercent);

  /// Create a copy of WatchlistItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WatchlistItemImplCopyWith<_$WatchlistItemImpl> get copyWith =>
      __$$WatchlistItemImplCopyWithImpl<_$WatchlistItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WatchlistItemImplToJson(
      this,
    );
  }
}

abstract class _WatchlistItem implements WatchlistItem {
  const factory _WatchlistItem(
      {required final String id,
      required final String symbol,
      required final String name,
      final String? englishName,
      final String? exchange,
      final int order,
      final DateTime? addedAt,
      final double? currentPrice,
      final double? change,
      final double? changePercent}) = _$WatchlistItemImpl;

  factory _WatchlistItem.fromJson(Map<String, dynamic> json) =
      _$WatchlistItemImpl.fromJson;

  @override
  String get id;
  @override
  String get symbol;
  @override
  String get name;
  @override
  String? get englishName;
  @override
  String? get exchange;
  @override
  int get order;
  @override
  DateTime? get addedAt; // Live data (populated at runtime)
  @override
  double? get currentPrice;
  @override
  double? get change;
  @override
  double? get changePercent;

  /// Create a copy of WatchlistItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WatchlistItemImplCopyWith<_$WatchlistItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
