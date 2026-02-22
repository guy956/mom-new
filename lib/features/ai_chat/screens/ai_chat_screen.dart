import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mom_connect/core/constants/app_colors.dart';

/// AI Chat - MomBot - מופעל על ידי Google Gemini
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_AIChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _pulseController;

  // Gemini API Configuration
  String? _geminiApiKey;
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // Conversation history for context
  final List<Map<String, dynamic>> _conversationHistory = [];

  // System prompt for MomBot
  static const String _systemPrompt = '''
אתה MomBot, עוזרת חכמה ומנוסה באפליקציית MOMIT (MOM Connect) - רשת חברתית לאמהות בישראל.
המטרה שלך היא לעזור לאמהות עם שאלות על הריון, תינוקות, ילדים, התפתחות, שינה, האכלה, בריאות, רווחה נפשית וכל נושא הקשור להורות.

כללי חשובים:
1. ענו תמיד בעברית
2. היו חמים, אמפתיים ותומכים
3. ציינו תמיד שאינכם מחליפים ייעוץ רפואי מקצועי
4. תנו מידע מבוסס מחקר כשאפשר
5. הציעו פנייה לרופא כשיש חשש רפואי
6. השתמשו באימוג'ים מתאימים
7. הציעו שאלות המשך רלוונטיות
8. היו קצרים וממוקדים אבל מספיק מפורטים
9. תנו עצות מעשיות וישימות
10. זכרו את ההקשר של השיחה
''';

  // Quick question categories
  final List<Map<String, dynamic>> _quickTopics = [
    {'icon': Icons.restaurant_outlined, 'label': 'האכלה', 'color': AppColors.secondary},
    {'icon': Icons.bedtime_outlined, 'label': 'שינה', 'color': AppColors.info},
    {'icon': Icons.healing_outlined, 'label': 'בריאות', 'color': AppColors.error},
    {'icon': Icons.child_friendly_outlined, 'label': 'התפתחות', 'color': AppColors.success},
    {'icon': Icons.fitness_center_outlined, 'label': 'כושר אחרי לידה', 'color': AppColors.accent},
    {'icon': Icons.spa_outlined, 'label': 'רווחה נפשית', 'color': const Color(0xFFD1C2D3)},
    {'icon': Icons.child_care_outlined, 'label': 'טיפול בתינוק', 'color': AppColors.primary},
    {'icon': Icons.lunch_dining_outlined, 'label': 'תזונה', 'color': const Color(0xFFD6C7C1)},
  ];

  final List<String> _suggestedQuestions = [
    'התינוק שלי לא ישן בלילה, מה עושים?',
    'איך להתמודד עם קנאה של הילד הגדול?',
    'מתי מתחילים מוצקים?',
    'טיפים להרגעת תינוק בוכה',
    'איך לחזור לשגרת כושר אחרי לידה?',
    'סימנים לדלקת אוזניים',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _messages.add(_AIChatMessage(
      content:
          'היי! אני MomBot, העוזרת החכמה שלך - מופעלת בינה מלאכותית של Google.\n\n'
          'אני כאן כדי לעזור לך עם שאלות על אמהות, תינוקות, התפתחות, שינה, האכלה ועוד.\n\n'
          'את יכולה לשאול אותי כל שאלה, או לבחור נושא מהתפריט למטה.',
      isUser: false,
      timestamp: DateTime.now(),
    ));

    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    // 1. Primary source: .env file
    final envKey = dotenv.env['GEMINI_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      debugPrint('[MomBot] API key loaded from .env');
      setState(() {
        _geminiApiKey = envKey;
      });
      return;
    }

    // 2. Fallback: Firestore admin_config
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_config')
          .doc('api_keys')
          .get();
      if (doc.exists) {
        final firestoreKey = doc.data()?['geminiApiKey']?.toString();
        if (firestoreKey != null && firestoreKey.isNotEmpty) {
          debugPrint('[MomBot] API key loaded from Firestore');
          setState(() {
            _geminiApiKey = firestoreKey;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[MomBot] Error loading API key from Firestore: $e');
    }

    // 3. No API key found from any source
    debugPrint('[MomBot] No API key available from .env or Firestore');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'שירות הצ\'אט אינו זמין כרגע. אנא נסי שוב מאוחר יותר.',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'Heebo'),
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F7),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child:
                _messages.length <= 1 ? _buildWelcomeView() : _buildChatView(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => Navigator.pop(context),
        tooltip: 'חזרה',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.home_outlined, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          tooltip: 'מסך ראשי',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
          onPressed: () => _clearChat(),
          tooltip: 'נקה שיחה',
        ),
      ],
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD1C2D3), Color(0xFFEDD3D8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MomBot',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'מופעל על ידי Google AI',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD1C2D3), Color(0xFFEDD3D8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD1C2D3)
                          .withValues(
                              alpha: 0.3 + (_pulseController.value * 0.2)),
                      blurRadius: 20 + (_pulseController.value * 10),
                      spreadRadius: _pulseController.value * 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'MomBot',
            style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'העוזרת החכמה שלך להורות\nמופעלת על ידי Google AI - זמינה 24/7',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Heebo',
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'MomBot נותנת מידע כללי בלבד ואינה מחליפה ייעוץ רפואי מקצועי',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 12,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'נושאים מהירים',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _quickTopics.map((topic) {
              return GestureDetector(
                onTap: () {
                  _sendMessage('רוצה לשאול על ${topic['label']}');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        (topic['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          (topic['color'] as Color).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(topic['icon'] as IconData, size: 18, color: topic['color'] as Color),
                      const SizedBox(width: 8),
                      Text(
                        topic['label'],
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 14,
                          color: topic['color'] as Color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'שאלות נפוצות',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...(_suggestedQuestions.map((q) {
            return GestureDetector(
              onTap: () => _sendMessage(q),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 18, color: Color(0xFFD1C2D3)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q,
                        style: const TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.textHint),
                  ],
                ),
              ),
            );
          })),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(_AIChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD1C2D3), Color(0xFFEDD3D8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'MomBot',
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD1C2D3),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 4 : 18),
                  bottomRight: Radius.circular(isUser ? 18 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 15,
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 11,
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD1C2D3), Color(0xFFEDD3D8)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'MomBot חושבת...',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 13,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 30,
              height: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (i) => _buildDot(i)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final delay = index * 0.2;
        final value = ((_pulseController.value + delay) % 1.0);
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color:
                const Color(0xFFD1C2D3).withValues(alpha: 0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF6F7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: const Color(0xFFD1C2D3).withValues(alpha: 0.2)),
                ),
                child: TextField(
                  controller: _messageController,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Heebo'),
                  decoration: InputDecoration(
                    hintText: 'שאלי את MomBot...',
                    hintStyle: TextStyle(
                      fontFamily: 'Heebo',
                      color: AppColors.textHint,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _messageController.text.isNotEmpty
                      ? const LinearGradient(
                          colors: [Color(0xFFD1C2D3), Color(0xFFEDD3D8)],
                        )
                      : null,
                  color: _messageController.text.isEmpty
                      ? AppColors.border
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: _messageController.text.isNotEmpty
                      ? Colors.white
                      : AppColors.textHint,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSend() {
    if (_messageController.text.trim().isEmpty) return;
    _sendMessage(_messageController.text.trim());
    _messageController.clear();
    setState(() {}); // Update send button state
  }

  Future<void> _sendMessage(String text) async {
    setState(() {
      _messages.add(_AIChatMessage(
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // Add to conversation history
    _conversationHistory.add({
      'role': 'user',
      'parts': [
        {'text': text}
      ]
    });

    try {
      final response = await _callGeminiApi(text);
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(_AIChatMessage(
            content: response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });

        // Add to conversation history
        _conversationHistory.add({
          'role': 'model',
          'parts': [
            {'text': response}
          ]
        });

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(_AIChatMessage(
            content:
                'מצטערת, נתקלתי בבעיה טכנית. נסי שוב בעוד רגע. 🙏',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    }
  }

  Future<String> _callGeminiApi(String userMessage) async {
    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      return 'מצטערת, השירות אינו זמין כרגע. נסי שוב מאוחר יותר.';
    }
    final url = Uri.parse(_geminiUrl);

    // Build conversation with system instruction
    final List<Map<String, dynamic>> contents = [];

    // Use existing conversation history (max last 10 messages)
    final recentHistory = _conversationHistory.length > 10
        ? _conversationHistory.sublist(_conversationHistory.length - 10)
        : List<Map<String, dynamic>>.from(_conversationHistory);
    contents.addAll(recentHistory);

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.8,
        'topP': 0.95,
        'topK': 40,
        'maxOutputTokens': 1024,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_LOW_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
      ],
    });

    final response = await http
        .post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _geminiApiKey!,
      },
      body: body,
    )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] as String;
        }
      }
      return 'מצטערת, לא הצלחתי לייצר תשובה. נסי לנסח את השאלה אחרת.';
    } else {
      debugPrint('[MomBot] Gemini API error: ${response.statusCode} - ${response.body}');
      switch (response.statusCode) {
        case 401:
          return 'מפתח ה-API אינו תקין. אנא פני למנהלת המערכת.';
        case 429:
          return 'יותר מדי בקשות בו-זמנית. אנא המתיני מספר שניות ונסי שוב.';
        case 500:
          return 'שגיאה בשרת של Google AI. אנא נסי שוב בעוד מספר דקות.';
        default:
          return 'מצטערת, נתקלתי בבעיה טכנית (שגיאה ${response.statusCode}). נסי שוב מאוחר יותר.';
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ניקוי שיחה',
            style: TextStyle(fontFamily: 'Heebo')),
        content: const Text('האם את בטוחה שברצונך לנקות את השיחה?',
            style: TextStyle(fontFamily: 'Heebo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('ביטול', style: TextStyle(fontFamily: 'Heebo')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _conversationHistory.clear();
                _messages.add(_AIChatMessage(
                  content:
                      'היי! אני MomBot, העוזרת החכמה שלך.\nאיך אפשר לעזור לך היום?',
                  isUser: false,
                  timestamp: DateTime.now(),
                ));
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('נקה',
                style: TextStyle(
                    fontFamily: 'Heebo', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AIChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  _AIChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}
