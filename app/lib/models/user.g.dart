// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      role: json['role'] as String? ?? 'free',
      subscription: json['subscription'] == null
          ? const UserSubscription()
          : UserSubscription.fromJson(
              json['subscription'] as Map<String, dynamic>),
      settings: json['settings'] == null
          ? null
          : UserSettings.fromJson(json['settings'] as Map<String, dynamic>),
      isBlocked: json['isBlocked'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastLogin: json['lastLogin'] == null
          ? null
          : DateTime.parse(json['lastLogin'] as String),
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'avatar': instance.avatar,
      'role': instance.role,
      'subscription': instance.subscription,
      'settings': instance.settings,
      'isBlocked': instance.isBlocked,
      'createdAt': instance.createdAt?.toIso8601String(),
      'lastLogin': instance.lastLogin?.toIso8601String(),
    };

_$UserSubscriptionImpl _$$UserSubscriptionImplFromJson(
        Map<String, dynamic> json) =>
    _$UserSubscriptionImpl(
      plan: json['plan'] as String? ?? 'free',
      credits: (json['credits'] as num?)?.toInt() ?? 3,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$$UserSubscriptionImplToJson(
        _$UserSubscriptionImpl instance) =>
    <String, dynamic>{
      'plan': instance.plan,
      'credits': instance.credits,
      'expiresAt': instance.expiresAt?.toIso8601String(),
    };

_$UserSettingsImpl _$$UserSettingsImplFromJson(Map<String, dynamic> json) =>
    _$UserSettingsImpl(
      language: json['language'] as String? ?? 'en',
      theme: json['theme'] as String? ?? 'dark',
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      priceAlerts: json['priceAlerts'] as bool? ?? true,
    );

Map<String, dynamic> _$$UserSettingsImplToJson(_$UserSettingsImpl instance) =>
    <String, dynamic>{
      'language': instance.language,
      'theme': instance.theme,
      'pushNotifications': instance.pushNotifications,
      'priceAlerts': instance.priceAlerts,
    };
