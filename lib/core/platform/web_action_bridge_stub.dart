import 'web_action_bridge.dart';

WebActionBridge createWebActionBridge() => _StubWebActionBridge();

class _StubWebActionBridge implements WebActionBridge {
  @override
  void init(void Function(String action) onAction) {}

  @override
  void dispose() {}
}
