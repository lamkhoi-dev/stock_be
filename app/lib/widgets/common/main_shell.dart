import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Main shell with bottom navigation bar — wraps tab screens.
class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTap,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: S.of(context).navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_outlined),
              activeIcon: const Icon(Icons.search),
              label: S.of(context).navSearch,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.star_outline),
              activeIcon: const Icon(Icons.star),
              label: S.of(context).navWatchlist,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: S.of(context).navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
