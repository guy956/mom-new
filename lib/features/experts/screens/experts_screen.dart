import 'package:flutter/material.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mom_connect/services/notification_service.dart';

/// מסך מומחים - Real-time from Firestore
class ExpertsScreen extends StatefulWidget {
  const ExpertsScreen({super.key});

  @override
  State<ExpertsScreen> createState() => _ExpertsScreenState();
}

class _ExpertsScreenState extends State<ExpertsScreen> {
  String _selectedCategory = 'הכל';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'חזרה',
        ),
        title: const Text('מומחים מאומתים', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.textSecondary),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: 'מסך ראשי',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(fs),
          _buildCategoryFilter(),
          Expanded(
            child: StreamBuilder<List<dynamic>>(
              stream: fs.expertsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final allExperts = snapshot.data ?? [];
                // Only show approved experts to users
                final approved = allExperts.where((e) {
                  final status = (e['status'] ?? 'approved').toString();
                  return status == 'approved';
                }).toList();
                // Filter by category
                final filtered = _selectedCategory == 'הכל'
                    ? approved
                    : approved.where((e) => (e['category'] ?? '') == _selectedCategory).toList();
                // Filter by search
                final results = _searchQuery.isEmpty
                    ? filtered
                    : filtered.where((e) {
                        final name = (e['name'] ?? '').toString().toLowerCase();
                        final cat = (e['category'] ?? '').toString().toLowerCase();
                        final bio = (e['bio'] ?? '').toString().toLowerCase();
                        final q = _searchQuery.toLowerCase();
                        return name.contains(q) || cat.contains(q) || bio.contains(q);
                      }).toList();

                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.medical_services_outlined, size: 60, color: AppColors.textHint.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('אין מומחים זמינים כרגע', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, color: AppColors.textHint)),
                        if (_selectedCategory != 'הכל' || _searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() { _selectedCategory = 'הכל'; _searchQuery = ''; }),
                            child: const Text('הצגי הכל', style: TextStyle(fontFamily: 'Heebo')),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) => _buildExpertCard(Map<String, dynamic>.from(results[index])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(FirestoreService fs) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Heebo'),
            decoration: InputDecoration(
              hintText: 'חפשי מומחה...',
              hintStyle: TextStyle(fontFamily: 'Heebo', color: AppColors.textHint),
              prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<dynamic>>(
            stream: fs.expertsStream,
            builder: (context, snapshot) {
              final experts = (snapshot.data ?? []).where((e) => (e['status'] ?? '') == 'approved').toList();
              final count = experts.length;
              double avgRating = 0;
              if (experts.isNotEmpty) {
                double total = 0;
                int rated = 0;
                for (final e in experts) {
                  final r = (e['rating'] as num?)?.toDouble() ?? 0;
                  if (r > 0) { total += r; rated++; }
                }
                avgRating = rated > 0 ? total / rated : 0;
              }
              return Row(
                children: [
                  _buildQuickStatIcon(Icons.medical_services_outlined, '$count', 'מומחים'),
                  const SizedBox(width: 10),
                  _buildQuickStatIcon(Icons.star_outline_rounded, avgRating > 0 ? avgRating.toStringAsFixed(1) : '-', 'דירוג ממוצע'),
                  const SizedBox(width: 10),
                  _buildQuickStatIcon(Icons.verified_outlined, '100%', 'מאומתים'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatIcon(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(value, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Text(label, style: TextStyle(fontFamily: 'Heebo', fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<AppState>(builder: (_, appState, __) {
      final categories = ['הכל', ...appState.expertCategories];
      return SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                ),
                child: Center(
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontFamily: 'Heebo', fontSize: 13,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildExpertCard(Map<String, dynamic> expert) {
    final name = expert['name'] ?? '';
    final category = expert['category'] ?? '';
    final bio = expert['bio'] ?? '';
    final phone = expert['phone'] ?? '';
    final email = expert['email'] ?? '';
    final rating = (expert['rating'] as num?)?.toDouble() ?? 0;
    final consultations = (expert['consultations'] as num?)?.toInt() ?? 0;
    final queues = (expert['queues'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: (expert['imageUrl'] ?? expert['photoUrl'] ?? '').toString().isNotEmpty
                    ? NetworkImage((expert['imageUrl'] ?? expert['photoUrl']).toString())
                    : null,
                child: (expert['imageUrl'] ?? expert['photoUrl'] ?? '').toString().isEmpty
                    ? const Icon(Icons.person, color: AppColors.primary, size: 30)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 12, color: AppColors.success),
                              SizedBox(width: 2),
                              Text('מאומת', style: TextStyle(fontFamily: 'Heebo', fontSize: 10, color: AppColors.success)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(category, style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (rating > 0) ...[
                          const Icon(Icons.star, size: 14, color: AppColors.accent),
                          Text(' ${rating.toStringAsFixed(1)}', style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(' ($consultations ייעוצים)', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textHint)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(bio, style: TextStyle(fontFamily: 'Heebo', fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (queues > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline, size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text('$queues בתור', style: const TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const Spacer(),
              if (phone.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                  onPressed: () async {
                    try {
                      final success = await launchUrl(Uri.parse('tel:$phone'));
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('לא ניתן לחייג ל-$phone')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('שגיאה בחיוג ל-$phone')),
                        );
                      }
                    }
                  },
                  tooltip: 'התקשר',
                ),
              if (email.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                  onPressed: () async {
                    try {
                      final success = await launchUrl(Uri.parse('mailto:$email'));
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('לא ניתן לשלוח מייל ל-$email')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('שגיאה בשליחת מייל ל-$email')),
                        );
                      }
                    }
                  },
                  tooltip: 'שלח אימייל',
                ),
              ElevatedButton(
                onPressed: () => _showBookingSheet(expert),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('קבעי תור', style: TextStyle(fontFamily: 'Heebo', color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBookingSheet(Map<String, dynamic> expert) {
    int selectedDateIndex = 0;
    String selectedTime = '15:00';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Center(child: Text('קביעת תור עם ${expert['name']}', style: const TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            const Text('בחרי תאריך:', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(7, (i) {
                  final date = DateTime.now().add(Duration(days: i));
                  final isSelected = i == selectedDateIndex;
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() => selectedDateIndex = i);
                    },
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'][date.weekday % 7],
                            style: TextStyle(fontFamily: 'Heebo', color: isSelected ? Colors.white : AppColors.textHint, fontSize: 12),
                          ),
                          Text(
                            '${date.day}',
                            style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 20, color: isSelected ? Colors.white : AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            const Text('בחרי שעה:', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00', '18:00'].map((time) {
                return GestureDetector(
                  onTap: () {
                    setSheetState(() => selectedTime = time);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: time == selectedTime ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        color: time == selectedTime ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final date = DateTime.now().add(Duration(days: selectedDateIndex));
                  final appState = Provider.of<AppState>(context, listen: false);
                  final fs = Provider.of<FirestoreService>(context, listen: false);
                  final currentUser = appState.currentUser;

                  if (currentUser == null || currentUser.id.isEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('יש להתחבר כדי לקבוע תור', style: TextStyle(fontFamily: 'Heebo')),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  try {
                    final bookingData = {
                      'userId': currentUser.id,
                      'userName': currentUser.fullName,
                      'expertId': expert['id'] ?? '',
                      'expertName': expert['name'] ?? '',
                      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                      'time': selectedTime,
                      'creatorName': currentUser.fullName,
                      'creatorEmail': currentUser.email,
                      'creatorPhone': currentUser.phone ?? '',
                    };
                    await fs.createBooking(bookingData);

                    // Send automatic email notification to admin
                    NotificationService().notifyAdminNewContent(
                      type: 'expert',
                      content: bookingData,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('בקשת תור נשלחה ל${expert['name']} ב-${date.day}/${date.month} בשעה $selectedTime', style: const TextStyle(fontFamily: 'Heebo')),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('שגיאה בקביעת תור: $e', style: const TextStyle(fontFamily: 'Heebo')),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('אישור קביעת תור', style: TextStyle(fontFamily: 'Heebo', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
