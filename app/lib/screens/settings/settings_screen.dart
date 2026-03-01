import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

/// Settings screen — Account, Plan, Preferences, About.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ─── Account Section ────────────────────────
          _buildSectionHeader(context, 'Account'),
          if (authState.isAuthenticated) ...[
            _buildUserCard(context, authState),
          ] else ...[
            _buildSignInCard(context),
          ],
          const SizedBox(height: 16),

          // ─── Plan & Credits ─────────────────────────
          if (authState.isAuthenticated) ...[
            _buildSectionHeader(context, 'Plan & Credits'),
            _buildPlanCard(context, authState),
            const SizedBox(height: 16),
          ],

          // ─── Preferences ────────────────────────────
          _buildSectionHeader(context, 'Preferences'),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Theme',
            trailing: Text(
              settings.themeMode == ThemeMode.dark ? 'Dark' : settings.themeMode == ThemeMode.light ? 'Light' : 'System',
              style: TextStyle(fontSize: 13, color: colorScheme.secondary),
            ),
            onTap: () => _showThemePicker(context, ref, settings),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: 'Language',
            trailing: Text(
              settings.language == 'ko' ? '한국어' : settings.language == 'vi' ? 'Tiếng Việt' : 'English',
              style: TextStyle(fontSize: 13, color: colorScheme.secondary),
            ),
            onTap: () => _showLanguagePicker(context, ref, settings),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            trailing: Switch.adaptive(
              value: settings.pushNotifications,
              onChanged: (v) => ref.read(settingsProvider.notifier).setPushNotifications(v),
              activeColor: colorScheme.primary,
            ),
          ),
          _SettingsTile(
            icon: Icons.trending_up,
            title: 'Price Alerts',
            trailing: Switch.adaptive(
              value: settings.priceAlerts,
              onChanged: (v) => ref.read(settingsProvider.notifier).setPriceAlerts(v),
              activeColor: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          // ─── About ─────────────────────────────────
          _buildSectionHeader(context, 'About'),
          _SettingsTile(
            icon: Icons.info_outlined,
            title: 'App Version',
            trailing: Text('1.0.0', style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.38))),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
          ),
          const SizedBox(height: 16),

          // ─── Logout ────────────────────────────────
          if (authState.isAuthenticated) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context, ref),
                icon: const Icon(Icons.logout, size: 18, color: Color(0xFFEF4444)),
                label: const Text('Log Out', style: TextStyle(color: Color(0xFFEF4444))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444), width: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withValues(alpha: 0.38),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AuthState authState) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = authState.user;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: InkWell(
        onTap: () => context.go('/settings/profile'),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [colorScheme.primary, const Color(0xFF8B5CF6)],
                ),
                boxShadow: [
                  BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8),
                ],
              ),
              child: Center(
                child: Text(
                  (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'User',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? 'user@example.com',
                    style: TextStyle(fontSize: 13, color: colorScheme.secondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.38)),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: appColors.surfaceHover,
            ),
            child: Icon(Icons.person_outline, size: 24, color: colorScheme.onSurface.withValues(alpha: 0.38)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text('Access watchlist, AI analysis & more', style: TextStyle(fontSize: 13, color: colorScheme.secondary)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.go('/auth/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign In', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, AuthState authState) {
    final colorScheme = Theme.of(context).colorScheme;
    final plan = authState.user?.subscription.plan ?? 'free';
    final credits = authState.user?.subscription.credits ?? 3;
    final isFree = plan == 'free';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFree
              ? [colorScheme.surface, colorScheme.surface]
              : [const Color(0xFFF59E0B).withValues(alpha: 0.08), colorScheme.surface],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isFree ? colorScheme.outline : const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFree ? colorScheme.primary.withValues(alpha: 0.15) : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isFree ? 'Free Plan' : 'Pro Plan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isFree ? colorScheme.primary : const Color(0xFFF59E0B),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$credits credits',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isFree ? '3 basic AI analyses per day' : 'Unlimited basic + credit-based pro analysis',
            style: TextStyle(fontSize: 12, color: colorScheme.secondary),
          ),
          if (isFree) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {}, // Phase 5: subscription upgrade
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Upgrade to Pro', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, SettingsState settings) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.outline, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          ...[
            (ThemeMode.dark, 'Dark', Icons.dark_mode),
            (ThemeMode.light, 'Light', Icons.light_mode),
            (ThemeMode.system, 'System', Icons.settings_brightness),
          ].map((item) {
            final (mode, label, icon) = item;
            final isActive = settings.themeMode == mode;
            return ListTile(
              leading: Icon(icon, color: isActive ? colorScheme.primary : colorScheme.secondary),
              title: Text(label, style: TextStyle(color: isActive ? colorScheme.primary : colorScheme.onSurface)),
              trailing: isActive ? Icon(Icons.check, color: colorScheme.primary) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setThemeMode(mode);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, SettingsState settings) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.outline, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          ...[
            ('en', 'English', '🇺🇸'),
            ('ko', '한국어', '🇰🇷'),
            ('vi', 'Tiếng Việt', '🇻🇳'),
          ].map((item) {
            final (code, label, flag) = item;
            final isActive = settings.language == code;
            return ListTile(
              leading: Text(flag, style: const TextStyle(fontSize: 22)),
              title: Text(label, style: TextStyle(color: isActive ? colorScheme.primary : colorScheme.onSurface)),
              trailing: isActive ? Icon(Icons.check, color: colorScheme.primary) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setLanguage(code);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: TextStyle(color: colorScheme.onSurface)),
        content: Text('Are you sure you want to log out?', style: TextStyle(color: colorScheme.secondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go('/auth/login');
            },
            child: const Text('Log Out', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: appColors.surfaceHover,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: colorScheme.secondary),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
      trailing: trailing ?? Icon(Icons.chevron_right, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.38)),
    );
  }
}
