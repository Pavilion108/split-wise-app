import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Web Client ID from Firebase Console (Google Sign-In provider).
/// Required by GoogleSignIn.initialize() on Android.
const _webClientId =
    '612502468471-q85dr65euduai9nnlr6ejh4gk2us4588.apps.googleusercontent.com';

/// Authentication service using Google Sign-In v7.x API.
/// Provides user identity and Drive access tokens.
///
/// Cross-platform identity:
/// - Web: Google Sign-In via browser (OAuth2 flow)
/// - Native: Google Sign-In via device account (auto-detected)
/// - Both produce the same Firebase Auth UID when using the same Google account
/// - Firebase RTDB is shared — same user sees same data on web + app
class AuthService extends ChangeNotifier {
  AuthService() : _googleSignIn = GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  bool get isSignedIn => _currentUser != null;

  /// Whether auto-login was successful (no user interaction needed).
  bool get wasAutoLogin => _wasAutoLogin;
  bool _wasAutoLogin = false;

  /// Initialize and check if user was previously signed in.
  /// On native: attempts lightweight auth (detects device Google account).
  /// On web: checks Firebase Auth persisted state.
  Future<void> checkSignIn() async {
    try {
      await _googleSignIn
          .initialize(serverClientId: _webClientId)
          .timeout(const Duration(seconds: 5));
    } catch (_) {}

    // Listen to auth events.
    _googleSignIn.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        _currentUser = event.user;
        notifyListeners();
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        _currentUser = null;
        notifyListeners();
      }
    });

    // On native: try lightweight auth (silent sign-in from device Google account).
    // This is the KEY to auto-login — if user is signed into Google on the device,
    // they're automatically signed into Split Wise without any prompt.
    if (!kIsWeb) {
      try {
        final future = _googleSignIn.attemptLightweightAuthentication();
        final account = future == null
            ? null
            : await future.timeout(const Duration(seconds: 5));
        if (account != null) {
          _currentUser = account;
          _wasAutoLogin = true;
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  /// Trigger Google Sign-In flow.
  /// On native: opens Google account picker (or auto-selects if only one account).
  /// On web: opens OAuth2 consent screen in browser.
  Future<AuthResult> signIn() async {
    try {
      final account = await _googleSignIn.authenticate();

      _currentUser = account;
      notifyListeners();

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
    _wasAutoLogin = false;
    notifyListeners();
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

  /// Get the signed-in user's email (for Drive folder sharing).
  String? get userEmail => _currentUser?.email;
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
