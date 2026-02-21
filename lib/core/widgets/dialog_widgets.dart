import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// Enhanced error dialog with consistent styling
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final bool showRetry;

  const ErrorDialog({
    super.key,
    this.title = 'שגיאה',
    required this.message,
    this.actionText,
    this.onAction,
    this.showRetry = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: AppColors.surface,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Heebo',
          fontSize: 15,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        textAlign: TextAlign.right,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'סגור',
            style: TextStyle(
              fontFamily: 'Heebo',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (showRetry)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAction?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              actionText ?? 'נסי שוב',
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

/// Enhanced success dialog
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String actionText;
  final VoidCallback? onAction;

  const SuccessDialog({
    super.key,
    this.title = 'הצלחה!',
    required this.message,
    this.actionText = 'אוקי',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: AppColors.surface,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Heebo',
          fontSize: 15,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        textAlign: TextAlign.right,
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onAction?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            actionText,
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Confirmation dialog with consistent styling
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'אישור',
    this.cancelText = 'ביטול',
    this.confirmColor,
    this.icon,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = confirmColor ?? (isDestructive ? AppColors.error : AppColors.primary);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: AppColors.surface,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Heebo',
          fontSize: 15,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        textAlign: TextAlign.right,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            cancelText,
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Extension methods for showing dialogs easily
extension DialogExtensions on BuildContext {
  /// Show error dialog
  Future<void> showErrorDialog({
    String title = 'שגיאה',
    required String message,
    bool showRetry = false,
    VoidCallback? onRetry,
  }) async {
    HapticFeedback.mediumImpact();
    return showDialog(
      context: this,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        showRetry: showRetry,
        onAction: onRetry,
      ),
    );
  }

  /// Show success dialog
  Future<void> showSuccessDialog({
    String title = 'הצלחה!',
    required String message,
    String actionText = 'אוקי',
    VoidCallback? onAction,
  }) async {
    HapticFeedback.lightImpact();
    return showDialog(
      context: this,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        actionText: actionText,
        onAction: onAction,
      ),
    );
  }

  /// Show confirmation dialog
  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'אישור',
    String cancelText = 'ביטול',
    Color? confirmColor,
    IconData? icon,
    bool isDestructive = false,
  }) async {
    HapticFeedback.lightImpact();
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  /// Show delete confirmation dialog
  Future<bool> showDeleteConfirm({
    String itemName = 'פריט',
  }) async {
    return showConfirmDialog(
      title: 'מחיקת $itemName',
      message: 'האם את בטוחה שברצונך למחוק? פעולה זו לא ניתנת לביטול.',
      confirmText: 'מחקי',
      cancelText: 'ביטול',
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
    );
  }

  /// Show logout confirmation dialog
  Future<bool> showLogoutConfirm() async {
    return showConfirmDialog(
      title: 'התנתקות',
      message: 'האם את בטוחה שברצונך להתנתק?',
      confirmText: 'התנתקי',
      cancelText: 'ביטול',
      icon: Icons.logout_rounded,
      isDestructive: true,
    );
  }
}

/// Enhanced snackbar with consistent styling
class AppSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colors = <SnackBarType, Color>{
      SnackBarType.success: AppColors.success,
      SnackBarType.error: AppColors.error,
      SnackBarType.warning: AppColors.warning,
      SnackBarType.info: AppColors.primary,
    };

    final icons = <SnackBarType, IconData>{
      SnackBarType.success: Icons.check_circle_outline_rounded,
      SnackBarType.error: Icons.error_outline_rounded,
      SnackBarType.warning: Icons.warning_amber_rounded,
      SnackBarType.info: Icons.info_outline_rounded,
    };

    final color = colors[type] ?? AppColors.primary;
    final icon = icons[type] ?? Icons.info_outline_rounded;

    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(
      context: context,
      message: message,
      type: SnackBarType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(
      context: context,
      message: message,
      type: SnackBarType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(
      context: context,
      message: message,
      type: SnackBarType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(
      context: context,
      message: message,
      type: SnackBarType.info,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

enum SnackBarType { success, error, warning, info }
