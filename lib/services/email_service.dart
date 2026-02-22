import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for sending emails via Mailjet API
/// Sends admin notifications when users create content requiring approval
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  /// Mailjet API endpoint
  static const String _mailjetApiUrl = 'https://api.mailjet.com/v3.1/send';

  /// Get Mailjet API key from environment
  String? get _mailjetApiKey => dotenv.env['MAILJET_API_KEY'];

  /// Get Mailjet Secret key from environment
  String? get _mailjetSecretKey => dotenv.env['MAILJET_SECRET_KEY'];

  /// Admin email address to receive notifications
  /// Falls back to hardcoded admin email if env variable is not set
  String get _adminEmail =>
      dotenv.env['ADMIN_EMAILS']?.split(',').first.trim() ?? 'admin@momit.co.il';

  /// Send notification email to admin
  ///
  /// [type] - Type of content (event, post, marketplace, etc.)
  /// [title] - Title of the content
  /// [details] - Additional details about the content
  /// [itemData] - Full data of the item for context
  /// [dashboardLink] - Optional direct link to admin dashboard
  Future<bool> sendAdminNotification({
    required String type,
    required String title,
    required String details,
    required Map<String, dynamic> itemData,
    String? dashboardLink,
  }) async {
    try {
      // Check if Mailjet API keys are configured
      if (_mailjetApiKey == null || _mailjetApiKey!.isEmpty ||
          _mailjetSecretKey == null || _mailjetSecretKey!.isEmpty) {
        debugPrint('[EmailService] Mailjet API keys not configured - skipping email');
        return false;
      }

      // Check if admin email is configured
      if (_adminEmail.isEmpty) {
        debugPrint('[EmailService] Admin email not configured - skipping email');
        return false;
      }

      // Build email HTML content with RTL support
      final htmlContent = _buildEmailHtml(
        type: type,
        title: title,
        details: details,
        itemData: itemData,
        dashboardLink: dashboardLink,
      );

      // Build email subject
      final subject = _buildSubject(type, title);

      // Build Mailjet Basic auth header
      final credentials = base64Encode(utf8.encode('$_mailjetApiKey:$_mailjetSecretKey'));

      // Send email via Mailjet
      final response = await http.post(
        Uri.parse(_mailjetApiUrl),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Messages': [
            {
              'From': {
                'Email': 'noreply@momit.co.il',
                'Name': 'MOMIT System',
              },
              'To': [
                {
                  'Email': _adminEmail,
                  'Name': 'Admin',
                }
              ],
              'Subject': subject,
              'HTMLPart': htmlContent,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[EmailService] Admin notification email sent successfully via Mailjet');
        return true;
      } else {
        debugPrint('[EmailService] Failed to send email: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[EmailService] Error sending email: $e');
      return false;
    }
  }

  /// Build email subject line
  String _buildSubject(String type, String title) {
    final typeLabel = _getTypeLabel(type);
    return 'MOMIT - $typeLabel חדש מחכה לאישור: $title';
  }

  /// Get Hebrew type label
  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'event':
        return 'אירוע';
      case 'post':
        return 'פוסט';
      case 'marketplace':
        return 'מוצר במסירות';
      case 'expert':
        return 'מומחה';
      case 'tip':
        return 'טיפ';
      case 'report':
        return 'דיווח';
      case 'sos':
      case 'sos_alert':
        return 'התראת SOS דחופה';
      case 'booking':
        return 'בקשת תור למומחה';
      case 'user':
        return 'משתמש';
      case 'chat_group':
      case 'new_chat_group':
        return 'קבוצת צ\'אט';
      default:
        return 'פריט';
    }
  }

  /// Build beautiful HTML email template with Hebrew RTL support
  String _buildEmailHtml({
    required String type,
    required String title,
    required String details,
    required Map<String, dynamic> itemData,
    String? dashboardLink,
  }) {
    final typeLabel = _getTypeLabel(type);
    final userName = _htmlEscape(itemData['createdBy'] ?? itemData['userName'] ?? itemData['author'] ?? 'משתמש לא ידוע');
    final createdAt = _formatDate(itemData['createdAt']);
    final itemId = _htmlEscape(itemData['id'] ?? 'unknown');

    // Build dashboard link
    final approvalLink = dashboardLink ?? 'https://momit.pages.dev/admin';

    // Build item details section
    final detailsHtml = _buildDetailsSection(type, itemData);

    return '''
<!DOCTYPE html>
<html dir="rtl" lang="he">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>התראת מנהל - MOMIT</title>
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: #f5f5f5;
      margin: 0;
      padding: 0;
      direction: rtl;
    }
    .container {
      max-width: 600px;
      margin: 20px auto;
      background-color: #ffffff;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }
    .header {
      background: linear-gradient(135deg, #D4A1AC 0%, #EDD3D8 100%);
      color: #ffffff;
      padding: 30px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      font-size: 28px;
      font-weight: bold;
    }
    .header p {
      margin: 10px 0 0 0;
      font-size: 14px;
      opacity: 0.9;
    }
    .content {
      padding: 30px;
    }
    .alert-box {
      background-color: #FFF9E6;
      border-right: 4px solid #FFB800;
      padding: 20px;
      margin-bottom: 25px;
      border-radius: 8px;
    }
    .alert-box h2 {
      margin: 0 0 10px 0;
      color: #CC9000;
      font-size: 20px;
    }
    .alert-box p {
      margin: 5px 0;
      color: #666;
      font-size: 14px;
    }
    .info-section {
      background-color: #f9f9f9;
      padding: 20px;
      border-radius: 8px;
      margin-bottom: 20px;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 10px 0;
      border-bottom: 1px solid #eee;
    }
    .info-row:last-child {
      border-bottom: none;
    }
    .info-label {
      font-weight: bold;
      color: #333;
    }
    .info-value {
      color: #666;
      text-align: left;
    }
    .details-box {
      background-color: #fff;
      border: 1px solid #e0e0e0;
      padding: 20px;
      border-radius: 8px;
      margin-bottom: 25px;
    }
    .details-box h3 {
      margin: 0 0 15px 0;
      color: #333;
      font-size: 18px;
    }
    .cta-button {
      display: inline-block;
      background: linear-gradient(135deg, #D4A1AC 0%, #DBC8B0 100%);
      color: #ffffff;
      text-decoration: none;
      padding: 16px 40px;
      border-radius: 8px;
      font-size: 16px;
      font-weight: bold;
      text-align: center;
      margin: 20px 0;
      transition: transform 0.2s;
    }
    .cta-button:hover {
      transform: translateY(-2px);
    }
    .footer {
      background-color: #f5f5f5;
      padding: 20px;
      text-align: center;
      font-size: 12px;
      color: #999;
    }
    .badge {
      display: inline-block;
      padding: 4px 12px;
      background-color: #D4A1AC;
      color: white;
      border-radius: 12px;
      font-size: 12px;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔔 התראת מנהל - MOMIT</h1>
      <p>מערכת ניהול תוכן</p>
    </div>

    <div class="content">
      <div class="alert-box">
        <h2>⏳ $typeLabel חדש מחכה לאישור</h2>
        <p><strong>כותרת:</strong> $title</p>
        <p><strong>נוצר על ידי:</strong> $userName</p>
        <p><strong>תאריך:</strong> $createdAt</p>
      </div>

      <div class="info-section">
        <div class="info-row">
          <span class="info-label">סוג:</span>
          <span class="info-value"><span class="badge">$typeLabel</span></span>
        </div>
        <div class="info-row">
          <span class="info-label">מזהה:</span>
          <span class="info-value">$itemId</span>
        </div>
        <div class="info-row">
          <span class="info-label">נוצר על ידי:</span>
          <span class="info-value">${_htmlEscape(itemData['creatorName'] ?? itemData['createdBy'] ?? itemData['userName'] ?? 'לא צוין')}</span>
        </div>
        <div class="info-row">
          <span class="info-label">📧 אימייל:</span>
          <span class="info-value">${_htmlEscape(itemData['creatorEmail'] ?? itemData['email'] ?? 'לא צוין')}</span>
        </div>
        <div class="info-row">
          <span class="info-label">📞 טלפון:</span>
          <span class="info-value">${_htmlEscape(itemData['creatorPhone'] ?? itemData['phone'] ?? itemData['contact'] ?? 'לא צוין')}</span>
        </div>
        <div class="info-row">
          <span class="info-label">פרטים:</span>
          <span class="info-value">${_htmlEscape(details)}</span>
        </div>
      </div>

      $detailsHtml

      <div style="text-align: center;">
        <a href="$approvalLink" class="cta-button">
          ✅ עבור לדשבורד לאישור
        </a>
      </div>

      <p style="color: #999; font-size: 13px; margin-top: 30px; text-align: center;">
        התראה זו נשלחה אוטומטית ממערכת MOMIT.<br>
        אנא היכנס לדשבורד הניהול לאשר או לדחות את הפריט.
      </p>
    </div>

    <div class="footer">
      <p>
        <strong>MOMIT</strong> - רשת חברתית לאמהות בישראל<br>
        כי רק אמא מבינה אמא 💗
      </p>
      <p style="margin-top: 10px;">
        <a href="https://momit.pages.dev" style="color: #D4A1AC; text-decoration: none;">אתר MOMIT</a> |
        <a href="$approvalLink" style="color: #D4A1AC; text-decoration: none;">דשבורד ניהול</a>
      </p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Build details section based on content type
  String _buildDetailsSection(String type, Map<String, dynamic> itemData) {
    switch (type.toLowerCase()) {
      case 'event':
        return _buildEventDetails(itemData);
      case 'post':
        return _buildPostDetails(itemData);
      case 'marketplace':
        return _buildMarketplaceDetails(itemData);
      case 'expert':
        return _buildExpertDetails(itemData);
      case 'booking':
        return _buildBookingDetails(itemData);
      case 'report':
      case 'sos':
      case 'sos_alert':
        return _buildSOSDetails(itemData);
      default:
        return '';
    }
  }

  /// Build event-specific details
  String _buildEventDetails(Map<String, dynamic> data) {
    final eventDate = _formatDate(data['eventDate']);
    final location = data['location'] ?? 'לא צוין';
    final maxAttendees = data['maxAttendees'] ?? 'ללא הגבלה';

    return '''
    <div class="details-box">
      <h3>📅 פרטי האירוע</h3>
      <div class="info-row">
        <span class="info-label">תאריך:</span>
        <span class="info-value">$eventDate</span>
      </div>
      <div class="info-row">
        <span class="info-label">מקום:</span>
        <span class="info-value">$location</span>
      </div>
      <div class="info-row">
        <span class="info-label">משתתפים מקסימום:</span>
        <span class="info-value">$maxAttendees</span>
      </div>
      <p style="margin-top: 15px; color: #666;">${data['description'] ?? ''}</p>
    </div>
    ''';
  }

  /// Build post-specific details
  String _buildPostDetails(Map<String, dynamic> data) {
    final content = data['content'] ?? data['text'] ?? 'אין תוכן';
    final category = data['category'] ?? 'כללי';

    return '''
    <div class="details-box">
      <h3>📝 תוכן הפוסט</h3>
      <div class="info-row">
        <span class="info-label">קטגוריה:</span>
        <span class="info-value">$category</span>
      </div>
      <p style="margin-top: 15px; color: #666; background-color: #f9f9f9; padding: 15px; border-radius: 6px;">
        ${_truncateText(content, 200)}
      </p>
    </div>
    ''';
  }

  /// Build marketplace-specific details
  String _buildMarketplaceDetails(Map<String, dynamic> data) {
    final price = data['price'] ?? 'מחיר לא צוין';
    final condition = data['condition'] ?? 'לא צוין';
    final category = data['category'] ?? 'כללי';

    return '''
    <div class="details-box">
      <h3>🛍️ פרטי המוצר</h3>
      <div class="info-row">
        <span class="info-label">מחיר:</span>
        <span class="info-value">$price</span>
      </div>
      <div class="info-row">
        <span class="info-label">מצב:</span>
        <span class="info-value">$condition</span>
      </div>
      <div class="info-row">
        <span class="info-label">קטגוריה:</span>
        <span class="info-value">$category</span>
      </div>
      <p style="margin-top: 15px; color: #666;">${data['description'] ?? ''}</p>
    </div>
    ''';
  }

  /// Build expert-specific details
  String _buildExpertDetails(Map<String, dynamic> data) {
    final specialty = data['specialty'] ?? 'לא צוין';
    final bio = data['bio'] ?? '';
    final phone = data['phone'] ?? 'לא צוין';

    return '''
    <div class="details-box">
      <h3>👩‍⚕️ פרטי המומחה</h3>
      <div class="info-row">
        <span class="info-label">התמחות:</span>
        <span class="info-value">$specialty</span>
      </div>
      <div class="info-row">
        <span class="info-label">טלפון:</span>
        <span class="info-value">$phone</span>
      </div>
      <p style="margin-top: 15px; color: #666;">${_truncateText(bio, 150)}</p>
    </div>
    ''';
  }

  /// Build booking-specific details
  String _buildBookingDetails(Map<String, dynamic> data) {
    final expertName = data['expertName'] ?? 'לא צוין';
    final date = data['date'] ?? 'לא צוין';
    final time = data['time'] ?? 'לא צוין';
    final userName = data['userName'] ?? 'לא צוין';

    return '''
    <div class="details-box">
      <h3>📅 פרטי התור</h3>
      <div class="info-row">
        <span class="info-label">מומחה:</span>
        <span class="info-value">$expertName</span>
      </div>
      <div class="info-row">
        <span class="info-label">משתמשת:</span>
        <span class="info-value">$userName</span>
      </div>
      <div class="info-row">
        <span class="info-label">תאריך:</span>
        <span class="info-value">$date</span>
      </div>
      <div class="info-row">
        <span class="info-label">שעה:</span>
        <span class="info-value">$time</span>
      </div>
    </div>
    ''';
  }

  /// Build SOS alert-specific details
  String _buildSOSDetails(Map<String, dynamic> data) {
    final category = data['category'] ?? 'לא צוין';
    final message = data['message'] ?? '';
    final userName = data['userName'] ?? 'אנונימית';

    return '''
    <div class="details-box" style="border-right-color: #FF0000;">
      <h3>🚨 פרטי התראת SOS</h3>
      <div class="info-row">
        <span class="info-label">קטגוריה:</span>
        <span class="info-value" style="color: red; font-weight: bold;">$category</span>
      </div>
      <div class="info-row">
        <span class="info-label">משתמשת:</span>
        <span class="info-value">$userName</span>
      </div>
      <p style="margin-top: 15px; color: #666; background-color: #FFF0F0; padding: 15px; border-radius: 6px; border-right: 3px solid red;">
        ${_truncateText(message, 300)}
      </p>
      <p style="color: red; font-weight: bold; margin-top: 10px;">⚠️ נדרש טיפול מיידי!</p>
    </div>
    ''';
  }

  /// Format date to Hebrew format
  String _formatDate(dynamic date) {
    if (date == null) return 'לא צוין';

    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return 'לא צוין';
      }

      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return '$day/$month/$year בשעה $hour:$minute';
    } catch (e) {
      return 'לא צוין';
    }
  }

  /// HTML-escape user input to prevent XSS
  String _htmlEscape(dynamic value) {
    return value.toString()
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Truncate text with ellipsis
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Send test email to verify configuration
  Future<bool> sendTestEmail() async {
    return sendAdminNotification(
      type: 'test',
      title: 'בדיקת מערכת Email',
      details: 'זוהי הודעת בדיקה אוטומטית ממערכת MOMIT',
      itemData: {
        'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
        'createdBy': 'MOMIT System',
        'createdAt': DateTime.now(),
      },
    );
  }
}
