class User {
  final String? id;
  final String username;
  final String? email;
  final String? npk;
  final String? name;
  final String? fullName;
  final String? department;
  final String? phoneNumber;
  final String? photo;
  final String? photoUrl;
  final int? type;
  final bool? isAdmin;
  final bool? isLocked;
  final int? loginAttempts;
  final String? roleId;
  final String? roleName;
  final String? vendorCode;
  final String? vendorName;
  final UserRole? role;

  User({
    this.id,
    required this.username,
    this.email,
    this.npk,
    this.name,
    this.fullName,
    this.department,
    this.phoneNumber,
    this.photo,
    this.photoUrl,
    this.type,
    this.isAdmin,
    this.isLocked,
    this.loginAttempts,
    this.roleId,
    this.roleName,
    this.vendorCode,
    this.vendorName,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString(),
      username: json['username'] ?? '',
      email: json['email'],
      npk: json['npk'],
      name: json['name'] ?? json['full_name'],
      fullName: json['full_name'],
      department: json['department'],
      phoneNumber: json['phone_number'],
      photo: json['photo'],
      photoUrl: json['photo_url'],
      type: json['type'] is int
          ? json['type']
          : (json['type'] != null
                ? int.tryParse(json['type'].toString())
                : null),
      isAdmin: json['is_admin'],
      isLocked: json['is_locked'],
      loginAttempts: json['login_attempts'] is int
          ? json['login_attempts']
          : (json['login_attempts'] != null
                ? int.tryParse(json['login_attempts'].toString())
                : null),
      roleId: json['role_id']?.toString(),
      roleName: json['role_name'],
      vendorCode: json['vendor_code'],
      vendorName: json['vendor_name'],
      role: json['role'] != null ? UserRole.fromJson(json['role']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'npk': npk,
      'name': name,
      'full_name': fullName,
      'department': department,
      'phone_number': phoneNumber,
      'photo': photo,
      'photo_url': photoUrl,
      'type': type,
      'is_admin': isAdmin,
      'is_locked': isLocked,
      'login_attempts': loginAttempts,
      'role_id': roleId,
      'role_name': roleName,
      'vendor_code': vendorCode,
      'vendor_name': vendorName,
      'role': role?.toJson(),
    };
  }
}

class UserRole {
  final String? id;
  final String name;
  final String? description;
  final String? displayName;
  final List<Permission>? permissions;

  UserRole({
    this.id,
    required this.name,
    this.description,
    this.displayName,
    this.permissions,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['_id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'],
      displayName: json['display_name'],
      permissions: json['permissions'] != null
          ? (json['permissions'] as List)
                .map((p) => Permission.fromJson(p))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'display_name': displayName,
      'permissions': permissions?.map((p) => p.toJson()).toList(),
    };
  }
}

class Permission {
  final dynamic id;
  final String name;
  final String? url;
  final String? icon;
  final bool allow;
  final List<Permission>? children;

  Permission({
    required this.id,
    required this.name,
    this.url,
    this.icon,
    required this.allow,
    this.children,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['_id'] ?? json['id'] ?? json['permission_id'],
      name: json['name'] ?? '',
      url: json['url'],
      icon: json['icon'],
      allow: json['allow'] ?? false,
      children: json['children'] != null
          ? (json['children'] as List)
                .map((c) => Permission.fromJson(c))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'url': url,
      'icon': icon,
      'allow': allow,
      'children': children?.map((c) => c.toJson()).toList(),
    };
  }
}
