import 'mobile_sign_in.dart' if (dart.library.js_interop) 'web_sign_in.dart' as platform;
import 'package:flutter/material.dart';

class SignInButton extends StatelessWidget {
  const SignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return platform.buildSignInButton(context);
  }
}
