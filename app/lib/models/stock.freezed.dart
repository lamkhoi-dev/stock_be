// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Stock _$StockFromJson(Map<String, dynamic> json) {
  return _Stock.fromJson(json);
}

/// @nodoc
mixin _$Stock {
  String get symbol => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get englishName => throw _privateConstructorUsedError;
  String? get exchange => throw _privateConstructorUsedError; // KOSPI or KOSDAQ
  String? get sector => throw _privateConstructorUsedError;
  String? get industry => throw _privateConstructorUsedError;
  double? get marketCap => throw _privateConstructorUsedError;
  double? get per => throw _privateConstructorUsedError; // P/E ratio
  double? get pbr => throw _privateConstructorUsedError; // P/B ratio
  double? get eps => throw _privateConstructorUsedError;
  double? get dividendYield => throw _privateConstructorUsedError;
  Quote? get quote => throw _privateConstructorUsedError;

  /// Serializes this Stock to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Stock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StockCopyWith<Stock> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockCopyWith<$Res> {
  factory $StockCopyWith(Stock value, $Res Function(Stock) then) =
      _$StockCopyWithImpl<$Res, Stock>;
  @useResult
  $Res call(
      {String symbol,
      String name,
      String? englishName,
      String? exchange,
      String? sector,
      String? industry,
      double? marketCap,
      double? per,
      double? pbr,
      double? eps,
      double? dividendYield,
      Quote? quote});

  $QuoteCopyWith<$Res>? get quote;
}

/// @nodoc
class _$StockCopyWithImpl<$Res, $Val extends Stock>
    implements $StockCopyWith<$Res> {
  _$StockCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Stock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? name = null,
    Object? englishName = freezed,
    Object? exchange = freezed,
    Object? sector = freezed,
    Object? industry = freezed,
    Object? marketCap = freezed,
    Object? per = freezed,
    Object? pbr = freezed,
    Object? eps = freezed,
    Object? dividendYield = freezed,
    Object? quote = freezed,
  }) {
    return _then(_value.copyWith(
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
      sector: freezed == sector
          ? _value.sector
          : sector // ignore: cast_nullable_to_non_nullable
              as String?,
      industry: freezed == industry
          ? _value.industry
          : industry // ignore: cast_nullable_to_non_nullable
              as String?,
      marketCap: freezed == marketCap
          ? _value.marketCap
          : marketCap // ignore: cast_nullable_to_non_nullable
              as double?,
      per: freezed == per
          ? _value.per
          : per // ignore: cast_nullable_to_non_nullable
              as double?,
      pbr: freezed == pbr
          ? _value.pbr
          : pbr // ignore: cast_nullable_to_non_nullable
              as double?,
      eps: freezed == eps
          ? _value.eps
          : eps // ignore: cast_nullable_to_non_nullable
              as double?,
      dividendYield: freezed == dividendYield
          ? _value.dividendYield
          : dividendYield // ignore: cast_nullable_to_non_nullable
              as double?,
      quote: freezed == quote
          ? _value.quote
          : quote // ignore: cast_nullable_to_non_nullable
              as Quote?,
    ) as $Val);
  }

  /// Create a copy of Stock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $QuoteCopyWith<$Res>? get quote {
    if (_value.quote == null) {
      return null;
    }

    return $QuoteCopyWith<$Res>(_value.quote!, (value) {
      return _then(_value.copyWith(quote: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StockImplCopyWith<$Res> implements $StockCopyWith<$Res> {
  factory _$$StockImplCopyWith(
          _$StockImpl value, $Res Function(_$StockImpl) then) =
      __$$StockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String symbol,
      String name,
      String? englishName,
      String? exchange,
      String? sector,
      String? industry,
      double? marketCap,
      double? per,
      double? pbr,
      double? eps,
      double? dividendYield,
      Quote? quote});

  @override
  $QuoteCopyWith<$Res>? get quote;
}

/// @nodoc
class __$$StockImplCopyWithImpl<$Res>
    extends _$StockCopyWithImpl<$Res, _$StockImpl>
    implements _$$StockImplCopyWith<$Res> {
  __$$StockImplCopyWithImpl(
      _$StockImpl _value, $Res Function(_$StockImpl) _then)
      : super(_value, _then);

  /// Create a copy of Stock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? name = null,
    Object? englishName = freezed,
    Object? exchange = freezed,
    Object? sector = freezed,
    Object? industry = freezed,
    Object? marketCap = freezed,
    Object? per = freezed,
    Object? pbr = freezed,
    Object? eps = freezed,
    Object? dividendYield = freezed,
    Object? quote = freezed,
  }) {
    return _then(_$StockImpl(
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
      sector: freezed == sector
          ? _value.sector
          : sector // ignore: cast_nullable_to_non_nullable
              as String?,
      industry: freezed == industry
          ? _value.industry
          : industry // ignore: cast_nullable_to_non_nullable
              as String?,
      marketCap: freezed == marketCap
          ? _value.marketCap
          : marketCap // ignore: cast_nullable_to_non_nullable
              as double?,
      per: freezed == per
          ? _value.per
          : per // ignore: cast_nullable_to_non_nullable
              as double?,
      pbr: freezed == pbr
          ? _value.pbr
          : pbr // ignore: cast_nullable_to_non_nullable
              as double?,
      eps: freezed == eps
          ? _value.eps
          : eps // ignore: cast_nullable_to_non_nullable
              as double?,
      dividendYield: freezed == dividendYield
          ? _value.dividendYield
          : dividendYield // ignore: cast_nullable_to_non_nullable
              as double?,
      quote: freezed == quote
          ? _value.quote
          : quote // ignore: cast_nullable_to_non_nullable
              as Quote?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StockImpl implements _Stock {
  const _$StockImpl(
      {required this.symbol,
      required this.name,
      this.englishName,
      this.exchange,
      this.sector,
      this.industry,
      this.marketCap,
      this.per,
      this.pbr,
      this.eps,
      this.dividendYield,
      this.quote});

  factory _$StockImpl.fromJson(Map<String, dynamic> json) =>
      _$$StockImplFromJson(json);

  @override
  final String symbol;
  @override
  final String name;
  @override
  final String? englishName;
  @override
  final String? exchange;
// KOSPI or KOSDAQ
  @override
  final String? sector;
  @override
  final String? industry;
  @override
  final double? marketCap;
  @override
  final double? per;
// P/E ratio
  @override
  final double? pbr;
// P/B ratio
  @override
  final double? eps;
  @override
  final double? dividendYield;
  @override
  final Quote? quote;

  @override
  String toString() {
    return 'Stock(symbol: $symbol, name: $name, englishName: $englishName, exchange: $exchange, sector: $sector, industry: $industry, marketCap: $marketCap, per: $per, pbr: $pbr, eps: $eps, dividendYield: $dividendYield, quote: $quote)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockImpl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.englishName, englishName) ||
                other.englishName == englishName) &&
            (identical(other.exchange, exchange) ||
                other.exchange == exchange) &&
            (identical(other.sector, sector) || other.sector == sector) &&
            (identical(other.industry, industry) ||
                other.industry == industry) &&
            (identical(other.marketCap, marketCap) ||
                other.marketCap == marketCap) &&
            (identical(other.per, per) || other.per == per) &&
            (identical(other.pbr, pbr) || other.pbr == pbr) &&
            (identical(other.eps, eps) || other.eps == eps) &&
            (identical(other.dividendYield, dividendYield) ||
                other.dividendYield == dividendYield) &&
            (identical(other.quote, quote) || other.quote == quote));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      symbol,
      name,
      englishName,
      exchange,
      sector,
      industry,
      marketCap,
      per,
      pbr,
      eps,
      dividendYield,
      quote);

  /// Create a copy of Stock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StockImplCopyWith<_$StockImpl> get copyWith =>
      __$$StockImplCopyWithImpl<_$StockImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StockImplToJson(
      this,
    );
  }
}

abstract class _Stock implements Stock {
  const factory _Stock(
      {required final String symbol,
      required final String name,
      final String? englishName,
      final String? exchange,
      final String? sector,
      final String? industry,
      final double? marketCap,
      final double? per,
      final double? pbr,
      final double? eps,
      final double? dividendYield,
      final Quote? quote}) = _$StockImpl;

  factory _Stock.fromJson(Map<String, dynamic> json) = _$StockImpl.fromJson;

  @override
  String get symbol;
  @override
  String get name;
  @override
  String? get englishName;
  @override
  String? get exchange; // KOSPI or KOSDAQ
  @override
  String? get sector;
  @override
  String? get industry;
  @override
  double? get marketCap;
  @override
  double? get per; // P/E ratio
  @override
  double? get pbr; // P/B ratio
  @override
  double? get eps;
  @override
  double? get dividendYield;
  @override
  Quote? get quote;

  /// Create a copy of Stock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StockImplCopyWith<_$StockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Quote _$QuoteFromJson(Map<String, dynamic> json) {
  return _Quote.fromJson(json);
}

/// @nodoc
mixin _$Quote {
  String get symbol => throw _privateConstructorUsedError;
  double get currentPrice => throw _privateConstructorUsedError;
  double get change => throw _privateConstructorUsedError;
  double get changePercent => throw _privateConstructorUsedError;
  double get open => throw _privateConstructorUsedError;
  double get high => throw _privateConstructorUsedError;
  double get low => throw _privateConstructorUsedError;
  double get previousClose => throw _privateConstructorUsedError;
  double get volume => throw _privateConstructorUsedError;
  double get value => throw _privateConstructorUsedError; // 거래대금
  String? get marketStatus =>
      throw _privateConstructorUsedError; // OPEN, CLOSED, PRE_MARKET, etc.
  DateTime? get timestamp => throw _privateConstructorUsedError;

  /// Serializes this Quote to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuoteCopyWith<Quote> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuoteCopyWith<$Res> {
  factory $QuoteCopyWith(Quote value, $Res Function(Quote) then) =
      _$QuoteCopyWithImpl<$Res, Quote>;
  @useResult
  $Res call(
      {String symbol,
      double currentPrice,
      double change,
      double changePercent,
      double open,
      double high,
      double low,
      double previousClose,
      double volume,
      double value,
      String? marketStatus,
      DateTime? timestamp});
}

/// @nodoc
class _$QuoteCopyWithImpl<$Res, $Val extends Quote>
    implements $QuoteCopyWith<$Res> {
  _$QuoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? currentPrice = null,
    Object? change = null,
    Object? changePercent = null,
    Object? open = null,
    Object? high = null,
    Object? low = null,
    Object? previousClose = null,
    Object? volume = null,
    Object? value = null,
    Object? marketStatus = freezed,
    Object? timestamp = freezed,
  }) {
    return _then(_value.copyWith(
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      currentPrice: null == currentPrice
          ? _value.currentPrice
          : currentPrice // ignore: cast_nullable_to_non_nullable
              as double,
      change: null == change
          ? _value.change
          : change // ignore: cast_nullable_to_non_nullable
              as double,
      changePercent: null == changePercent
          ? _value.changePercent
          : changePercent // ignore: cast_nullable_to_non_nullable
              as double,
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
      previousClose: null == previousClose
          ? _value.previousClose
          : previousClose // ignore: cast_nullable_to_non_nullable
              as double,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as double,
      marketStatus: freezed == marketStatus
          ? _value.marketStatus
          : marketStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuoteImplCopyWith<$Res> implements $QuoteCopyWith<$Res> {
  factory _$$QuoteImplCopyWith(
          _$QuoteImpl value, $Res Function(_$QuoteImpl) then) =
      __$$QuoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String symbol,
      double currentPrice,
      double change,
      double changePercent,
      double open,
      double high,
      double low,
      double previousClose,
      double volume,
      double value,
      String? marketStatus,
      DateTime? timestamp});
}

/// @nodoc
class __$$QuoteImplCopyWithImpl<$Res>
    extends _$QuoteCopyWithImpl<$Res, _$QuoteImpl>
    implements _$$QuoteImplCopyWith<$Res> {
  __$$QuoteImplCopyWithImpl(
      _$QuoteImpl _value, $Res Function(_$QuoteImpl) _then)
      : super(_value, _then);

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? currentPrice = null,
    Object? change = null,
    Object? changePercent = null,
    Object? open = null,
    Object? high = null,
    Object? low = null,
    Object? previousClose = null,
    Object? volume = null,
    Object? value = null,
    Object? marketStatus = freezed,
    Object? timestamp = freezed,
  }) {
    return _then(_$QuoteImpl(
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      currentPrice: null == currentPrice
          ? _value.currentPrice
          : currentPrice // ignore: cast_nullable_to_non_nullable
              as double,
      change: null == change
          ? _value.change
          : change // ignore: cast_nullable_to_non_nullable
              as double,
      changePercent: null == changePercent
          ? _value.changePercent
          : changePercent // ignore: cast_nullable_to_non_nullable
              as double,
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
      previousClose: null == previousClose
          ? _value.previousClose
          : previousClose // ignore: cast_nullable_to_non_nullable
              as double,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as double,
      marketStatus: freezed == marketStatus
          ? _value.marketStatus
          : marketStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuoteImpl implements _Quote {
  const _$QuoteImpl(
      {required this.symbol,
      this.currentPrice = 0,
      this.change = 0,
      this.changePercent = 0,
      this.open = 0,
      this.high = 0,
      this.low = 0,
      this.previousClose = 0,
      this.volume = 0,
      this.value = 0,
      this.marketStatus,
      this.timestamp});

  factory _$QuoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuoteImplFromJson(json);

  @override
  final String symbol;
  @override
  @JsonKey()
  final double currentPrice;
  @override
  @JsonKey()
  final double change;
  @override
  @JsonKey()
  final double changePercent;
  @override
  @JsonKey()
  final double open;
  @override
  @JsonKey()
  final double high;
  @override
  @JsonKey()
  final double low;
  @override
  @JsonKey()
  final double previousClose;
  @override
  @JsonKey()
  final double volume;
  @override
  @JsonKey()
  final double value;
// 거래대금
  @override
  final String? marketStatus;
// OPEN, CLOSED, PRE_MARKET, etc.
  @override
  final DateTime? timestamp;

  @override
  String toString() {
    return 'Quote(symbol: $symbol, currentPrice: $currentPrice, change: $change, changePercent: $changePercent, open: $open, high: $high, low: $low, previousClose: $previousClose, volume: $volume, value: $value, marketStatus: $marketStatus, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuoteImpl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.currentPrice, currentPrice) ||
                other.currentPrice == currentPrice) &&
            (identical(other.change, change) || other.change == change) &&
            (identical(other.changePercent, changePercent) ||
                other.changePercent == changePercent) &&
            (identical(other.open, open) || other.open == open) &&
            (identical(other.high, high) || other.high == high) &&
            (identical(other.low, low) || other.low == low) &&
            (identical(other.previousClose, previousClose) ||
                other.previousClose == previousClose) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.marketStatus, marketStatus) ||
                other.marketStatus == marketStatus) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      symbol,
      currentPrice,
      change,
      changePercent,
      open,
      high,
      low,
      previousClose,
      volume,
      value,
      marketStatus,
      timestamp);

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuoteImplCopyWith<_$QuoteImpl> get copyWith =>
      __$$QuoteImplCopyWithImpl<_$QuoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuoteImplToJson(
      this,
    );
  }
}

abstract class _Quote implements Quote {
  const factory _Quote(
      {required final String symbol,
      final double currentPrice,
      final double change,
      final double changePercent,
      final double open,
      final double high,
      final double low,
      final double previousClose,
      final double volume,
      final double value,
      final String? marketStatus,
      final DateTime? timestamp}) = _$QuoteImpl;

  factory _Quote.fromJson(Map<String, dynamic> json) = _$QuoteImpl.fromJson;

  @override
  String get symbol;
  @override
  double get currentPrice;
  @override
  double get change;
  @override
  double get changePercent;
  @override
  double get open;
  @override
  double get high;
  @override
  double get low;
  @override
  double get previousClose;
  @override
  double get volume;
  @override
  double get value; // 거래대금
  @override
  String? get marketStatus; // OPEN, CLOSED, PRE_MARKET, etc.
  @override
  DateTime? get timestamp;

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuoteImplCopyWith<_$QuoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
