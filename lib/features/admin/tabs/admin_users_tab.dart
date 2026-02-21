import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/rbac_service.dart';
import 'package:mom_connect/features/admin/widgets/admin_shared_widgets.dart';
import 'package:mom_connect/features/admin/widgets/role_assignment_widget.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  String _searchQuery = '';
  String _statusFilter = 'הכל';

  final List<String> _filters = ['הכל', 'פעילות', 'ממתינות', 'חסומות'];

  String _filterToStatus(String filter) {
    switch (filter) {
      case 'פעילות':
        return 'active';
      case 'ממתינות':
        return 'pending';
      case 'חסומות':
        return 'banned';
      default:
        return 'all';
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> users) {
    return users.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final name = (user['fullName'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!name.contains(query) && !email.contains(query)) {
          return false;
        }
      }

      // Status filter
      if (_statusFilter != 'הכל') {
        final status = user['status'] ?? 'active';
        if (status != _filterToStatus(_statusFilter)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _approveUser(
    FirestoreService fs,
    String id,
    String name,
  ) async {
    await fs.updateUserStatus(id, 'active');
    await fs.logActivity(
      action: 'אישור משתמשת',
      user: name,
      type: 'user',
    );
    if (mounted) {
      AdminWidgets.snack(context, 'המשתמשת אושרה בהצלחה');
    }
  }

  Future<void> _banUser(
    FirestoreService fs,
    String id,
    String name,
  ) async {
    await fs.updateUserStatus(id, 'banned');
    await fs.logActivity(
      action: 'חסימה',
      user: name,
      type: 'user',
    );
    if (mounted) {
      AdminWidgets.snack(context, 'המשתמשת נחסמה');
    }
  }

  Future<void> _makeAdmin(
    FirestoreService fs,
    String id,
    String name,
  ) async {
    await fs.setUserAdmin(id, true);
    await fs.logActivity(
      action: 'הפוך למנהלת',
      user: name,
      type: 'user',
    );
    if (mounted) {
      AdminWidgets.snack(context, 'המשתמשת הוגדרה כמנהלת');
    }
  }

  Future<void> _unblockUser(
    FirestoreService fs,
    String id,
    String name,
  ) async {
    await fs.updateUserStatus(id, 'active');
    await fs.logActivity(
      action: 'ביטול חסימה',
      user: name,
      type: 'user',
    );
    if (mounted) {
      AdminWidgets.snack(context, 'המשתמשת שוחררה מחסימה');
    }
  }

  void _showUserProfileDialog(BuildContext context, Map<String, dynamic> user, FirestoreService fs) {
    final id = user['id'] ?? '';
    final fullName = user['fullName'] ?? '';
    final email = user['email'] ?? '';
    final city = user['city'] ?? '';
    final phone = user['phone'] ?? '';
    final status = user['status'] ?? 'active';
    final isAdmin = user['isAdmin'] == true;
    final bio = user['bio'] ?? '';
    final posts = user['posts'] ?? 0;
    final reports = user['reports'] ?? 0;
    final rbac = RbacService.instance;

    String createdAt = '';
    try {
      final ts = user['createdAt'];
      if (ts != null) {
        final dt = ts is DateTime ? ts : ts.toDate();
        createdAt = '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFD1C2D3),
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(fullName.isNotEmpty ? fullName : email, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold, fontSize: 16)),
              Row(children: [
                AdminWidgets.statusChip(status),
                if (isAdmin) ...[const SizedBox(width: 6), AdminWidgets.chip('מנהלת', const Color(0xFFE8D5B7), const Color(0xFF795548))],
              ]),
              const SizedBox(height: 4),
              // Show current role from RBAC
              StreamBuilder<UserRole?>(
                stream: rbac.getUserRoleStream(id),
                builder: (context, snapshot) {
                  final role = snapshot.data;
                  if (role != null) {
                    return RoleBadge(role: role, fontSize: 9);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ])),
          ]),
          content: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Divider(),
              _profileRow(Icons.email, 'אימייל', email),
              if (phone.isNotEmpty) _profileRow(Icons.phone, 'טלפון', phone),
              if (city.isNotEmpty) _profileRow(Icons.location_on, 'עיר', city),
              if (bio.isNotEmpty) _profileRow(Icons.info_outline, 'ביוגרפיה', bio),
              if (createdAt.isNotEmpty) _profileRow(Icons.calendar_today, 'תאריך הרשמה', createdAt),
              if (user['lastLogin'] != null) _profileRow(Icons.login, 'כניסה אחרונה', _formatTimestamp(user['lastLogin'])),
              _profileRow(Icons.article, 'פוסטים', '$posts'),
              _profileRow(Icons.flag, 'דיווחים', '$reports'),
              const Divider(height: 24),
              // Quick actions
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (status == 'pending' && rbac.hasPermission(Permission.approveUsers))
                  _profileAction('אשר', Icons.check_circle, Colors.green, () async {
                    await _approveUser(fs, id, fullName);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }),
                if (status == 'banned' && rbac.hasPermission(Permission.banUsers))
                  _profileAction('שחרר חסימה', Icons.lock_open, Colors.teal, () async {
                    await _unblockUser(fs, id, fullName);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }),
                if (status != 'banned' && rbac.hasPermission(Permission.banUsers))
                  _profileAction('חסום', Icons.block, Colors.red, () async {
                    await _banUser(fs, id, fullName);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }),
                if (!isAdmin && rbac.hasPermission(Permission.assignRoles))
                  _profileAction('הפוך למנהלת', Icons.admin_panel_settings, Colors.orange, () async {
                    await _makeAdmin(fs, id, fullName);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }),
                // Role assignment button
                if (rbac.hasPermission(Permission.assignRoles))
                  _profileAction('שייך תפקיד', Icons.manage_accounts, const Color(0xFF8E44AD), () async {
                    Navigator.pop(ctx);
                    await RoleAssignmentDialog.show(
                      context: context,
                      userId: id,
                      userName: fullName.isNotEmpty ? fullName : email,
                      userEmail: email,
                    );
                  }),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('סגור', style: TextStyle(fontFamily: 'Heebo'))),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _deleteUser(fs, id, fullName);
              },
              child: Text('מחק', style: TextStyle(fontFamily: 'Heebo', color: Colors.red.shade400)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    try {
      final dt = ts is DateTime ? ts : ts.toDate();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  void _exportUsersToClipboard(List<Map<String, dynamic>> users) {
    final buffer = StringBuffer();
    buffer.writeln('שם,אימייל,עיר,סטטוס,תאריך הרשמה');
    for (final user in users) {
      final name = user['fullName'] ?? '';
      final email = user['email'] ?? '';
      final city = user['city'] ?? '';
      final status = user['status'] ?? 'active';
      String createdAt = '';
      try {
        final ts = user['createdAt'];
        if (ts != null) {
          final dt = ts is DateTime ? ts : ts.toDate();
          createdAt = '${dt.day}/${dt.month}/${dt.year}';
        }
      } catch (_) {}
      buffer.writeln('$name,$email,$city,$status,$createdAt');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    AdminWidgets.snack(context, 'הנתונים הועתקו ללוח');
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontFamily: 'Heebo', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Heebo', fontSize: 13))),
      ]),
    );
  }

  Widget _profileAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontFamily: 'Heebo', fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _deleteUser(
    FirestoreService fs,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'מחיקת משתמשת',
          style: TextStyle(fontFamily: 'Heebo'),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'האם את בטוחה שברצונך למחוק את $name?',
          style: const TextStyle(fontFamily: 'Heebo'),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'ביטול',
              style: TextStyle(fontFamily: 'Heebo'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'מחק',
              style: TextStyle(
                fontFamily: 'Heebo',
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await fs.deleteUser(id);
      await fs.logActivity(
        action: 'מחק',
        user: name,
        type: 'user',
      );
      if (mounted) {
        AdminWidgets.snack(context, 'המשתמשת נמחקה');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Container(
      color: const Color(0xFFF9F5F4),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Heebo'),
              decoration: InputDecoration(
                hintText: 'חיפוש לפי שם או אימייל...',
                hintStyle: const TextStyle(fontFamily: 'Heebo'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                children: _filters.map((filter) {
                  final isSelected = _statusFilter == filter;
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
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _statusFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // User list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: fs.usersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'שגיאה בטעינת משתמשות',
                      style: const TextStyle(fontFamily: 'Heebo'),
                    ),
                  );
                }

                final allUsers = snapshot.data ?? [];
                final filteredUsers = _applyFilters(allUsers);

                if (filteredUsers.isEmpty) {
                  return AdminWidgets.emptyState('אין משתמשות');
                }

                return Column(
                  children: [
                    // User count badge + export button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1C2D3).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${filteredUsers.length} משתמשות',
                              style: const TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _exportUsersToClipboard(filteredUsers),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text(
                              'ייצוא',
                              style: TextStyle(fontFamily: 'Heebo', fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFD1C2D3),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Users list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final id = user['id'] ?? '';
                          final fullName = user['fullName'] ?? '';
                          final email = user['email'] ?? '';
                          final city = user['city'] ?? '';
                          final status = user['status'] ?? 'active';
                          final displayName =
                              fullName.isNotEmpty ? fullName : email;
                          final firstLetter = displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?';

                          return Card(
                            color: Colors.white,
                            elevation: 1,
                            shadowColor: Colors.black12,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              onTap: () => _showUserProfileDialog(context, user, fs),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFD1C2D3),
                                child: Text(
                                  firstLetter,
                                  style: const TextStyle(
                                    fontFamily: 'Heebo',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              title: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontFamily: 'Heebo',
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AdminWidgets.statusChip(status),
                                ],
                              ),
                              subtitle: Text(
                                city.isNotEmpty
                                    ? '$email \u00B7 $city'
                                    : email,
                                style: const TextStyle(
                                  fontFamily: 'Heebo',
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.rtl,
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) async {
                                  final rbac = RbacService.instance;
                                  switch (value) {
                                    case 'approve':
                                      if (rbac.hasPermission(Permission.approveUsers)) {
                                        await _approveUser(fs, id, displayName);
                                      }
                                      break;
                                    case 'ban':
                                      if (rbac.hasPermission(Permission.banUsers)) {
                                        await _banUser(fs, id, displayName);
                                      }
                                      break;
                                    case 'unblock':
                                      if (rbac.hasPermission(Permission.banUsers)) {
                                        await _unblockUser(fs, id, displayName);
                                      }
                                      break;
                                    case 'makeAdmin':
                                      if (rbac.hasPermission(Permission.assignRoles)) {
                                        await _makeAdmin(fs, id, displayName);
                                      }
                                      break;
                                    case 'assignRole':
                                      if (rbac.hasPermission(Permission.assignRoles)) {
                                        await RoleAssignmentDialog.show(
                                          context: context,
                                          userId: id,
                                          userName: displayName,
                                          userEmail: email,
                                        );
                                      }
                                      break;
                                    case 'delete':
                                      if (rbac.hasPermission(Permission.deleteUsers)) {
                                        await _deleteUser(fs, id, displayName);
                                      }
                                      break;
                                  }
                                },
                                itemBuilder: (context) {
                                  final rbac = RbacService.instance;
                                  return [
                                  if (status == 'pending' && rbac.hasPermission(Permission.approveUsers))
                                    const PopupMenuItem(
                                      value: 'approve',
                                      child: Text(
                                        'אישור',
                                        style: TextStyle(fontFamily: 'Heebo'),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  if (status == 'banned' && rbac.hasPermission(Permission.banUsers))
                                    const PopupMenuItem(
                                      value: 'unblock',
                                      child: Text(
                                        'שחרר חסימה',
                                        style: TextStyle(fontFamily: 'Heebo', color: Colors.teal),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  if (status != 'banned' && rbac.hasPermission(Permission.banUsers))
                                    const PopupMenuItem(
                                      value: 'ban',
                                      child: Text(
                                        'חסימה',
                                        style: TextStyle(fontFamily: 'Heebo'),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  if (rbac.hasPermission(Permission.assignRoles))
                                    const PopupMenuItem(
                                      value: 'assignRole',
                                      child: Text(
                                        'שיוך תפקיד',
                                        style: TextStyle(fontFamily: 'Heebo', color: Color(0xFF8E44AD)),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  if (rbac.hasPermission(Permission.deleteUsers))
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'מחק',
                                        style: TextStyle(
                                          fontFamily: 'Heebo',
                                          color: Colors.red,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                ];}
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
