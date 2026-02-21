import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

class AdminExpertsTab extends StatefulWidget {
  const AdminExpertsTab({super.key});

  @override
  State<AdminExpertsTab> createState() => _AdminExpertsTabState();
}

class _AdminExpertsTabState extends State<AdminExpertsTab> {
  String _selectedFilter = 'הכל';

  final List<String> _filters = ['הכל', 'מאושר', 'ממתין', 'נדחה'];

  final Map<String, String> _filterToStatus = {
    'הכל': 'all',
    'מאושר': 'approved',
    'ממתין': 'pending',
    'נדחה': 'rejected',
  };

  static const List<String> _fallbackCategories = [
    'רופאת ילדים',
    'יועצת שינה',
    'יועצת הנקה',
    'דיאטנית',
    'פסיכולוגית',
    'מטפלת רגשית',
    'פיזיותרפיסטית',
    'אחר',
  ];

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<Map<String, dynamic>>(
        stream: fs.uiConfigStream,
        builder: (context, uiSnap) {
          final uiConfig = uiSnap.data ?? {};
          final dynamicCategories = (uiConfig['expertCategories'] as List<dynamic>?)
              ?.map((e) => e.toString()).toList() ?? _fallbackCategories;

          return Container(
            color: const Color(0xFFF9F5F4),
            child: Column(
              children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ניהול מומחים',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FloatingActionButton.small(
                    onPressed: () => _showExpertDialog(context, fs, categoryOptions: dynamicCategories),
                    backgroundColor: const Color(0xFFD1C2D3),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFFD1C2D3),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Expert cards list
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: fs.expertsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'שגיאה בטעינת מומחים',
                        style: const TextStyle(fontFamily: 'Heebo'),
                      ),
                    );
                  }

                  final experts = snapshot.data ?? [];

                  // Apply filter
                  final filteredExperts = _selectedFilter == 'הכל'
                      ? experts
                      : experts.where((expert) {
                          final status = expert['status'] as String? ?? '';
                          return status == _filterToStatus[_selectedFilter];
                        }).toList();

                  if (filteredExperts.isEmpty) {
                    return Center(
                      child: Text(
                        'אין מומחים להצגה',
                        style: const TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredExperts.length,
                    itemBuilder: (context, index) {
                      final expert = filteredExperts[index];
                      final id = expert['id'] as String? ?? '';
                      return _buildExpertCard(context, fs, expert, id, dynamicCategories);
                    },
                  );
                },
              ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  Widget _buildExpertCard(
    BuildContext context,
    FirestoreService fs,
    Map<String, dynamic> expert,
    String id,
    List<String> categoryOptions,
  ) {
    final name = expert['name'] as String? ?? '';
    final category = expert['category'] as String? ?? '';
    final phone = expert['phone'] as String? ?? '';
    final email = expert['email'] as String? ?? '';
    final rating = (expert['rating'] as num?)?.toDouble() ?? 0.0;
    final consultations = expert['consultations'] as int? ?? 0;
    final queues = expert['queues'] as int? ?? 0;
    final status = expert['status'] as String? ?? 'pending';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + info + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFD1C2D3),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: const TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                AdminWidgets.statusChip(status),
              ],
            ),
            const SizedBox(height: 12),

            // Contact info
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.email, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Rating + Consultations
            Row(
              children: [
                _buildRatingStars(rating),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '$consultations ייעוצים',
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.queue,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '$queues בתור',
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Queue management row
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.queue_rounded, size: 18, color: Color(0xFFD1C2D3)),
                  const SizedBox(width: 8),
                  const Text('תור ייעוץ:', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                    color: Colors.red.shade300,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: queues > 0 ? () async {
                      await fs.updateExpert(id, {'queues': queues - 1});
                      await fs.logActivity(action: 'הפחתת תור למומחה: $name', user: 'admin', type: 'expert');
                    } : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$queues', style: const TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    color: const Color(0xFFB5C8B9),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      await fs.updateExpert(id, {'queues': queues + 1});
                      await fs.logActivity(action: 'הוספת תור למומחה: $name', user: 'admin', type: 'expert');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'pending') ...[
                  TextButton.icon(
                    onPressed: () async {
                      await fs.updateExpertStatus(id, 'approved');
                      await fs.logActivity(action: 'אישור מומחה: $name', user: 'admin', type: 'expert');
                      if (context.mounted) AdminWidgets.snack(context, 'המומחה אושר');
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'אשר',
                      style: TextStyle(fontFamily: 'Heebo'),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () async {
                      await fs.updateExpertStatus(id, 'rejected');
                      await fs.logActivity(action: 'דחיית מומחה: $name', user: 'admin', type: 'expert');
                      if (context.mounted) AdminWidgets.snack(context, 'המומחה נדחה');
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text(
                      'דחה',
                      style: TextStyle(fontFamily: 'Heebo'),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  onPressed: () =>
                      _showExpertDialog(context, fs, expert: expert, id: id, categoryOptions: categoryOptions),
                  icon: const Icon(Icons.edit, size: 20),
                  color: Colors.blueGrey,
                  tooltip: 'ערוך',
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context, fs, id, name),
                  icon: const Icon(Icons.delete, size: 20),
                  color: Colors.red.shade300,
                  tooltip: 'מחק',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, size: 18, color: Colors.amber);
        } else if (index < rating) {
          return const Icon(Icons.star_half, size: 18, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, size: 18, color: Colors.amber);
        }
      }),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FirestoreService fs,
    String id,
    String name,
  ) async {
    final confirmed = await AdminWidgets.confirmDelete(context, name);

    if (confirmed == true) {
      await fs.deleteExpert(id);
      await fs.logActivity(action: 'מחיקת מומחה: $name', user: 'admin', type: 'expert');
      if (context.mounted) AdminWidgets.snack(context, 'המומחה נמחק');
    }
  }

  void _showExpertDialog(
    BuildContext context,
    FirestoreService fs, {
    Map<String, dynamic>? expert,
    String? id,
    List<String>? categoryOptions,
  }) {
    final categories = categoryOptions ?? _fallbackCategories;
    final isEditing = expert != null;
    final nameController =
        TextEditingController(text: expert?['name'] as String? ?? '');
    final phoneController =
        TextEditingController(text: expert?['phone'] as String? ?? '');
    final emailController =
        TextEditingController(text: expert?['email'] as String? ?? '');
    final bioController =
        TextEditingController(text: expert?['bio'] as String? ?? '');
    final otherCategoryController = TextEditingController();

    // Check if the existing category is a custom one
    String existingCat = expert?['category'] as String? ?? categories.first;
    bool isOtherCategory = !categories.contains(existingCat) && existingCat.isNotEmpty;
    String selectedCategory = isOtherCategory ? 'אחר' : existingCat;
    if (isOtherCategory) {
      otherCategoryController.text = existingCat;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  isEditing ? 'עריכת מומחה' : 'הוספת מומחה',
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'שם',
                          labelStyle: const TextStyle(fontFamily: 'Heebo'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Heebo'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'קטגוריה',
                          labelStyle: const TextStyle(fontFamily: 'Heebo'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Heebo',
                          color: Colors.black87,
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(
                              cat,
                              style: const TextStyle(fontFamily: 'Heebo'),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                      if (selectedCategory == 'אחר') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: otherCategoryController,
                          decoration: InputDecoration(
                            labelText: 'פרט קטגוריה',
                            labelStyle: const TextStyle(fontFamily: 'Heebo'),
                            hintText: 'לדוגמה: מרפאה בעיסוק',
                            hintStyle: TextStyle(fontFamily: 'Heebo', color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'Heebo'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: 'טלפון',
                          labelStyle: const TextStyle(fontFamily: 'Heebo'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Heebo'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'אימייל',
                          labelStyle: const TextStyle(fontFamily: 'Heebo'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Heebo'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: bioController,
                        decoration: InputDecoration(
                          labelText: 'ביוגרפיה',
                          labelStyle: const TextStyle(fontFamily: 'Heebo'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Heebo'),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text(
                      'ביטול',
                      style: TextStyle(fontFamily: 'Heebo', color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final categoryValue = selectedCategory == 'אחר' && otherCategoryController.text.trim().isNotEmpty
                          ? otherCategoryController.text.trim()
                          : selectedCategory;
                      final data = {
                        'name': nameController.text.trim(),
                        'category': categoryValue,
                        'phone': phoneController.text.trim(),
                        'email': emailController.text.trim(),
                        'bio': bioController.text.trim(),
                      };

                      if (data['name']!.isEmpty) return;

                      if (isEditing && id != null) {
                        await fs.updateExpert(id, data);
                        await fs.logActivity(
                            action: 'עריכת מומחה: ${data['name']}', user: 'admin', type: 'expert');
                      } else {
                        await fs.addExpert(data);
                        await fs.logActivity(
                            action: 'הוספת מומחה: ${data['name']}', user: 'admin', type: 'expert');
                      }

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                        AdminWidgets.snack(context, isEditing ? 'המומחה עודכן' : 'המומחה נוסף');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD1C2D3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'עדכן' : 'הוסף',
                      style: const TextStyle(fontFamily: 'Heebo'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
