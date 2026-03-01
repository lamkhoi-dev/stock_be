import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    String? avatar,
    @Default('free') String role,
    @Default(UserSubscription()) UserSubscription subscription,
    UserSettings? settings,
    @Default(false) bool isBlocked,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class UserSubscription with _$UserSubscription {
  const factory UserSubscription({
    @Default('free') String plan,
    @Default(3) int credits,
    DateTime? expiresAt,
  }) = _UserSubscription;

  factory UserSubscription.fromJson(Map<String, dynamic> json) =>
      _$UserSubscriptionFromJson(json);
}

@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default('en') String language,
    @Default('dark') String theme,
    @Default(true) bool pushNotifications,
    @Default(true) bool priceAlerts,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
