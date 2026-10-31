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
  web.HTMLDivElement? _container;

  @override
  void didUpdateWidget(covariant Model3DOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _injectModels();
    } else if (!widget.show && oldWidget.show) {
      _removeModels();
    }
  }

  void _injectModels() {
    if (!mounted) return;
    _removeModels();

    if (web.document.getElementById('model-viewer-script') == null) {
      final script = web.HTMLScriptElement()
        ..id = 'model-viewer-script'
        ..src =
            'https://ajax.googleapis.com/ajax/libs/model-viewer/3.5.0/model-viewer.min.js'
        ..type = 'module';
      web.document.head?.appendChild(script);
    }

    if (web.document.getElementById('spliti5-popup-anim') == null) {
      final style = web.HTMLStyleElement()
        ..id = 'spliti5-popup-anim'
        ..innerText = '''
          @keyframes spliti5SlideUp {
            0% { opacity:0; transform:translateY(60px) scale(0.95); }
            60% { opacity:1; transform:translateY(-8px) scale(1.01); }
            100% { opacity:1; transform:translateY(0) scale(1); }
          }
          @keyframes spliti5Glow {
            0%,100% { box-shadow: 0 8px 40px rgba(0,0,0,0.5), 0 0 60px rgba(102,126,234,0.08), inset 0 1px 0 rgba(255,255,255,0.12); }
            50% { box-shadow: 0 8px 40px rgba(0,0,0,0.5), 0 0 90px rgba(102,126,234,0.15), inset 0 1px 0 rgba(255,255,255,0.18); }
          }
        ''';
      web.document.head?.appendChild(style);
    }

    final html = '''
      <div id="spliti5-3d-overlay" style="position:fixed;bottom:0;left:0;z-index:10;pointer-events:none;display:flex;flex-direction:column;align-items:flex-start;padding:0 16px 20px;animation:spliti5SlideUp 0.8s cubic-bezier(0.34,1.56,0.64,1) forwards;">
        <div style="pointer-events:auto;display:flex;flex-direction:row;align-items:stretch;gap:16px;background:rgba(255,255,255,0.06);backdrop-filter:blur(28px) saturate(1.4);-webkit-backdrop-filter:blur(28px) saturate(1.4);border:1px solid rgba(255,255,255,0.12);border-radius:24px;padding:20px 24px 20px;width:auto;max-width:540px;animation:spliti5Glow 4s ease-in-out infinite;">
          <div style="flex:1;display:flex;flex-direction:column;align-items:center;cursor:pointer;transition:all 0.25s cubic-bezier(0.4,0,0.2,1);padding:12px 8px;border-radius:16px;border:1px solid transparent;position:relative;pointer-events:none;">
            <div onclick="document.getElementById('spliti5-action').textContent='download'" style="position:absolute;top:0;left:0;right:0;bottom:0;pointer-events:auto;cursor:pointer;border-radius:16px;z-index:1;"></div>
            <model-viewer src="https://modelviewer.dev/shared-assets/models/RobotExpressive.glb" alt="Download the App" auto-rotate shadow-intensity="0" environment-image="neutral" interaction-prompt="none" style="width:100%;height:140px;background:transparent;--poster-color:transparent;pointer-events:none;"></model-viewer>
            <div style="color:white;font-size:15px;font-weight:700;margin-top:6px;text-align:center;pointer-events:none;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;letter-spacing:-0.2px;">Download the App</div>
            <div style="color:rgba(255,255,255,0.5);font-size:11px;margin-top:3px;text-align:center;line-height:1.4;pointer-events:none;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">Best experience — offline, notifications, camera</div>
          </div>
          <div style="width:1px;background:rgba(255,255,255,0.12);align-self:stretch;margin:4px 0;"></div>
          <div style="flex:1;display:flex;flex-direction:column;align-items:center;cursor:pointer;transition:all 0.25s cubic-bezier(0.4,0,0.2,1);padding:12px 8px;border-radius:16px;border:1px solid transparent;position:relative;pointer-events:none;">
            <div onclick="document.getElementById('spliti5-action').textContent='web'" style="position:absolute;top:0;left:0;right:0;bottom:0;pointer-events:auto;cursor:pointer;border-radius:16px;z-index:1;"></div>
            <model-viewer src="https://modelviewer.dev/shared-assets/models/Astronaut.glb" alt="Continue on Web" auto-rotate shadow-intensity="0" environment-image="neutral" interaction-prompt="none" style="width:100%;height:140px;background:transparent;--poster-color:transparent;pointer-events:none;"></model-viewer>
            <div style="color:white;font-size:15px;font-weight:700;margin-top:6px;text-align:center;pointer-events:none;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;letter-spacing:-0.2px;">Continue on Web</div>
            <div style="color:rgba(255,255,255,0.5);font-size:11px;margin-top:3px;text-align:center;line-height:1.4;pointer-events:none;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">No install needed — works in any browser</div>
          </div>
        </div>
        <div style="color:rgba(255,255,255,0.35);font-size:11px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;letter-spacing:0.2px;margin-top:12px;text-align:left;pointer-events:none;padding-left:24px;">Both versions share the same account &amp; data</div>
      </div>
    ''';

    final div = web.HTMLDivElement();
    div.innerHTML = html.toJS;
    final container = div.firstElementChild as web.HTMLDivElement;
    web.document.body?.appendChild(container);
    _container = container;
  }

  void _removeModels() {
    _container?.remove();
    _container = null;
  }

  @override
  void dispose() {
    _removeModels();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
