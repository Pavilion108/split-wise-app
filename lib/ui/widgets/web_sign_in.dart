import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget buildSignInButton(BuildContext context) {
  return SizedBox(
    height: 48,
    child: web.renderButton(),
  );
}
