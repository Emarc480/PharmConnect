/// The two actors from the proposal's use-case diagram: Customer and
/// Pharmacy Staff. This drives login-time routing and screen guards.
enum UserRole { customer, staff }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.staff:
        return 'Pharmacy Staff';
    }
  }

  static UserRole fromName(String name) {
    return UserRole.values.firstWhere(
      (r) => r.name == name,
      orElse: () => UserRole.customer,
    );
  }
}

/// Mirrors the ERD's USER entity (user_id, name, email, role).
/// passwordHash is intentionally absent here — Firebase Auth stores and
/// hashes it server-side, so the app never sees or stores it (NFR4).
class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool deletionRequested;

  /// Grants access to the Staff Management screen (promoting/demoting
  /// staff, deactivating accounts). Defaults false for everyone —
  /// there's no client-side way to create the first admin, so it must
  /// be set to `true` on a staff user's Firestore doc from the
  /// console once, to bootstrap access.
  final bool isAdmin;

  /// Staff-only "soft disable" switch an admin can flip instead of
  /// deleting an account outright (client apps can't delete other
  /// Firebase Auth users without the Admin SDK). Deactivated staff are
  /// treated as non-staff by [StaffOnly] guards. Always true for
  /// customers.
  final bool isActive;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.deletionRequested = false,
    this.isAdmin = false,
    this.isActive = true,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      role: UserRoleLabel.fromName((map['role'] as String?) ?? 'customer'),
      deletionRequested: (map['deletionRequested'] as bool?) ?? false,
      isAdmin: (map['isAdmin'] as bool?) ?? false,
      isActive: (map['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'deletionRequested': deletionRequested,
      'isAdmin': isAdmin,
      'isActive': isActive,
    };
  }

  AppUser copyWith({bool? deletionRequested}) => AppUser(
    uid: uid,
    name: name,
    email: email,
    role: role,
    deletionRequested: deletionRequested ?? this.deletionRequested,
    isAdmin: isAdmin,
    isActive: isActive,
  );
}
