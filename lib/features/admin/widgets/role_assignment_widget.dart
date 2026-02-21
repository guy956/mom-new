import 'package:flutter/material.dart';
import 'package:mom_connect/services/rbac_service.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/auth_service.dart';
import 'package:provider/provider.dart';

/// Role assignment dialog for admins
class RoleAssignmentDialog extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final UserRole? currentRole;

  const RoleAssignmentDialog({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.currentRole,
  });

  static Future<void> show({
    required BuildContext context,
    required String userId,
    required String userName,
    required String userEmail,
    UserRole? currentRole,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => RoleAssignmentDialog(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        currentRole: currentRole,
      ),
    );
  }

  @override
  State<RoleAssignmentDialog> createState() => _RoleAssignmentDialogState();
}

class _RoleAssignmentDialogState extends State<RoleAssignmentDialog> {
  UserRole? _selectedRole;
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole ?? UserRole.viewer;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _assignRole() async {
    if (_selectedRole == null) return;

    setState(() => _isLoading = true);

    final rbac = RbacService.instance;
    final fs = context.read<FirestoreService>();
    
    // Get current admin info
    final currentUser = await AuthService.instance.getSavedSession();
    final assignedBy = currentUser?['email'] ?? 'unknown';

    final success = await rbac.assignRole(
      userId: widget.userId,
      role: _selectedRole!,
      assignedBy: assignedBy,
      expiresAt: _expiresAt,
      reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
    );

    if (success) {
      // Log activity
      await fs.logActivity(
        action: 'שינוי תפקיד: ${_selectedRole!.displayName}',
        user: widget.userName,
        type: 'role',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'התפקיד הוגדר בהצלחה: ${_selectedRole!.displayName}',
              style: const TextStyle(fontFamily: 'Heebo'),
            ),
            backgroundColor: const Color(0xFFB5C8B9),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'אין הרשאה לשייך תפקיד זה',
              style: TextStyle(fontFamily: 'Heebo'),
            ),
            backgroundColor: Color(0xFFD4A3A3),
          ),
        );
      }
    }
  }

  Future<void> _revokeRole() async {
    setState(() => _isLoading = true);

    final rbac = RbacService.instance;
    final currentUser = await AuthService.instance.getSavedSession();
    final revokedBy = currentUser?['email'] ?? 'unknown';

    final success = await rbac.revokeRole(widget.userId, revokedBy);

    if (success) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'התפקיד בוטל בהצלחה',
              style: TextStyle(fontFamily: 'Heebo'),
            ),
            backgroundColor: const Color(0xFFB5C8B9),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'אין הרשאה לבטל תפקיד',
              style: TextStyle(fontFamily: 'Heebo'),
            ),
            backgroundColor: const Color(0xFFD4A3A3),
          ),
        );
      }
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD1C2D3),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  Widget _buildRoleOption(UserRole role, String description) {
    final isSelected = _selectedRole == role;
    final rbac = RbacService.instance;
    final canAssign = rbac.canAssignRole(role);

    return Opacity(
      opacity: canAssign ? 1.0 : 0.5,
      child: InkWell(
        onTap: canAssign ? () => setState(() => _selectedRole = role) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFD1C2D3).withValues(alpha: 0.2)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD1C2D3)
                  : Colors.grey.shade200,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Radio<UserRole>(
                value: role,
                groupValue: _selectedRole,
                onChanged: canAssign ? (value) => setState(() => _selectedRole = value) : null,
                activeColor: const Color(0xFFD1C2D3),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RoleBadge(role: role, fontSize: 12) as Widget,
                        if (!canAssign) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.lock,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Heebo',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rbac = RbacService.instance;
    final canRevoke = rbac.hasPermission(Permission.assignRoles);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Color(0xFFD1C2D3)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'שיוך תפקיד',
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    widget.userName,
                    style: TextStyle(
                      fontFamily: 'Heebo',
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current role display
                if (widget.currentRole != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'תפקיד נוכחי: ',
                          style: TextStyle(
                            fontFamily: 'Heebo',
                            color: Colors.grey.shade700,
                          ),
                        ),
                        RoleBadge(role: widget.currentRole!) as Widget,
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                const Text(
                  'בחירת תפקיד:',
                  style: TextStyle(
                    fontFamily: 'Heebo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Role options
                _buildRoleOption(
                  UserRole.superAdmin,
                  'גישה מלאה לכל האזורים, ניהול מנהלות',
                ),
                const SizedBox(height: 8),
                _buildRoleOption(
                  UserRole.admin,
                  'ניהול משתמשות, תוכן, דיווחים והגדרות',
                ),
                const SizedBox(height: 8),
                _buildRoleOption(
                  UserRole.moderator,
                  'ניהול תוכן, דיווחים ותקשורת',
                ),
                const SizedBox(height: 8),
                _buildRoleOption(
                  UserRole.viewer,
                  'צפייה בלבד בכל האזורים',
                ),
                
                const SizedBox(height: 20),
                
                // Expiry date
                InkWell(
                  onTap: _selectExpiryDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _expiresAt != null
                                ? 'תפקיד יפוג בתאריך: ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                                : 'ללא תאריך תפוגה',
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (_expiresAt != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _expiresAt = null),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Reason field
                TextField(
                  controller: _reasonController,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Heebo'),
                  decoration: InputDecoration(
                    labelText: 'סיבה (אופציונלי)',
                    labelStyle: const TextStyle(fontFamily: 'Heebo'),
                    hintText: 'למה משייכים תפקיד זה?',
                    hintStyle: TextStyle(
                      fontFamily: 'Heebo',
                      color: Colors.grey.shade400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (canRevoke && widget.currentRole != null)
            TextButton(
              onPressed: _isLoading ? null : _revokeRole,
              child: const Text(
                'ביטול תפקיד',
                style: TextStyle(
                  fontFamily: 'Heebo',
                  color: Colors.red,
                ),
              ),
            ),
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text(
              'ביטול',
              style: TextStyle(fontFamily: 'Heebo'),
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _assignRole,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD1C2D3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'שמור',
                    style: TextStyle(fontFamily: 'Heebo'),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Permission check widget for wrapping actions
class PermissionGuard extends StatelessWidget {
  final Permission permission;
  final Widget child;
  final VoidCallback? onDenied;

  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.onDenied,
  });

  void _showDeniedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'אין לך הרשאה לפעולה זו',
          style: TextStyle(fontFamily: 'Heebo'),
        ),
        backgroundColor: Color(0xFFD4A3A3),
      ),
    );
    onDenied?.call();
  }

  @override
  Widget build(BuildContext context) {
    final rbac = RbacService.instance;
    
    if (!rbac.hasPermission(permission)) {
      return InkWell(
        onTap: () => _showDeniedMessage(context),
        child: Opacity(
          opacity: 0.5,
          child: IgnorePointer(
            child: child,
          ),
        ),
      );
    }
    
    return child;
  }
}

/// Permission required dialog
class PermissionDeniedDialog extends StatelessWidget {
  final Permission permission;

  const PermissionDeniedDialog({
    super.key,
    required this.permission,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.lock, color: Color(0xFFD4A3A3)),
          SizedBox(width: 12),
          Text(
            'הרשאה נדרשת',
            style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          'אין לך הרשאה לבצע פעולה זה. פנה למנהלת המערכת לקבלת הרשאות נוספות.',
          style: TextStyle(fontFamily: 'Heebo', color: Colors.grey.shade700),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'הבנתי',
            style: TextStyle(fontFamily: 'Heebo'),
          ),
        ),
      ],
    );
  }
}
