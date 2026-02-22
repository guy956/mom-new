import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mom_connect/services/auth_service.dart';

/// User roles in the system
enum UserRole {
  superAdmin('super_admin', 'מנהלת על'),
  admin('admin', 'מנהלת'),
  moderator('moderator', 'מנחה'),
  viewer('viewer', 'צופה');

  final String value;
  final String displayName;
  
  const UserRole(this.value, this.displayName);

  static UserRole fromString(String? value) {
    switch (value) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      case 'viewer':
        return UserRole.viewer;
      default:
        return UserRole.viewer;
    }
  }
}

/// Permission types for different actions
enum Permission {
  // User management
  viewUsers('view_users'),
  editUsers('edit_users'),
  deleteUsers('delete_users'),
  approveUsers('approve_users'),
  banUsers('ban_users'),
  assignRoles('assign_roles'),
  
  // Content management
  viewContent('view_content'),
  editContent('edit_content'),
  deleteContent('delete_content'),
  approveContent('approve_content'),
  manageTips('manage_tips'),
  manageEvents('manage_events'),
  
  // Expert management
  viewExperts('view_experts'),
  editExperts('edit_experts'),
  approveExperts('approve_experts'),
  
  // Marketplace
  viewMarketplace('view_marketplace'),
  editMarketplace('edit_marketplace'),
  manageListings('manage_listings'),
  
  // Reports
  viewReports('view_reports'),
  handleReports('handle_reports'),
  
  // Media
  viewMedia('view_media'),
  uploadMedia('upload_media'),
  deleteMedia('delete_media'),
  
  // Communication
  sendNotifications('send_notifications'),
  manageCommunication('manage_communication'),
  
  // App configuration
  viewConfig('view_config'),
  editConfig('edit_config'),
  manageFeatures('manage_features'),
  manageUIDesign('manage_ui_design'),
  manageForms('manage_forms'),
  
  // Audit & Security
  viewAuditLog('view_audit_log'),
  manageSecurity('manage_security'),
  viewAnalytics('view_analytics'),
  
  // Admin management (super admin only)
  manageAdmins('manage_admins'),
  accessGodMode('access_god_mode');

  final String value;
  const Permission(this.value);
}

/// Role permissions mapping
class RolePermissions {
  static final Map<UserRole, List<Permission>> _permissions = {
    UserRole.superAdmin: [
      // All permissions
      ...Permission.values,
    ],
    UserRole.admin: [
      // Dashboard access
      Permission.accessGodMode,
      // User management
      Permission.viewUsers,
      Permission.editUsers,
      Permission.deleteUsers,
      Permission.approveUsers,
      Permission.banUsers,
      Permission.assignRoles,
      // Content management
      Permission.viewContent,
      Permission.editContent,
      Permission.deleteContent,
      Permission.approveContent,
      Permission.manageTips,
      Permission.manageEvents,
      // Expert management
      Permission.viewExperts,
      Permission.editExperts,
      Permission.approveExperts,
      // Marketplace
      Permission.viewMarketplace,
      Permission.editMarketplace,
      Permission.manageListings,
      // Reports
      Permission.viewReports,
      Permission.handleReports,
      // Media
      Permission.viewMedia,
      Permission.uploadMedia,
      Permission.deleteMedia,
      // Communication
      Permission.sendNotifications,
      Permission.manageCommunication,
      // Config
      Permission.viewConfig,
      Permission.editConfig,
      Permission.manageFeatures,
      Permission.manageUIDesign,
      Permission.manageForms,
      // Audit & Security
      Permission.viewAuditLog,
      Permission.manageSecurity,
      Permission.viewAnalytics,
    ],
    UserRole.moderator: [
      // Dashboard access
      Permission.accessGodMode,
      // User management (view only)
      Permission.viewUsers,
      // Content management
      Permission.viewContent,
      Permission.editContent,
      Permission.approveContent,
      Permission.manageTips,
      // Expert management (view only)
      Permission.viewExperts,
      // Marketplace (view only)
      Permission.viewMarketplace,
      // Reports
      Permission.viewReports,
      Permission.handleReports,
      // Media
      Permission.viewMedia,
      // Communication (limited)
      Permission.sendNotifications,
      // Config (view only)
      Permission.viewConfig,
      // Analytics
      Permission.viewAnalytics,
    ],
    UserRole.viewer: [
      // View-only access
      Permission.viewUsers,
      Permission.viewContent,
      Permission.viewExperts,
      Permission.viewMarketplace,
      Permission.viewReports,
      Permission.viewMedia,
      Permission.viewConfig,
      Permission.viewAuditLog,
      Permission.viewAnalytics,
    ],
  };

  static List<Permission> getPermissionsForRole(UserRole role) {
    return _permissions[role] ?? _permissions[UserRole.viewer]!;
  }

  static bool hasPermission(UserRole role, Permission permission) {
    final permissions = getPermissionsForRole(role);
    return permissions.contains(permission);
  }
}

/// User role data model
class UserRoleData {
  final String userId;
  final UserRole role;
  final String assignedBy;
  final DateTime assignedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  UserRoleData({
    required this.userId,
    required this.role,
    required this.assignedBy,
    required this.assignedAt,
    this.expiresAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role.value,
      'assignedBy': assignedBy,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'metadata': metadata,
    };
  }

  factory UserRoleData.fromMap(Map<String, dynamic> map) {
    return UserRoleData(
      userId: map['userId'] ?? '',
      role: UserRole.fromString(map['role']),
      assignedBy: map['assignedBy'] ?? '',
      assignedAt: (map['assignedAt'] as Timestamp).toDate(),
      expiresAt: map['expiresAt'] != null ? (map['expiresAt'] as Timestamp).toDate() : null,
      metadata: map['metadata'] ?? {},
    );
  }
}

/// RBAC Service for role-based access control
class RbacService extends ChangeNotifier {
  static final RbacService _instance = RbacService._internal();
  static RbacService get instance => _instance;

  RbacService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Current user's role cache
  UserRole? _currentUserRole;
  String? _currentUserId;
  
  // Stream controllers
  final _roleStreamController = StreamController<UserRole?>.broadcast();
  Stream<UserRole?> get roleStream => _roleStreamController.stream;

  /// Initialize RBAC for current user
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await _loadUserRole(userId);
  }

  /// Get current user's role
  UserRole? get currentUserRole => _currentUserRole;
  
  /// Check if current user has a specific role
  bool get isSuperAdmin => _currentUserRole == UserRole.superAdmin;
  bool get isAdmin => _currentUserRole == UserRole.admin || _currentUserRole == UserRole.superAdmin;
  bool get isModerator => _currentUserRole == UserRole.moderator || isAdmin;
  bool get isViewer => _currentUserRole == UserRole.viewer;

  /// Load user role from Firestore
  Future<void> _loadUserRole(String userId) async {
    try {
      final doc = await _db.collection('user_roles').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          _currentUserRole = UserRole.fromString(data['role']);
          
          // Check if role has expired
          if (data['expiresAt'] != null) {
            final expiresAt = (data['expiresAt'] as Timestamp).toDate();
            if (DateTime.now().isAfter(expiresAt)) {
              // Role expired, downgrade to viewer
              _currentUserRole = UserRole.viewer;
              await assignRole(
                userId: userId,
                role: UserRole.viewer,
                assignedBy: 'system',
                reason: 'Role expired',
              );
            }
          }
        }
      } else {
        // No role assigned, check if admin by email
        final userData = await AuthService.instance.getSavedSession();
        if (userData != null) {
          final email = userData['email'] as String? ?? '';
          if (AuthService.isAdminEmail(email)) {
            _currentUserRole = UserRole.superAdmin;
            // Create role entry
            await assignRole(
              userId: userId,
              role: UserRole.superAdmin,
              assignedBy: 'system',
              reason: 'Auto-assigned based on admin email',
            );
          } else {
            _currentUserRole = UserRole.viewer;
          }
        }
      }
      _roleStreamController.add(_currentUserRole);
      notifyListeners();
    } catch (e) {
      debugPrint('[RbacService] Error loading role: $e');
      _currentUserRole = UserRole.viewer;
      _roleStreamController.add(_currentUserRole);
      notifyListeners();
    }
  }

  /// Check if current user has a specific permission
  bool hasPermission(Permission permission) {
    if (_currentUserRole == null) return false;
    return RolePermissions.hasPermission(_currentUserRole!, permission);
  }

  /// Check permissions for multiple actions
  bool hasAnyPermission(List<Permission> permissions) {
    return permissions.any((p) => hasPermission(p));
  }

  bool hasAllPermissions(List<Permission> permissions) {
    return permissions.every((p) => hasPermission(p));
  }

  /// Assign a role to a user
  Future<bool> assignRole({
    required String userId,
    required UserRole role,
    required String assignedBy,
    DateTime? expiresAt,
    String? reason,
  }) async {
    try {
      // Check if current user can assign this role
      if (!canAssignRole(role)) {
        debugPrint('[RbacService] Cannot assign role: insufficient permissions');
        return false;
      }

      final roleData = UserRoleData(
        userId: userId,
        role: role,
        assignedBy: assignedBy,
        assignedAt: DateTime.now(),
        expiresAt: expiresAt,
        metadata: {
          'reason': reason,
          'previousRole': (await getUserRole(userId))?.value,
        },
      );

      await _db.collection('user_roles').doc(userId).set(roleData.toMap());
      
      // Log the role assignment
      await _logRoleChange(userId, role, assignedBy, reason);
      
      // If this is the current user, update cached role
      if (userId == _currentUserId) {
        _currentUserRole = role;
        _roleStreamController.add(_currentUserRole);
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('[RbacService] Error assigning role: $e');
      return false;
    }
  }

  /// Get a user's role
  Future<UserRole?> getUserRole(String userId) async {
    try {
      final doc = await _db.collection('user_roles').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          return UserRole.fromString(data['role']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[RbacService] Error getting user role: $e');
      return null;
    }
  }

  /// Stream of user role
  Stream<UserRole?> getUserRoleStream(String userId) {
    return _db.collection('user_roles').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          return UserRole.fromString(data['role']);
        }
      }
      return null;
    });
  }

  /// Get all user roles (super admin only)
  Stream<List<Map<String, dynamic>>> get allUserRolesStream {
    return _db.collection('user_roles').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userId': data['userId'],
          'role': data['role'],
          'assignedBy': data['assignedBy'],
          'assignedAt': data['assignedAt'],
          'expiresAt': data['expiresAt'],
        };
      }).toList();
    });
  }

  /// Revoke a user's role
  Future<bool> revokeRole(String userId, String revokedBy) async {
    try {
      if (!hasPermission(Permission.assignRoles)) {
        return false;
      }

      // Cannot revoke super admin unless you're super admin
      final targetRole = await getUserRole(userId);
      if (targetRole == UserRole.superAdmin && !isSuperAdmin) {
        return false;
      }

      await _db.collection('user_roles').doc(userId).delete();
      
      // Log the role revocation
      await _logRoleChange(userId, null, revokedBy, 'Role revoked');

      // If this is the current user, update cached role
      if (userId == _currentUserId) {
        _currentUserRole = UserRole.viewer;
        _roleStreamController.add(_currentUserRole);
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('[RbacService] Error revoking role: $e');
      return false;
    }
  }

  /// Check if current user can assign a specific role
  bool canAssignRole(UserRole role) {
    if (_currentUserRole == null) return false;
    
    // Super admin can assign any role
    if (_currentUserRole == UserRole.superAdmin) return true;
    
    // Admin can assign moderator and viewer roles only
    if (_currentUserRole == UserRole.admin) {
      return role == UserRole.moderator || role == UserRole.viewer;
    }
    
    // Moderator and viewer cannot assign roles
    return false;
  }

  /// Log role changes to activity log
  Future<void> _logRoleChange(String userId, UserRole? newRole, String changedBy, String? reason) async {
    try {
      await _db.collection('activity_log').add({
        'action': newRole == null ? 'Role Revoked' : 'Role Assigned',
        'user': userId,
        'type': 'role',
        'details': {
          'newRole': newRole?.value,
          'changedBy': changedBy,
          'reason': reason,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[RbacService] Error logging role change: $e');
    }
  }

  /// Get permissions for the current user
  List<Permission> get currentUserPermissions {
    if (_currentUserRole == null) return [];
    return RolePermissions.getPermissionsForRole(_currentUserRole!);
  }

  /// Get permissions for a specific role
  static List<Permission> getPermissionsForRole(UserRole role) {
    return RolePermissions.getPermissionsForRole(role);
  }

  /// Check if user can access a specific admin tab
  bool canAccessTab(String tabName) {
    switch (tabName) {
      case 'overview':
        return hasPermission(Permission.viewAnalytics);
      case 'users':
        return hasPermission(Permission.viewUsers);
      case 'experts':
        return hasPermission(Permission.viewExperts);
      case 'media':
        return hasPermission(Permission.viewMedia);
      case 'events':
        return hasPermission(Permission.manageEvents);
      case 'marketplace':
        return hasPermission(Permission.viewMarketplace);
      case 'content':
        return hasPermission(Permission.viewContent);
      case 'reports':
        return hasPermission(Permission.viewReports);
      case 'config':
        return hasPermission(Permission.viewConfig);
      case 'features':
        return hasPermission(Permission.manageFeatures);
      case 'design':
        return hasPermission(Permission.manageUIDesign);
      case 'communication':
        return hasPermission(Permission.manageCommunication);
      case 'forms':
        return hasPermission(Permission.manageForms);
      case 'audit':
        return hasPermission(Permission.viewAuditLog);
      default:
        return false;
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _roleStreamController.close();
    super.dispose();
  }
}

/// Widget builder that conditionally renders based on permission
class PermissionBuilder extends StatelessWidget {
  final Permission permission;
  final Widget child;
  final Widget? fallback;

  const PermissionBuilder({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final rbacService = RbacService.instance;
    if (rbacService.hasPermission(permission)) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

/// Role badge widget for displaying user roles
class RoleBadge extends StatelessWidget {
  final UserRole role;
  final double fontSize;

  const RoleBadge({
    super.key,
    required this.role,
    this.fontSize = 10,
  });

  Color get _roleColor {
    switch (role) {
      case UserRole.superAdmin:
        return const Color(0xFF8E44AD); // Purple
      case UserRole.admin:
        return const Color(0xFFE74C3C); // Red
      case UserRole.moderator:
        return const Color(0xFF3498DB); // Blue
      case UserRole.viewer:
        return const Color(0xFF95A5A6); // Gray
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _roleColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _roleColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.displayName,
        style: TextStyle(
          fontFamily: 'Heebo',
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: _roleColor,
        ),
      ),
    );
  }
}

/// Extension methods for easier permission checking
extension RbacExtension on BuildContext {
  RbacService get rbac => RbacService.instance;
  
  bool hasPermission(Permission permission) {
    return rbac.hasPermission(permission);
  }
  
  bool canAssignRole(UserRole role) {
    return rbac.canAssignRole(role);
  }
}
