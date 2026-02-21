import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mom_connect/core/constants/app_colors.dart';

/// מסך SOS חירום - עזרה מיידית מהקהילה
class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _sosActive = false;
  int _respondersCount = 0;
  Timer? _responseTimer;

  final List<Map<String, dynamic>> _sosCategories = [
    {'icon': Icons.medical_services, 'label': 'חירום רפואי', 'color': AppColors.error, 'desc': 'מצב רפואי דחוף לתינוק/ילד'},
    {'icon': Icons.psychology, 'label': 'משבר רגשי', 'color': Color(0xFFD1C2D3), 'desc': 'מרגישה מוצפת ומחפשת אוזן קשבת'},
    {'icon': Icons.child_care, 'label': 'צריכה שמרטפית דחוף', 'color': AppColors.accent, 'desc': 'חייבת מישהי עכשיו לשמור על הילדים'},
    {'icon': Icons.directions_car, 'label': 'צריכה הסעה', 'color': AppColors.info, 'desc': 'צריכה להגיע דחוף למקום'},
    {'icon': Icons.shopping_basket, 'label': 'חסר לי משהו דחוף', 'color': AppColors.success, 'desc': 'חסרה לי חיתול/פורמולה/תרופה'},
    {'icon': Icons.help_outline, 'label': 'עזרה אחרת', 'color': AppColors.primary, 'desc': 'כל בקשה אחרת שדורשת עזרה מיידית'},
  ];

  final List<Map<String, dynamic>> _nearbyHelpers = [
    {'name': 'מיכל לוי', 'distance': '200 מטר', 'rating': 4.9, 'responses': 23},
    {'name': 'יעל כהן', 'distance': '350 מטר', 'rating': 4.8, 'responses': 15},
    {'name': 'נועה שמש', 'distance': '500 מטר', 'rating': 5.0, 'responses': 31},
    {'name': 'דנה אברהם', 'distance': '700 מטר', 'rating': 4.7, 'responses': 8},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _responseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sosActive ? AppColors.error.withValues(alpha: 0.05) : Colors.white,
      appBar: AppBar(
        backgroundColor: _sosActive ? AppColors.error : Colors.white,
        foregroundColor: _sosActive ? Colors.white : AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _sosActive ? 'SOS פעיל' : 'עזרה מהקהילה',
          style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_sosActive)
            TextButton(
              onPressed: _cancelSOS,
              child: const Text('בטלי', style: TextStyle(fontFamily: 'Heebo', color: Colors.white)),
            ),
          IconButton(
            icon: Icon(Icons.home_outlined, color: _sosActive ? Colors.white70 : AppColors.textSecondary),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: 'מסך ראשי',
          ),
        ],
      ),
      body: _sosActive ? _buildActiveSOSView() : _buildSOSCategories(),
    );
  }

  Widget _buildSOSCategories() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.error.withValues(alpha: 0.1), AppColors.secondary.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.3 + _pulseController.value * 0.3),
                            blurRadius: 15 + _pulseController.value * 10,
                            spreadRadius: _pulseController.value * 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.sos, color: Colors.white, size: 40),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'צריכה עזרה? הקהילה כאן בשבילך!',
                  style: TextStyle(fontFamily: 'Heebo', fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_nearbyHelpers.length} אמהות באזורך זמינות עכשיו',
                  style: TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Categories
          const Text('במה צריכה עזרה?', style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...(_sosCategories.map((cat) {
            return GestureDetector(
              onTap: () => _showSOSConfirmation(cat),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (cat['color'] as Color).withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (cat['color'] as Color).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat['label'], style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(cat['desc'], style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
                  ],
                ),
              ),
            );
          })),
          const SizedBox(height: 24),

          // Emergency contacts
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('קווי חירום', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildEmergencyContact('מד"א', '101', Icons.local_hospital),
                _buildEmergencyContact('ער"ן - עזרה ראשונה נפשית', '*2784', Icons.psychology),
                _buildEmergencyContact('נט"ל - קו חם לילדים', '*6581', Icons.child_care),
                _buildEmergencyContact('משטרה', '100', Icons.local_police),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(String name, String number, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontFamily: 'Heebo', fontSize: 14))),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('מתקשר ל-$number', style: const TextStyle(fontFamily: 'Heebo')),
                  backgroundColor: AppColors.info,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, size: 14, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(number, style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: AppColors.info, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSOSView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Active SOS
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.1), blurRadius: 15)],
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.4 + _pulseController.value * 0.3),
                            blurRadius: 20 + _pulseController.value * 15,
                            spreadRadius: _pulseController.value * 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.sos, color: Colors.white, size: 50),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'בקשת העזרה שלך נשלחה!',
                  style: TextStyle(fontFamily: 'Heebo', fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'שלחנו התראה ל-${_nearbyHelpers.length} אמהות באזורך',
                  style: TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        '$_respondersCount אמהות הגיבו',
                        style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Nearby helpers responding
          const Align(
            alignment: Alignment.centerRight,
            child: Text('מגיבות באזורך', style: TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          ...(_nearbyHelpers.take(_respondersCount).map((helper) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(helper['name'].toString().substring(0, 1),
                      style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(helper['name'], style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: AppColors.textHint),
                            Text(' ${helper['distance']}', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                            const SizedBox(width: 10),
                            Icon(Icons.star, size: 14, color: AppColors.accent),
                            Text(' ${helper['rating']}', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('צ\'אט', style: TextStyle(fontFamily: 'Heebo', color: Colors.white)),
                  ),
                ],
              ),
            );
          })),
        ],
      ),
    );
  }

  void _showSOSConfirmation(Map<String, dynamic> category) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(category['icon'] as IconData, color: category['color'] as Color),
            const SizedBox(width: 10),
            Expanded(child: Text(category['label'], style: const TextStyle(fontFamily: 'Heebo'))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 3,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Heebo'),
              decoration: InputDecoration(
                hintText: 'ספרי בקצרה מה קורה...',
                hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.success),
                const SizedBox(width: 4),
                Text('המיקום שלך ישותף אוטומטית', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _activateSOS();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('שלחי SOS', style: TextStyle(fontFamily: 'Heebo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _activateSOS() {
    HapticFeedback.heavyImpact();
    setState(() {
      _sosActive = true;
      _respondersCount = 0;
    });

    // Simulate responses coming in
    _responseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _respondersCount < _nearbyHelpers.length) {
        HapticFeedback.mediumImpact();
        setState(() => _respondersCount++);
      } else {
        timer.cancel();
      }
    });
  }

  void _cancelSOS() {
    _responseTimer?.cancel();
    setState(() {
      _sosActive = false;
      _respondersCount = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('בקשת ה-SOS בוטלה', style: TextStyle(fontFamily: 'Heebo')),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
