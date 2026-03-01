import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../utils/helpers.dart';

/// Register screen — name, email, password, confirm password with validation.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (success && mounted) {
      ref.read(websocketProvider.notifier).connect();
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Get started',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your account to access Korean stock AI analysis',
                  style: TextStyle(fontSize: 14, color: colorScheme.secondary),
                ),
                const SizedBox(height: 32),
                // Full name
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: validateName,
                  decoration: const InputDecoration(
                    hintText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: validateEmail,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final result = validatePassword(v);
                    if (result != null) return result;
                    if (v != null && !RegExp(r'(?=.*[A-Z])(?=.*\d)').hasMatch(v)) {
                      return 'Must contain uppercase letter and number';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: colorScheme.secondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Confirm password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: colorScheme.secondary,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Password requirements hint
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Min 8 chars, 1 uppercase, 1 number',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.38)),
                  ),
                ),
                const SizedBox(height: 24),
                // Error message
                if (authState.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withAlpha(40)),
                    ),
                    child: Text(
                      authState.error!,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleRegister,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: colorScheme.outline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: colorScheme.outline)),
                  ],
                ),
                const SizedBox(height: 24),
                // Google sign up
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {/* Phase 7 */},
                    icon: const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    label: const Text('Continue with Google'),
                  ),
                ),
                const SizedBox(height: 32),
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: colorScheme.secondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
