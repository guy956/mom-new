import 'package:flutter/material.dart';
import 'package:mom_connect/core/constants/app_strings.dart';
import 'package:mom_connect/services/branding_config_service.dart';

/// Dynamic text configuration that overlays Firestore overrides on top of
/// static [AppStrings] defaults. Every user-facing string in the app should
/// read from TextConfig instead of AppStrings so the admin dashboard can
/// change it at runtime without a code deploy.
class TextConfig {
  TextConfig._();

  static Map<String, Map<String, String>> _overrides = {};
  
  // Branding service reference for dynamic app name
  static BrandingConfigService? _brandingService;
  
  /// Initialize TextConfig with branding service
  static void initialize(BrandingConfigService brandingService) {
    _brandingService = brandingService;
  }
  
  /// Stream of app name changes for real-time updates
  static Stream<String> get appNameStream {
    if (_brandingService == null) return Stream.value(AppStrings.appName);
    return _brandingService!.brandingStream.map((config) => 
      _r('app', 'appName', config.appName)
    );
  }

  /// Called by AppState whenever the `text_overrides` Firestore doc changes.
  static void updateOverrides(Map<String, dynamic> raw) {
    final parsed = <String, Map<String, String>>{};
    for (final section in raw.entries) {
      if (section.value is Map) {
        parsed[section.key] = Map<String, String>.from(
          (section.value as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
    }
    _overrides = parsed;
  }

  /// Raw overrides map (for admin editor).
  static Map<String, Map<String, String>> get overrides => _overrides;

  // ── Internal resolver ──
  static String _r(String section, String key, String fallback) {
    return _overrides[section]?[key] ?? fallback;
  }

  // ════════════════════════════════════════════════════════════════
  //  SECTION: app - DYNAMIC BRANDING
  // ════════════════════════════════════════════════════════════════
  
  /// Dynamic app name - reads from Firestore branding config with fallback to text overrides
  static String get appName {
    final brandingName = _brandingService?.config.appName;
    return _r('app', 'appName', brandingName ?? AppStrings.appName);
  }
  
  /// Dynamic app name English - reads from Firestore branding config
  static String get appNameEnglish {
    final brandingName = _brandingService?.config.appNameEnglish;
    return _r('app', 'appNameEnglish', brandingName ?? AppStrings.appNameEnglish);
  }
  
  /// Dynamic slogan - reads from Firestore branding config
  static String get slogan {
    final brandingSlogan = _brandingService?.config.slogan;
    return _r('app', 'slogan', brandingSlogan ?? AppStrings.slogan);
  }
  
  /// Dynamic tagline - reads from Firestore branding config  
  static String get tagline {
    final brandingTagline = _brandingService?.config.tagline;
    return _r('app', 'tagline', brandingTagline ?? AppStrings.tagline);
  }
  
  /// Get the logo URL from branding config
  static String? get logoUrl => _brandingService?.config.logoUrl;
  
  /// Get the splash image URL from branding config
  static String? get splashImageUrl => _brandingService?.config.splashImageUrl;
  
  /// Get cached logo file path
  static String? get cachedLogoPath => _brandingService?.cachedLogoPath;
  
  /// Get cached splash image file path
  static String? get cachedSplashPath => _brandingService?.cachedSplashPath;

  // ════════════════════════════════════════════════════════════════
  //  SECTION: welcome
  // ════════════════════════════════════════════════════════════════
  static String get welcomeTitle => _r('welcome', 'welcomeTitle', AppStrings.welcomeTitle);
  static String get welcomeSubtitle => _r('welcome', 'welcomeSubtitle', AppStrings.welcomeSubtitle);
  static String get welcomeDescription => _r('welcome', 'welcomeDescription', AppStrings.welcomeDescription);
  static String get joinFree => _r('welcome', 'joinFree', AppStrings.joinFree);
  static String get learnMore => _r('welcome', 'learnMore', AppStrings.learnMore);
  static String get alreadyMember => _r('welcome', 'alreadyMember', AppStrings.alreadyMember);

  // ════════════════════════════════════════════════════════════════
  //  SECTION: auth
  // ════════════════════════════════════════════════════════════════
  static String get login => _r('auth', 'login', AppStrings.login);
  static String get register => _r('auth', 'register', AppStrings.register);
  static String get loginTitle => _r('auth', 'loginTitle', AppStrings.loginTitle);
  static String get registerTitle => _r('auth', 'registerTitle', AppStrings.registerTitle);
  static String get email => _r('auth', 'email', AppStrings.email);
  static String get password => _r('auth', 'password', AppStrings.password);
  static String get confirmPassword => _r('auth', 'confirmPassword', AppStrings.confirmPassword);
  static String get phone => _r('auth', 'phone', AppStrings.phone);
  static String get fullName => _r('auth', 'fullName', AppStrings.fullName);
  static String get city => _r('auth', 'city', AppStrings.city);
  static String get forgotPassword => _r('auth', 'forgotPassword', AppStrings.forgotPassword);
  static String get orContinueWith => _r('auth', 'orContinueWith', AppStrings.orContinueWith);
  static String get continueWithGoogle => _r('auth', 'continueWithGoogle', AppStrings.continueWithGoogle);
  static String get continueWithPhone => _r('auth', 'continueWithPhone', AppStrings.continueWithPhone);
  static String get sendCode => _r('auth', 'sendCode', AppStrings.sendCode);
  static String get verifyCode => _r('auth', 'verifyCode', AppStrings.verifyCode);
  static String get resendCode => _r('auth', 'resendCode', AppStrings.resendCode);
  static String get agreeToTerms => _r('auth', 'agreeToTerms', AppStrings.agreeToTerms);
  static String get termsOfService => _r('auth', 'termsOfService', AppStrings.termsOfService);
  static String get and => _r('auth', 'and', AppStrings.and);
  static String get privacyPolicy => _r('auth', 'privacyPolicy', AppStrings.privacyPolicy);

  // ════════════════════════════════════════════════════════════════
  //  SECTION: nav
  // ════════════════════════════════════════════════════════════════
  static String get home => _r('nav', 'home', AppStrings.home);
  static String get search => _r('nav', 'search', AppStrings.search);
  static String get create => _r('nav', 'create', AppStrings.create);
  static String get messages => _r('nav', 'messages', AppStrings.messages);
  static String get profile => _r('nav', 'profile', AppStrings.profile);
  static String get groups => _r('nav', 'groups', AppStrings.groups);
  static String get conversations => _r('nav', 'conversations', AppStrings.conversations);
  static String get events => _r('nav', 'events', AppStrings.events);
  static String get tools => _r('nav', 'tools', AppStrings.tools);

  // ════════════════════════════════════════════════════════════════
  //  SECTION: feed
  // ════════════════════════════════════════════════════════════════
  static String get feed => _r('feed', 'feed', AppStrings.feed);
  static String get hotConversations => _r('feed', 'hotConversations', AppStrings.hotConversations);
  static String get selectedContent => _r('feed', 'selectedContent', AppStrings.selectedContent);
  static String get questionsAndAnswers => _r('feed', 'questionsAndAnswers', AppStrings.questionsAndAnswers);
  static String get newPost => _r('feed', 'newPost', AppStrings.newPost);
  static String get whatsOnYourMind => _r('feed', 'whatsOnYourMind', AppStrings.whatsOnYourMind);
  static String get shareWithCommunity => _r('feed', 'shareWithCommunity', AppStrings.shareWithCommunity);
  static String get addPhoto => _r('feed', 'addPhoto', AppStrings.addPhoto);
  static String get addVideo => _r('feed', 'addVideo', AppStrings.addVideo);
  static String get createPoll => _r('feed', 'createPoll', AppStrings.createPoll);
  static String get askForHelp => _r('feed', 'askForHelp', AppStrings.askForHelp);
  static String get postAnonymously => _r('feed', 'postAnonymously', AppStrings.postAnonymously);

  // ════════════════════════════════════════════════════════════════
  //  SECTION: tracking
  // ════════════════════════════════════════════════════════════════
  static String get trackingTools => _r('tracking', 'trackingTools', AppStrings.trackingTools);
  static String get trackingDescription => _r('tracking', 'trackingDescription', AppStrings.trackingDescription);
  static String get feedingTracker => _r('tracking', 'feedingTracker', AppStrings.feedingTracker);
  static String get sleepTracker => _r('tracking', 'sleepTracker', AppStrings.sleepTracker);
  static String get growthTracker => _r('tracking', 'growthTracker', AppStrings.growthTracker);
  static String get diaperTracker => _r('tracking', 'diaperTracker', AppStrings.diaperTracker);
  static String get milestonesTracker => _r('tracking', 'milestonesTracker', AppStrings.milestonesTracker);
  static String get vaccinations => _r('tracking', 'vaccinations', AppStrings.vaccinations);
  static String get reminders => _r('tracking', 'reminders', AppStrings.reminders);
  static String get exportData => _r('tracking', 'exportData', AppStrings.exportData);
  static String get trackFor => _r('tracking', 'trackFor', AppStrings.trackFor);
  static String get addBaby => _r('tracking', 'addBaby', AppStrings.addBaby);
  static String get quickLog => _r('tracking', 'quickLog', AppStrings.quickLog);
  static String get startFeeding => _r('tracking', 'startFeeding', AppStrings.startFeeding);
  static String get startSleep => _r('tracking', 'startSleep', AppStrings.startSleep);
  static String get changeDiaper => _r('tracking', 'changeDiaper', AppStrings.changeDiaper);
  static String get todaysSummary => _r('tracking', 'todaysSummary', AppStrings.todaysSummary);
  static String get sleepHours => _r('tracking', 'sleepHours', AppStrings.sleepHours);
  static String get feedings => _r('tracking', 'feedings', AppStrings.feedings);
  static String get diapers => _r('tracking', 'diapers', AppStrings.diapers);
  static String get monthlyGrowth => _r('tracking', 'monthlyGrowth', AppStrings.monthlyGrowth);
  static String get recentActivity => _r('tracking', 'recentActivity', AppStrings.recentActivity);
  static String get viewAll => _r('tracking', 'viewAll', AppStrings.viewAll);
  static String get upcomingReminders => _r('tracking', 'upcomingReminders', AppStrings.upcomingReminders);
  static String get nextVaccine => _r('tracking', 'nextVaccine', AppStrings.nextVaccine);
  static String get inDays => _r('tracking', 'inDays', AppStrings.inDays);
  static String get days => _r('tracking', 'days', AppStrings.days);
  static String get details => _r('tracking', 'details', AppStrings.details);

  // ════════════════════════════════════════════════════════════════
  //  SECTION: events
  // ════════════════════════════════════════════════════════════════
  static String get eventsAndMeetups => _r('events', 'eventsAndMeetups', AppStrings.eventsAndMeetups);
  static String get opportunitiesToConnect => _r('events', 'opportunitiesToConnect', AppStrings.opportunitiesToConnect);
  static String get eventsDescription => _r('events', 'eventsDescription', AppStrings.eventsDescription);
  static String get searchEvents => _r('events', 'searchEvents', AppStrings.searchEvents);
  static String get all => _r('events', 'all', AppStrings.all);
  static String get playMeetups => _r('events', 'playMeetups', AppStrings.playMeetups);
  static String get classes => _r('events', 'classes', AppStrings.classes);
  static String get womensEvenings => _r('events', 'womensEvenings', AppStrings.womensEvenings);
  static String get webinars => _r('events', 'webinars', AppStrings.webinars);
  static String get supportGroups => _r('events', 'supportGroups', AppStrings.supportGroups);
  static String get workshops => _r('events', 'workshops', AppStrings.workshops);
  static String get online => _r('events', 'online', AppStrings.online);
  static String get faceToFace => _r('events', 'faceToFace', AppStrings.faceToFace);
  static String get participate => _r('events', 'participate', AppStrings.participate);
  static String get hostedBy => _r('events', 'hostedBy', AppStrings.hostedBy);
  static String get registered => _r('events', 'registered', AppStrings.registered);
  static String get spotsLeft => _r('events', 'spotsLeft', AppStrings.spotsLeft);
  static String get spots => _r('events', 'spots', AppStrings.spots);
  static String get free => _r('events', 'free', AppStrings.free);

  // ════════════════════════════════════════════════════════════════
  //  SECTION: chat
  // ════════════════════════════════════════════════════════════════
  static String get noMessages => _r('chat', 'noMessages', AppStrings.noMessages);
  static String get startConversation => _r('chat', 'startConversation', AppStrings.startConversation);
  static String get typeMessage => _r('chat', 'typeMessage', AppStrings.typeMessage);
  static String get send => _r('chat', 'send', AppStrings.send);
  static String get online_ => _r('chat', 'online_', AppStrings.online_);
  static String get offline => _r('chat', 'offline', AppStrings.offline);
  static String get typing => _r('chat', 'typing', AppStrings.typing);
  static String get seen => _r('chat', 'seen', AppStrings.seen);
  static String get delivered => _r('chat', 'delivered', AppStrings.delivered);

  // ════════════════════════════════════════════════════════════════
  //  SECTION: profile
  // ════════════════════════════════════════════════════════════════
  static String get editProfile => _r('profile', 'editProfile', AppStrings.editProfile);
  static String get myChildren => _r('profile', 'myChildren', AppStrings.myChildren);
  static String get myPosts => _r('profile', 'myPosts', AppStrings.myPosts);
  static String get savedPosts => _r('profile', 'savedPosts', AppStrings.savedPosts);
  static String get settings => _r('profile', 'settings', AppStrings.settings);
  static String get notifications => _r('profile', 'notifications', AppStrings.notifications);
  static String get privacy => _r('profile', 'privacy', AppStrings.privacy);
  static String get help => _r('profile', 'help', AppStrings.help);
  static String get about => _r('profile', 'about', AppStrings.about);
  static String get logout => _r('profile', 'logout', AppStrings.logout);
  static String get deleteAccount => _r('profile', 'deleteAccount', AppStrings.deleteAccount);
  static String get momsSince => _r('profile', 'momsSince', AppStrings.momsSince);
  static String get averageRating => _r('profile', 'averageRating', AppStrings.averageRating);

  // ════════════════════════════════════════════════════════════════
  //  SECTION: general
  // ════════════════════════════════════════════════════════════════
  static String get loading => _r('general', 'loading', AppStrings.loading);
  static String get error => _r('general', 'error', AppStrings.error);
  static String get retry => _r('general', 'retry', AppStrings.retry);
  static String get cancel => _r('general', 'cancel', AppStrings.cancel);
  static String get save => _r('general', 'save', AppStrings.save);
  static String get delete => _r('general', 'delete', AppStrings.delete);
  static String get edit => _r('general', 'edit', AppStrings.edit);
  static String get share => _r('general', 'share', AppStrings.share);
  static String get report => _r('general', 'report', AppStrings.report);
  static String get block => _r('general', 'block', AppStrings.block);
  static String get confirm => _r('general', 'confirm', AppStrings.confirm);
  static String get yes => _r('general', 'yes', AppStrings.yes);
  static String get no => _r('general', 'no', AppStrings.no);
  static String get ok => _r('general', 'ok', AppStrings.ok);
  static String get done => _r('general', 'done', AppStrings.done);
  static String get next => _r('general', 'next', AppStrings.next);
  static String get back => _r('general', 'back', AppStrings.back);
  static String get skip => _r('general', 'skip', AppStrings.skip);
  static String get seeMore => _r('general', 'seeMore', AppStrings.seeMore);
  static String get seeLess => _r('general', 'seeLess', AppStrings.seeLess);
  static String get hours => _r('general', 'hours', AppStrings.hours);
  static String get minutes => _r('general', 'minutes', AppStrings.minutes);
  static String get ago => _r('general', 'ago', AppStrings.ago);
  static String get today => _r('general', 'today', AppStrings.today);
  static String get yesterday => _r('general', 'yesterday', AppStrings.yesterday);
  static String get updatedAgo => _r('general', 'updatedAgo', AppStrings.updatedAgo);
  static String get hour => _r('general', 'hour', AppStrings.hour);
  static String get achievements => _r('general', 'achievements', AppStrings.achievements);
  static String get close => _r('general', 'close', 'סגור');
  static String get submit => _r('general', 'submit', 'שלחי');
  static String get apply => _r('general', 'apply', 'החילי');
  static String get filter => _r('general', 'filter', 'סינון');
  static String get sort => _r('general', 'sort', 'מיון');
  static String get search_ => _r('general', 'search_', 'חיפוש');
  static String get clear => _r('general', 'clear', 'נקי');
  static String get refresh => _r('general', 'refresh', 'רענן');

  // ════════════════════════════════════════════════════════════════
  //  SECTION: errors
  // ════════════════════════════════════════════════════════════════
  static String get errorGeneral => _r('errors', 'errorGeneral', AppStrings.errorGeneral);
  static String get errorNetwork => _r('errors', 'errorNetwork', AppStrings.errorNetwork);
  static String get errorInvalidEmail => _r('errors', 'errorInvalidEmail', AppStrings.errorInvalidEmail);
  static String get errorInvalidPassword => _r('errors', 'errorInvalidPassword', AppStrings.errorInvalidPassword);
  static String get errorPasswordMismatch => _r('errors', 'errorPasswordMismatch', AppStrings.errorPasswordMismatch);
  static String get errorInvalidPhone => _r('errors', 'errorInvalidPhone', AppStrings.errorInvalidPhone);
  static String get errorRequiredField => _r('errors', 'errorRequiredField', AppStrings.errorRequiredField);

  // ════════════════════════════════════════════════════════════════
  //  SECTION: success
  // ════════════════════════════════════════════════════════════════
  static String get successSaved => _r('success', 'successSaved', AppStrings.successSaved);
  static String get successPosted => _r('success', 'successPosted', AppStrings.successPosted);
  static String get successSent => _r('success', 'successSent', AppStrings.successSent);
  static String get successDeleted => _r('success', 'successDeleted', AppStrings.successDeleted);

  // ════════════════════════════════════════════════════════════════
  //  REGISTRY: for admin UI - section → key → Hebrew label
  // ════════════════════════════════════════════════════════════════
  static const Map<String, Map<String, String>> registry = {
    'app': {
      'appName': 'שם האפליקציה',
      'appNameEnglish': 'שם באנגלית',
      'slogan': 'סלוגן',
      'tagline': 'תגליין',
    },
    'welcome': {
      'welcomeTitle': 'כותרת מסך פתיחה',
      'welcomeSubtitle': 'תת כותרת פתיחה',
      'welcomeDescription': 'תיאור פתיחה',
      'joinFree': 'כפתור הצטרפות',
      'learnMore': 'למדי עוד',
      'alreadyMember': 'כבר יש חשבון',
    },
    'auth': {
      'login': 'התחברות',
      'register': 'הרשמה',
      'loginTitle': 'כותרת התחברות',
      'registerTitle': 'כותרת הרשמה',
      'email': 'אימייל',
      'password': 'סיסמה',
      'confirmPassword': 'אימות סיסמה',
      'phone': 'טלפון',
      'fullName': 'שם מלא',
      'city': 'עיר',
      'forgotPassword': 'שכחת סיסמה',
      'orContinueWith': 'או המשיכי עם',
      'continueWithGoogle': 'המשיכי עם Google',
      'continueWithPhone': 'המשיכי עם טלפון',
      'sendCode': 'שלחי קוד',
      'verifyCode': 'אמתי קוד',
      'resendCode': 'שליחה מחדש',
      'agreeToTerms': 'הסכמה לתנאים',
      'termsOfService': 'תנאי שימוש',
      'and': 'ו',
      'privacyPolicy': 'מדיניות פרטיות',
    },
    'nav': {
      'home': 'בית',
      'search': 'חיפוש',
      'create': 'יצירה',
      'messages': 'הודעות',
      'profile': 'פרופיל',
      'groups': 'קבוצות',
      'conversations': 'שיחות',
      'events': 'אירועים',
      'tools': 'כלים',
    },
    'feed': {
      'feed': 'פיד',
      'hotConversations': 'שיחות חמות',
      'selectedContent': 'תוכן נבחר',
      'questionsAndAnswers': 'שאלות ותשובות',
      'newPost': 'פוסט חדש',
      'whatsOnYourMind': 'מה על הלב',
      'shareWithCommunity': 'שתפי עם הקהילה',
      'addPhoto': 'הוספת תמונה',
      'addVideo': 'הוספת וידאו',
      'createPoll': 'יצירת סקר',
      'askForHelp': 'בקשת עזרה',
      'postAnonymously': 'פרסום אנונימי',
    },
    'tracking': {
      'trackingTools': 'כלי מעקב',
      'trackingDescription': 'תיאור כלי מעקב',
      'feedingTracker': 'מעקב הזנות',
      'sleepTracker': 'מעקב שינה',
      'growthTracker': 'מעקב צמיחה',
      'diaperTracker': 'מעקב חיתולים',
      'milestonesTracker': 'אבני דרך',
      'vaccinations': 'חיסונים',
      'reminders': 'תזכורות',
      'exportData': 'ייצוא נתונים',
      'todaysSummary': 'סיכום היום',
    },
    'events': {
      'eventsAndMeetups': 'כותרת אירועים',
      'eventsDescription': 'תיאור אירועים',
      'searchEvents': 'חיפוש אירועים',
      'all': 'הכל',
      'playMeetups': 'מפגשי משחק',
      'classes': 'חוגים',
      'womensEvenings': 'ערבי נשים',
      'webinars': 'וובינרים',
      'supportGroups': 'קבוצות תמיכה',
      'workshops': 'סדנאות',
      'online': 'מקוון',
      'faceToFace': 'פרונטלי',
      'participate': 'השתתפות',
      'free': 'חינם',
    },
    'chat': {
      'noMessages': 'אין הודעות',
      'startConversation': 'התחלת שיחה',
      'typeMessage': 'כתיבת הודעה',
      'send': 'שליחה',
      'online_': 'מחוברת',
      'offline': 'לא מחוברת',
      'typing': 'מקלידה',
      'seen': 'נקרא',
      'delivered': 'נמסר',
    },
    'profile': {
      'editProfile': 'עריכת פרופיל',
      'myChildren': 'הילדים שלי',
      'myPosts': 'הפוסטים שלי',
      'savedPosts': 'פוסטים שמורים',
      'settings': 'הגדרות',
      'notifications': 'התראות',
      'privacy': 'פרטיות',
      'help': 'עזרה',
      'about': 'אודות',
      'logout': 'התנתקות',
      'deleteAccount': 'מחיקת חשבון',
    },
    'general': {
      'loading': 'טוען',
      'error': 'שגיאה',
      'retry': 'נסי שוב',
      'cancel': 'ביטול',
      'save': 'שמירה',
      'delete': 'מחיקה',
      'edit': 'עריכה',
      'share': 'שיתוף',
      'confirm': 'אישור',
      'yes': 'כן',
      'no': 'לא',
      'ok': 'אוקי',
      'done': 'סיום',
      'next': 'הבא',
      'back': 'חזרה',
      'skip': 'דלגי',
      'close': 'סגור',
      'submit': 'שלחי',
      'apply': 'החילי',
      'filter': 'סינון',
      'sort': 'מיון',
      'search_': 'חיפוש',
      'clear': 'נקי',
      'refresh': 'רענן',
    },
    'errors': {
      'errorGeneral': 'שגיאה כללית',
      'errorNetwork': 'שגיאת רשת',
      'errorInvalidEmail': 'אימייל לא תקין',
      'errorInvalidPassword': 'סיסמה לא תקינה',
      'errorPasswordMismatch': 'סיסמאות לא תואמות',
      'errorInvalidPhone': 'טלפון לא תקין',
      'errorRequiredField': 'שדה חובה',
    },
    'success': {
      'successSaved': 'נשמר בהצלחה',
      'successPosted': 'פורסם בהצלחה',
      'successSent': 'נשלח בהצלחה',
      'successDeleted': 'נמחק בהצלחה',
    },
  };

  /// Section display names for admin UI.
  static const Map<String, String> sectionLabels = {
    'app': 'אפליקציה',
    'welcome': 'מסך פתיחה',
    'auth': 'הרשמה והתחברות',
    'nav': 'ניווט',
    'feed': 'פיד',
    'tracking': 'מעקב',
    'events': 'אירועים',
    'chat': 'צ\'אט',
    'profile': 'פרופיל',
    'general': 'כללי',
    'errors': 'הודעות שגיאה',
    'success': 'הודעות הצלחה',
  };
}
