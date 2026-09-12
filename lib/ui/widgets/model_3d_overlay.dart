import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Injects model-viewer 3D models into the DOM as an overlay.
/// Left-aligned glassmorphism popup with transparent click overlays.
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

    // Load model-viewer script from CDN (only once)
    final existingScript = web.document.getElementById('model-viewer-script');
    if (existingScript == null) {
      final script = web.HTMLScriptElement()
        ..id = 'model-viewer-script'
        ..src =
            'https://ajax.googleapis.com/ajax/libs/model-viewer/3.5.0/model-viewer.min.js'
        ..type = 'module';
      web.document.head?.appendChild(script);
    }

    // Inject CSS animations (only once)
    final existingStyle = web.document.getElementById('spliti5-popup-anim');
    if (existingStyle == null) {
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

    // Main container — LEFT aligned, auto-adjust width
    final container = web.HTMLDivElement()
      ..id = 'spliti5-3d-overlay'
      ..style.cssText = '''
        position:fixed;
        bottom:0;
        left:0;
        z-index:10;
        pointer-events:none;
        display:flex;
        flex-direction:column;
        align-items:flex-start;
        padding:0 16px 20px;
        animation: spliti5SlideUp 0.8s cubic-bezier(0.34,1.56,0.64,1) forwards;
      ''';

    // Glassmorphism box — auto-width, fits content
    final box = web.HTMLDivElement()
      ..style.cssText = '''
        pointer-events:auto;
        display:flex;
        flex-direction:row;
        align-items:stretch;
        gap:16px;
        background:rgba(255,255,255,0.06);
        backdrop-filter:blur(28px) saturate(1.4);
        -webkit-backdrop-filter:blur(28px) saturate(1.4);
        border:1px solid rgba(255,255,255,0.12);
        border-radius:24px;
        padding:20px 24px 20px;
        width:auto;
        max-width:540px;
        animation: spliti5Glow 4s ease-in-out infinite;
      ''';

    // Download App card — transparent click overlay fixes shadow DOM click issue
    final downloadCard = _createModelCard(
      modelSrc:
          'https://modelviewer.dev/shared-assets/models/RobotExpressive.glb',
      title: 'Download the App',
      subtitle: 'Best experience \u2014 offline, notifications, camera',
      actionValue: 'download',
      accentColor: '102,126,234',
    );

    // Divider
    final divider = web.HTMLDivElement()
      ..style.cssText = '''
        width:1px;
        background:rgba(255,255,255,0.12);
        align-self:stretch;
        margin:4px 0;
      ''';

    // Continue on Web card
    final webCard = _createModelCard(
      modelSrc:
          'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      title: 'Continue on Web',
      subtitle: 'No install needed \u2014 works in any browser',
      actionValue: 'web',
      accentColor: '118,75,162',
    );

    box.appendChild(downloadCard);
    box.appendChild(divider);
    box.appendChild(webCard);
    container.appendChild(box);

    // Footer — floating line OUTSIDE glass box, left-aligned
    final footer = web.HTMLDivElement()
      ..innerText = 'Both versions share the same account & data'
      ..style.cssText = '''
        color:rgba(255,255,255,0.35);
        font-size:11px;
        font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
        letter-spacing:0.2px;
        margin-top:12px;
        text-align:left;
        pointer-events:none;
        padding-left:24px;
      ''';
    container.appendChild(footer);

    web.document.body?.appendChild(container);
    _container = container;
  }

  web.HTMLDivElement _createModelCard({
    required String modelSrc,
    required String title,
    required String subtitle,
    required String actionValue,
    required String accentColor,
  }) {
    // Card wrapper — relative positioning for absolute overlay
    final card = web.HTMLDivElement()
      ..style.cssText = '''
        flex:1;
        display:flex;
        flex-direction:column;
        align-items:center;
        cursor:pointer;
        transition:all 0.25s cubic-bezier(0.4,0,0.2,1);
        padding:12px 8px;
        border-radius:16px;
        border:1px solid transparent;
        position:relative;
      ''';

    // Hover effects
    card.onMouseOver.listen((_) {
      card.style.background = 'rgba(255,255,255,0.07)';
      card.style.borderColor = 'rgba($accentColor,0.3)';
      card.style.transform = 'translateY(-4px) scale(1.02)';
    });
    card.onMouseOut.listen((_) {
      card.style.background = 'transparent';
      card.style.borderColor = 'transparent';
      card.style.transform = 'translateY(0) scale(1)';
    });

    // Transparent click overlay — solves model-viewer shadow DOM click hijacking
    final overlay = web.HTMLDivElement()
      ..style.cssText = '''
        position:absolute;
        top:0;left:0;right:0;bottom:0;
        pointer-events:auto;
        cursor:pointer;
        border-radius:16px;
        z-index:1;
      ''';
    overlay.onClick.listen((_) {
      final ch = web.document.getElementById('spliti5-action');
      if (ch != null) ch.textContent = actionValue;
    });

    // model-viewer with pointer-events:none on all elements
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
        height:140px;
        background:transparent;
        --poster-color:transparent;
        pointer-events:none;
      ''';

    final titleEl = web.HTMLDivElement()
      ..innerText = title
      ..style.cssText = '''
        color:white;
        font-size:15px;
        font-weight:700;
        margin-top:6px;
        text-align:center;
        pointer-events:none;
        font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
        letter-spacing:-0.2px;
      ''';

    final subtitleEl = web.HTMLDivElement()
      ..innerText = subtitle
      ..style.cssText = '''
        color:rgba(255,255,255,0.5);
        font-size:11px;
        margin-top:3px;
        text-align:center;
        line-height:1.4;
        pointer-events:none;
        font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
      ''';

    card.appendChild(overlay);
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
