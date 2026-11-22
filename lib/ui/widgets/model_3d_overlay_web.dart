import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class Model3DOverlay extends StatefulWidget {
  final bool show;

  const Model3DOverlay({super.key, required this.show});

  @override
  State<Model3DOverlay> createState() => _Model3DOverlayState();
}

class _Model3DOverlayState extends State<Model3DOverlay> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
