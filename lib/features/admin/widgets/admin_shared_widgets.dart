import 'package:flutter/material.dart';

/// Shared UI helpers for admin dashboard tabs.
class AdminWidgets {
  AdminWidgets._();

  static const _heebo = TextStyle(fontFamily: 'Heebo');
  static const Color kPrimary = Color(0xFFD1C2D3);
  static const Color kDark = Color(0xFF43363A);
  static const Color kBg = Color(0xFFF9F5F4);

  // ── KPI Card ──
  static Widget kpiCard({
    required IconData icon,
    required String value,
    Color? color,
    String? label,
    String? title,
    String? subtitle,
  }) {
    final c = color ?? kPrimary;
    final displayLabel = title ?? label ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: c.withValues(alpha:0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: c, size: 20),
          ),
          const Spacer(),
          if (subtitle != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: c.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(subtitle, style: _heebo.copyWith(fontSize: 9, color: c, fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 12),
        Text(value, style: _heebo.copyWith(fontSize: 24, fontWeight: FontWeight.bold, color: kDark)),
        const SizedBox(height: 2),
        Text(displayLabel, style: _heebo.copyWith(fontSize: 12, color: Colors.grey[600])),
      ]),
    );
  }

  // ── Section Title ──
  static Widget sectionTitle(String text, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        if (icon != null) ...[Icon(icon, size: 18, color: kPrimary), const SizedBox(width: 6)],
        Text(text, style: _heebo.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: kDark)),
      ]),
    );
  }

  // ── Card Decoration ──
  static BoxDecoration cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
  );

  // ── Status Chip ──
  static Widget chip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: _heebo.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: text)),
    );
  }

  static Widget statusChip(String status) {
    switch (status) {
      case 'active': case 'approved':
        return chip(status == 'active' ? 'פעילה' : 'מאושר', const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
      case 'pending':
        return chip('ממתין', const Color(0xFFFFF3E0), const Color(0xFFE65100));
      case 'banned': case 'rejected':
        return chip(status == 'banned' ? 'חסומה' : 'נדחה', const Color(0xFFFFEBEE), const Color(0xFFC62828));
      case 'closed':
        return chip('סגור', const Color(0xFFE3F2FD), const Color(0xFF1565C0));
      default:
        return chip(status, Colors.grey[200]!, Colors.grey[700]!);
    }
  }

  // ── Quick Action Button ──
  static Widget quickActionBtn({
    IconData? icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? kPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: c.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha:0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: c, size: 22),
            const SizedBox(height: 6),
          ],
          Text(label, style: _heebo.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: c), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ── Empty State ──
  static Widget emptyState(String text, {IconData icon = Icons.inbox_outlined}) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 48, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text(text, style: _heebo.copyWith(color: Colors.grey[500], fontSize: 14)),
    ]));
  }

  // ── Config Field ──
  static Widget configField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textDirection: TextDirection.rtl,
        style: _heebo.copyWith(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _heebo.copyWith(fontSize: 12, color: Colors.grey[600]),
          prefixIcon: icon != null ? Icon(icon, size: 18, color: kPrimary) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ── Feature Toggle ──
  static Widget featureToggle({
    required String label,
    String? description,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    final desc = description ?? subtitle ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? kPrimary.withValues(alpha:0.3) : Colors.grey[200]!),
      ),
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: value ? kPrimary : Colors.grey),
          const SizedBox(width: 10),
        ],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: _heebo.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
          if (desc.isNotEmpty)
            Text(desc, style: _heebo.copyWith(fontSize: 10, color: Colors.grey[500])),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: kPrimary),
      ]),
    );
  }

  // ── Color Row ──
  static Widget colorRow({
    required String label,
    String? hex,
    Color? color,
    required VoidCallback onTap,
  }) {
    final displayColor = color ?? (hex != null ? parseColor(hex) : kPrimary);
    final displayHex = hex ?? '#${displayColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: displayColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: _heebo.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(displayHex, style: _heebo.copyWith(fontSize: 11, color: Colors.grey)),
          ])),
          const Icon(Icons.edit, size: 16, color: Colors.grey),
        ]),
      ),
    );
  }

  static Color parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  // ── Legend Dot ──
  static Widget legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: _heebo.copyWith(fontSize: 10, color: Colors.grey[600])),
    ]);
  }

  // ── Snackbar ──
  static void snack(BuildContext context, String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: _heebo),
        backgroundColor: color ?? const Color(0xFFB5C8B9),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Confirm Delete Dialog ──
  static Future<bool> confirmDelete(BuildContext context, String itemName) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('מחיקה', style: _heebo.copyWith(fontWeight: FontWeight.bold)),
        content: Text('למחוק את $itemName?', style: _heebo),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('ביטול', style: _heebo)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
            child: Text('מחק', style: _heebo.copyWith(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  // ── Confirm Action Dialog ──
  static Future<bool> confirmAction(BuildContext context, {required String title, required String message, String confirmLabel = 'אישור', Color? confirmColor}) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: _heebo.copyWith(fontWeight: FontWeight.bold)),
          content: Text(message, style: _heebo),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('ביטול', style: _heebo)),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: confirmColor ?? kPrimary),
              child: Text(confirmLabel, style: _heebo.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  // ── Stat Card ──
  static Widget statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: _heebo.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: _heebo.copyWith(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Save Button ──
  static Widget saveButton({
    required VoidCallback onPressed,
    String label = 'שמור שינויים',
    bool loading = false,
    bool saving = false,
  }) {
    final isLoading = loading || saving;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_rounded, size: 18),
        label: Text(label, style: _heebo.copyWith(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
