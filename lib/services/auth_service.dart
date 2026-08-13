import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

/// Authentication service using Google Sign-In v7.x API.
/// Provides user identity and Drive access tokens.
class AuthService {
  AuthService() : _googleSignIn = GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;

  final _authController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authState => _authController.stream;

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  bool get isSignedIn => _currentUser != null;

  /// Initialize and check if user was previously signed in.
  Future<void> checkSignIn() async {
    try {
      await _googleSignIn.initialize();
    } catch (_) {}

    // Listen to auth events.
    _googleSignIn.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        _currentUser = event.user;
        _authController.add(AuthState.signedIn(event.user));
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        _currentUser = null;
        _authController.add(AuthState.signedOut());
      }
    });

    // Try lightweight auth (silent sign-in).
    final account = await _googleSignIn.attemptLightweightAuthentication();
    if (account != null) {
      _currentUser = account;
      _authController.add(AuthState.signedIn(account));
    } else {
      _authController.add(AuthState.signedOut());
    }
  }

  /// Trigger Google Sign-In flow.
  Future<AuthResult> signIn() async {
    try {
      final account = await _googleSignIn.authenticate();

      _currentUser = account;
      _authController.add(AuthState.signedIn(account));

      // Get authorization for Drive scopes.
      final authorization = await account.authorizationClient
          .authorizeScopes(['https://www.googleapis.com/auth/drive.file']);

      return AuthResult.success(
        user: AuthUser(
          id: account.id,
          email: account.email,
          displayName: account.displayName ?? '',
          photoUrl: account.photoUrl,
        ),
        accessToken: authorization.accessToken,
      );
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _authController.add(AuthState.signedOut());
  }

  /// Get fresh access token for Drive API calls.
  Future<String?> getAccessToken() async {
    final account = _currentUser;
    if (account == null) return null;

    try {
      final authorization = await account.authorizationClient
          .authorizationForScopes(['https://www.googleapis.com/auth/drive.file']);
      return authorization?.accessToken;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _authController.close();
  }
}

// --- Models ---

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
}

class AuthResult {
  const AuthResult._({
    this.success = false,
    this.cancelled = false,
    this.error,
    this.user,
    this.accessToken,
  });

  factory AuthResult.success({
    required AuthUser user,
    String? accessToken,
  }) =>
      AuthResult._(
        success: true,
        user: user,
        accessToken: accessToken,
      );

  factory AuthResult.cancelled() => AuthResult._(cancelled: true);
  factory AuthResult.error(String e) => AuthResult._(error: e);

  final bool success;
  final bool cancelled;
  final String? error;
  final AuthUser? user;
  final String? accessToken;
}

class AuthState {
  const AuthState._({this.isSignedIn = false, this.user});

  factory AuthState.signedIn(GoogleSignInAccount account) => AuthState._(
        isSignedIn: true,
        user: AuthUser(
          id: account.id,
          email: account.email,
          displayName: account.displayName ?? '',
          photoUrl: account.photoUrl,
        ),
      );

  factory AuthState.signedOut() => AuthState._();

  final bool isSignedIn;
  final AuthUser? user;
}
