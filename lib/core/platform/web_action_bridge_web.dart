import 'dart:async';
import 'package:web/web.dart' as web;
import 'web_action_bridge.dart';

WebActionBridge createWebActionBridge() => _WebActionBridgeImpl();

class _WebActionBridgeImpl implements WebActionBridge {
  Timer? _pollTimer;

  @override
  void init(void Function(String action) onAction) {
    var channel = web.document.getElementById('spliti5-action');
    if (channel == null) {
      final div = web.HTMLDivElement()
        ..id = 'spliti5-action'
        ..style.cssText = 'display:none;';
      web.document.body?.appendChild(div);
      channel = div;
    }

    _pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final ch = web.document.getElementById('spliti5-action');
      if (ch == null) return;
      final action = ch.textContent ?? '';
      if (action.isEmpty) return;
      ch.textContent = '';
      onAction(action);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
