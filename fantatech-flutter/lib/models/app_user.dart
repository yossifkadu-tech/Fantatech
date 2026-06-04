// ─────────────────────────────────────────────────────────────────────────────
// AppUser — persistent user record stored in USERS.CSV
// ─────────────────────────────────────────────────────────────────────────────

enum UserRole { homeManager, member }

enum AuthProvider { google, apple, member }

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

  const AppUser({
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
  });

  bool get isManager => role == UserRole.homeManager;

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? photoUrl,
    bool? isApproved,
    String? password,
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
    );
  }

  // ── CSV serialization ─────────────────────────────────────────────────────

  /// Returns a CSV row (9 fields, comma-separated, values quoted with ").
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
    ].join(',');
  }

  /// Parses a CSV row produced by [toCsvRow].
  static AppUser? fromCsvRow(String row) {
    try {
      final fields = _parseCsvRow(row);
      if (fields.length < 10) return null;
      return AppUser(
        id:           fields[0],
        name:         fields[1],
        email:        fields[2],
        phone:        fields[3],
        role:         UserRole.values.firstWhere(
                        (e) => e.name == fields[4],
                        orElse: () => UserRole.member),
        authProvider: AuthProvider.values.firstWhere(
                        (e) => e.name == fields[5],
                        orElse: () => AuthProvider.member),
        photoUrl:     fields[6].isEmpty ? null : fields[6],
        registeredAt: DateTime.tryParse(fields[7]) ?? DateTime.now(),
        invitedBy:    fields[8].isEmpty ? null : fields[8],
        isApproved:   fields[9] == '1',
        password:     fields.length > 10 ? fields[10] : '',
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
