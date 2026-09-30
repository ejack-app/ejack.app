enum UserRole { driver, customer, manager, admin, unknown }

UserRole roleFromString(String? s) {
  switch (s?.toLowerCase()) {
    case 'driver':
      return UserRole.driver;
    case 'customer':
    case 'client':
      return UserRole.customer;
    case 'manager':
      return UserRole.manager;
    case 'admin':
    case 'superuser':
      return UserRole.admin;
    default:
      return UserRole.unknown;
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatar,
  });

  final int id;
  final String username;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? avatar;

  factory AppUser.fromJson(Map<String, dynamic> j) {
    // Accepts several common Django shapes; adjust to match your serializer.
    final roleRaw = j['role'] ?? j['user_type'] ?? j['profile']?['role'];
    final fullName = (j['full_name'] ??
            [j['first_name'], j['last_name']]
                .where((p) => p != null && (p as String).isNotEmpty)
                .join(' ')) as String;

    return AppUser(
      id: (j['id'] ?? j['pk'] ?? 0) as int,
      username: (j['username'] ?? '') as String,
      email: (j['email'] ?? '') as String,
      fullName: fullName.isEmpty ? (j['username'] ?? '') as String : fullName,
      role: roleFromString(roleRaw as String?),
      phone: j['phone'] as String?,
      avatar: (j['avatar'] ?? j['profile']?['avatar']) as String?,
    );
  }
}
