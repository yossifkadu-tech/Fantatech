// ─────────────────────────────────────────────────────────────────────────────
// AuthRepository — real cloud auth via Supabase (email/password + session).
//
// Replaces the local CSV-based UserService once a backend is configured.
// Tokens are managed by supabase_flutter's secure session store.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend_service.dart';

class AuthRepository {
  GoTrueClient get _auth => BackendService.client.auth;

  /// Currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  /// Emits on every sign-in / sign-out / token-refresh.
  Stream<AuthState> get authChanges => _auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.resetPasswordForEmail(email);

  Future<void> signOut() => _auth.signOut();
}
