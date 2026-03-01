import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../utils/helpers.dart';

/// Profile Edit Screen — update name, email, password.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final api = ref.read(apiClientProvider);

      // Update profile name
      final currentUser = ref.read(authProvider).user;
      if (_nameController.text != currentUser?.name) {
        final response = await api.updateProfile({'name': _nameController.text.trim()});
        if (response.data['success'] == true) {
          // Refresh auth state to get updated user
          await ref.read(authProvider.notifier).checkAuth();
        }
      }

      // Change password if provided
      if (_currentPasswordController.text.isNotEmpty && _newPasswordController.text.isNotEmpty) {
        final pwResponse = await api.changePassword(
          _currentPasswordController.text,
          _newPasswordController.text,
        );
        if (pwResponse.data['success'] != true) {
          if (!mounted) return;
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(pwResponse.data['message']?.toString() ?? 'Failed to change password'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
          return;
        }
        _currentPasswordController.clear();
        _newPasswordController.clear();
      }

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account', style: TextStyle(color: Color(0xFFEF4444))),
        content: Text(
          'This action is permanent and cannot be undone. All your data will be deleted.',
          style: TextStyle(color: colorScheme.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.deleteAccount();
      if (response.data['success'] == true) {
        if (!mounted) return;
        await ref.read(authProvider.notifier).logout();
        if (mounted) context.go('/auth/login');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _hasChanges && !_isSaving ? _save : null,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: _hasChanges ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.38),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          onChanged: () {
            if (!_hasChanges) setState(() => _hasChanges = true);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, const Color(0xFF8B5CF6)],
                        ),
                        boxShadow: [
                          BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 12),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name
              _buildLabel('Full Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                validator: validateName,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _inputDecoration('Enter your name'),
              ),
              const SizedBox(height: 18),

              // Email (read-only for now)
              _buildLabel('Email'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                readOnly: true,
                style: TextStyle(color: colorScheme.secondary),
                decoration: _inputDecoration('Email cannot be changed').copyWith(
                  filled: true,
                  fillColor: const Color(0xFF0D0F19),
                ),
              ),
              const SizedBox(height: 24),

              // Change Password Section
              Divider(color: colorScheme.outline),
              const SizedBox(height: 16),
              _buildLabel('Change Password'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _inputDecoration('Current password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                style: TextStyle(color: colorScheme.onSurface),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
                decoration: _inputDecoration('New password (min 8 chars)').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Danger zone
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danger Zone',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Permanently delete your account and all associated data.',
                      style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _deleteAccount,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Delete Account', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colorScheme.secondary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.38)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }
}
