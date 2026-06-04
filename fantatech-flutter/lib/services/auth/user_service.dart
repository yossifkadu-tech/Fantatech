// ─────────────────────────────────────────────────────────────────────────────
// UserService — manages app users, persisted to USERS.CSV
//
// Roles:
//   HomeManager — the first user to sign in with Google/Apple.
//                 Can add/remove household members.
//   Member      — added by the manager; no auth required.
//
// Storage:
//   {documents}/fantatech_users.csv   — all users
//   SharedPreferences 'current_user_id' — active session
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:uuid/uuid.dart';

import '../../models/app_user.dart';

class UserService {
  UserService._();

  static const _prefCurrentUserId = 'current_user_id';
  static const _csvFileName = 'yossiini.csv';
  static const _csvHeader = 'id,name,email,phone,role,authProvider,photoUrl,registeredAt,invitedBy,isApproved,password';

  // Default seed account(s) — created on first run so there is a user to start
  // from. Email login validates against these (and any later registrations).
  static const _seedManagerEmail    = 'yossi@gmail.com';
  static const _seedManagerName     = 'יוסי';
  static const _seedManagerPassword = '123456';

  static final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  static const _uuid = Uuid();

  // ── In-memory state ───────────────────────────────────────────────────────

  static final List<AppUser> _users = [];
  static AppUser? _currentUser;

  /// Last email used to sign in / register — prefilled on the login screen.
  static String? lastEmail;

  static AppUser?  get currentUser  => _currentUser;
  static bool      get isLoggedIn   => _currentUser != null;
  static AppUser?  get homeManager  =>
      _users.where((u) => u.isManager).firstOrNull;
  static List<AppUser> get allUsers => List.unmodifiable(_users);
  static List<AppUser> get members  =>
      _users.where((u) => !u.isManager).toList();

  // ── Init / Persistence ────────────────────────────────────────────────────

  /// Call once at app startup (before showing any screen).
  static Future<void> init() async {
    await _loadCsv();
    await _seedDefaultsIfEmpty();
    final prefs = await SharedPreferences.getInstance();
    lastEmail = prefs.getString('last_email');
    final savedId = prefs.getString(_prefCurrentUserId);
    if (savedId != null) {
      _currentUser = _users.where((u) => u.id == savedId).firstOrNull;
    }
  }

  static Future<void> _rememberEmail(String email) async {
    lastEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_email', email);
  }

  /// Creates the default manager account on first run (empty store).
  static Future<void> _seedDefaultsIfEmpty() async {
    if (_users.isNotEmpty) return;
    _users.add(AppUser(
      id:           _uuid.v4(),
      name:         _seedManagerName,
      email:        _seedManagerEmail,
      phone:        '',
      role:         UserRole.homeManager,
      authProvider: AuthProvider.member,
      photoUrl:     null,
      registeredAt: DateTime.now(),
      invitedBy:    null,
      isApproved:   true,
      password:     _seedManagerPassword,
    ));
    await _saveCsv();
  }

  static Future<File?> _csvFile() async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_csvFileName');
  }

  static Future<void> _loadCsv() async {
    _users.clear();
    final file = await _csvFile();
    if (file == null || !await file.exists()) return;
    final lines = await file.readAsLines();
    for (final line in lines) {
      if (line.trim().isEmpty || line.startsWith('id,')) continue;
      final user = AppUser.fromCsvRow(line);
      if (user != null) _users.add(user);
    }
  }

  static Future<void> _saveCsv() async {
    final file = await _csvFile();
    if (file == null) return;
    final buf = StringBuffer('$_csvHeader\n');
    for (final u in _users) {
      buf.writeln(u.toCsvRow());
    }
    await file.writeAsString(buf.toString());
  }

  static Future<void> _persistSession(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      await prefs.remove(_prefCurrentUserId);
    } else {
      await prefs.setString(_prefCurrentUserId, userId);
    }
  }

  // ── Email / Password (local auth) ────────────────────────────────────────

  static final _emailRegex =
      RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w.\-]+$');

  /// Returns true if [email] is a syntactically valid address.
  static bool isValidEmail(String email) =>
      _emailRegex.hasMatch(email.trim());

  /// Returns true if [password] meets the minimum policy (≥ 6 chars).
  static bool isValidPassword(String password) => password.length >= 6;

  /// Email + password login. Requires a valid email and a valid password that
  /// matches an existing account. Throws a Hebrew message on any failure.
  static Future<AppUser> signInWithEmail(String email, String password) async {
    final e = email.trim().toLowerCase();
    if (!isValidEmail(e)) {
      throw Exception('כתובת אימייל לא תקינה');
    }
    if (!isValidPassword(password)) {
      throw Exception('סיסמה לא תקינה (לפחות 6 תווים)');
    }
    final user = _users.where((u) => u.email.toLowerCase() == e).firstOrNull;
    if (user == null) {
      throw Exception('לא נמצא משתמש עם אימייל זה — הירשם תחילה');
    }
    if (user.password != password) {
      throw Exception('סיסמה שגויה');
    }
    _currentUser = user;
    await _persistSession(user.id);
    await _rememberEmail(e);
    return user;
  }

  /// Registers a new email/password account (used by the register screen).
  /// The first account created becomes the home manager.
  static Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final e = email.trim().toLowerCase();
    if (!isValidEmail(e)) throw Exception('כתובת אימייל לא תקינה');
    if (!isValidPassword(password)) {
      throw Exception('סיסמה לא תקינה (לפחות 6 תווים)');
    }
    if (_users.any((u) => u.email.toLowerCase() == e)) {
      throw Exception('כבר קיים משתמש עם אימייל זה');
    }
    final isFirstUser = _users.isEmpty || homeManager == null;
    final user = AppUser(
      id:           _uuid.v4(),
      name:         name.trim().isNotEmpty ? name.trim() : e.split('@').first,
      email:        e,
      phone:        '',
      role:         isFirstUser ? UserRole.homeManager : UserRole.member,
      authProvider: AuthProvider.member,
      photoUrl:     null,
      registeredAt: DateTime.now(),
      invitedBy:    isFirstUser ? null : homeManager?.id,
      isApproved:   true,
      password:     password,
    );
    _users.add(user);
    await _saveCsv();
    _currentUser = user;
    await _persistSession(user.id);
    await _rememberEmail(e);
    return user;
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  /// Signs in with Google. Returns the AppUser (created or existing).
  /// Throws a user-readable Hebrew message on failure.
  static Future<AppUser> signInWithGoogle() async {
    try {
      // Ensure any previous session is cleared first (avoids stale token errors)
      await _googleSignIn.signOut().catchError((_) => null);

      final account = await _googleSignIn.signIn();
      if (account == null) throw Exception('הכניסה בוטלה');

      return _resolveOrCreateManager(
        email:    account.email,
        name:     account.displayName ?? account.email,
        photoUrl: account.photoUrl,
        provider: AuthProvider.google,
      );
    } catch (e) {
      final msg = e.toString();
      // ApiException 10 = DEVELOPER_ERROR → google-services.json not configured
      if (msg.contains('ApiException: 10') || msg.contains('DEVELOPER_ERROR')) {
        throw Exception(
          'כניסה עם Google אינה מוגדרת עדיין.\n'
          'הוסף את קובץ google-services.json מה-Firebase Console\n'
          'לתיקייה android/app/ ובנה מחדש.',
        );
      }
      // ApiException 7 = NETWORK_ERROR
      if (msg.contains('ApiException: 7') || msg.contains('NETWORK_ERROR')) {
        throw Exception('אין חיבור לרשת. בדוק את החיבור ונסה שוב.');
      }
      // ApiException 12500 = sign-in required (Play Services update needed)
      if (msg.contains('12500')) {
        throw Exception('נדרש עדכון של Google Play Services.');
      }
      // User cancelled (null account / sign_in_cancelled)
      if (msg.contains('cancelled') || msg.contains('sign_in_cancelled')) {
        throw Exception('הכניסה בוטלה');
      }
      rethrow;
    }
  }

  /// Creates a local account using a Google email address (offline fallback).
  /// Used when OAuth is not configured but the user wants a Google-linked profile.
  static Future<AppUser> signInWithGoogleEmail(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('כתובת אימייל לא תקינה');
    }
    return _resolveOrCreateManager(
      email:    email.trim().toLowerCase(),
      name:     email.split('@').first,
      photoUrl: null,
      provider: AuthProvider.google,
    );
  }

  // ── Apple Sign-In ─────────────────────────────────────────────────────────

  /// Signs in with Apple. Returns the AppUser (created or existing).
  /// Throws if cancelled or failed.
  static Future<AppUser> signInWithApple() async {
    final cred = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    // Apple only returns name on first sign-in; fall back to email prefix.
    final givenName  = cred.givenName  ?? '';
    final familyName = cred.familyName ?? '';
    final fullName   = '$givenName $familyName'.trim();
    final email      = cred.email ?? 'apple_${cred.userIdentifier}';
    final name = fullName.isNotEmpty ? fullName : email.split('@').first;

    return _resolveOrCreateManager(
      email:    email,
      name:     name,
      photoUrl: null,
      provider: AuthProvider.apple,
    );
  }

  // ── Shared helper for SSO sign-ins ────────────────────────────────────────

  static Future<AppUser> _resolveOrCreateManager({
    required String email,
    required String name,
    required String? photoUrl,
    required AuthProvider provider,
  }) async {
    // Check if this email already exists
    AppUser? existing = _users.where((u) => u.email == email).firstOrNull;
    if (existing != null) {
      _currentUser = existing;
      await _persistSession(existing.id);
      return existing;
    }

    // First user to sign in becomes home manager
    final isFirstUser = _users.isEmpty || homeManager == null;
    final user = AppUser(
      id:           _uuid.v4(),
      name:         name,
      email:        email,
      phone:        '',
      role:         isFirstUser ? UserRole.homeManager : UserRole.member,
      authProvider: provider,
      photoUrl:     photoUrl,
      registeredAt: DateTime.now(),
      invitedBy:    null,
      isApproved:   true,
    );

    _users.add(user);
    await _saveCsv();
    _currentUser = user;
    await _persistSession(user.id);
    return user;
  }

  // ── Household members ─────────────────────────────────────────────────────

  /// Adds a household member (name-only, no auth).
  /// Only callable when a home manager exists.
  static Future<AppUser> addMember({
    required String name,
    String phone = '',
    String email = '',
  }) async {
    assert(homeManager != null, 'Cannot add members without a home manager');
    final user = AppUser(
      id:           _uuid.v4(),
      name:         name,
      email:        email,
      phone:        phone,
      role:         UserRole.member,
      authProvider: AuthProvider.member,
      photoUrl:     null,
      registeredAt: DateTime.now(),
      invitedBy:    homeManager?.id,
      isApproved:   true,
    );
    _users.add(user);
    await _saveCsv();
    return user;
  }

  /// Removes a user by id. Cannot remove the home manager.
  static Future<void> removeUser(String id) async {
    _users.removeWhere((u) => u.id == id && !u.isManager);
    await _saveCsv();
  }

  /// Renames a user.
  static Future<void> renameUser(String id, String newName) async {
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx == -1) return;
    _users[idx] = _users[idx].copyWith(name: newName);
    await _saveCsv();
  }

  // ── Sign-in as member (no auth) ───────────────────────────────────────────

  /// Sets current user to an existing member profile — no auth required.
  static Future<void> signInAsMember(AppUser member) async {
    _currentUser = member;
    await _persistSession(member.id);
  }

  // ── Sign-out ──────────────────────────────────────────────────────────────

  /// Full sign-out: clears session, signs out from Google/Apple.
  static Future<void> signOut() async {
    _currentUser = null;
    await _persistSession(null);
    try { await _googleSignIn.signOut(); } catch (_) {}
    // Apple sign-in has no server-side revocation in the Flutter SDK
  }
}
