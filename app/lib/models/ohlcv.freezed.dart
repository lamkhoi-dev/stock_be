// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ohlcv.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OHLCV _$OHLCVFromJson(Map<String, dynamic> json) {
  return _OHLCV.fromJson(json);
}

/// @nodoc
mixin _$OHLCV {
  DateTime get date => throw _privateConstructorUsedError;
  double get open => throw _privateConstructorUsedError;
  double get high => throw _privateConstructorUsedError;
  double get low => throw _privateConstructorUsedError;
  double get close => throw _privateConstructorUsedError;
  double get volume => throw _privateConstructorUsedError;

  /// Serializes this OHLCV to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OHLCV
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OHLCVCopyWith<OHLCV> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OHLCVCopyWith<$Res> {
  factory $OHLCVCopyWith(OHLCV value, $Res Function(OHLCV) then) =
      _$OHLCVCopyWithImpl<$Res, OHLCV>;
  @useResult
  $Res call(
      {DateTime date,
      double open,
      double high,
      double low,
      double close,
      double volume});
}

/// @nodoc
class _$OHLCVCopyWithImpl<$Res, $Val extends OHLCV>
    implements $OHLCVCopyWith<$Res> {
  _$OHLCVCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OHLCV
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? open = null,
    Object? high = null,
    Object? low = null,
    Object? close = null,
    Object? volume = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      open: null == open
          ? _value.open
          : open // ignore: cast_nullable_to_non_nullable
              as double,
      high: null == high
          ? _value.high
          : high // ignore: cast_nullable_to_non_nullable
              as double,
      low: null == low
          ? _value.low
          : low // ignore: cast_nullable_to_non_nullable
              as double,
      close: null == close
          ? _value.close
          : close // ignore: cast_nullable_to_non_nullable
              as double,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OHLCVImplCopyWith<$Res> implements $OHLCVCopyWith<$Res> {
  factory _$$OHLCVImplCopyWith(
          _$OHLCVImpl value, $Res Function(_$OHLCVImpl) then) =
      __$$OHLCVImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime date,
      double open,
      double high,
      double low,
      double close,
      double volume});
}

/// @nodoc
class __$$OHLCVImplCopyWithImpl<$Res>
    extends _$OHLCVCopyWithImpl<$Res, _$OHLCVImpl>
    implements _$$OHLCVImplCopyWith<$Res> {
  __$$OHLCVImplCopyWithImpl(
      _$OHLCVImpl _value, $Res Function(_$OHLCVImpl) _then)
      : super(_value, _then);

  /// Create a copy of OHLCV
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? open = null,
    Object? high = null,
    Object? low = null,
    Object? close = null,
    Object? volume = null,
  }) {
    return _then(_$OHLCVImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      open: null == open
          ? _value.open
          : open // ignore: cast_nullable_to_non_nullable
              as double,
      high: null == high
          ? _value.high
          : high // ignore: cast_nullable_to_non_nullable
              as double,
      low: null == low
          ? _value.low
          : low // ignore: cast_nullable_to_non_nullable
              as double,
      close: null == close
          ? _value.close
          : close // ignore: cast_nullable_to_non_nullable
              as double,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OHLCVImpl implements _OHLCV {
  const _$OHLCVImpl(
      {required this.date,
      required this.open,
      required this.high,
      required this.low,
      required this.close,
      this.volume = 0});

  factory _$OHLCVImpl.fromJson(Map<String, dynamic> json) =>
      _$$OHLCVImplFromJson(json);

  @override
  final DateTime date;
  @override
  final double open;
  @override
  final double high;
  @override
  final double low;
  @override
  final double close;
  @override
  @JsonKey()
  final double volume;

  @override
  String toString() {
    return 'OHLCV(date: $date, open: $open, high: $high, low: $low, close: $close, volume: $volume)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OHLCVImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.open, open) || other.open == open) &&
            (identical(other.high, high) || other.high == high) &&
            (identical(other.low, low) || other.low == low) &&
            (identical(other.close, close) || other.close == close) &&
            (identical(other.volume, volume) || other.volume == volume));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, date, open, high, low, close, volume);

  /// Create a copy of OHLCV
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OHLCVImplCopyWith<_$OHLCVImpl> get copyWith =>
      __$$OHLCVImplCopyWithImpl<_$OHLCVImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OHLCVImplToJson(
      this,
    );
  }
}

abstract class _OHLCV implements OHLCV {
  const factory _OHLCV(
      {required final DateTime date,
      required final double open,
      required final double high,
      required final double low,
      required final double close,
      final double volume}) = _$OHLCVImpl;

  factory _OHLCV.fromJson(Map<String, dynamic> json) = _$OHLCVImpl.fromJson;

  @override
  DateTime get date;
  @override
  double get open;
  @override
  double get high;
  @override
  double get low;
  @override
  double get close;
  @override
  double get volume;

  /// Create a copy of OHLCV
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OHLCVImplCopyWith<_$OHLCVImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PriceHistory _$PriceHistoryFromJson(Map<String, dynamic> json) {
  return _PriceHistory.fromJson(json);
}

/// @nodoc
mixin _$PriceHistory {
  String get symbol => throw _privateConstructorUsedError;
  String get period => throw _privateConstructorUsedError;
  List<OHLCV> get candles => throw _privateConstructorUsedError;

  /// Serializes this PriceHistory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PriceHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PriceHistoryCopyWith<PriceHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PriceHistoryCopyWith<$Res> {
  factory $PriceHistoryCopyWith(
          PriceHistory value, $Res Function(PriceHistory) then) =
      _$PriceHistoryCopyWithImpl<$Res, PriceHistory>;
  @useResult
  $Res call({String symbol, String period, List<OHLCV> candles});
}

/// @nodoc
class _$PriceHistoryCopyWithImpl<$Res, $Val extends PriceHistory>
    implements $PriceHistoryCopyWith<$Res> {
  _$PriceHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PriceHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? period = null,
    Object? candles = null,
  }) {
    return _then(_value.copyWith(
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as String,
      candles: null == candles
          ? _value.candles
          : candles // ignore: cast_nullable_to_non_nullable
              as List<OHLCV>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PriceHistoryImplCopyWith<$Res>
    implements $PriceHistoryCopyWith<$Res> {
  factory _$$PriceHistoryImplCopyWith(
          _$PriceHistoryImpl value, $Res Function(_$PriceHistoryImpl) then) =
      __$$PriceHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String symbol, String period, List<OHLCV> candles});
}

/// @nodoc
class __$$PriceHistoryImplCopyWithImpl<$Res>
    extends _$PriceHistoryCopyWithImpl<$Res, _$PriceHistoryImpl>
    implements _$$PriceHistoryImplCopyWith<$Res> {
  __$$PriceHistoryImplCopyWithImpl(
      _$PriceHistoryImpl _value, $Res Function(_$PriceHistoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of PriceHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? period = null,
    Object? candles = null,
  }) {
    return _then(_$PriceHistoryImpl(
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as String,
      candles: null == candles
          ? _value._candles
          : candles // ignore: cast_nullable_to_non_nullable
              as List<OHLCV>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PriceHistoryImpl implements _PriceHistory {
  const _$PriceHistoryImpl(
      {required this.symbol,
      required this.period,
      required final List<OHLCV> candles})
      : _candles = candles;

  factory _$PriceHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$PriceHistoryImplFromJson(json);

  @override
  final String symbol;
  @override
  final String period;
  final List<OHLCV> _candles;
  @override
  List<OHLCV> get candles {
    if (_candles is EqualUnmodifiableListView) return _candles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_candles);
  }

  @override
  String toString() {
    return 'PriceHistory(symbol: $symbol, period: $period, candles: $candles)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PriceHistoryImpl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.period, period) || other.period == period) &&
            const DeepCollectionEquality().equals(other._candles, _candles));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, symbol, period,
      const DeepCollectionEquality().hash(_candles));

  /// Create a copy of PriceHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PriceHistoryImplCopyWith<_$PriceHistoryImpl> get copyWith =>
      __$$PriceHistoryImplCopyWithImpl<_$PriceHistoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PriceHistoryImplToJson(
      this,
    );
  }
}

abstract class _PriceHistory implements PriceHistory {
  const factory _PriceHistory(
      {required final String symbol,
      required final String period,
      required final List<OHLCV> candles}) = _$PriceHistoryImpl;

  factory _PriceHistory.fromJson(Map<String, dynamic> json) =
      _$PriceHistoryImpl.fromJson;

  @override
  String get symbol;
  @override
  String get period;
  @override
  List<OHLCV> get candles;

  /// Create a copy of PriceHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PriceHistoryImplCopyWith<_$PriceHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
