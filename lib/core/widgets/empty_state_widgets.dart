import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhanced empty state widget with illustration, title, subtitle and optional action button
class EnhancedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double iconSize;
  final bool useLottie;
  final String? lottieAsset;

  const EnhancedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
    this.backgroundColor,
    this.iconSize = 80,
    this.useLottie = false,
    this.lottieAsset,
  });

  /// Factory constructor for no search results
  factory EnhancedEmptyState.search({
    String query = '',
    VoidCallback? onClearSearch,
  }) {
    return EnhancedEmptyState(
      icon: Icons.search_off_rounded,
      title: 'לא נמצאו תוצאות',
      subtitle: query.isNotEmpty 
          ? 'נסי לחפש משהו אחר או שנה את מילות החיפוש'
          : 'הקלידי מילות חיפוש כדי למצוא תוכן',
      buttonText: query.isNotEmpty ? 'נקי חיפוש' : null,
      onButtonPressed: onClearSearch,
      iconColor: AppColors.info,
    );
  }

  /// Factory constructor for no notifications
  factory EnhancedEmptyState.notifications() {
    return const EnhancedEmptyState(
      icon: Icons.notifications_off_outlined,
      title: 'אין התראות חדשות',
      subtitle: 'כשתקבלי התראות, הן יופיעו כאן',
      iconColor: AppColors.textHint,
    );
  }

  /// Factory constructor for no messages
  factory EnhancedEmptyState.messages({VoidCallback? onStartChat}) {
    return EnhancedEmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'אין הודעות עדיין',
      subtitle: 'התחילי שיחה עם אמהות אחרות בקהילה',
      buttonText: 'התחילי שיחה',
      onButtonPressed: onStartChat,
      iconColor: AppColors.primary,
    );
  }

  /// Factory constructor for no events
  factory EnhancedEmptyState.events({VoidCallback? onCreateEvent}) {
    return EnhancedEmptyState(
      icon: Icons.event_busy_outlined,
      title: 'אין אירועים כרגע',
      subtitle: 'היו הראשונה ליצור אירוע ולהזמין אמהות!',
      buttonText: 'צרי אירוע',
      onButtonPressed: onCreateEvent,
      iconColor: AppColors.accent,
    );
  }

  /// Factory constructor for no posts
  factory EnhancedEmptyState.posts({VoidCallback? onCreatePost}) {
    return EnhancedEmptyState(
      icon: Icons.forum_outlined,
      title: 'עדיין אין פוסטים',
      subtitle: 'היי הראשונה לשתף ולהתחיל שיחה!',
      buttonText: 'כתבי פוסט',
      onButtonPressed: onCreatePost,
      iconColor: AppColors.primary,
    );
  }

  /// Factory constructor for error state
  factory EnhancedEmptyState.error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return EnhancedEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'אופס, משהו השתבש',
      subtitle: message ?? 'לא הצלחנו לטעון את התוכן. נסי שוב.',
      buttonText: 'נסי שוב',
      onButtonPressed: onRetry,
      iconColor: AppColors.error,
    );
  }

  /// Factory constructor for network error
  factory EnhancedEmptyState.noInternet({VoidCallback? onRetry}) {
    return EnhancedEmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'אין חיבור לאינטרנט',
      subtitle: 'בדקי את החיבור שלך ונסי שוב',
      buttonText: 'נסי שוב',
      onButtonPressed: onRetry,
      iconColor: AppColors.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container with gradient background
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (iconColor ?? AppColors.primary).withValues(alpha: 0.15),
                    (iconColor ?? AppColors.primary).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'Heebo',
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Heebo',
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            // Action button
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                height: 56,
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(buttonText!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated empty state with subtle pulse animation
class AnimatedEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;

  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
  });

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (widget.iconColor ?? AppColors.primary)
                              .withValues(alpha: 0.15),
                          (widget.iconColor ?? AppColors.primary)
                              .withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 72,
                      color: widget.iconColor ?? AppColors.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'Heebo',
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.subtitle!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Heebo',
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
