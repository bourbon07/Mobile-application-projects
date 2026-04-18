import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'app_button.dart';

/// AppErrorWidget - Error fallback UI
///
/// Equivalent to Vue's error fallback HTML in app.js.
/// Displays a user-friendly error message when the app fails to load.
class AppErrorWidget extends StatelessWidget {
  /// The error that occurred
  final Object error;

  /// Optional callback to retry initialization
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final errorMessage = error.toString();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Error icon
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: AppTheme.spacingLG),

                  // Error title
                  Text(
                    'Error Loading Application',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.error,
                      // font-weight: regular (default)
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingMD),

                  // Error message
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppTheme.borderRadiusMediumValue,
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error Details:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            // font-weight: regular (default)
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSM),
                        Text(errorMessage, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLG),

                  // Instructions
                  Text(
                    'Please check the console for more details.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingXL),

                  // Retry button (if callback provided)
                  if (onRetry != null)
                    AppButton(
                      text: 'Retry',
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      size: AppButtonSize.medium,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
