import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web Client ID from Firebase Console (Google Sign-In provider).
/// Required by GoogleSignIn.initialize() on Android.
const _webClientId =
    '612502468471-q85dr65euduai9nnlr6ejh4gk2us4588.apps.googleusercontent.com';

/// Authentication service using Google Sign-In v7.x API.
/// Provides user identity and Drive access tokens.
///
/// Cross-platform identity:
/// - Web: Google Sign-In via browser (OAuth2 flow) — uses renderButton widget
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

  /// Whether web sign-in completed via renderButton callback.
  bool get webSignInCompleted => _webSignInCompleted;
  bool _webSignInCompleted = false;

  /// Guard against calling initialize() more than once (web plugin throws).
  bool _isInitialized = false;

  /// Completer that resolves when the first authentication event fires.
  Completer<void>? _authEventCompleter;

  static const _kSignedInFlag = 'splitwise_signed_in';

  Future<void> _setSignedInFlag(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSignedInFlag, value);
    } catch (_) {}
  }

  /// Initialize and check if user was previously signed in.
  ///
  /// On web: the client ID is auto-detected from the HTML meta tag
  /// `<meta name="google-signin-client_id" content="...">`. We must NOT
  /// pass `serverClientId` on web — it's not supported and will crash.
  /// On native: we pass `serverClientId` for the Android token exchange.
  ///
  /// IMPORTANT: This method is idempotent — calling it more than once is safe.
  /// The web plugin throws if `initialize()` is called twice, so we guard it.
  Future<void> checkSignIn() async {
    // Guard: only initialize once (web plugin asserts on double init).
    if (!_isInitialized) {
      _isInitialized = true;
      _authEventCompleter = Completer<void>();
      try {
        if (kIsWeb) {
          await _googleSignIn.initialize().timeout(const Duration(seconds: 5));
        } else {
          await _googleSignIn
              .initialize(serverClientId: _webClientId)
              .timeout(const Duration(seconds: 5));
        }
      } catch (e) {
        debugPrint('GoogleSignIn.initialize failed: $e');
      }

      // Listen to auth events — fires on both initial restore and fresh sign-in.
      _googleSignIn.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
          _webSignInCompleted = true;
          _setSignedInFlag(true);
          _upsertDirectory(event.user);
          if (_authEventCompleter != null && !_authEventCompleter!.isCompleted) {
            _authEventCompleter!.complete();
          }
          notifyListeners();
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
          _setSignedInFlag(false);
          if (_authEventCompleter != null && !_authEventCompleter!.isCompleted) {
            _authEventCompleter!.complete();
          }
          notifyListeners();
        }
      });
    }

    // On web, attemptLightweightAuthentication() always returns null (by design).
    // The actual restore happens via the authenticationEvents stream when
    // Google One Tap completes in the background. We wait for that event
    // so the UI doesn't flash the onboarding screen.
    if (kIsWeb) {
      // Check if user was previously signed in — if so, give One Tap more time.
      final prefs = await SharedPreferences.getInstance();
      final wasSignedIn = prefs.getBool(_kSignedInFlag) == true;
      final timeout = wasSignedIn
          ? const Duration(seconds: 6)
          : const Duration(seconds: 3);

      _googleSignIn.attemptLightweightAuthentication();
      // Wait for Google One Tap to restore the session.
      if (_authEventCompleter != null && !_authEventCompleter!.isCompleted) {
        await _authEventCompleter!.future.timeout(
          timeout,
          onTimeout: () {}, // Timeout is fine — user will see sign-in button.
        );
      }
      return;
    }

    // On native, attemptLightweightAuthentication() returns the account or null.
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSignedInFlag) != true) return;

    try {
      final future = _googleSignIn.attemptLightweightAuthentication();
      final account = future == null
          ? null
          : await future.timeout(const Duration(seconds: 8));
      if (account != null) {
        _currentUser = account;
        _webSignInCompleted = true;
        _wasAutoLogin = true;
        notifyListeners();
      } else {
        // Session expired or revoked — clear the flag.
        await _setSignedInFlag(false);
      }
    } catch (e) {
      debugPrint('Silent auth restore failed: $e');
      await _setSignedInFlag(false);
    }
  }

  /// Trigger Google Sign-In flow (native only).
  /// On web, the sign-in is handled by the renderButton widget.
  Future<AuthResult> signIn() async {
    if (kIsWeb) {
      return AuthResult.error(
          'Web sign-in uses the Google button widget — call signInFromButton() after renderButton callback.');
    }
    return _signInNative();
  }

  /// Native sign-in via Google account picker.
  Future<AuthResult> _signInNative() async {
    try {
      final account = await _googleSignIn.authenticate();

      _currentUser = account;
      notifyListeners();
      await _setSignedInFlag(true);

      // Request Drive scope, but NEVER fail sign-in if it's denied.
      String? driveToken;
      try {
        final authorization = await account.authorizationClient
            .authorizeScopes(['https://www.googleapis.com/auth/drive.file']);
        driveToken = authorization.accessToken;
      } catch (_) {
        driveToken = null;
      }
      // Upsert directory profile (best-effort)
      try {
        await _upsertDirectory(account);
      } catch (_) {}

      return AuthResult.success(
        user: AuthUser(
          id: account.id,
          email: account.email,
          displayName: account.displayName ?? '',
          photoUrl: account.photoUrl,
        ),
        accessToken: driveToken,
      );
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Called after the web renderButton triggers authenticationEvents.
  /// The actual user is already set via the event listener — this just
  /// persists the flag and returns the result.
  Future<AuthResult> signInFromButton() async {
    if (_currentUser == null) {
      return AuthResult.error('No user after web sign-in');
    }
    await _setSignedInFlag(true);

    String? driveToken;
    try {
      final authorization = await _currentUser!.authorizationClient
          .authorizeScopes(['https://www.googleapis.com/auth/drive.file']);
      driveToken = authorization.accessToken;
    } catch (_) {
      driveToken = null;
    }
    try {
      await _upsertDirectory(_currentUser!);
    } catch (_) {}

    return AuthResult.success(
      user: AuthUser(
        id: _currentUser!.id,
        email: _currentUser!.email,
        displayName: _currentUser!.displayName ?? '',
        photoUrl: _currentUser!.photoUrl,
      ),
      accessToken: driveToken,
    );
  }

  Future<void> _upsertDirectory(GoogleSignInAccount account) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchable = prefs.getBool('user_searchable') ?? true;
      final avatarAsset = prefs.getString('user_avatar_asset') ?? '';
      final lower = account.email.toLowerCase().trim();
      final usernameLower = (account.displayName ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), '');
      await FirebaseDatabase.instance.ref('users/${account.id}/profile').set({
        'googleId': account.id,
        'email': account.email,
        'emailLower': lower,
        'displayName': account.displayName ?? '',
        'usernameLower': usernameLower,
        'photoUrl': account.photoUrl ?? '',
        'avatarAsset': avatarAsset,
        'searchable': searchable,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (searchable) {
        await FirebaseDatabase.instance.ref('directory/${account.id}').set({
          'googleId': account.id,
          'displayName': account.displayName ?? '',
          'usernameLower': usernameLower,
          'emailLower': lower,
          'email': account.email,
          'avatarAsset': avatarAsset,
          'photoUrl': account.photoUrl ?? '',
        });
      } else {
        await FirebaseDatabase.instance.ref('directory/${account.id}').remove();
      }
    } catch (_) {}
  }

  /// Sign out.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _wasAutoLogin = false;
    _webSignInCompleted = false;
    await _setSignedInFlag(false);
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
