import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App settings state.
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.language = 'en',
    this.pushNotifications = true,
    this.priceAlerts = true,
  });

  final ThemeMode themeMode;
  final String language; // 'en', 'vi', 'ko'
  final bool pushNotifications;
  final bool priceAlerts;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? pushNotifications,
    bool? priceAlerts,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      priceAlerts: priceAlerts ?? this.priceAlerts,
    );
  }
}

/// Settings notifier — persists preferences with SharedPreferences.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    // Defer loading so we don't modify state during widget tree build
    Future.microtask(() => _loadSettings());
  }

  /// Load saved settings from SharedPreferences.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeStr = prefs.getString('theme_mode') ?? 'dark';
    final themeMode = switch (themeModeStr) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

    state = state.copyWith(
      themeMode: themeMode,
      language: prefs.getString('language') ?? 'en',
      pushNotifications: prefs.getBool('push_notifications') ?? true,
      priceAlerts: prefs.getBool('price_alerts') ?? true,
    );
  }

  /// Toggle theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      _ => 'dark',
    };
    await prefs.setString('theme_mode', str);
  }

  /// Set language.
  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  /// Toggle push notifications.
  Future<void> setPushNotifications(bool enabled) async {
    state = state.copyWith(pushNotifications: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', enabled);
  }

  /// Toggle price alerts.
  Future<void> setPriceAlerts(bool enabled) async {
    state = state.copyWith(priceAlerts: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('price_alerts', enabled);
  }
}

/// Settings provider instance.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
