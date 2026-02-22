// ═══════════════════════════════════════════════════════════════
// MOMIT - Barrel Exports File
// All public-facing modules for the MOMIT app
// ═══════════════════════════════════════════════════════════════

// ──── Core ────
export 'core/constants/app_colors.dart';
export 'core/constants/app_strings.dart';
export 'core/constants/color_config.dart';
export 'core/constants/text_config.dart';
export 'core/theme/app_theme.dart';
export 'core/widgets/common_widgets.dart';

// ──── Widgets ────
export 'widgets/dynamic_content.dart';
export 'widgets/feature_flag_widgets.dart';

// ──── Providers ────
export 'providers/theme_provider.dart';

// ──── Middleware ────
export 'middleware/rate_limiter.dart';

// ──── Models ────
export 'models/chat_model.dart';
export 'models/event_model.dart';
export 'models/feature_flag_model.dart';
export 'models/notification_model.dart';
export 'models/post_model.dart';
export 'models/product_model.dart';
export 'models/tracking_models.dart';
export 'models/user_model.dart';

// ──── Services ────
export 'services/accessibility_service.dart';
export 'services/app_config_provider.dart';
export 'services/app_router.dart';
export 'services/app_state.dart';
export 'services/audit_log_service.dart';
export 'services/auth_service.dart';
export 'services/dynamic_config_service.dart';
export 'services/feature_flag_service.dart';
export 'services/firestore_service.dart';
export 'services/rbac_service.dart';
export 'services/secure_api_client.dart';
export 'services/secure_cookie_manager.dart';
export 'services/tracking_service.dart';

// ──── Utils ────
export 'utils/random_utils.dart';

// ──── Firebase ────
export 'firebase_options.dart';

// ──── Feature: Auth ────
export 'features/auth/screens/welcome_screen.dart';
export 'features/auth/screens/login_screen.dart';
export 'features/auth/screens/register_screen.dart';
export 'features/auth/screens/intro_splash_screen.dart';

// ──── Feature: Home ────
export 'features/home/screens/main_screen.dart';

// ──── Feature: Feed ────
export 'features/feed/screens/feed_screen.dart';
export 'features/feed/screens/create_post_screen.dart';

// ──── Feature: Tracking ────
export 'features/tracking/screens/tracking_screen.dart';

// ──── Feature: Events ────
export 'features/events/screens/events_screen.dart';

// ──── Feature: Chat ────
export 'features/chat/screens/chat_screen.dart';

// ──── Feature: Profile ────
export 'features/profile/screens/profile_screen.dart';

// ──── Feature: AI Chat ────
export 'features/ai_chat/screens/ai_chat_screen.dart';

// ──── Feature: SOS ────
export 'features/sos/screens/sos_screen.dart';

// ──── Feature: Daily Tips ────
export 'features/tips/screens/daily_tips_screen.dart';

// ──── Feature: Mood Tracker ────
export 'features/mood/screens/mood_tracker_screen.dart';

// ──── Feature: Experts ────
export 'features/experts/screens/experts_screen.dart';

// ──── Feature: WhatsApp Integration ────
export 'features/whatsapp/screens/whatsapp_screen.dart';

// ──── Feature: Gamification ────
export 'features/gamification/screens/gamification_screen.dart';

// ──── Feature: Marketplace ────
export 'features/marketplace/screens/marketplace_screen.dart';

// ──── Feature: Admin ────
export 'features/admin/screens/admin_dashboard_screen.dart';
export 'features/admin/widgets/admin_shared_widgets.dart';
export 'features/admin/widgets/content_editor.dart';
export 'features/admin/widgets/navigation_editor.dart';
export 'features/admin/widgets/role_assignment_widget.dart';
export 'features/admin/widgets/section_editor.dart';
export 'features/admin/tabs/admin_overview_tab.dart';
export 'features/admin/tabs/admin_users_tab.dart';
export 'features/admin/tabs/admin_experts_tab.dart';
export 'features/admin/tabs/admin_media_vault_tab.dart';
export 'features/admin/tabs/admin_events_tab.dart';
export 'features/admin/tabs/admin_marketplace_tab.dart';
export 'features/admin/tabs/admin_content_tips_tab.dart';
export 'features/admin/tabs/admin_reports_tab.dart';
export 'features/admin/tabs/admin_app_config_tab.dart';
export 'features/admin/tabs/admin_audit_log_tab.dart';
export 'features/admin/tabs/admin_communication_tab.dart';
export 'features/admin/tabs/admin_dynamic_forms_tab.dart';
export 'features/admin/tabs/admin_dynamic_sections_tab.dart';
export 'features/admin/tabs/admin_feature_toggles_tab.dart';
export 'features/admin/tabs/admin_ui_design_tab.dart';
export 'features/admin/tabs/admin_content_manager_tab.dart';
export 'features/admin/tabs/admin_navigation_editor_tab.dart';

// ──── Feature: Legal ────
export 'features/legal/screens/legal_screen.dart';

// ──── Feature: Accessibility ────
export 'features/accessibility/screens/accessibility_screen.dart';

// ──── Feature: Notifications ────
export 'features/notifications/screens/notifications_screen.dart';

// ──── Feature: Photo Album ────
export 'features/album/screens/photo_album_screen.dart';
