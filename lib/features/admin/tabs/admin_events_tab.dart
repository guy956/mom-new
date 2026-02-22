import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

class AdminEventsTab extends StatefulWidget {
  const AdminEventsTab({super.key});

  @override
  State<AdminEventsTab> createState() => _AdminEventsTabState();
}

class _AdminEventsTabState extends State<AdminEventsTab> {
  String _selectedFilter = 'הכל';

  final List<String> _filters = ['הכל', 'מאושר', 'ממתין', 'נדחה'];

  String _filterToStatus(String filter) {
    switch (filter) {
      case 'מאושר':
        return 'approved';
      case 'ממתין':
        return 'pending';
      case 'נדחה':
        return 'rejected';
      default:
        return 'all';
    }
  }

  bool _matchesFilter(Map<String, dynamic> event) {
    if (_selectedFilter == 'הכל') return true;
    final status = event['status'] as String? ?? 'pending';
    return status == _filterToStatus(_selectedFilter);
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is DateTime) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    if (date is String) return date;
    return date.toString();
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F5F4),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showEventDialog(context, fs),
          backgroundColor: const Color(0xFFB5C8B9),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'אירוע חדש',
            style: TextStyle(
              fontFamily: 'Heebo',
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'ניהול אירועים',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return ChoiceChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFB5C8B9),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFFB5C8B9)
                            : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Events List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: fs.eventsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFB5C8B9),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'שגיאה בטעינת אירועים',
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final events = (snapshot.data ?? [])
                      .where(_matchesFilter)
                      .toList();

                  if (events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'אין אירועים להצגה',
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 18,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildEventCard(context, fs, event);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    FirestoreService fs,
    Map<String, dynamic> event,
  ) {
    final status = event['status'] as String? ?? 'pending';
    final attendees = (event['attendees'] as num?)?.toInt() ?? 0;
    final maxAttendees = (event['maxAttendees'] as num?)?.toInt() ?? 1;
    final progress = maxAttendees > 0 ? attendees / maxAttendees : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row + Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    event['title'] ?? 'ללא כותרת',
                    style: const TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                AdminWidgets.statusChip(status),
              ],
            ),

            const SizedBox(height: 12),

            // Date & Time
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  _formatDate(event['date']),
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  event['time'] ?? '',
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event['location'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Organizer
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  event['organizer'] ?? '',
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Attendees progress
            Row(
              children: [
                Icon(Icons.group, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  '$attendees/$maxAttendees משתתפים',
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFB5C8B9)),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Approve / Reject for pending events
                if (status == 'pending') ...[
                  _buildActionButton(
                    label: 'אישור',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF4CAF50),
                    onPressed: () async {
                      await fs.updateEvent(event['id'], {'status': 'approved'});
                      await fs.logActivity(
                        action: 'אירוע אושר: ${event['title']}',
                        user: 'מנהלת',
                        type: 'event',
                      );
                      if (context.mounted) AdminWidgets.snack(context, 'האירוע אושר');
                    },
                  ),
                  _buildActionButton(
                    label: 'דחייה',
                    icon: Icons.cancel_outlined,
                    color: const Color(0xFFE57373),
                    onPressed: () async {
                      await fs.updateEvent(event['id'], {'status': 'rejected'});
                      await fs.logActivity(
                        action: 'אירוע נדחה: ${event['title']}',
                        user: 'מנהלת',
                        type: 'event',
                      );
                      if (context.mounted) AdminWidgets.snack(context, 'האירוע נדחה');
                    },
                  ),
                ],

                // Edit
                _buildActionButton(
                  label: 'עריכה',
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF64B5F6),
                  onPressed: () =>
                      _showEventDialog(context, fs, existingEvent: event),
                ),

                // Delete
                _buildActionButton(
                  label: 'מחיקה',
                  icon: Icons.delete_outline,
                  color: const Color(0xFFE57373),
                  onPressed: () => _confirmDelete(context, fs, event),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FirestoreService fs,
    Map<String, dynamic> event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'מחיקת אירוע',
            style: TextStyle(
              fontFamily: 'Heebo',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'האם למחוק את האירוע "${event['title']}"?',
            style: const TextStyle(fontFamily: 'Heebo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'ביטול',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'מחיקה',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  color: Color(0xFFE57373),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await fs.deleteEvent(event['id']);
      await fs.logActivity(
        action: 'אירוע נמחק: ${event['title']}',
        user: 'מנהלת',
        type: 'event',
      );
      if (context.mounted) AdminWidgets.snack(context, 'האירוע נמחק');
    }
  }

  Future<void> _showEventDialog(
    BuildContext context,
    FirestoreService fs, {
    Map<String, dynamic>? existingEvent,
  }) async {
    final isEditing = existingEvent != null;

    final titleController =
        TextEditingController(text: existingEvent?['title'] ?? '');
    final locationController =
        TextEditingController(text: existingEvent?['location'] ?? '');
    final organizerController =
        TextEditingController(text: existingEvent?['organizer'] ?? '');
    final maxAttendeesController = TextEditingController(
        text: (existingEvent?['maxAttendees'] ?? '').toString());
    final descriptionController =
        TextEditingController(text: existingEvent?['description'] ?? '');

    DateTime? selectedDate;
    if (existingEvent?['date'] is DateTime) {
      selectedDate = existingEvent!['date'] as DateTime;
    }

    TimeOfDay? selectedTime;
    if (existingEvent?['time'] is String) {
      final parts = (existingEvent!['time'] as String).split(':');
      if (parts.length == 2) {
        selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    String dateText = selectedDate != null
        ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
        : 'בחר תאריך';
    String timeText = selectedTime != null
        ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
        : 'בחר שעה';

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              isEditing ? 'עריכת אירוע' : 'אירוע חדש',
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    _buildTextField(
                      controller: titleController,
                      label: 'שם האירוע',
                      icon: Icons.event,
                    ),
                    const SizedBox(height: 12),

                    // Date Picker
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() {
                            selectedDate = date;
                            dateText =
                                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                          });
                        }
                      },
                      child: _buildPickerField(
                        label: 'תאריך',
                        value: dateText,
                        icon: Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Time Picker
                    InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setDialogState(() {
                            selectedTime = time;
                            timeText =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: _buildPickerField(
                        label: 'שעה',
                        value: timeText,
                        icon: Icons.access_time,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Location
                    _buildTextField(
                      controller: locationController,
                      label: 'מיקום',
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 12),

                    // Organizer
                    _buildTextField(
                      controller: organizerController,
                      label: 'מארגנת',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),

                    // Max Attendees
                    _buildTextField(
                      controller: maxAttendeesController,
                      label: 'מספר משתתפות מקסימלי',
                      icon: Icons.group,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    _buildTextField(
                      controller: descriptionController,
                      label: 'תיאור',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'ביטול',
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('חובה למלא כותרת', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  if (selectedDate == null && !isEditing) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('חובה לבחור תאריך', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  final eventData = {
                    'title': title,
                    'date': selectedDate,
                    'time': timeText != 'בחר שעה' ? timeText : null,
                    'location': locationController.text.trim(),
                    'organizer': organizerController.text.trim(),
                    'maxAttendees':
                        int.tryParse(maxAttendeesController.text.trim()) ?? 0,
                    'description': descriptionController.text.trim(),
                  };

                  if (isEditing) {
                    await fs.updateEvent(existingEvent['id'], eventData);
                    await fs.logActivity(
                      action: 'אירוע עודכן: ${titleController.text.trim()}',
                      user: 'מנהלת',
                      type: 'event',
                    );
                  } else {
                    eventData['status'] = 'approved';
                    eventData['attendees'] = 0;
                    await fs.createEvent(eventData);
                    await fs.logActivity(
                      action: 'אירוע חדש נוצר: ${titleController.text.trim()}',
                      user: 'מנהלת',
                      type: 'event',
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    AdminWidgets.snack(context, isEditing ? 'האירוע עודכן' : 'האירוע נוצר');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB5C8B9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  isEditing ? 'עדכון' : 'יצירה',
                  style: const TextStyle(
                    fontFamily: 'Heebo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    titleController.dispose();
    locationController.dispose();
    organizerController.dispose();
    maxAttendeesController.dispose();
    descriptionController.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Heebo', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Heebo',
          color: Colors.grey.shade500,
        ),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB5C8B9), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Heebo',
                  fontSize: 14,
                  color: value.contains('בחר')
                      ? Colors.grey.shade400
                      : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
