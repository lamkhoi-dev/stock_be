import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/env.dart';
import '../../providers/auth_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../services/api_client.dart';

/// Splash screen — animated app logo, checks auth state and navigates.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _loadingOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.6, curve: Curves.easeIn)),
    );
    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 0.8, curve: Curves.easeIn)),
    );

    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Fire a health check in background to pre-warm backend (Render cold start)
    final api = ref.read(apiClientProvider);
    unawaited(api.healthCheck().catchError((_) {}));

    try {
      // Timeout guard — don't let auth check block splash for more than 5s
      await ref
          .read(authProvider.notifier)
          .checkAuth()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Timeout or error — force-reset loading state and proceed as unauthenticated
      ref.read(authProvider.notifier).forceResetLoading();
    }
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      // Connect WebSocket for real-time price updates
      ref.read(websocketProvider.notifier).connect();
      context.go('/home');
    } else {
      // Optimistic auth: if token exists in storage, go to home anyway
      // (backend cold start may have caused timeout but token is still valid)
      final storage = ref.read(secureStorageProvider);
      final token = await storage.read(key: Env.accessTokenKey);
      if (!mounted) return;
      if (token != null) {
        // Mark as authenticated so watchlist/other screens don't redirect
        ref.read(authProvider.notifier).setOptimisticAuth();
        ref.read(websocketProvider.notifier).connect();
        context.go('/home');
        // Retry loading user data in background (no timeout pressure)
        ref.read(authProvider.notifier).silentCheckAuth();
      } else {
        context.go('/auth/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFF0F1120),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  // App logo
                  Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [colorScheme.primary, const Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withAlpha(60),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 18,
                              right: 18,
                              child: Icon(Icons.show_chart, color: Colors.white24, size: 28),
                            ),
                            Text(
                              'KRX',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // App name + tagline
                  Opacity(
                    opacity: _textOpacity.value,
                    child: Column(
                      children: [
                        Text(
                          'KRX Analysis',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🇰🇷', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              'Korean Stock AI Analysis',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Loading
                  Opacity(
                    opacity: _loadingOpacity.value,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary.withAlpha(180),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading market data...',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.38)),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 1),
                  // Version
                  Opacity(
                    opacity: _textOpacity.value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Text(
                        'v2.0.0',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.38)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Simple AnimatedWidget wrapper.
class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) => builder(context, null);
}
