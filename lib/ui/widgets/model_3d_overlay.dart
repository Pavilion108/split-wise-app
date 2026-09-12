import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Injects model-viewer 3D models into the DOM as an overlay.
/// Shows two models inside a glassmorphism popup with onclick handlers
/// that call global JS functions registered by the Flutter onboarding screen.
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

    final existingScript = web.document.getElementById('model-viewer-script');
    if (existingScript == null) {
      final script = web.HTMLScriptElement()
        ..id = 'model-viewer-script'
        ..src =
            'https://ajax.googleapis.com/ajax/libs/model-viewer/3.5.0/model-viewer.min.js'
        ..type = 'module';
      web.document.head?.appendChild(script);
    }

    final container = web.HTMLDivElement()
      ..id = 'spliti5-3d-overlay'
      ..style.cssText = '''
        position:fixed;
        bottom:0;left:0;right:0;
        z-index:10;
        pointer-events:none;
        display:flex;
        justify-content:center;
        padding:0 20px 20px;
      ''';

    final box = web.HTMLDivElement()
      ..style.cssText = '''
        pointer-events:auto;
        display:flex;
        flex-direction:row;
        align-items:center;
        gap:12px;
        background:rgba(255,255,255,0.08);
        backdrop-filter:blur(20px);
        -webkit-backdrop-filter:blur(20px);
        border:1px solid rgba(255,255,255,0.15);
        border-radius:20px;
        padding:16px 20px;
        max-width:440px;
        width:100%;
        box-shadow:0 8px 32px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.1);
      ''';

    final downloadCard = _createModelCard(
      modelSrc:
          'https://modelviewer.dev/shared-assets/models/RobotExpressive.glb',
      title: 'Download the App',
      subtitle: 'Offline \u00B7 Notifications \u00B7 Camera',
      onclick: 'spliti5DownloadApk()',
    );

    final webCard = _createModelCard(
      modelSrc:
          'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      title: 'Continue on Web',
      subtitle: 'No install \u00B7 Any browser',
      onclick: 'spliti5OpenWeb()',
    );

    box.appendChild(downloadCard);
    box.appendChild(webCard);
    container.appendChild(box);
    web.document.body?.appendChild(container);
    _container = container;
  }

  web.HTMLDivElement _createModelCard({
    required String modelSrc,
    required String title,
    required String subtitle,
    required String onclick,
  }) {
    final card = web.HTMLDivElement()
      ..setAttribute('onclick', onclick)
      ..style.cssText = '''
        flex:1;
        display:flex;
        flex-direction:column;
        align-items:center;
        cursor:pointer;
        transition:transform 0.2s, background 0.2s;
        padding:8px;
        border-radius:14px;
      ''';

    card.onMouseOver.listen((_) {
      card.style.background = 'rgba(255,255,255,0.06)';
      card.style.transform = 'scale(1.03)';
    });
    card.onMouseOut.listen((_) {
      card.style.background = 'transparent';
      card.style.transform = 'scale(1)';
    });

    final modelViewer =
        (web.document.createElement('model-viewer') as web.HTMLElement)
          ..setAttribute('src', modelSrc)
          ..setAttribute('alt', title)
          ..setAttribute('auto-rotate', '')
          ..setAttribute('shadow-intensity', '0')
          ..setAttribute('environment-image', 'neutral')
          ..setAttribute('interaction-prompt', 'none')
          ..style.cssText = '''
        width:100%;
        height:120px;
        background:transparent;
        --poster-color:transparent;
        pointer-events:none;
      ''';

    final titleEl = web.HTMLDivElement()
      ..innerText = title
      ..style.cssText = '''
        color:white;
        font-size:13px;
        font-weight:700;
        margin-top:4px;
        text-align:center;
        font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
      ''';

    final subtitleEl = web.HTMLDivElement()
      ..innerText = subtitle
      ..style.cssText = '''
        color:rgba(255,255,255,0.5);
        font-size:10px;
        margin-top:2px;
        text-align:center;
        font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
      ''';

    card.appendChild(modelViewer);
    card.appendChild(titleEl);
    card.appendChild(subtitleEl);

    return card;
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
