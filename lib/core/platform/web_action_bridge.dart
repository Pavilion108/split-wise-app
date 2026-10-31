import 'web_action_bridge_stub.dart'
    if (dart.library.js_interop) 'web_action_bridge_web.dart';

abstract class WebActionBridge {
  static WebActionBridge create() => createWebActionBridge();

  void init(void Function(String action) onAction);
  void dispose();
}
