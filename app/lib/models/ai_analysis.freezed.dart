// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_analysis.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AIAnalysis _$AIAnalysisFromJson(Map<String, dynamic> json) {
  return _AIAnalysis.fromJson(json);
}

/// @nodoc
mixin _$AIAnalysis {
  String get id => throw _privateConstructorUsedError;
  String get symbol => throw _privateConstructorUsedError;
  String get model =>
      throw _privateConstructorUsedError; // gemini-flash, gemini-pro, gpt-4
  String get type => throw _privateConstructorUsedError; // basic, pro
  String get signal => throw _privateConstructorUsedError; // BUY, SELL, HOLD
  double get confidence => throw _privateConstructorUsedError; // 0-100
  AIAnalysisSections? get sections => throw _privateConstructorUsedError;
  int get creditsUsed => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this AIAnalysis to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AIAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AIAnalysisCopyWith<AIAnalysis> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AIAnalysisCopyWith<$Res> {
  factory $AIAnalysisCopyWith(
          AIAnalysis value, $Res Function(AIAnalysis) then) =
      _$AIAnalysisCopyWithImpl<$Res, AIAnalysis>;
  @useResult
  $Res call(
      {String id,
      String symbol,
      String model,
      String type,
      String signal,
      double confidence,
      AIAnalysisSections? sections,
      int creditsUsed,
      DateTime? createdAt});

  $AIAnalysisSectionsCopyWith<$Res>? get sections;
}

/// @nodoc
class _$AIAnalysisCopyWithImpl<$Res, $Val extends AIAnalysis>
    implements $AIAnalysisCopyWith<$Res> {
  _$AIAnalysisCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AIAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? symbol = null,
    Object? model = null,
    Object? type = null,
    Object? signal = null,
    Object? confidence = null,
    Object? sections = freezed,
    Object? creditsUsed = null,
    Object? createdAt = freezed,
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
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      signal: null == signal
          ? _value.signal
          : signal // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      sections: freezed == sections
          ? _value.sections
          : sections // ignore: cast_nullable_to_non_nullable
              as AIAnalysisSections?,
      creditsUsed: null == creditsUsed
          ? _value.creditsUsed
          : creditsUsed // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of AIAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AIAnalysisSectionsCopyWith<$Res>? get sections {
    if (_value.sections == null) {
      return null;
    }

    return $AIAnalysisSectionsCopyWith<$Res>(_value.sections!, (value) {
      return _then(_value.copyWith(sections: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AIAnalysisImplCopyWith<$Res>
    implements $AIAnalysisCopyWith<$Res> {
  factory _$$AIAnalysisImplCopyWith(
          _$AIAnalysisImpl value, $Res Function(_$AIAnalysisImpl) then) =
      __$$AIAnalysisImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String symbol,
      String model,
      String type,
      String signal,
      double confidence,
      AIAnalysisSections? sections,
      int creditsUsed,
      DateTime? createdAt});

  @override
  $AIAnalysisSectionsCopyWith<$Res>? get sections;
}

/// @nodoc
class __$$AIAnalysisImplCopyWithImpl<$Res>
    extends _$AIAnalysisCopyWithImpl<$Res, _$AIAnalysisImpl>
    implements _$$AIAnalysisImplCopyWith<$Res> {
  __$$AIAnalysisImplCopyWithImpl(
      _$AIAnalysisImpl _value, $Res Function(_$AIAnalysisImpl) _then)
      : super(_value, _then);

  /// Create a copy of AIAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? symbol = null,
    Object? model = null,
    Object? type = null,
    Object? signal = null,
    Object? confidence = null,
    Object? sections = freezed,
    Object? creditsUsed = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$AIAnalysisImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      signal: null == signal
          ? _value.signal
          : signal // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      sections: freezed == sections
          ? _value.sections
          : sections // ignore: cast_nullable_to_non_nullable
              as AIAnalysisSections?,
      creditsUsed: null == creditsUsed
          ? _value.creditsUsed
          : creditsUsed // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AIAnalysisImpl implements _AIAnalysis {
  const _$AIAnalysisImpl(
      {required this.id,
      required this.symbol,
      required this.model,
      required this.type,
      required this.signal,
      required this.confidence,
      this.sections,
      this.creditsUsed = 0,
      this.createdAt});

  factory _$AIAnalysisImpl.fromJson(Map<String, dynamic> json) =>
      _$$AIAnalysisImplFromJson(json);

  @override
  final String id;
  @override
  final String symbol;
  @override
  final String model;
// gemini-flash, gemini-pro, gpt-4
  @override
  final String type;
// basic, pro
  @override
  final String signal;
// BUY, SELL, HOLD
  @override
  final double confidence;
// 0-100
  @override
  final AIAnalysisSections? sections;
  @override
  @JsonKey()
  final int creditsUsed;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'AIAnalysis(id: $id, symbol: $symbol, model: $model, type: $type, signal: $signal, confidence: $confidence, sections: $sections, creditsUsed: $creditsUsed, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AIAnalysisImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.signal, signal) || other.signal == signal) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.sections, sections) ||
                other.sections == sections) &&
            (identical(other.creditsUsed, creditsUsed) ||
                other.creditsUsed == creditsUsed) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, symbol, model, type, signal,
      confidence, sections, creditsUsed, createdAt);

  /// Create a copy of AIAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AIAnalysisImplCopyWith<_$AIAnalysisImpl> get copyWith =>
      __$$AIAnalysisImplCopyWithImpl<_$AIAnalysisImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AIAnalysisImplToJson(
      this,
    );
  }
}

abstract class _AIAnalysis implements AIAnalysis {
  const factory _AIAnalysis(
      {required final String id,
      required final String symbol,
      required final String model,
      required final String type,
      required final String signal,
      required final double confidence,
      final AIAnalysisSections? sections,
      final int creditsUsed,
      final DateTime? createdAt}) = _$AIAnalysisImpl;

  factory _AIAnalysis.fromJson(Map<String, dynamic> json) =
      _$AIAnalysisImpl.fromJson;

  @override
  String get id;
  @override
  String get symbol;
  @override
  String get model; // gemini-flash, gemini-pro, gpt-4
  @override
  String get type; // basic, pro
  @override
  String get signal; // BUY, SELL, HOLD
  @override
  double get confidence; // 0-100
  @override
  AIAnalysisSections? get sections;
  @override
  int get creditsUsed;
  @override
  DateTime? get createdAt;

  /// Create a copy of AIAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AIAnalysisImplCopyWith<_$AIAnalysisImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AIAnalysisSections _$AIAnalysisSectionsFromJson(Map<String, dynamic> json) {
  return _AIAnalysisSections.fromJson(json);
}

/// @nodoc
mixin _$AIAnalysisSections {
  String? get summary => throw _privateConstructorUsedError;
  String? get technicalAnalysis => throw _privateConstructorUsedError;
  String? get fundamentalAnalysis => throw _privateConstructorUsedError;
  String? get sentiment => throw _privateConstructorUsedError;
  String? get riskAssessment => throw _privateConstructorUsedError;
  String? get recommendation => throw _privateConstructorUsedError;
  List<String>? get keyPoints => throw _privateConstructorUsedError;

  /// Serializes this AIAnalysisSections to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AIAnalysisSections
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AIAnalysisSectionsCopyWith<AIAnalysisSections> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AIAnalysisSectionsCopyWith<$Res> {
  factory $AIAnalysisSectionsCopyWith(
          AIAnalysisSections value, $Res Function(AIAnalysisSections) then) =
      _$AIAnalysisSectionsCopyWithImpl<$Res, AIAnalysisSections>;
  @useResult
  $Res call(
      {String? summary,
      String? technicalAnalysis,
      String? fundamentalAnalysis,
      String? sentiment,
      String? riskAssessment,
      String? recommendation,
      List<String>? keyPoints});
}

/// @nodoc
class _$AIAnalysisSectionsCopyWithImpl<$Res, $Val extends AIAnalysisSections>
    implements $AIAnalysisSectionsCopyWith<$Res> {
  _$AIAnalysisSectionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AIAnalysisSections
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? summary = freezed,
    Object? technicalAnalysis = freezed,
    Object? fundamentalAnalysis = freezed,
    Object? sentiment = freezed,
    Object? riskAssessment = freezed,
    Object? recommendation = freezed,
    Object? keyPoints = freezed,
  }) {
    return _then(_value.copyWith(
      summary: freezed == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String?,
      technicalAnalysis: freezed == technicalAnalysis
          ? _value.technicalAnalysis
          : technicalAnalysis // ignore: cast_nullable_to_non_nullable
              as String?,
      fundamentalAnalysis: freezed == fundamentalAnalysis
          ? _value.fundamentalAnalysis
          : fundamentalAnalysis // ignore: cast_nullable_to_non_nullable
              as String?,
      sentiment: freezed == sentiment
          ? _value.sentiment
          : sentiment // ignore: cast_nullable_to_non_nullable
              as String?,
      riskAssessment: freezed == riskAssessment
          ? _value.riskAssessment
          : riskAssessment // ignore: cast_nullable_to_non_nullable
              as String?,
      recommendation: freezed == recommendation
          ? _value.recommendation
          : recommendation // ignore: cast_nullable_to_non_nullable
              as String?,
      keyPoints: freezed == keyPoints
          ? _value.keyPoints
          : keyPoints // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AIAnalysisSectionsImplCopyWith<$Res>
    implements $AIAnalysisSectionsCopyWith<$Res> {
  factory _$$AIAnalysisSectionsImplCopyWith(_$AIAnalysisSectionsImpl value,
          $Res Function(_$AIAnalysisSectionsImpl) then) =
      __$$AIAnalysisSectionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? summary,
      String? technicalAnalysis,
      String? fundamentalAnalysis,
      String? sentiment,
      String? riskAssessment,
      String? recommendation,
      List<String>? keyPoints});
}

/// @nodoc
class __$$AIAnalysisSectionsImplCopyWithImpl<$Res>
    extends _$AIAnalysisSectionsCopyWithImpl<$Res, _$AIAnalysisSectionsImpl>
    implements _$$AIAnalysisSectionsImplCopyWith<$Res> {
  __$$AIAnalysisSectionsImplCopyWithImpl(_$AIAnalysisSectionsImpl _value,
      $Res Function(_$AIAnalysisSectionsImpl) _then)
      : super(_value, _then);

  /// Create a copy of AIAnalysisSections
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? summary = freezed,
    Object? technicalAnalysis = freezed,
    Object? fundamentalAnalysis = freezed,
    Object? sentiment = freezed,
    Object? riskAssessment = freezed,
    Object? recommendation = freezed,
    Object? keyPoints = freezed,
  }) {
    return _then(_$AIAnalysisSectionsImpl(
      summary: freezed == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String?,
      technicalAnalysis: freezed == technicalAnalysis
          ? _value.technicalAnalysis
          : technicalAnalysis // ignore: cast_nullable_to_non_nullable
              as String?,
      fundamentalAnalysis: freezed == fundamentalAnalysis
          ? _value.fundamentalAnalysis
          : fundamentalAnalysis // ignore: cast_nullable_to_non_nullable
              as String?,
      sentiment: freezed == sentiment
          ? _value.sentiment
          : sentiment // ignore: cast_nullable_to_non_nullable
              as String?,
      riskAssessment: freezed == riskAssessment
          ? _value.riskAssessment
          : riskAssessment // ignore: cast_nullable_to_non_nullable
              as String?,
      recommendation: freezed == recommendation
          ? _value.recommendation
          : recommendation // ignore: cast_nullable_to_non_nullable
              as String?,
      keyPoints: freezed == keyPoints
          ? _value._keyPoints
          : keyPoints // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AIAnalysisSectionsImpl implements _AIAnalysisSections {
  const _$AIAnalysisSectionsImpl(
      {this.summary,
      this.technicalAnalysis,
      this.fundamentalAnalysis,
      this.sentiment,
      this.riskAssessment,
      this.recommendation,
      final List<String>? keyPoints})
      : _keyPoints = keyPoints;

  factory _$AIAnalysisSectionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AIAnalysisSectionsImplFromJson(json);

  @override
  final String? summary;
  @override
  final String? technicalAnalysis;
  @override
  final String? fundamentalAnalysis;
  @override
  final String? sentiment;
  @override
  final String? riskAssessment;
  @override
  final String? recommendation;
  final List<String>? _keyPoints;
  @override
  List<String>? get keyPoints {
    final value = _keyPoints;
    if (value == null) return null;
    if (_keyPoints is EqualUnmodifiableListView) return _keyPoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'AIAnalysisSections(summary: $summary, technicalAnalysis: $technicalAnalysis, fundamentalAnalysis: $fundamentalAnalysis, sentiment: $sentiment, riskAssessment: $riskAssessment, recommendation: $recommendation, keyPoints: $keyPoints)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AIAnalysisSectionsImpl &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.technicalAnalysis, technicalAnalysis) ||
                other.technicalAnalysis == technicalAnalysis) &&
            (identical(other.fundamentalAnalysis, fundamentalAnalysis) ||
                other.fundamentalAnalysis == fundamentalAnalysis) &&
            (identical(other.sentiment, sentiment) ||
                other.sentiment == sentiment) &&
            (identical(other.riskAssessment, riskAssessment) ||
                other.riskAssessment == riskAssessment) &&
            (identical(other.recommendation, recommendation) ||
                other.recommendation == recommendation) &&
            const DeepCollectionEquality()
                .equals(other._keyPoints, _keyPoints));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      summary,
      technicalAnalysis,
      fundamentalAnalysis,
      sentiment,
      riskAssessment,
      recommendation,
      const DeepCollectionEquality().hash(_keyPoints));

  /// Create a copy of AIAnalysisSections
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AIAnalysisSectionsImplCopyWith<_$AIAnalysisSectionsImpl> get copyWith =>
      __$$AIAnalysisSectionsImplCopyWithImpl<_$AIAnalysisSectionsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AIAnalysisSectionsImplToJson(
      this,
    );
  }
}

abstract class _AIAnalysisSections implements AIAnalysisSections {
  const factory _AIAnalysisSections(
      {final String? summary,
      final String? technicalAnalysis,
      final String? fundamentalAnalysis,
      final String? sentiment,
      final String? riskAssessment,
      final String? recommendation,
      final List<String>? keyPoints}) = _$AIAnalysisSectionsImpl;

  factory _AIAnalysisSections.fromJson(Map<String, dynamic> json) =
      _$AIAnalysisSectionsImpl.fromJson;

  @override
  String? get summary;
  @override
  String? get technicalAnalysis;
  @override
  String? get fundamentalAnalysis;
  @override
  String? get sentiment;
  @override
  String? get riskAssessment;
  @override
  String? get recommendation;
  @override
  List<String>? get keyPoints;

  /// Create a copy of AIAnalysisSections
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AIAnalysisSectionsImplCopyWith<_$AIAnalysisSectionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AICredits _$AICreditsFromJson(Map<String, dynamic> json) {
  return _AICredits.fromJson(json);
}

/// @nodoc
mixin _$AICredits {
  int get remaining => throw _privateConstructorUsedError;
  int get dailyLimit => throw _privateConstructorUsedError;
  int get totalUsed => throw _privateConstructorUsedError;
  DateTime? get resetsAt => throw _privateConstructorUsedError;

  /// Serializes this AICredits to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AICredits
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AICreditsCopyWith<AICredits> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AICreditsCopyWith<$Res> {
  factory $AICreditsCopyWith(AICredits value, $Res Function(AICredits) then) =
      _$AICreditsCopyWithImpl<$Res, AICredits>;
  @useResult
  $Res call({int remaining, int dailyLimit, int totalUsed, DateTime? resetsAt});
}

/// @nodoc
class _$AICreditsCopyWithImpl<$Res, $Val extends AICredits>
    implements $AICreditsCopyWith<$Res> {
  _$AICreditsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AICredits
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? remaining = null,
    Object? dailyLimit = null,
    Object? totalUsed = null,
    Object? resetsAt = freezed,
  }) {
    return _then(_value.copyWith(
      remaining: null == remaining
          ? _value.remaining
          : remaining // ignore: cast_nullable_to_non_nullable
              as int,
      dailyLimit: null == dailyLimit
          ? _value.dailyLimit
          : dailyLimit // ignore: cast_nullable_to_non_nullable
              as int,
      totalUsed: null == totalUsed
          ? _value.totalUsed
          : totalUsed // ignore: cast_nullable_to_non_nullable
              as int,
      resetsAt: freezed == resetsAt
          ? _value.resetsAt
          : resetsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AICreditsImplCopyWith<$Res>
    implements $AICreditsCopyWith<$Res> {
  factory _$$AICreditsImplCopyWith(
          _$AICreditsImpl value, $Res Function(_$AICreditsImpl) then) =
      __$$AICreditsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int remaining, int dailyLimit, int totalUsed, DateTime? resetsAt});
}

/// @nodoc
class __$$AICreditsImplCopyWithImpl<$Res>
    extends _$AICreditsCopyWithImpl<$Res, _$AICreditsImpl>
    implements _$$AICreditsImplCopyWith<$Res> {
  __$$AICreditsImplCopyWithImpl(
      _$AICreditsImpl _value, $Res Function(_$AICreditsImpl) _then)
      : super(_value, _then);

  /// Create a copy of AICredits
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? remaining = null,
    Object? dailyLimit = null,
    Object? totalUsed = null,
    Object? resetsAt = freezed,
  }) {
    return _then(_$AICreditsImpl(
      remaining: null == remaining
          ? _value.remaining
          : remaining // ignore: cast_nullable_to_non_nullable
              as int,
      dailyLimit: null == dailyLimit
          ? _value.dailyLimit
          : dailyLimit // ignore: cast_nullable_to_non_nullable
              as int,
      totalUsed: null == totalUsed
          ? _value.totalUsed
          : totalUsed // ignore: cast_nullable_to_non_nullable
              as int,
      resetsAt: freezed == resetsAt
          ? _value.resetsAt
          : resetsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AICreditsImpl implements _AICredits {
  const _$AICreditsImpl(
      {this.remaining = 3,
      this.dailyLimit = 3,
      this.totalUsed = 0,
      this.resetsAt});

  factory _$AICreditsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AICreditsImplFromJson(json);

  @override
  @JsonKey()
  final int remaining;
  @override
  @JsonKey()
  final int dailyLimit;
  @override
  @JsonKey()
  final int totalUsed;
  @override
  final DateTime? resetsAt;

  @override
  String toString() {
    return 'AICredits(remaining: $remaining, dailyLimit: $dailyLimit, totalUsed: $totalUsed, resetsAt: $resetsAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AICreditsImpl &&
            (identical(other.remaining, remaining) ||
                other.remaining == remaining) &&
            (identical(other.dailyLimit, dailyLimit) ||
                other.dailyLimit == dailyLimit) &&
            (identical(other.totalUsed, totalUsed) ||
                other.totalUsed == totalUsed) &&
            (identical(other.resetsAt, resetsAt) ||
                other.resetsAt == resetsAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, remaining, dailyLimit, totalUsed, resetsAt);

  /// Create a copy of AICredits
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AICreditsImplCopyWith<_$AICreditsImpl> get copyWith =>
      __$$AICreditsImplCopyWithImpl<_$AICreditsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AICreditsImplToJson(
      this,
    );
  }
}

abstract class _AICredits implements AICredits {
  const factory _AICredits(
      {final int remaining,
      final int dailyLimit,
      final int totalUsed,
      final DateTime? resetsAt}) = _$AICreditsImpl;

  factory _AICredits.fromJson(Map<String, dynamic> json) =
      _$AICreditsImpl.fromJson;

  @override
  int get remaining;
  @override
  int get dailyLimit;
  @override
  int get totalUsed;
  @override
  DateTime? get resetsAt;

  /// Create a copy of AICredits
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AICreditsImplCopyWith<_$AICreditsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
