import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SponsorCard extends StatefulWidget {
  const SponsorCard({super.key});
  @override
  State<SponsorCard> createState() => _SponsorCardState();
}

class _SponsorCardState extends State<SponsorCard> with TickerProviderStateMixin {
  bool _cheers = false;
  late AnimationController _ctrl;
  late AnimationController _lottieCtrl;
  late Animation<double> _steam;
  late Animation<double> _shimmer;

  String get _upiUrl => Uri(scheme: 'upi', host: 'pay', queryParameters: {
        'pa': 'vighnesh.bagal99-1@okicici',
        'pn': 'Vighnesh Bagal',
        'cu': 'INR',
        'tn': 'Support Split Wise',
      }).toString();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _lottieCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _steam = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _shimmer = Tween<double>(begin: -1, end: 2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
    // Play Lottie 3s then stop (modern Ara: show craft once, not loop forever)
    _lottieCtrl.forward();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) _lottieCtrl.stop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _lottieCtrl.dispose();
    super.dispose();
  }

  void _onTapSupport() {
    HapticFeedback.lightImpact();
    _showQrSheet();
  }

  void _showQrSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1D2B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
                child: QrImageView(
                  data: _upiUrl,
                  version: QrVersions.auto,
                  size: 220,
                  gapless: true,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                ),
              ),
              const SizedBox(height: 10),
              Text('Scan with any UPI app', style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.outline)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'vighnesh.bagal99-1@okicici'));
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('UPI ID copied')));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy UPI ID', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      // On web/desktop, UPI deep links don't work — just copy.
                      if (kIsWeb) {
                        Clipboard.setData(const ClipboardData(text: 'vighnesh.bagal99-1@okicici'));
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('UPI ID copied — open your UPI app')));
                        return;
                      }
                      final uri = Uri.parse(_upiUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                        setState(() => _cheers = true);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for the support — means a lot! ☕')));
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _cheers = false);
                        });
                      } else {
                        Clipboard.setData(const ClipboardData(text: 'vighnesh.bagal99-1@okicici'));
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('UPI ID copied — open your UPI app')));
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Open UPI', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Text('You pick the amount — 100% voluntary, app stays free. Not a charitable donation.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Theme.of(ctx).colorScheme.outline, height: 1.3)),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isDark ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)] : [const Color(0xFF667eea), const Color(0xFF764ba2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Idle animation directly — no white box, 52×52 transparent
              GestureDetector(
                onTap: () {
                  _lottieCtrl.reset();
                  _lottieCtrl.forward();
                  Future.delayed(const Duration(milliseconds: 3000), () {
                    if (mounted) _lottieCtrl.stop();
                  });
                },
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Lottie.asset('assets/animations/coffee_pour.json', controller: _lottieCtrl, width: 52, height: 52, fit: BoxFit.contain, onLoaded: (comp) {
                        _lottieCtrl.duration = comp.duration;
                        if (!_lottieCtrl.isAnimating) _lottieCtrl.forward();
                      }, errorBuilder: (ctx, err, st) => const Icon(Icons.coffee_rounded, color: Colors.white, size: 28)),
                      if (_cheers) const Positioned(top: 0, right: 0, child: Text('✨', style: TextStyle(fontSize: 10))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Built with heart, runs on coffee', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('One dev, countless splits.', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('No awkward money talk between friends — but a coffee for the dev? Always welcome. You pick the amount, UPI does the rest.', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4)),
          const SizedBox(height: 14),
          // Modern button with shimmer — no aside image
          AnimatedBuilder(
            animation: _shimmer,
            builder: (_, child) => Stack(
              children: [
                child!,
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FractionallySizedBox(
                      widthFactor: 0.3,
                      alignment: Alignment(_shimmer.value, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.18), Colors.transparent], stops: const [0, 0.5, 1]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _onTapSupport,
                icon: Icon(_cheers ? Icons.favorite_rounded : Icons.coffee_rounded, size: 18, color: const Color(0xFF667eea)),
                label: Text(_cheers ? 'Thank you!' : 'Buy Me a Coffee', style: const TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF667eea), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text('UPI: vighnesh.bagal99-1@okicici • Voluntary — no perks unlocked', style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10))),
        ],
      ),
    );
  }
}
