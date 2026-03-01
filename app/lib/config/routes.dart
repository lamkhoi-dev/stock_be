import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/search/stock_list_screen.dart';
import '../screens/watchlist/watchlist_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/profile_edit_screen.dart';
import '../screens/stock_detail/stock_detail_screen.dart';
import '../widgets/common/main_shell.dart';

// Navigation keys for ShellRoute
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter provider — can be overridden for testing.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // TODO: Phase 4 — check auth state from authProvider
      // final isLoggedIn = ref.read(authProvider).isAuthenticated;
      // final isAuthRoute = state.matchedLocation.startsWith('/auth');
      // final isSplash = state.matchedLocation == '/splash';
      //
      // if (!isLoggedIn && !isAuthRoute && !isSplash) return '/auth/login';
      // if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // ─── Splash ───────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ─── Auth Routes ──────────────────────────────
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ─── Main Shell (BottomNavBar) ────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            child: navigationShell,
          );
        },
        branches: [
          // Home tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Search tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          // Watchlist tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/watchlist',
                builder: (context, state) => const WatchlistScreen(),
              ),
            ],
          ),
          // Settings tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const ProfileEditScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ─── Full-Screen Routes (no bottom nav) ──────
      GoRoute(
        path: '/stock/:symbol',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StockDetailScreen(
          symbol: state.pathParameters['symbol']!,
        ),
      ),
      GoRoute(
        path: '/stocks',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StockListScreen(),
      ),
    ],
  );
});
