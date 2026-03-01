// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'indicator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

IndicatorResult _$IndicatorResultFromJson(Map<String, dynamic> json) {
  return _IndicatorResult.fromJson(json);
}

/// @nodoc
mixin _$IndicatorResult {
  String get name => throw _privateConstructorUsedError; // RSI, MACD, SMA, etc.
  String get signal =>
      throw _privateConstructorUsedError; // BUY, SELL, HOLD, NEUTRAL
  Map<String, dynamic>? get values =>
      throw _privateConstructorUsedError; // indicator-specific values
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this IndicatorResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IndicatorResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IndicatorResultCopyWith<IndicatorResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IndicatorResultCopyWith<$Res> {
  factory $IndicatorResultCopyWith(
          IndicatorResult value, $Res Function(IndicatorResult) then) =
      _$IndicatorResultCopyWithImpl<$Res, IndicatorResult>;
  @useResult
  $Res call(
      {String name,
      String signal,
      Map<String, dynamic>? values,
      String? description});
}

/// @nodoc
class _$IndicatorResultCopyWithImpl<$Res, $Val extends IndicatorResult>
    implements $IndicatorResultCopyWith<$Res> {
  _$IndicatorResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IndicatorResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? signal = null,
    Object? values = freezed,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      signal: null == signal
          ? _value.signal
          : signal // ignore: cast_nullable_to_non_nullable
              as String,
      values: freezed == values
          ? _value.values
          : values // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IndicatorResultImplCopyWith<$Res>
    implements $IndicatorResultCopyWith<$Res> {
  factory _$$IndicatorResultImplCopyWith(_$IndicatorResultImpl value,
          $Res Function(_$IndicatorResultImpl) then) =
      __$$IndicatorResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String signal,
      Map<String, dynamic>? values,
      String? description});
}

/// @nodoc
class __$$IndicatorResultImplCopyWithImpl<$Res>
    extends _$IndicatorResultCopyWithImpl<$Res, _$IndicatorResultImpl>
    implements _$$IndicatorResultImplCopyWith<$Res> {
  __$$IndicatorResultImplCopyWithImpl(
      _$IndicatorResultImpl _value, $Res Function(_$IndicatorResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of IndicatorResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? signal = null,
    Object? values = freezed,
    Object? description = freezed,
  }) {
    return _then(_$IndicatorResultImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      signal: null == signal
          ? _value.signal
          : signal // ignore: cast_nullable_to_non_nullable
              as String,
      values: freezed == values
          ? _value._values
          : values // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IndicatorResultImpl implements _IndicatorResult {
  const _$IndicatorResultImpl(
      {required this.name,
      required this.signal,
      final Map<String, dynamic>? values,
      this.description})
      : _values = values;

  factory _$IndicatorResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$IndicatorResultImplFromJson(json);

  @override
  final String name;
// RSI, MACD, SMA, etc.
  @override
  final String signal;
// BUY, SELL, HOLD, NEUTRAL
  final Map<String, dynamic>? _values;
// BUY, SELL, HOLD, NEUTRAL
  @override
  Map<String, dynamic>? get values {
    final value = _values;
    if (value == null) return null;
    if (_values is EqualUnmodifiableMapView) return _values;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

// indicator-specific values
  @override
  final String? description;

  @override
  String toString() {
    return 'IndicatorResult(name: $name, signal: $signal, values: $values, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IndicatorResultImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.signal, signal) || other.signal == signal) &&
            const DeepCollectionEquality().equals(other._values, _values) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, signal,
      const DeepCollectionEquality().hash(_values), description);

  /// Create a copy of IndicatorResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IndicatorResultImplCopyWith<_$IndicatorResultImpl> get copyWith =>
      __$$IndicatorResultImplCopyWithImpl<_$IndicatorResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IndicatorResultImplToJson(
      this,
    );
  }
}

abstract class _IndicatorResult implements IndicatorResult {
  const factory _IndicatorResult(
      {required final String name,
      required final String signal,
      final Map<String, dynamic>? values,
      final String? description}) = _$IndicatorResultImpl;

  factory _IndicatorResult.fromJson(Map<String, dynamic> json) =
      _$IndicatorResultImpl.fromJson;

  @override
  String get name; // RSI, MACD, SMA, etc.
  @override
  String get signal; // BUY, SELL, HOLD, NEUTRAL
  @override
  Map<String, dynamic>? get values; // indicator-specific values
  @override
  String? get description;

  /// Create a copy of IndicatorResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IndicatorResultImplCopyWith<_$IndicatorResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TechnicalSummary _$TechnicalSummaryFromJson(Map<String, dynamic> json) {
  return _TechnicalSummary.fromJson(json);
}

/// @nodoc
mixin _$TechnicalSummary {
  String get symbol => throw _privateConstructorUsedError;
  String get overallSignal =>
      throw _privateConstructorUsedError; // BUY, SELL, HOLD
  double get score => throw _privateConstructorUsedError; // -100 to +100
  List<IndicatorResult> get indicators => throw _privateConstructorUsedError;
  DateTime? get calculatedAt => throw _privateConstructorUsedError;

  /// Serializes this TechnicalSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TechnicalSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TechnicalSummaryCopyWith<TechnicalSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TechnicalSummaryCopyWith<$Res> {
  factory $TechnicalSummaryCopyWith(
          TechnicalSummary value, $Res Function(TechnicalSummary) then) =
      _$TechnicalSummaryCopyWithImpl<$Res, TechnicalSummary>;
  @useResult
  $Res call(
      {String symbol,
      String overallSignal,
      double score,
      List<IndicatorResult> indicators,
      DateTime? calculatedAt});
}

/// @nodoc
class _$TechnicalSummaryCopyWithImpl<$Res, $Val extends TechnicalSummary>
    implements $TechnicalSummaryCopyWith<$Res> {
  _$TechnicalSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TechnicalSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? overallSignal = null,
    Object? score = null,
    Object? indicators = null,
    Object? calculatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      overallSignal: null == overallSignal
          ? _value.overallSignal
          : overallSignal // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      indicators: null == indicators
          ? _value.indicators
          : indicators // ignore: cast_nullable_to_non_nullable
              as List<IndicatorResult>,
      calculatedAt: freezed == calculatedAt
          ? _value.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TechnicalSummaryImplCopyWith<$Res>
    implements $TechnicalSummaryCopyWith<$Res> {
  factory _$$TechnicalSummaryImplCopyWith(_$TechnicalSummaryImpl value,
          $Res Function(_$TechnicalSummaryImpl) then) =
      __$$TechnicalSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String symbol,
      String overallSignal,
      double score,
      List<IndicatorResult> indicators,
      DateTime? calculatedAt});
}

/// @nodoc
class __$$TechnicalSummaryImplCopyWithImpl<$Res>
    extends _$TechnicalSummaryCopyWithImpl<$Res, _$TechnicalSummaryImpl>
    implements _$$TechnicalSummaryImplCopyWith<$Res> {
  __$$TechnicalSummaryImplCopyWithImpl(_$TechnicalSummaryImpl _value,
      $Res Function(_$TechnicalSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of TechnicalSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? overallSignal = null,
    Object? score = null,
    Object? indicators = null,
    Object? calculatedAt = freezed,
  }) {
    return _then(_$TechnicalSummaryImpl(
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      overallSignal: null == overallSignal
          ? _value.overallSignal
          : overallSignal // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      indicators: null == indicators
          ? _value._indicators
          : indicators // ignore: cast_nullable_to_non_nullable
              as List<IndicatorResult>,
      calculatedAt: freezed == calculatedAt
          ? _value.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TechnicalSummaryImpl implements _TechnicalSummary {
  const _$TechnicalSummaryImpl(
      {required this.symbol,
      required this.overallSignal,
      required this.score,
      required final List<IndicatorResult> indicators,
      this.calculatedAt})
      : _indicators = indicators;

  factory _$TechnicalSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TechnicalSummaryImplFromJson(json);

  @override
  final String symbol;
  @override
  final String overallSignal;
// BUY, SELL, HOLD
  @override
  final double score;
// -100 to +100
  final List<IndicatorResult> _indicators;
// -100 to +100
  @override
  List<IndicatorResult> get indicators {
    if (_indicators is EqualUnmodifiableListView) return _indicators;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_indicators);
  }

  @override
  final DateTime? calculatedAt;

  @override
  String toString() {
    return 'TechnicalSummary(symbol: $symbol, overallSignal: $overallSignal, score: $score, indicators: $indicators, calculatedAt: $calculatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TechnicalSummaryImpl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.overallSignal, overallSignal) ||
                other.overallSignal == overallSignal) &&
            (identical(other.score, score) || other.score == score) &&
            const DeepCollectionEquality()
                .equals(other._indicators, _indicators) &&
            (identical(other.calculatedAt, calculatedAt) ||
                other.calculatedAt == calculatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, symbol, overallSignal, score,
      const DeepCollectionEquality().hash(_indicators), calculatedAt);

  /// Create a copy of TechnicalSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TechnicalSummaryImplCopyWith<_$TechnicalSummaryImpl> get copyWith =>
      __$$TechnicalSummaryImplCopyWithImpl<_$TechnicalSummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TechnicalSummaryImplToJson(
      this,
    );
  }
}

abstract class _TechnicalSummary implements TechnicalSummary {
  const factory _TechnicalSummary(
      {required final String symbol,
      required final String overallSignal,
      required final double score,
      required final List<IndicatorResult> indicators,
      final DateTime? calculatedAt}) = _$TechnicalSummaryImpl;

  factory _TechnicalSummary.fromJson(Map<String, dynamic> json) =
      _$TechnicalSummaryImpl.fromJson;

  @override
  String get symbol;
  @override
  String get overallSignal; // BUY, SELL, HOLD
  @override
  double get score; // -100 to +100
  @override
  List<IndicatorResult> get indicators;
  @override
  DateTime? get calculatedAt;

  /// Create a copy of TechnicalSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TechnicalSummaryImplCopyWith<_$TechnicalSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
