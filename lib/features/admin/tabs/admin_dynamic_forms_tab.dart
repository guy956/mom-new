import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';

class AdminDynamicFormsTab extends StatefulWidget {
  const AdminDynamicFormsTab({super.key});

  @override
  State<AdminDynamicFormsTab> createState() => _AdminDynamicFormsTabState();
}

class _AdminDynamicFormsTabState extends State<AdminDynamicFormsTab>
    with SingleTickerProviderStateMixin {
  late TabController _formTab;

  List<Map<String, dynamic>> _registrationFields = [];
  List<Map<String, dynamic>> _sosFields = [];
  bool _regInitialized = false;
  bool _sosInitialized = false;
  bool _regSaving = false;
  bool _sosSaving = false;

  @override
  void initState() {
    super.initState();
    _formTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _formTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F5F4),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _formTab,
                labelColor: const Color(0xFF43363A),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFD1C2D3),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'טופס הרשמה'),
                  Tab(text: 'טופס SOS'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _formTab,
                children: [
                  _buildRegistrationForm(context.read<FirestoreService>()),
                  _buildSosForm(context.read<FirestoreService>()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  REGISTRATION FORM EDITOR
  // ════════════════════════════════════════════════════════════════

  Widget _buildRegistrationForm(FirestoreService fs) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: fs.registrationFormStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_regInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && !_regInitialized) {
          final fields = snapshot.data!['fields'] as List<dynamic>? ?? [];
          _registrationFields = fields.map((f) => Map<String, dynamic>.from(f)).toList();
          _registrationFields.sort((a, b) => (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));
          _regInitialized = true;
        }

        return _buildFormEditor(
          fields: _registrationFields,
          saving: _regSaving,
          onAddField: () => _showAddFieldDialog(isRegistration: true),
          onSave: () => _saveRegistrationForm(fs),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = _registrationFields.removeAt(oldIndex);
              _registrationFields.insert(newIndex, item);
              for (int i = 0; i < _registrationFields.length; i++) {
                _registrationFields[i]['order'] = i;
              }
            });
          },
          onToggle: (index, value) {
            setState(() => _registrationFields[index]['enabled'] = value);
          },
          onToggleRequired: (index, value) {
            setState(() => _registrationFields[index]['required'] = value);
          },
          onDelete: (index) {
            setState(() => _registrationFields.removeAt(index));
          },
          onEdit: (index) => _showEditFieldDialog(isRegistration: true, index: index),
          formTitle: 'שדות טופס הרשמה',
          formDescription: 'הגדירו אילו שדות יופיעו בטופס ההרשמה',
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SOS FORM EDITOR
  // ════════════════════════════════════════════════════════════════

  Widget _buildSosForm(FirestoreService fs) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: fs.sosFormStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_sosInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && !_sosInitialized) {
          final fields = snapshot.data!['fields'] as List<dynamic>? ?? [];
          _sosFields = fields.map((f) => Map<String, dynamic>.from(f)).toList();
          _sosFields.sort((a, b) => (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));
          _sosInitialized = true;
        }

        return _buildFormEditor(
          fields: _sosFields,
          saving: _sosSaving,
          onAddField: () => _showAddFieldDialog(isRegistration: false),
          onSave: () => _saveSosForm(fs),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = _sosFields.removeAt(oldIndex);
              _sosFields.insert(newIndex, item);
              for (int i = 0; i < _sosFields.length; i++) {
                _sosFields[i]['order'] = i;
              }
            });
          },
          onToggle: (index, value) {
            setState(() => _sosFields[index]['enabled'] = value);
          },
          onToggleRequired: (index, value) {
            setState(() => _sosFields[index]['required'] = value);
          },
          onDelete: (index) {
            setState(() => _sosFields.removeAt(index));
          },
          onEdit: (index) => _showEditFieldDialog(isRegistration: false, index: index),
          formTitle: 'שדות טופס SOS',
          formDescription: 'הגדירו אילו שדות יופיעו בטופס חירום SOS',
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SHARED FORM EDITOR BUILDER
  // ════════════════════════════════════════════════════════════════

  Widget _buildFormEditor({
    required List<Map<String, dynamic>> fields,
    required bool saving,
    required VoidCallback onAddField,
    required VoidCallback onSave,
    required void Function(int, int) onReorder,
    required void Function(int, bool) onToggle,
    required void Function(int, bool) onToggleRequired,
    required void Function(int) onDelete,
    required void Function(int) onEdit,
    required String formTitle,
    required String formDescription,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formTitle, style: const TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(formDescription, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              FloatingActionButton.small(
                heroTag: 'addField_$formTitle',
                onPressed: onAddField,
                backgroundColor: const Color(0xFFD1C2D3),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),

        Expanded(
          child: fields.isEmpty
              ? AdminWidgets.emptyState('אין שדות בטופס', icon: Icons.dynamic_form_rounded)
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: fields.length,
                  onReorder: onReorder,
                  itemBuilder: (context, index) {
                    final field = fields[index];
                    final label = field['label'] ?? '';
                    final type = field['type'] ?? 'text';
                    final required_ = field['required'] == true;
                    final enabled = field['enabled'] == true;

                    return Container(
                      key: ValueKey('${field['key']}_$index'),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: enabled ? Colors.white : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: enabled ? const Color(0xFFD1C2D3).withValues(alpha: 0.3) : Colors.grey.shade300),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.drag_handle, color: Colors.grey.shade400),
                        title: Row(
                          children: [
                            Expanded(child: Text(label, style: TextStyle(fontFamily: 'Heebo', fontSize: 14, fontWeight: FontWeight.w600, color: enabled ? Colors.black87 : Colors.grey))),
                            AdminWidgets.chip(_fieldTypeLabel(type), const Color(0xFFE8D5B7).withValues(alpha: 0.3), const Color(0xFF795548)),
                            if (required_) ...[
                              const SizedBox(width: 4),
                              AdminWidgets.chip('חובה', const Color(0xFFFFEBEE), const Color(0xFFC62828)),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: enabled,
                              activeColor: const Color(0xFFD1C2D3),
                              onChanged: (val) => onToggle(index, val),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit': onEdit(index); break;
                                  case 'required': onToggleRequired(index, !required_); break;
                                  case 'delete': onDelete(index); break;
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('ערוך', style: TextStyle(fontFamily: 'Heebo'))),
                                PopupMenuItem(value: 'required', child: Text(required_ ? 'הפוך לאופציונלי' : 'הפוך לחובה', style: const TextStyle(fontFamily: 'Heebo'))),
                                PopupMenuItem(value: 'delete', child: Text('מחק', style: TextStyle(fontFamily: 'Heebo', color: Colors.red.shade400))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: AdminWidgets.saveButton(label: 'שמור טופס', loading: saving, onPressed: onSave),
        ),
      ],
    );
  }

  String _fieldTypeLabel(String type) {
    switch (type) {
      case 'text': return 'טקסט';
      case 'email': return 'אימייל';
      case 'password': return 'סיסמה';
      case 'phone': return 'טלפון';
      case 'textarea': return 'טקסט ארוך';
      case 'select': return 'בחירה';
      case 'number': return 'מספר';
      case 'date': return 'תאריך';
      default: return type;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  ADD/EDIT FIELD DIALOGS
  // ════════════════════════════════════════════════════════════════

  void _showAddFieldDialog({required bool isRegistration}) {
    final keyCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final optionsCtrl = TextEditingController();
    String selectedType = 'text';
    bool isRequired = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('הוסף שדה חדש', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'מפתח (באנגלית)', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'Heebo')),
                const SizedBox(height: 12),
                TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'תווית (בעברית)', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'Heebo')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'סוג שדה', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()),
                  items: ['text', 'email', 'password', 'phone', 'textarea', 'select', 'number', 'date']
                      .map((t) => DropdownMenuItem(value: t, child: Text(_fieldTypeLabel(t), style: const TextStyle(fontFamily: 'Heebo'))))
                      .toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => selectedType = v); },
                ),
                if (selectedType == 'select') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: optionsCtrl,
                    decoration: const InputDecoration(labelText: 'אפשרויות (מופרדות בפסיק)', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()),
                    style: const TextStyle(fontFamily: 'Heebo'),
                  ),
                ],
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('שדה חובה', style: TextStyle(fontFamily: 'Heebo')),
                  value: isRequired,
                  onChanged: (v) => setDialogState(() => isRequired = v ?? false),
                  activeColor: const Color(0xFFD1C2D3),
                  contentPadding: EdgeInsets.zero,
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo'))),
              ElevatedButton(
                onPressed: () {
                  if (keyCtrl.text.trim().isEmpty || labelCtrl.text.trim().isEmpty) return;
                  final newField = <String, dynamic>{
                    'key': keyCtrl.text.trim(),
                    'label': labelCtrl.text.trim(),
                    'type': selectedType,
                    'required': isRequired,
                    'enabled': true,
                  };
                  if (selectedType == 'select' && optionsCtrl.text.trim().isNotEmpty) {
                    newField['options'] = optionsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  }
                  setState(() {
                    if (isRegistration) {
                      newField['order'] = _registrationFields.length;
                      _registrationFields.add(newField);
                    } else {
                      newField['order'] = _sosFields.length;
                      _sosFields.add(newField);
                    }
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD1C2D3), foregroundColor: Colors.white),
                child: const Text('הוסף', style: TextStyle(fontFamily: 'Heebo')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditFieldDialog({required bool isRegistration, required int index}) {
    final fields = isRegistration ? _registrationFields : _sosFields;
    final field = fields[index];
    final labelCtrl = TextEditingController(text: field['label'] ?? '');
    final optionsCtrl = TextEditingController(text: (field['options'] as List<dynamic>?)?.join(', ') ?? '');
    String selectedType = field['type'] ?? 'text';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('עריכת שדה', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'תווית', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'Heebo')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'סוג שדה', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()),
                  items: ['text', 'email', 'password', 'phone', 'textarea', 'select', 'number', 'date']
                      .map((t) => DropdownMenuItem(value: t, child: Text(_fieldTypeLabel(t), style: const TextStyle(fontFamily: 'Heebo'))))
                      .toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => selectedType = v); },
                ),
                if (selectedType == 'select') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: optionsCtrl,
                    decoration: const InputDecoration(labelText: 'אפשרויות (מופרדות בפסיק)', labelStyle: TextStyle(fontFamily: 'Heebo'), border: OutlineInputBorder()),
                    style: const TextStyle(fontFamily: 'Heebo'),
                  ),
                ],
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo'))),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    fields[index]['label'] = labelCtrl.text.trim();
                    fields[index]['type'] = selectedType;
                    if (selectedType == 'select' && optionsCtrl.text.trim().isNotEmpty) {
                      fields[index]['options'] = optionsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                    }
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD1C2D3), foregroundColor: Colors.white),
                child: const Text('עדכן', style: TextStyle(fontFamily: 'Heebo')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SAVE METHODS
  // ════════════════════════════════════════════════════════════════

  Future<void> _saveRegistrationForm(FirestoreService fs) async {
    setState(() => _regSaving = true);
    try {
      await fs.updateRegistrationForm({'fields': _registrationFields});
      await fs.logActivity(action: 'עדכון טופס הרשמה', user: 'מנהלת', type: 'config');
      if (mounted) AdminWidgets.snack(context, 'טופס ההרשמה עודכן');
    } catch (e) {
      if (mounted) AdminWidgets.snack(context, 'שגיאה: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _regSaving = false);
    }
  }

  Future<void> _saveSosForm(FirestoreService fs) async {
    setState(() => _sosSaving = true);
    try {
      await fs.updateSosForm({'fields': _sosFields});
      await fs.logActivity(action: 'עדכון טופס SOS', user: 'מנהלת', type: 'config');
      if (mounted) AdminWidgets.snack(context, 'טופס SOS עודכן');
    } catch (e) {
      if (mounted) AdminWidgets.snack(context, 'שגיאה: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _sosSaving = false);
    }
  }
}
