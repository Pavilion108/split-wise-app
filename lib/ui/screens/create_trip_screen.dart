import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../providers/app_provider.dart';
import '../widgets/daily_travel_background.dart';

/// Immersive full-screen trip creation page with travel-themed background.
class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _nameCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  String _currency = 'INR';
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _createTrip() async {
    final tripName = _nameCtrl.text.trim();
    if (tripName.isEmpty) return;
    setState(() => _creating = true);
    try {
      final deviceId = ref.read(deviceIdentityProvider).id;
      final auth = ref.read(authServiceProvider);
      final repo = ref.read(tripRepositoryProvider);
      final memberName = (auth.currentUser?.displayName?.trim().isNotEmpty == true)
          ? auth.currentUser!.displayName!.trim()
          : 'Me';
      final googleId = auth.currentUser?.id ?? '';
      final emailLower = (auth.currentUser?.email ?? '').toLowerCase().trim();

      final trip = await repo.createTrip(
        name: tripName,
        baseCurrency: _currency,
        memberName: memberName,
        deviceId: deviceId,
        googleId: googleId,
        emailLower: emailLower,
        whatsappGroupLink: _whatsappCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, trip);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DailyTravelBackground(
        child: Stack(
          children: [
            // Content
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 24),
                      // Title with Hero transition
                      Hero(
                        tag: 'create_trip_title',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            'Create Trip',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                      const SizedBox(height: 6),
                      Text(
                        'Where are we heading?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 40),
                    // Trip name
                    _buildField(
                      controller: _nameCtrl,
                      label: 'Trip name',
                      hint: 'Goa Trip Dec 2026',
                      icon: Icons.flight_takeoff_rounded,
                      delay: 200,
                    ),
                    const SizedBox(height: 20),
                    // Currency selector
                    _buildCurrencySelector(cs, isDark),
                    const SizedBox(height: 20),
                    // WhatsApp link
                    _buildField(
                      controller: _whatsappCtrl,
                      label: 'WhatsApp group link (optional)',
                      hint: 'https://chat.whatsapp.com/...',
                      icon: Icons.chat_outlined,
                      delay: 500,
                    ),
                    const SizedBox(height: 48),
                    // Create button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _creating ? null : _createTrip,
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _creating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Trip',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required int delay,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white60),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white54, width: 1.5),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideX(begin: -0.05);
  }

  Widget _buildCurrencySelector(ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<String>(
        value: _currency,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFF2C2C3E),
        style: const TextStyle(color: Colors.white),
        icon: Icon(Icons.expand_more, color: Colors.white.withValues(alpha: 0.6)),
        items: [
          for (final c in kDefaultCurrencies)
            DropdownMenuItem(
              value: c['code'],
              child: Text('${c['code']}  ${c['name']}', style: const TextStyle(fontSize: 14)),
            ),
        ],
        onChanged: (v) => setState(() => _currency = v!),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: -0.05);
  }
}
