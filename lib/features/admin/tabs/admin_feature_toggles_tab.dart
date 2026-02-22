import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/models/feature_flag_model.dart';
import 'package:mom_connect/services/feature_flag_service.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

class AdminFeatureTogglesTab extends StatefulWidget {
  const AdminFeatureTogglesTab({super.key});

  @override
  State<AdminFeatureTogglesTab> createState() => _AdminFeatureTogglesTabState();
}

class _AdminFeatureTogglesTabState extends State<AdminFeatureTogglesTab> {
  Map<String, bool> _flags = {};
  Map<String, bool> _moderation = {};
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Initialize feature flag service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeatureFlagService>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final featureFlagService = context.watch<FeatureFlagService>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<Map<String, dynamic>>(
        stream: fs.featureFlagsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_initialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && !_initialized) {
            final data = snapshot.data!;
            _flags = {
              'chat': data['chat'] ?? false,
              'events': data['events'] ?? false,
              'marketplace': data['marketplace'] ?? false,
              'experts': data['experts'] ?? false,
              'tips': data['tips'] ?? false,
              'mood': data['mood'] ?? false,
              'sos': data['sos'] ?? false,
              'gamification': data['gamification'] ?? false,
              'aiChat': data['aiChat'] ?? false,
              'whatsapp': data['whatsapp'] ?? false,
              'album': data['album'] ?? false,
              'tracking': data['tracking'] ?? false,
            };
            _moderation = {
              'requireUserApproval': data['requireUserApproval'] ?? false,
              'autoContentFilter': data['autoContentFilter'] ?? false,
              'profanityFilter': data['profanityFilter'] ?? false,
              'requireEventApproval': data['requireEventApproval'] ?? false,
            };
            _initialized = true;
          }

          return Container(
            color: const Color(0xFFF9F5F4),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- New Feature Flag System Card ---
                  _buildNewFeatureFlagSystemCard(featureFlagService),
                  
                  const SizedBox(height: 16),
                  
                  // --- Legacy Section: App Features ---
                  Container(
                    decoration: AdminWidgets.cardDecor(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'תכונות אפליקציה (Legacy)',
                                style: TextStyle(
                                  fontFamily: 'Heebo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  for (final key in _flags.keys) {
                                    _flags[key] = true;
                                  }
                                });
                              },
                              child: const Text('הפעל הכל', style: TextStyle(fontFamily: 'Heebo', fontSize: 12)),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  for (final key in _flags.keys) {
                                    _flags[key] = false;
                                  }
                                });
                              },
                              child: Text('כבה הכל', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: Colors.red.shade300)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '⚠️ מערכת ה-Legacy תוחלף במערכת החדשה',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AdminWidgets.featureToggle(
                          label: 'צ\'אט',
                          subtitle: 'אפשר צ\'אט בין משתמשות',
                          icon: Icons.chat_rounded,
                          value: _flags['chat'] ?? false,
                          onChanged: (val) {
                            setState(() => _flags['chat'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'אירועים',
                          subtitle: 'אפשר צפייה ויצירת אירועים',
                          icon: Icons.event_rounded,
                          value: _flags['events'] ?? false,
                          onChanged: (val) {
                            setState(() => _flags['events'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'שוק יד שניה',
                          subtitle: 'אפשר מסירות והחלפות',
                          icon: Icons.store_rounded,
                          value: _flags['marketplace'] ?? false,
                          onChanged: (val) {
                            setState(() => _flags['marketplace'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'מומחים',
                          subtitle: 'אפשר גישה למומחים',
                          icon: Icons.school_rounded,
                          value: _flags['experts'] ?? false,
                          onChanged: (val) {
                            setState(() => _flags['experts'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'טיפים',
                          subtitle: 'הצג טיפים ותוכן',
                          icon: Icons.tips_and_updates_rounded,
                          value: _flags['tips'] ?? false,
                          onChanged: (val) {
                            setState(() => _flags['tips'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'מד מצב רוח',
                          subtitle: 'אפשר מעקב מצב רוח',
                          icon: Icons.mood_rounded,
                          value: _flags['mood'] ?? false,
                          onChanged: (val) {
                            setState(() => _flags['mood'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'SOS',
                          subtitle: 'כפתור חירום',
                          icon: Icons.emergency_rounded,
                          value: _flags['sos'] ?? false,
                          onChanged: (val) {
                            setState(() => _flags['sos'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'גיימיפיקציה',
                          subtitle: 'נקודות ותגים',
                          icon: Icons.emoji_events_rounded,
                          value: _flags['gamification'] ?? false,
                          onChanged: (val) {
                            setState(() => _flags['gamification'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'צ\'אט AI',
                          subtitle: 'עוזרת AI חכמה',
                          icon: Icons.smart_toy_rounded,
                          value: _flags['aiChat'] ?? false,
                          onChanged: (val) {
                            setState(() => _flags['aiChat'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'WhatsApp',
                          subtitle: 'קישור לקבוצת WhatsApp',
                          icon: Icons.message_rounded,
                          value: _flags['whatsapp'] ?? false,
                          onChanged: (val) {
                            setState(() => _flags['whatsapp'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'אלבום',
                          subtitle: 'אלבום תמונות',
                          icon: Icons.photo_album_rounded,
                          value: _flags['album'] ?? false,
                          onChanged: (val) {
                            setState(() => _flags['album'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'מעקב',
                          subtitle: 'מעקב התפתחות',
                          icon: Icons.track_changes_rounded,
                          value: _flags['tracking'] ?? false,
                          onChanged: (val) {
                            setState(() => _flags['tracking'] = val);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Section: Moderation Settings ---
                  Container(
                    decoration: AdminWidgets.cardDecor(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'הגדרות מודרציה',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AdminWidgets.featureToggle(
                          label: 'אישור משתמשות',
                          subtitle: 'דרוש אישור מנהלת לרישום',
                          icon: Icons.verified_user_rounded,
                          value: _moderation['requireUserApproval'] ?? false,
                          onChanged: (val) {
                            setState(
                                () => _moderation['requireUserApproval'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'סינון תוכן אוטומטי',
                          subtitle: 'סנן תוכן לא הולם',
                          icon: Icons.filter_alt_rounded,
                          value: _moderation['autoContentFilter'] ?? false,
                          onChanged: (val) {
                            setState(
                                () => _moderation['autoContentFilter'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'פילטר ניבולי פה',
                          subtitle: 'חסום ניבולי פה בצ\'אט',
                          icon: Icons.block_rounded,
                          value: _moderation['profanityFilter'] ?? false,
                          onChanged: (val) {
                            setState(
                                () => _moderation['profanityFilter'] = val);
                          },
                        ),
                        AdminWidgets.featureToggle(
                          label: 'אישור אירועים',
                          subtitle: 'דרוש אישור מנהלת לאירועים',
                          icon: Icons.event_available_rounded,
                          value: _moderation['requireEventApproval'] ?? false,
                          onChanged: (val) {
                            setState(() =>
                                _moderation['requireEventApproval'] = val);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Save Button ---
                  AdminWidgets.saveButton(
                    loading: _saving,
                    onPressed: () async {
                      setState(() => _saving = true);
                      try {
                        final merged = <String, dynamic>{
                          ..._flags,
                          ..._moderation,
                        };
                        await fs.updateFeatureFlags(merged);
                        await fs.logActivity(
                          action: 'עדכון תכונות',
                          user: AdminWidgets.adminName(context),
                          type: 'config',
                        );
                        if (mounted) {
                          AdminWidgets.snack(context, 'התכונות עודכנו!');
                          setState(() => _initialized = false);
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _saving = false);
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewFeatureFlagSystemCard(FeatureFlagService service) {
    return Container(
      decoration: AdminWidgets.cardDecor(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'מערכת Feature Flags חדשה',
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ניהול מתקדם של תכונות האפליקציה',
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (service.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Feature flag list
          ...FeatureFlagIds.all.map((flagId) {
            final flag = service.getFlag(flagId);
            if (flag == null) return const SizedBox.shrink();
            
            return _buildFeatureFlagItem(service, flag);
          }),
          
          const SizedBox(height: 16),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await service.seedInitialFlags();
                    if (mounted) {
                      AdminWidgets.snack(context, 'דגלים ראשוניים נוצרו!');
                    }
                  },
                  icon: const Icon(Icons.playlist_add_rounded, size: 18),
                  label: const Text(
                    'יצירת דגלים ראשוניים',
                    style: TextStyle(fontFamily: 'Heebo', fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await service.resetToDefaults();
                    if (mounted) {
                      AdminWidgets.snack(context, 'אופס לברירת מחדל!');
                    }
                  },
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text(
                    'איפוס לברירת מחדל',
                    style: TextStyle(fontFamily: 'Heebo', fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await service.refresh();
                    if (mounted) {
                      AdminWidgets.snack(context, 'רענון הושלם!');
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'רענון',
                    style: TextStyle(fontFamily: 'Heebo', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureFlagItem(FeatureFlagService service, FeatureFlag flag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: flag.enabled 
              ? Colors.green.withValues(alpha: 0.3) 
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: flag.enabled ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          
          // Flag info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flag.name,
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  flag.description,
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (flag.rolloutPercentage < 100)
                  Text(
                    'Rollout: ${flag.rolloutPercentage}%',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 10,
                      color: Colors.blue.shade600,
                    ),
                  ),
              ],
            ),
          ),
          
          // Toggle switch
          Switch.adaptive(
            value: flag.enabled,
            onChanged: (value) async {
              try {
                await service.toggleFlag(flag.id);
                if (mounted) {
                  AdminWidgets.snack(
                    context, 
                    '${flag.name} ${value ? "הופעל" : "כובה"}',
                  );
                }
              } catch (e) {
                if (mounted) {
                  AdminWidgets.snack(context, 'שגיאה: $e');
                }
              }
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
