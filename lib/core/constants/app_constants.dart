/// App-wide constants for MOMIT
/// 
/// Use these constants for consistent behavior across the app:
/// - Animation durations
/// - Timeout values
/// - Pagination limits
/// - UI dimensions
/// - Cache settings
class AppConstants {
  AppConstants._();

  // ════════════════════════════════════════════════════════════════
  //  ANIMATION DURATIONS
  // ════════════════════════════════════════════════════════════════
  
  /// Quick animations (micro-interactions)
  static const Duration animationQuick = Duration(milliseconds: 150);
  
  /// Standard animations (most UI transitions)
  static const Duration animationStandard = Duration(milliseconds: 300);
  
  /// Slow animations (emphasis, page transitions)
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  /// Very slow animations (splash, onboarding)
  static const Duration animationVerySlow = Duration(milliseconds: 800);

  // ════════════════════════════════════════════════════════════════
  //  TIMEOUTS
  // ════════════════════════════════════════════════════════════════
  
  /// Network request timeout
  static const Duration networkTimeout = Duration(seconds: 30);
  
  /// Connection timeout
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  /// Splash screen minimum display time
  static const Duration splashMinDuration = Duration(seconds: 2);
  
  /// Debounce duration for search inputs
  static const Duration searchDebounce = Duration(milliseconds: 300);
  
  /// Throttle duration for button clicks
  static const Duration buttonThrottle = Duration(milliseconds: 500);

  // ════════════════════════════════════════════════════════════════
  //  PAGINATION
  // ════════════════════════════════════════════════════════════════
  
  /// Default page size for lists
  static const int defaultPageSize = 20;
  
  /// Small page size for initial load
  static const int smallPageSize = 10;
  
  /// Large page size for bulk operations
  static const int largePageSize = 50;
  
  /// Maximum items to keep in memory cache
  static const int maxCachedItems = 100;

  // ════════════════════════════════════════════════════════════════
  //  UI DIMENSIONS
  // ════════════════════════════════════════════════════════════════
  
  /// Default padding for screens
  static const double screenPadding = 16.0;
  
  /// Small padding
  static const double paddingSmall = 8.0;
  
  /// Medium padding
  static const double paddingMedium = 16.0;
  
  /// Large padding
  static const double paddingLarge = 24.0;
  
  /// Extra large padding
  static const double paddingXLarge = 32.0;
  
  /// Default border radius
  static const double borderRadius = 12.0;
  
  /// Small border radius
  static const double borderRadiusSmall = 8.0;
  
  /// Large border radius
  static const double borderRadiusLarge = 16.0;
  
  /// Button height (standard)
  static const double buttonHeight = 56.0;
  
  /// Button height (small)
  static const double buttonHeightSmall = 40.0;
  
  /// App bar height
  static const double appBarHeight = 56.0;
  
  /// Bottom nav bar height
  static const double bottomNavHeight = 64.0;
  
  /// Max content width (for tablets/desktop)
  static const double maxContentWidth = 600.0;

  // ════════════════════════════════════════════════════════════════
  //  CACHE SETTINGS
  // ════════════════════════════════════════════════════════════════
  
  /// Default cache duration
  static const Duration cacheDuration = Duration(hours: 24);
  
  /// Short cache duration (frequently changing data)
  static const Duration cacheDurationShort = Duration(minutes: 5);
  
  /// Long cache duration (rarely changing data)
  static const Duration cacheDurationLong = Duration(days: 7);
  
  /// Image cache size in MB
  static const int imageCacheSizeMB = 100;
  
  /// Max disk cache size in MB
  static const int maxDiskCacheSizeMB = 200;

  // ════════════════════════════════════════════════════════════════
  //  VALIDATION LIMITS
  // ════════════════════════════════════════════════════════════════
  
  /// Minimum password length
  static const int minPasswordLength = 8;
  
  /// Maximum password length
  static const int maxPasswordLength = 128;
  
  /// Minimum username length
  static const int minUsernameLength = 3;
  
  /// Maximum username length
  static const int maxUsernameLength = 30;
  
  /// Maximum bio length
  static const int maxBioLength = 500;
  
  /// Maximum post content length
  static const int maxPostLength = 2000;
  
  /// Maximum comment length
  static const int maxCommentLength = 500;
  
  /// Maximum image upload size in MB
  static const int maxImageSizeMB = 10;
  
  /// Maximum video upload size in MB
  static const int maxVideoSizeMB = 100;

  // ════════════════════════════════════════════════════════════════
  //  RETRY CONFIGURATION
  // ════════════════════════════════════════════════════════════════
  
  /// Maximum retry attempts
  static const int maxRetryAttempts = 3;
  
  /// Initial retry delay
  static const Duration retryInitialDelay = Duration(seconds: 1);
  
  /// Retry delay multiplier (exponential backoff)
  static const double retryMultiplier = 2.0;
  
  /// Maximum retry delay
  static const Duration retryMaxDelay = Duration(seconds: 30);

  // ════════════════════════════════════════════════════════════════
  //  FEATURE FLAGS DEFAULTS
  // ════════════════════════════════════════════════════════════════
  
  /// Default value for analytics enabled
  static const bool defaultAnalyticsEnabled = true;
  
  /// Default value for crash reporting
  static const bool defaultCrashReporting = true;
  
  /// Default value for push notifications
  static const bool defaultPushNotifications = true;
  
  /// Default value for auto-play videos
  static const bool defaultAutoPlayVideos = false;
  
  /// Default value for dark mode (follows system)
  static const bool defaultFollowSystemTheme = true;

  // ════════════════════════════════════════════════════════════════
  //  DATE/TIME FORMATS
  // ════════════════════════════════════════════════════════════════
  
  /// Date format for display (Hebrew locale)
  static const String dateFormatDisplay = 'dd/MM/yyyy';
  
  /// Date format for display with time
  static const String dateTimeFormatDisplay = 'dd/MM/yyyy HH:mm';
  
  /// Short time format
  static const String timeFormatShort = 'HH:mm';
  
  /// ISO date format for API
  static const String dateFormatISO = 'yyyy-MM-dd';
  
  /// ISO datetime format for API
  static const String dateTimeFormatISO = 'yyyy-MM-ddTHH:mm:ss';
}

/// Extension for easy duration access
extension DurationConstants on int {
  /// Get milliseconds as Duration
  Duration get ms => Duration(milliseconds: this);
  
  /// Get seconds as Duration
  Duration get seconds => Duration(seconds: this);
  
  /// Get minutes as Duration
  Duration get minutes => Duration(minutes: this);
  
  /// Get hours as Duration
  Duration get hours => Duration(hours: this);
  
  /// Get days as Duration
  Duration get days => Duration(days: this);
}
