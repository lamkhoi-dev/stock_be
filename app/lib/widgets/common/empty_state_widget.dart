import 'package:flutter/material.dart';

/// Empty state widget — shown when there's no data.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.actionLabel,
  });

  final String message;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline),
              ),
              child: Icon(icon, size: 40, color: colorScheme.onSurface.withValues(alpha: 0.38)),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.secondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: action,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
