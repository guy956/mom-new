import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/feature_flag_service.dart';
import 'package:mom_connect/services/app_state.dart';

/// A widget that conditionally builds its child based on a feature flag.
/// 
/// Usage:
/// ```dart
/// FeatureFlagGuard(
///   featureId: FeatureFlagIds.enableAiChat,
///   child: AIChatButton(),
///   fallback: SizedBox.shrink(),
/// )
/// ```
class FeatureFlagGuard extends StatelessWidget {
  final String featureId;
  final Widget child;
  final Widget? fallback;
  final bool useNewSystem;

  const FeatureFlagGuard({
    super.key,
    required this.featureId,
    required this.child,
    this.fallback,
    this.useNewSystem = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useNewSystem) {
      // Use the new FeatureFlagService
      final service = context.watch<FeatureFlagService>();
      if (service.isEnabled(featureId)) {
        return child;
      }
    } else {
      // Use the legacy AppState system
      final appState = context.watch<AppState>();
      if (appState.isFeatureEnabled(featureId)) {
        return child;
      }
    }
    
    return fallback ?? const SizedBox.shrink();
  }
}

/// A widget that shows different children based on whether a feature is enabled
/// for the current user (with rollout percentage support).
/// 
/// Usage:
/// ```dart
/// FeatureFlagForUser(
///   featureId: FeatureFlagIds.enableAiChat,
///   userId: currentUser.id,
///   enabledChild: NewFeatureWidget(),
///   disabledChild: OldFeatureWidget(),
/// )
/// ```
class FeatureFlagForUser extends StatelessWidget {
  final String featureId;
  final String userId;
  final Widget enabledChild;
  final Widget disabledChild;

  const FeatureFlagForUser({
    super.key,
    required this.featureId,
    required this.userId,
    required this.enabledChild,
    required this.disabledChild,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FeatureFlagService>();
    
    if (service.isEnabledForUser(featureId, userId)) {
      return enabledChild;
    }
    
    return disabledChild;
  }
}

/// A widget that fades in/out based on feature flag state
class AnimatedFeatureFlagGuard extends StatelessWidget {
  final String featureId;
  final Widget child;
  final Duration duration;
  final bool useNewSystem;

  const AnimatedFeatureFlagGuard({
    super.key,
    required this.featureId,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.useNewSystem = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = useNewSystem
        ? context.watch<FeatureFlagService>().isEnabled(featureId)
        : context.watch<AppState>().isFeatureEnabled(featureId);

    return AnimatedSwitcher(
      duration: duration,
      child: isEnabled ? child : const SizedBox.shrink(key: ValueKey('disabled')),
    );
  }
}

/// A widget that shows a badge on the child if a feature is new/experimental
class ExperimentalFeatureBadge extends StatelessWidget {
  final Widget child;
  final String? label;
  final Color badgeColor;

  const ExperimentalFeatureBadge({
    super.key,
    required this.child,
    this.label,
    this.badgeColor = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label ?? 'בטא',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Heebo',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A navigation destination that conditionally shows based on feature flag
class FeatureFlagNavigationItem {
  final String featureId;
  final NavigationDestination destination;
  final bool useNewSystem;

  const FeatureFlagNavigationItem({
    required this.featureId,
    required this.destination,
    this.useNewSystem = false,
  });

  bool isEnabled(BuildContext context) {
    if (useNewSystem) {
      return context.read<FeatureFlagService>().isEnabled(featureId);
    }
    return context.read<AppState>().isFeatureEnabled(featureId);
  }
}

/// Extension methods for easier feature flag checking in BuildContext
extension FeatureFlagExtension on BuildContext {
  /// Check if a feature is enabled (uses legacy AppState by default)
  bool isFeatureEnabled(String featureId, {bool useNewSystem = false}) {
    if (useNewSystem) {
      return read<FeatureFlagService>().isEnabled(featureId);
    }
    return read<AppState>().isFeatureEnabled(featureId);
  }

  /// Check if a feature is enabled for a specific user
  bool isFeatureEnabledForUser(String featureId, String userId) {
    return read<FeatureFlagService>().isEnabledForUser(featureId, userId);
  }

  /// Get the feature flag service
  FeatureFlagService get featureFlags => read<FeatureFlagService>();
}
