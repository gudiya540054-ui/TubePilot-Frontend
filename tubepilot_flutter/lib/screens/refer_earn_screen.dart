import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user ?? {};
    final code = (user['referralCode'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Refer & Earn')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                  child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 12),
                const Text('Invite friends, earn diamonds', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                const Text(
                  'You and your friend both get bonus diamonds when they sign up with your code.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Your referral code', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(code.isEmpty ? '—' : code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: code.isEmpty ? null : () {
                    Clipboard.setData(ClipboardData(text: code));
                    showToast(context, 'Referral code copied!', isSuccess: true);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          GradientButton(
            label: 'Share Invite',
            icon: Icons.share_outlined,
            onPressed: code.isEmpty ? null : () {
              SharePlus.instance.share(ShareParams(
                text: 'Join me on Tube Pilot and schedule your YouTube uploads effortlessly! '
                    'Use my referral code "$code" when you sign up to get bonus diamonds.',
              ));
            },
          ),
          const SizedBox(height: 24),

          Text('How it works', style: TextStyle(color: context.surfaces.textDim, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _step(Icons.ios_share_rounded, 'Share your code with a friend'),
          _step(Icons.person_add_alt_1_rounded, 'They enter it during sign up'),
          _step(Icons.diamond_rounded, 'You both get bonus diamonds instantly'),
        ],
      ),
    );
  }

  Widget _step(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: const BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
            child: Center(child: Icon(icon, color: Colors.white, size: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }
}