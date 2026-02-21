import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// Enhanced button with proper feedback, accessibility labels and RTL support
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final ButtonVariant variant;
  final ButtonSize size;
  final String? tooltip;
  final String? semanticLabel;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.tooltip,
    this.semanticLabel,
  });

  /// Primary filled button
  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
    this.tooltip,
    this.semanticLabel,
  }) : variant = ButtonVariant.primary,
       size = ButtonSize.medium;

  /// Secondary outlined button
  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
    this.tooltip,
    this.semanticLabel,
  }) : variant = ButtonVariant.secondary,
       size = ButtonSize.medium;

  /// Text button
  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48,
    this.tooltip,
    this.semanticLabel,
  }) : variant = ButtonVariant.text,
       size = ButtonSize.medium;

  /// Danger/destructive button
  const AppButton.danger({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
    this.tooltip,
    this.semanticLabel,
  }) : variant = ButtonVariant.danger,
       size = ButtonSize.medium;

  @override
  Widget build(BuildContext context) {
    Widget button;

    switch (variant) {
      case ButtonVariant.primary:
        button = _buildElevatedButton(AppColors.primary, Colors.white);
        break;
      case ButtonVariant.secondary:
        button = _buildOutlinedButton(AppColors.primary);
        break;
      case ButtonVariant.text:
        button = _buildTextButton(AppColors.primary);
        break;
      case ButtonVariant.danger:
        button = _buildElevatedButton(AppColors.error, Colors.white);
        break;
    }

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel ?? text,
      child: button,
    );
  }

  Widget _buildElevatedButton(Color backgroundColor, Color foregroundColor) {
    return SizedBox(
      width: width ?? double.infinity,
      height: _getHeight(),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: backgroundColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
        ),
        child: _buildContent(foregroundColor),
      ),
    );
  }

  Widget _buildOutlinedButton(Color color) {
    return SizedBox(
      width: width ?? double.infinity,
      height: _getHeight(),
      child: OutlinedButton(
        onPressed: isLoading ? null : _handlePress,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          disabledForegroundColor: color.withValues(alpha: 0.5),
          side: BorderSide(color: isLoading ? color.withValues(alpha: 0.3) : color, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
        ),
        child: _buildContent(color),
      ),
    );
  }

  Widget _buildTextButton(Color color) {
    return SizedBox(
      width: width,
      height: _getHeight(),
      child: TextButton(
        onPressed: isLoading ? null : _handlePress,
        style: TextButton.styleFrom(
          foregroundColor: color,
          disabledForegroundColor: color.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
        ),
        child: _buildContent(color),
      ),
    );
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: color,
          strokeWidth: 2.5,
        ),
      );
    }

    final textWidget = Text(
      text,
      style: TextStyle(
        fontFamily: 'Heebo',
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          textWidget,
          const SizedBox(width: 8),
          Icon(icon, size: _getIconSize()),
        ],
      );
    }

    return textWidget;
  }

  void _handlePress() {
    HapticFeedback.mediumImpact();
    onPressed?.call();
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 40;
      case ButtonSize.medium:
        return height;
      case ButtonSize.large:
        return 64;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 18;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 20;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 18);
    }
  }
}

enum ButtonVariant { primary, secondary, text, danger }
enum ButtonSize { small, medium, large }

/// Icon button with enhanced feedback and accessibility
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;
  final String? semanticLabel;
  final bool isLoading;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 48,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
    this.semanticLabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: backgroundColor ?? AppColors.surfaceVariant,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: isLoading ? null : _handlePress,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: iconColor ?? AppColors.textPrimary,
                    ),
                  )
                : Icon(
                    icon,
                    color: iconColor ?? AppColors.textPrimary,
                    size: size * 0.45,
                  ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel ?? tooltip ?? 'כפתור',
      child: button,
    );
  }

  void _handlePress() {
    HapticFeedback.lightImpact();
    onPressed?.call();
  }
}

/// Floating action button with enhanced feedback
class AppFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final String? semanticLabel;
  final bool isExtended;
  final String? label;
  final bool isLoading;

  const AppFAB({
    super.key,
    this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
    this.semanticLabel,
    this.isExtended = false,
    this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget fab;

    if (isExtended && label != null) {
      fab = FloatingActionButton.extended(
        onPressed: isLoading ? null : _handlePress,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon),
        label: Text(
          label!,
          style: const TextStyle(
            fontFamily: 'Heebo',
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else {
      fab = FloatingActionButton(
        onPressed: isLoading ? null : _handlePress,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(icon),
      );
    }

    if (tooltip != null) {
      fab = Tooltip(
        message: tooltip!,
        child: fab,
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel ?? tooltip ?? label ?? 'כפתור פעולה',
      child: fab,
    );
  }

  void _handlePress() {
    HapticFeedback.mediumImpact();
    onPressed?.call();
  }
}

/// Back button with proper RTL support
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const AppBackButton({super.key, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_forward_ios_rounded),
      color: color ?? AppColors.textPrimary,
      tooltip: 'חזרה',
      onPressed: onPressed ?? () => Navigator.pop(context),
    );
  }
}
