// ─────────────────────────────────────────────────────────────────────────────
// AppUser — persistent user record stored in USERS.CSV
// ─────────────────────────────────────────────────────────────────────────────

enum UserRole { homeManager, member }

enum AuthProvider { google, apple, member }

/// Granular actions a user may or may not be allowed to perform. Every user
/// gets [defaultPermissionsFor]'s set for their [UserRole] unless overridden
/// explicitly (e.g. a manager narrowing what a specific member can do).
enum Permission {
  controlDevices,    // lights / switches / plugs / blinds / climate
  controlSecurity,   // arm / disarm / panic
  viewCameras,
  manageAutomations, // create / edit / delete IF-THEN automations
  manageUsers,       // invite / remove household members, join code
  manageBilling,     // subscription plan & payment method
  viewEnergyData,
}

/// The permission set a role gets unless a user's record overrides it.
/// Both roles can operate the home day-to-day; only the manager can manage
/// *who else* is in the home or *how it's billed*.
Set<Permission> defaultPermissionsFor(UserRole role) => switch (role) {
      UserRole.homeManager => Permission.values.toSet(),
      UserRole.member => const {
          Permission.controlDevices,
          Permission.controlSecurity,
          Permission.viewCameras,
          Permission.manageAutomations,
          Permission.viewEnergyData,
        },
    };

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final AuthProvider authProvider;
  final String? photoUrl;
  final DateTime registeredAt;
  final String? invitedBy; // id of home manager who added this member
  final bool isApproved;
  final String password; // local-auth password (empty for SSO/member accounts)
  final Set<Permission> permissions;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
    required this.authProvider,
    this.photoUrl,
    required this.registeredAt,
    this.invitedBy,
    this.isApproved = true,
    this.password = '',
    Set<Permission>? permissions,
  }) : permissions = permissions ?? defaultPermissionsFor(role);

  bool get isManager => role == UserRole.homeManager;
  bool can(Permission p) => permissions.contains(p);

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? photoUrl,
    bool? isApproved,
    String? password,
    Set<Permission>? permissions,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      authProvider: authProvider,
      photoUrl: photoUrl ?? this.photoUrl,
      registeredAt: registeredAt,
      invitedBy: invitedBy,
      isApproved: isApproved ?? this.isApproved,
      password: password ?? this.password,
      // Explicit overrides win; otherwise keep this user's current grants —
      // unless the role itself is changing, in which case re-derive the
      // defaults for the new role.
      permissions: permissions ?? (role != null ? null : this.permissions),
    );
  }

  // ── CSV serialization ─────────────────────────────────────────────────────

  /// Returns a CSV row (12 fields, comma-separated, values quoted with ").
  String toCsvRow() {
    return [
      _q(id),
      _q(name),
      _q(email),
      _q(phone),
      _q(role.name),
      _q(authProvider.name),
      _q(photoUrl ?? ''),
      _q(registeredAt.toIso8601String()),
      _q(invitedBy ?? ''),
      _q(isApproved ? '1' : '0'),
      _q(password),
      _q(permissions.map((p) => p.name).join('|')),
    ].join(',');
  }

  /// Parses a CSV row produced by [toCsvRow].
  static AppUser? fromCsvRow(String row) {
    try {
      final fields = _parseCsvRow(row);
      if (fields.length < 10) return null;
      final role = UserRole.values.firstWhere(
          (e) => e.name == fields[4], orElse: () => UserRole.member);
      // Field 11 (permissions) is absent on rows written before this feature
      // existed — those users fall back to their role's default grants.
      final hasPermField = fields.length > 11 && fields[11].isNotEmpty;
      return AppUser(
        id:           fields[0],
        name:         fields[1],
        email:        fields[2],
        phone:        fields[3],
        role:         role,
        authProvider: AuthProvider.values.firstWhere(
                        (e) => e.name == fields[5],
                        orElse: () => AuthProvider.member),
        photoUrl:     fields[6].isEmpty ? null : fields[6],
        registeredAt: DateTime.tryParse(fields[7]) ?? DateTime.now(),
        invitedBy:    fields[8].isEmpty ? null : fields[8],
        isApproved:   fields[9] == '1',
        password:     fields.length > 10 ? fields[10] : '',
        permissions:  hasPermField
            ? Permission.values
                .where((p) => fields[11].split('|').contains(p.name))
                .toSet()
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _q(String v) => '"${v.replaceAll('"', '""')}"';

  /// Minimal CSV parser — handles double-quoted fields.
  static List<String> _parseCsvRow(String row) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inQuote = false;
    for (int i = 0; i < row.length; i++) {
      final ch = row[i];
      if (inQuote) {
        if (ch == '"') {
          if (i + 1 < row.length && row[i + 1] == '"') {
            buf.write('"');
            i++; // skip escaped quote
          } else {
            inQuote = false;
          }
        } else {
          buf.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuote = true;
        } else if (ch == ',') {
          result.add(buf.toString());
          buf.clear();
        } else {
          buf.write(ch);
        }
      }
    }
    result.add(buf.toString());
    return result;
  }
}
