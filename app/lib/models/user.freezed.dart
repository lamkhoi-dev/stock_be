// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get avatar => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  UserSubscription get subscription => throw _privateConstructorUsedError;
  UserSettings? get settings => throw _privateConstructorUsedError;
  bool get isBlocked => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get lastLogin => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call(
      {String id,
      String email,
      String name,
      String? avatar,
      String role,
      UserSubscription subscription,
      UserSettings? settings,
      bool isBlocked,
      DateTime? createdAt,
      DateTime? lastLogin});

  $UserSubscriptionCopyWith<$Res> get subscription;
  $UserSettingsCopyWith<$Res>? get settings;
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? name = null,
    Object? avatar = freezed,
    Object? role = null,
    Object? subscription = null,
    Object? settings = freezed,
    Object? isBlocked = null,
    Object? createdAt = freezed,
    Object? lastLogin = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      subscription: null == subscription
          ? _value.subscription
          : subscription // ignore: cast_nullable_to_non_nullable
              as UserSubscription,
      settings: freezed == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as UserSettings?,
      isBlocked: null == isBlocked
          ? _value.isBlocked
          : isBlocked // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastLogin: freezed == lastLogin
          ? _value.lastLogin
          : lastLogin // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserSubscriptionCopyWith<$Res> get subscription {
    return $UserSubscriptionCopyWith<$Res>(_value.subscription, (value) {
      return _then(_value.copyWith(subscription: value) as $Val);
    });
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserSettingsCopyWith<$Res>? get settings {
    if (_value.settings == null) {
      return null;
    }

    return $UserSettingsCopyWith<$Res>(_value.settings!, (value) {
      return _then(_value.copyWith(settings: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
          _$UserImpl value, $Res Function(_$UserImpl) then) =
      __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      String name,
      String? avatar,
      String role,
      UserSubscription subscription,
      UserSettings? settings,
      bool isBlocked,
      DateTime? createdAt,
      DateTime? lastLogin});

  @override
  $UserSubscriptionCopyWith<$Res> get subscription;
  @override
  $UserSettingsCopyWith<$Res>? get settings;
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
      : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? name = null,
    Object? avatar = freezed,
    Object? role = null,
    Object? subscription = null,
    Object? settings = freezed,
    Object? isBlocked = null,
    Object? createdAt = freezed,
    Object? lastLogin = freezed,
  }) {
    return _then(_$UserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      subscription: null == subscription
          ? _value.subscription
          : subscription // ignore: cast_nullable_to_non_nullable
              as UserSubscription,
      settings: freezed == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as UserSettings?,
      isBlocked: null == isBlocked
          ? _value.isBlocked
          : isBlocked // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastLogin: freezed == lastLogin
          ? _value.lastLogin
          : lastLogin // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl implements _User {
  const _$UserImpl(
      {required this.id,
      required this.email,
      required this.name,
      this.avatar,
      this.role = 'free',
      this.subscription = const UserSubscription(),
      this.settings,
      this.isBlocked = false,
      this.createdAt,
      this.lastLogin});

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  final String id;
  @override
  final String email;
  @override
  final String name;
  @override
  final String? avatar;
  @override
  @JsonKey()
  final String role;
  @override
  @JsonKey()
  final UserSubscription subscription;
  @override
  final UserSettings? settings;
  @override
  @JsonKey()
  final bool isBlocked;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? lastLogin;

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, avatar: $avatar, role: $role, subscription: $subscription, settings: $settings, isBlocked: $isBlocked, createdAt: $createdAt, lastLogin: $lastLogin)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.subscription, subscription) ||
                other.subscription == subscription) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.isBlocked, isBlocked) ||
                other.isBlocked == isBlocked) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastLogin, lastLogin) ||
                other.lastLogin == lastLogin));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, email, name, avatar, role,
      subscription, settings, isBlocked, createdAt, lastLogin);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(
      this,
    );
  }
}

abstract class _User implements User {
  const factory _User(
      {required final String id,
      required final String email,
      required final String name,
      final String? avatar,
      final String role,
      final UserSubscription subscription,
      final UserSettings? settings,
      final bool isBlocked,
      final DateTime? createdAt,
      final DateTime? lastLogin}) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  String get id;
  @override
  String get email;
  @override
  String get name;
  @override
  String? get avatar;
  @override
  String get role;
  @override
  UserSubscription get subscription;
  @override
  UserSettings? get settings;
  @override
  bool get isBlocked;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get lastLogin;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserSubscription _$UserSubscriptionFromJson(Map<String, dynamic> json) {
  return _UserSubscription.fromJson(json);
}

/// @nodoc
mixin _$UserSubscription {
  String get plan => throw _privateConstructorUsedError;
  int get credits => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;

  /// Serializes this UserSubscription to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserSubscription
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserSubscriptionCopyWith<UserSubscription> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSubscriptionCopyWith<$Res> {
  factory $UserSubscriptionCopyWith(
          UserSubscription value, $Res Function(UserSubscription) then) =
      _$UserSubscriptionCopyWithImpl<$Res, UserSubscription>;
  @useResult
  $Res call({String plan, int credits, DateTime? expiresAt});
}

/// @nodoc
class _$UserSubscriptionCopyWithImpl<$Res, $Val extends UserSubscription>
    implements $UserSubscriptionCopyWith<$Res> {
  _$UserSubscriptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserSubscription
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plan = null,
    Object? credits = null,
    Object? expiresAt = freezed,
  }) {
    return _then(_value.copyWith(
      plan: null == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as String,
      credits: null == credits
          ? _value.credits
          : credits // ignore: cast_nullable_to_non_nullable
              as int,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSubscriptionImplCopyWith<$Res>
    implements $UserSubscriptionCopyWith<$Res> {
  factory _$$UserSubscriptionImplCopyWith(_$UserSubscriptionImpl value,
          $Res Function(_$UserSubscriptionImpl) then) =
      __$$UserSubscriptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String plan, int credits, DateTime? expiresAt});
}

/// @nodoc
class __$$UserSubscriptionImplCopyWithImpl<$Res>
    extends _$UserSubscriptionCopyWithImpl<$Res, _$UserSubscriptionImpl>
    implements _$$UserSubscriptionImplCopyWith<$Res> {
  __$$UserSubscriptionImplCopyWithImpl(_$UserSubscriptionImpl _value,
      $Res Function(_$UserSubscriptionImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserSubscription
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plan = null,
    Object? credits = null,
    Object? expiresAt = freezed,
  }) {
    return _then(_$UserSubscriptionImpl(
      plan: null == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as String,
      credits: null == credits
          ? _value.credits
          : credits // ignore: cast_nullable_to_non_nullable
              as int,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSubscriptionImpl implements _UserSubscription {
  const _$UserSubscriptionImpl(
      {this.plan = 'free', this.credits = 3, this.expiresAt});

  factory _$UserSubscriptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSubscriptionImplFromJson(json);

  @override
  @JsonKey()
  final String plan;
  @override
  @JsonKey()
  final int credits;
  @override
  final DateTime? expiresAt;

  @override
  String toString() {
    return 'UserSubscription(plan: $plan, credits: $credits, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSubscriptionImpl &&
            (identical(other.plan, plan) || other.plan == plan) &&
            (identical(other.credits, credits) || other.credits == credits) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, plan, credits, expiresAt);

  /// Create a copy of UserSubscription
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSubscriptionImplCopyWith<_$UserSubscriptionImpl> get copyWith =>
      __$$UserSubscriptionImplCopyWithImpl<_$UserSubscriptionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSubscriptionImplToJson(
      this,
    );
  }
}

abstract class _UserSubscription implements UserSubscription {
  const factory _UserSubscription(
      {final String plan,
      final int credits,
      final DateTime? expiresAt}) = _$UserSubscriptionImpl;

  factory _UserSubscription.fromJson(Map<String, dynamic> json) =
      _$UserSubscriptionImpl.fromJson;

  @override
  String get plan;
  @override
  int get credits;
  @override
  DateTime? get expiresAt;

  /// Create a copy of UserSubscription
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserSubscriptionImplCopyWith<_$UserSubscriptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) {
  return _UserSettings.fromJson(json);
}

/// @nodoc
mixin _$UserSettings {
  String get language => throw _privateConstructorUsedError;
  String get theme => throw _privateConstructorUsedError;
  bool get pushNotifications => throw _privateConstructorUsedError;
  bool get priceAlerts => throw _privateConstructorUsedError;

  /// Serializes this UserSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserSettingsCopyWith<UserSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSettingsCopyWith<$Res> {
  factory $UserSettingsCopyWith(
          UserSettings value, $Res Function(UserSettings) then) =
      _$UserSettingsCopyWithImpl<$Res, UserSettings>;
  @useResult
  $Res call(
      {String language,
      String theme,
      bool pushNotifications,
      bool priceAlerts});
}

/// @nodoc
class _$UserSettingsCopyWithImpl<$Res, $Val extends UserSettings>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? language = null,
    Object? theme = null,
    Object? pushNotifications = null,
    Object? priceAlerts = null,
  }) {
    return _then(_value.copyWith(
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      theme: null == theme
          ? _value.theme
          : theme // ignore: cast_nullable_to_non_nullable
              as String,
      pushNotifications: null == pushNotifications
          ? _value.pushNotifications
          : pushNotifications // ignore: cast_nullable_to_non_nullable
              as bool,
      priceAlerts: null == priceAlerts
          ? _value.priceAlerts
          : priceAlerts // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSettingsImplCopyWith<$Res>
    implements $UserSettingsCopyWith<$Res> {
  factory _$$UserSettingsImplCopyWith(
          _$UserSettingsImpl value, $Res Function(_$UserSettingsImpl) then) =
      __$$UserSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String language,
      String theme,
      bool pushNotifications,
      bool priceAlerts});
}

/// @nodoc
class __$$UserSettingsImplCopyWithImpl<$Res>
    extends _$UserSettingsCopyWithImpl<$Res, _$UserSettingsImpl>
    implements _$$UserSettingsImplCopyWith<$Res> {
  __$$UserSettingsImplCopyWithImpl(
      _$UserSettingsImpl _value, $Res Function(_$UserSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? language = null,
    Object? theme = null,
    Object? pushNotifications = null,
    Object? priceAlerts = null,
  }) {
    return _then(_$UserSettingsImpl(
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      theme: null == theme
          ? _value.theme
          : theme // ignore: cast_nullable_to_non_nullable
              as String,
      pushNotifications: null == pushNotifications
          ? _value.pushNotifications
          : pushNotifications // ignore: cast_nullable_to_non_nullable
              as bool,
      priceAlerts: null == priceAlerts
          ? _value.priceAlerts
          : priceAlerts // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSettingsImpl implements _UserSettings {
  const _$UserSettingsImpl(
      {this.language = 'en',
      this.theme = 'dark',
      this.pushNotifications = true,
      this.priceAlerts = true});

  factory _$UserSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSettingsImplFromJson(json);

  @override
  @JsonKey()
  final String language;
  @override
  @JsonKey()
  final String theme;
  @override
  @JsonKey()
  final bool pushNotifications;
  @override
  @JsonKey()
  final bool priceAlerts;

  @override
  String toString() {
    return 'UserSettings(language: $language, theme: $theme, pushNotifications: $pushNotifications, priceAlerts: $priceAlerts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSettingsImpl &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.theme, theme) || other.theme == theme) &&
            (identical(other.pushNotifications, pushNotifications) ||
                other.pushNotifications == pushNotifications) &&
            (identical(other.priceAlerts, priceAlerts) ||
                other.priceAlerts == priceAlerts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, language, theme, pushNotifications, priceAlerts);

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      __$$UserSettingsImplCopyWithImpl<_$UserSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSettingsImplToJson(
      this,
    );
  }
}

abstract class _UserSettings implements UserSettings {
  const factory _UserSettings(
      {final String language,
      final String theme,
      final bool pushNotifications,
      final bool priceAlerts}) = _$UserSettingsImpl;

  factory _UserSettings.fromJson(Map<String, dynamic> json) =
      _$UserSettingsImpl.fromJson;

  @override
  String get language;
  @override
  String get theme;
  @override
  bool get pushNotifications;
  @override
  bool get priceAlerts;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
