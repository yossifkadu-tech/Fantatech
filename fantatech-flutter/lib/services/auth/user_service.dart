// ─────────────────────────────────────────────────────────────────────────────
// UserService — manages app users, persisted locally on device.
//
// Roles:
//   HomeManager — the first user to register becomes the home manager.
//                 Can add/remove household members.
//   Member      — added by the manager; no admin privileges.
//
// Storage:
//   {documents}/fantatech_users.csv   — all users (local, never transmitted)
//   SharedPreferences 'current_user_id' — active session
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException, User;

import '../../models/app_user.dart';
import '../../backend/backend_service.dart';
import '../../backend/auth/auth_repository.dart';
import 'password_hasher.dart';

class UserService {
  UserService._();

  static const _prefCurrentUserId = 'current_user_id';
  static const _prefLastUserId    = 'last_user_id';    // survives sign-out, used for bio-login
  static const _csvFileName    = 'fantatech_users.csv';
  static const _csvFileNameOld = 'yossiini.csv'; // legacy name — migrated on first open
  static const _csvHeader = 'id,name,email,phone,role,authProvider,photoUrl,registeredAt,invitedBy,isApproved,password,permissions';

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
    await _migrateLegacyFile(); // rename yossiini.csv → fantatech_users.csv
    await _loadCsv();
    final prefs = await SharedPreferences.getInstance();
    lastEmail = prefs.getString('last_email');
    final savedId = prefs.getString(_prefCurrentUserId);
    if (savedId != null) {
      _currentUser = _users.where((u) => u.id == savedId).firstOrNull;
    }

    // Restore an active cloud session (survives app restarts via Supabase's
    // secure session store).
    if (BackendService.isReady) {
      final su = AuthRepository().currentUser;
      if (su != null) {
        await _syncCloudUser(su, su.email ?? lastEmail ?? '');
      }
    }
  }

  /// One-time migration: rename the old CSV file to the new standard name.
  static Future<void> _migrateLegacyFile() async {
    if (kIsWeb) return;
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final old  = File('${dir.path}/$_csvFileNameOld');
      final next = File('${dir.path}/$_csvFileName');
      if (await old.exists() && !await next.exists()) {
        await old.rename(next.path);
      }
    } catch (_) {
      // Migration is best-effort; failure is non-fatal.
    }
  }

  static Future<void> _rememberEmail(String email) async {
    lastEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_email', email);
  }

  /// Clears the remembered email — called when the user signs in with
  /// "Remember me" unchecked, so the next login screen won't prefill it.
  static Future<void> forgetEmail() async {
    lastEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_email');
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
      // NOTE: _prefLastUserId is intentionally NOT cleared on sign-out
      // so biometric login can restore the last user.
    } else {
      await prefs.setString(_prefCurrentUserId, userId);
      await prefs.setString(_prefLastUserId, userId);   // survives sign-out
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
      throw Exception('Invalid email address');
    }
    if (!isValidPassword(password)) {
      throw Exception('Invalid password (at least 6 characters)');
    }
    // ── Cloud auth (when a Supabase backend is configured) ──────────────────
    if (BackendService.isReady) {
      try {
        final res = await AuthRepository().signIn(email: e, password: password);
        final su = res.user;
        if (su == null) throw Exception('Sign in failed');
        return _syncCloudUser(su, e);
      } on AuthException catch (ex) {
        throw Exception(_mapAuthError(ex));
      }
    }

    // ── Local fallback ──────────────────────────────────────────────────────
    final user = _users.where((u) => u.email.toLowerCase() == e).firstOrNull;
    if (user == null) {
      throw Exception('No account with this email — please register first');
    }
    final stored = user.password;
    final valid = PasswordHasher.isHashed(stored)
        ? PasswordHasher.verify(password, stored)
        : stored == password; // legacy plaintext account, checked as-is below
    if (!valid) {
      throw Exception('Incorrect password');
    }
    // One-time migration: upgrade a legacy plaintext password to a salted
    // hash now that we've verified it, so it's never stored in the clear again.
    if (!PasswordHasher.isHashed(stored)) {
      final idx = _users.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        _users[idx] = user.copyWith(password: PasswordHasher.hash(password));
        await _saveCsv();
      }
    }
    _currentUser = user;
    await _persistSession(user.id);
    await _rememberEmail(e);
    return user;
  }

  static String _mapAuthError(AuthException ex) {
    final m = ex.message.toLowerCase();
    if (m.contains('invalid login') || m.contains('credentials')) {
      return 'Incorrect email or password';
    }
    if (m.contains('already registered') || m.contains('already exists')) {
      return 'An account with this email already exists';
    }
    if (m.contains('email not confirmed')) {
      return 'Please confirm your email address before signing in';
    }
    return ex.message;
  }

  /// Mirrors a cloud (Supabase) user into the local user list so the rest of
  /// the app — which reads UserService.currentUser / allUsers — keeps working.
  static Future<AppUser> _syncCloudUser(User su, String email) async {
    final existing =
        _users.where((u) => u.id == su.id || u.email.toLowerCase() == email)
            .firstOrNull;
    if (existing != null) {
      _currentUser = existing;
      await _persistSession(existing.id);
      await _rememberEmail(email);
      return existing;
    }
    final isFirstUser = _users.isEmpty || homeManager == null;
    final metaName = (su.userMetadata?['full_name'] as String?)?.trim();
    final user = AppUser(
      id:           su.id,
      name:         (metaName != null && metaName.isNotEmpty)
          ? metaName
          : email.split('@').first,
      email:        email,
      phone:        '',
      role:         isFirstUser ? UserRole.homeManager : UserRole.member,
      authProvider: AuthProvider.member,
      photoUrl:     null,
      registeredAt: DateTime.now(),
      invitedBy:    isFirstUser ? null : homeManager?.id,
      isApproved:   true,
    );
    _users.add(user);
    await _saveCsv();
    _currentUser = user;
    await _persistSession(user.id);
    await _rememberEmail(email);
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
    if (!isValidEmail(e)) throw Exception('Invalid email address');
    if (!isValidPassword(password)) {
      throw Exception('Invalid password (at least 6 characters)');
    }
    // ── Cloud registration (when a Supabase backend is configured) ──────────
    if (BackendService.isReady) {
      try {
        final res = await AuthRepository()
            .signUp(email: e, password: password, fullName: name.trim());
        final su = res.user;
        if (su == null) throw Exception('Registration failed');
        return _syncCloudUser(su, e);
      } on AuthException catch (ex) {
        throw Exception(_mapAuthError(ex));
      }
    }

    // ── Local fallback ──────────────────────────────────────────────────────
    if (_users.any((u) => u.email.toLowerCase() == e)) {
      throw Exception('An account with this email already exists');
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
      password:     PasswordHasher.hash(password),
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
      if (account == null) throw Exception('Sign in cancelled');

      return _resolveOrCreateManager(
        email:    account.email,
        name:     account.displayName ?? account.email,
        photoUrl: account.photoUrl,
        provider: AuthProvider.google,
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('ApiException: 10') || msg.contains('DEVELOPER_ERROR')) {
        throw Exception(
          'Google sign-in is not configured yet.\n'
          'Add google-services.json from the Firebase Console\n'
          'to android/app/ and rebuild.',
        );
      }
      if (msg.contains('ApiException: 7') || msg.contains('NETWORK_ERROR')) {
        throw Exception('No network connection. Check your connection and try again.');
      }
      if (msg.contains('12500')) {
        throw Exception('Google Play Services update required.');
      }
      if (msg.contains('cancelled') || msg.contains('sign_in_cancelled')) {
        throw Exception('Sign in cancelled');
      }
      rethrow;
    }
  }

  static Future<AppUser> signInWithGoogleEmail(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Invalid email address');
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

  // ── Guest sign-in ─────────────────────────────────────────────────────────

  /// Signs in as an anonymous guest — no account needed.
  static Future<AppUser> signInAsGuest() async {
    final guest = AppUser(
      id: 'guest',
      name: 'Guest',
      email: '',
      role: UserRole.member,
      authProvider: AuthProvider.member,
      registeredAt: DateTime.now(),
      isApproved: true,
    );
    _currentUser = guest;
    return guest;
  }

  // ── Sign-in as member (no auth) ───────────────────────────────────────────

  /// Sets current user to an existing member profile — no auth required.
  static Future<void> signInAsMember(AppUser member) async {
    _currentUser = member;
    await _persistSession(member.id);
  }

  // ── Biometric login ───────────────────────────────────────────────────────

  /// Returns true if there is at least one registered user — meaning biometric
  /// login makes sense (someone to sign back in as).
  static bool get hasBiometricCandidate => _users.isNotEmpty;

  /// Called after the OS biometric prompt succeeds.
  /// Restores the last active session (or falls back to the home manager).
  /// Returns the signed-in user, or null if no users exist.
  static Future<AppUser?> signInWithBiometric() async {
    if (_users.isEmpty) return null;

    // 1. Try the last user who was explicitly logged in
    final prefs  = await SharedPreferences.getInstance();
    final lastId = prefs.getString(_prefLastUserId);
    AppUser? user = lastId != null
        ? _users.where((u) => u.id == lastId).firstOrNull
        : null;

    // 2. Fall back to home manager, then any first user
    user ??= _users.where((u) => u.isManager).firstOrNull;
    user ??= _users.first;

    _currentUser = user;
    await _persistSession(user.id);
    return user;
  }

  // ── Sign-out ──────────────────────────────────────────────────────────────

  /// Sends a password reset email.
  static Future<void> sendPasswordResetEmail(String email) async {
    if (BackendService.isReady) {
      await AuthRepository().sendPasswordReset(email);
    }
    // When backend is not configured, silently succeed — the dialog still shows
    // the "check your inbox" confirmation so the UX flow stays consistent.
  }

  /// Full sign-out: clears session, signs out from Google/Apple.
  static Future<void> signOut() async {
    _currentUser = null;
    await _persistSession(null);
    if (BackendService.isReady) {
      try { await AuthRepository().signOut(); } catch (_) {}
    }
    try { await _googleSignIn.signOut(); } catch (_) {}
    // Apple sign-in has no server-side revocation in the Flutter SDK
  }
}
