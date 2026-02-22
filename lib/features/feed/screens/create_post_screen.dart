import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/notification_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String? initialType;

  const CreatePostScreen({super.key, this.initialType});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedCategory = 'general';
  bool _isAnonymous = false;
  final List<String> _selectedImages = [];
  final List<String> _tags = [];

  // Poll data
  bool _isPoll = false;
  final TextEditingController _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptions = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    _isPoll = widget.initialType == 'poll';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    _pollQuestionController.dispose();
    for (var controller in _pollOptions) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserHeader(),
            _buildContentInput(),
            if (_isPoll) _buildPollSection(),
            if (_selectedImages.isNotEmpty) _buildImagePreview(),
            _buildOptions(),
            _buildCategorySelector(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded),
        color: AppColors.textPrimary,
      ),
      title: Text(
        _isPoll ? 'סקר חדש' : 'פוסט חדש',
        style: const TextStyle(
          fontFamily: 'Heebo',
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: ElevatedButton(
            onPressed: _contentController.text.isNotEmpty || _isPoll ? _publishPost : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.surfaceVariant,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'פרסום',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              final user = context.read<AppState>().currentUser;
              final userName = user?.fullName ?? 'משתמשת';
              final initial = userName.isNotEmpty ? userName[0] : 'M';
              return CircleAvatar(
                radius: 24,
                backgroundColor: _isAnonymous ? AppColors.surfaceVariant : AppColors.primary.withValues(alpha: 0.15),
                child: _isAnonymous
                    ? const Icon(Icons.person, color: AppColors.textHint)
                    : Text(initial, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final user = context.read<AppState>().currentUser;
                    return Text(
                      _isAnonymous ? 'אנונימית' : (user?.fullName ?? 'משתמשת'),
                      style: const TextStyle(
                        fontFamily: 'Heebo',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () => setState(() => _isAnonymous = !_isAnonymous),
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isAnonymous
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isAnonymous ? Icons.visibility_off : Icons.public,
                          size: 14,
                          color: _isAnonymous ? AppColors.primary : AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isAnonymous ? 'פרסום אנונימי' : 'ציבורי',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 12,
                            color: _isAnonymous ? AppColors.primary : AppColors.textHint,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: _isAnonymous ? AppColors.primary : AppColors.textHint,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _contentController,
            focusNode: _focusNode,
            maxLines: null,
            minLines: 5,
            style: const TextStyle(
              fontFamily: 'Heebo',
              fontSize: 16,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: _isPoll
                  ? 'ספרי קצת על הסקר...'
                  : 'מה על הלב? שתפי את הקהילה...',
              hintStyle: TextStyle(
                fontFamily: 'Heebo',
                color: AppColors.textHint,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'פרטי קשר נשמרים למנהלת בלבד',
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'שאלת הסקר:',
            style: TextStyle(
              fontFamily: 'Heebo',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pollQuestionController,
            style: const TextStyle(fontFamily: 'Heebo'),
            decoration: InputDecoration(
              hintText: 'מה תרצי לשאול?',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'אפשרויות תשובה:',
            style: TextStyle(
              fontFamily: 'Heebo',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ..._pollOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(fontFamily: 'Heebo'),
                      decoration: InputDecoration(
                        hintText: 'אפשרות ${index + 1}',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  if (_pollOptions.length > 2)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _pollOptions.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.error,
                    ),
                ],
              ),
            );
          }),
          if (_pollOptions.length < 6)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _pollOptions.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                'הוספת אפשרות',
                style: TextStyle(fontFamily: 'Heebo'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _selectedImages[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImages.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildOptionChip(
            icon: Icons.camera_alt_outlined,
            label: 'תמונה',
            onTap: () {
              // Add image picker
            },
          ),
          _buildOptionChip(
            icon: Icons.poll_outlined,
            label: _isPoll ? 'ביטול סקר' : 'סקר',
            isSelected: _isPoll,
            onTap: () {
              setState(() => _isPoll = !_isPoll);
            },
          ),
          _buildOptionChip(
            icon: Icons.location_on_outlined,
            label: 'מיקום',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('שיתוף מיקום יהיה זמין בקרוב', style: TextStyle(fontFamily: 'Heebo')),
                  backgroundColor: AppColors.info,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
          _buildOptionChip(
            icon: Icons.tag,
            label: 'תיוג',
            onTap: () {
              _showTagsDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip({
    required IconData icon,
    required String label,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Heebo',
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'id': 'general', 'name': 'כללי', 'icon': 'chat'},
      {'id': 'questions', 'name': 'שאלות', 'icon': 'help'},
      {'id': 'tips', 'name': 'טיפים', 'icon': 'lightbulb'},
      {'id': 'recommendations', 'name': 'המלצות', 'icon': 'thumb_up'},
      {'id': 'moments', 'name': 'רגעים', 'icon': 'camera'},
      {'id': 'help', 'name': 'עזרה', 'icon': 'support'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'קטגוריה:',
            style: TextStyle(
              fontFamily: 'Heebo',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final isSelected = _selectedCategory == category['id'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = category['id']!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getCategoryIcon(category['icon']!), size: 15, color: isSelected ? Colors.white : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        category['name']!,
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            if (_tags.isNotEmpty) ...[
              Expanded(
                child: Wrap(
                  spacing: 4,
                  children: _tags.map((tag) => Chip(
                    label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      setState(() => _tags.remove(tag));
                    },
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTagsDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הוספת תגית', style: TextStyle(fontFamily: 'Heebo')),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'הקלידי תגית...',
            prefixText: '#',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _tags.add(controller.text));
              }
              Navigator.pop(context);
            },
            child: const Text('הוספה'),
          ),
        ],
      ),
    );
  }

  void _publishPost() async {
    HapticFeedback.mediumImpact();

    final appState = context.read<AppState>();
    final firestoreService = context.read<FirestoreService>();
    final user = appState.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('שגיאה: משתמש לא מחובר'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Build post data
    final postData = {
      'content': _contentController.text.trim(),
      'authorName': _isAnonymous ? 'אנונימית' : user.fullName,
      'isAnonymous': _isAnonymous,
      'category': _selectedCategory,
      'tags': _tags,
      'images': _selectedImages,
      // Creator contact info (for admin only)
      'creatorId': user.id,
      'creatorName': user.fullName,
      'creatorEmail': user.email,
      'creatorPhone': user.phone ?? '',
    };

    // Add poll data if it's a poll
    if (_isPoll) {
      final pollOptions = _pollOptions
          .where((controller) => controller.text.trim().isNotEmpty)
          .map((controller) => controller.text.trim())
          .toList();

      if (_pollQuestionController.text.trim().isEmpty || pollOptions.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('נא להזין שאלת סקר ולפחות 2 אפשרויות'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      postData['type'] = 'poll';
      postData['pollQuestion'] = _pollQuestionController.text.trim();
      postData['pollOptions'] = pollOptions.map((opt) => {
        'text': opt,
        'votes': 0,
        'voters': <String>[],
      }).toList();
    } else {
      postData['type'] = 'post';
    }

    try {
      // Create post in Firestore
      await firestoreService.addPost(postData);

      // Send automatic email notification to admin
      NotificationService().notifyAdminNewContent(
        type: 'post',
        content: postData,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('הפוסט פורסם בהצלחה!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בפרסום הפוסט: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  IconData _getCategoryIcon(String key) {
    switch (key) {
      case 'chat': return Icons.chat_bubble_outline_rounded;
      case 'help': return Icons.help_outline_rounded;
      case 'lightbulb': return Icons.lightbulb_outline_rounded;
      case 'thumb_up': return Icons.thumb_up_outlined;
      case 'camera': return Icons.camera_alt_outlined;
      case 'support': return Icons.support_agent_rounded;
      default: return Icons.circle_outlined;
    }
  }
}
