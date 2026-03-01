import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

/// Authentication tokens.
@freezed
class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}

/// Login request payload.
@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

/// Register request payload.
@freezed
class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String name,
    required String email,
    required String password,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}

/// Generic API response wrapper.
@freezed
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required bool success,
    String? message,
    T? data,
  }) = _ApiResponse<T>;
}
