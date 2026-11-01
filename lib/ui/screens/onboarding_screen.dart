import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/platform_detect.dart';
import '../../core/platform/web_action_bridge.dart';
import '../../core/platform/web_download.dart';
import '../../services/auth_service.dart';
import '../../providers/app_provider.dart';
import '../widgets/sign_in_button.dart';
import '../widgets/video_background.dart';
import '../widgets/model_3d_overlay.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _videoDone = false;
  bool _popupVisible = false;
  Timer? _fallbackTimer;
  Timer? _popupDelayTimer;
  WebActionBridge? _actionBridge;

  @override
  void initState() {
    super.initState();
    _createActionChannel();
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_videoDone) _onVideoDone();
    });
  }

  void _createActionChannel() {
    _actionBridge = WebActionBridge.create()
      ..init((action) {
        if (!mounted) return;
        if (action == 'download') _downloadApk();
        if (action == 'web') _openWebSignIn();
      });
  }

  void _onVideoDone() {
    if (!mounted || _videoDone) return;
    setState(() => _videoDone = true);
    _popupDelayTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _popupVisible = true);
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _popupDelayTimer?.cancel();
    _actionBridge?.dispose();
    _actionBridge = null;
    super.dispose();
  }

  void _openWebSignIn() {
    if (!mounted) return;
    if (kIsWeb) {
      _showWebSignInDialog();
    } else {
      _signInNative();
    }
  }

  Future<void> _signInNative() async {
    final auth = ref.read(authServiceProvider);
    final result = await auth.signIn();
    if (!result.success && result.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: ${result.error}')),
      );
    }
  }

  void _showWebSignInDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF16162a),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 18),
              const Text(
                'Spliti5 Web',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in with Google to continue to your trips in your browser',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  children: [
                    _featureRow(Icons.sync_rounded, 'Real-time multi-device sync'),
                    const SizedBox(height: 8),
                    _featureRow(Icons.cloud_outlined, 'Trip backup & cloud restore'),
                    const SizedBox(height: 8),
                    _featureRow(Icons.devices_rounded, 'Same account on web and mobile app'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                height: 48,
                child: Center(child: SignInButton()),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Dismiss',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF667eea), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadApk() async {
    final ok = await downloadFile(
      PlatformDetect.apkDownloadUrl,
      fileName: 'split-wise.apk',
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start download')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthService>(authServiceProvider, (prev, next) {
      if (next.isSignedIn && mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }
    });

    if (!kIsWeb) {
      return _buildNativeOnboarding(context);
    }

    return _buildWebOnboarding(context);
  }

  Widget _buildNativeOnboarding(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070911),
      body: Stack(
        children: [
          // Ambient Top Gold Glow
          Positioned(
            top: -50,
            left: 0,
            right: 0,
            height: 280,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.85,
                    colors: [
                      const Color(0xFFEAB308).withValues(alpha: 0.15),
                      const Color(0xFF6366F1).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Ambient Bottom Cyan Glow
          Positioned(
            bottom: -60,
            left: -40,
            width: 280,
            height: 280,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.8,
                    colors: [
                      const Color(0xFF0EA5E9).withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      // Floating Classic Gold Crest (No box, no border)
                      Image.asset(
                        'assets/spliti5_crest_gold.png',
                        height: 95,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Spliti5',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'TRAVEL • SPLIT • EXPLORE',
                        style: TextStyle(
                          color: Color(0xFFEAB308),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Smart group expenses, zero awkwardness.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Live Glassmorphic Split Preview Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: const [
                                    Text(
                                      'Next Trip to ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    _DestinationDashSlot(),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    '4 Members',
                                    style: TextStyle(
                                      color: Color(0xFFA5B4FC),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '✈️ Group Flights & Stay',
                                        style: TextStyle(
                                          color: Color(0xFFE2E8F0),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Paid by David • Equal Split',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.45),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Text(
                                    '₹18,400',
                                    style: TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Alex owes David',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const Text(
                                    '₹4,600',
                                    style: TextStyle(
                                      color: Color(0xFF4ADE80),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Feature Chips
                      Row(
                        children: [
                          Expanded(child: _featureChip('⚡', '100% Offline')),
                          const SizedBox(width: 8),
                          Expanded(child: _featureChip('🔄', 'Cloud Sync')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _featureChip('💸', 'UPI Deep-links')),
                          const SizedBox(width: 8),
                          Expanded(child: _featureChip('🛡️', 'No Ad Tracking')),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Google Sign-in Button
                      const SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Center(child: SignInButton()),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'By continuing, you agree to our Terms of Service',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 10)),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebOnboarding(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: VideoBackground(
        duration: const Duration(seconds: 10),
        onLoopComplete: () => _onVideoDone(),
        child: Stack(
          children: [
            if (_videoDone)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 340,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _popupVisible ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.82),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Model3DOverlay(show: _popupVisible),
            if (_popupVisible)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: const SignInButton(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DestinationDashSlot extends StatefulWidget {
  const _DestinationDashSlot();

  @override
  State<_DestinationDashSlot> createState() => _DestinationDashSlotState();
}

class _DestinationDashSlotState extends State<_DestinationDashSlot> {
  static const List<String> _destinations = [
    '🏔️ Himachal',
    '🏰 Rajasthan',
    '🌴 Goa',
    '🛶 Kerala',
    '❄️ Kashmir',
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _destinations.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.35),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            _destinations[_currentIndex],
            key: ValueKey<int>(_currentIndex),
            style: const TextStyle(
              color: Color(0xFFFDE047),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: 2,
          width: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFFACC15),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFACC15).withValues(alpha: 0.55),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

