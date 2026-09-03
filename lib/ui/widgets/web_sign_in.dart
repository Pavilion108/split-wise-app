import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;

/// Web Google Sign-In button using the official renderButton widget.
///
/// On web, `GoogleSignIn.authenticate()` is NOT supported. Instead, Google
/// provides `renderButton()` which creates an iframe-based button that
/// handles the entire OAuth flow.
///
/// The flow:
/// 1. renderButton renders Google's iframe button
/// 2. User clicks the button → Google OAuth popup appears
/// 3. User authorizes → GoogleSignIn.authenticationEvents fires
/// 4. The listener in AuthService.checkSignIn() picks up the event
/// 5. The onboarding screen detects isSignedIn and navigates to Home
Widget buildSignInButton(BuildContext context) {
  return web_only.renderButton(
    configuration: web_only.GSIButtonConfiguration(
      theme: web_only.GSIButtonTheme.outline,
      size: web_only.GSIButtonSize.large,
      text: web_only.GSIButtonText.continueWith,
      shape: web_only.GSIButtonShape.pill,
    ),
  );
}
