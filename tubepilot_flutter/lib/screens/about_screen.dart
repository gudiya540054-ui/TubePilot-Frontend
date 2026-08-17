import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Core feature list — kept in sync with what the app actually does today:
  // multi-platform publishing (YouTube, Facebook Reels),
  // Drive auto-upload, AI content tools, scheduling, and notifications.
  // Titles/descriptions are translation keys (see app_strings.dart, "About
  // screen" section) resolved via context.tr() at build time.
  static const _features = [
    _Feature(icon: Icons.cloud_upload_rounded, titleKey: 'feature_multi_platform_title', descKey: 'feature_multi_platform_desc'),
    _Feature(icon: Icons.folder_special_rounded, titleKey: 'feature_drive_title', descKey: 'feature_drive_desc'),
    _Feature(icon: Icons.schedule_send_rounded, titleKey: 'feature_scheduling_title', descKey: 'feature_scheduling_desc'),
    _Feature(icon: Icons.auto_awesome_rounded, titleKey: 'feature_ai_title', descKey: 'feature_ai_desc'),
    _Feature(icon: Icons.lock_clock_rounded, titleKey: 'feature_privacy_title', descKey: 'feature_privacy_desc'),
    _Feature(icon: Icons.notifications_active_rounded, titleKey: 'feature_notif_title', descKey: 'feature_notif_desc'),
    _Feature(icon: Icons.diamond_rounded, titleKey: 'feature_credit_title', descKey: 'feature_credit_desc'),
    _Feature(icon: Icons.card_giftcard_rounded, titleKey: 'feature_refer_title', descKey: 'feature_refer_desc'),
    _Feature(icon: Icons.dark_mode_rounded, titleKey: 'feature_theme_title', descKey: 'feature_theme_desc'),
  ];

  // Short "how it works" steps shown as a numbered flow, so new users
  // understand the core loop (connect -> select platforms -> relax) at a glance.
  static const _steps = [
    _Step(number: '1', titleKey: 'step_connect_title', descKey: 'step_connect_desc'),
    _Step(number: '2', titleKey: 'step_upload_title', descKey: 'step_upload_desc'),
    _Step(number: '3', titleKey: 'step_relax_title', descKey: 'step_relax_desc'),
  ];

  static const _platforms = [
    _Platform(emoji: '📺', name: 'YouTube', descKey: 'platform_youtube_desc'),
    _Platform(emoji: '📘', name: 'Facebook', descKey: 'platform_facebook_desc'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('about_app_bar_title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(22)),
              child: const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40)),
            ),
          ),
          const SizedBox(height: 16),
          // Brand wordmark — kept literal (proper noun), matches every
          // language variant of the translated body copy below.
          const Center(
            child: Text(
              'Tube Pilot',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              context.tr('app_tagline'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.surfaces.textDim, fontSize: 13.5),
            ),
          ),
          const SizedBox(height: 24),

          // ---------------- What is Tube Pilot ----------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('what_is_tubepilot'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(
                  context.tr('what_is_tubepilot_body'),
                  style: TextStyle(color: context.surfaces.textDim, fontSize: 13.5, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---------------- Supported Platforms ----------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('supported_platforms_title'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                for (int i = 0; i < _platforms.length; i++) ...[
                  _PlatformRow(platform: _platforms[i]),
                  if (i != _platforms.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---------------- Features ----------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('features_title'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                for (int i = 0; i < _features.length; i++) ...[
                  _FeatureRow(feature: _features[i]),
                  if (i != _features.length - 1) const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
                Divider(color: context.surfaces.border, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.purple, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('app_version_label'),
                      style: TextStyle(color: context.surfaces.textDim, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---------------- How it works ----------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('how_it_works_title'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                for (int i = 0; i < _steps.length; i++) ...[
                  _StepRow(step: _steps[i]),
                  if (i != _steps.length - 1) const SizedBox(height: 18),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---------------- Why Tube Pilot ----------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('why_creators_title'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _WhyRow(icon: Icons.speed_rounded, text: context.tr('why_speed')),
                const SizedBox(height: 10),
                _WhyRow(icon: Icons.hub_rounded, text: context.tr('why_hub')),
                const SizedBox(height: 10),
                _WhyRow(icon: Icons.auto_mode_rounded, text: context.tr('why_automation')),
                const SizedBox(height: 10),
                _WhyRow(icon: Icons.support_agent_rounded, text: context.tr('why_support')),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---------------- Company / Developer card ----------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.surfaces.border),
              boxShadow: [
                BoxShadow(color: AppColors.purple.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                Text(
                  context.tr('developed_powered_by'),
                  style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5, letterSpacing: 0.3),
                ),
                const SizedBox(height: 12),
                Image.asset(
                  'assets/companylogo.png',
                  height: 48,
                  errorBuilder: (_, __, ___) => const Icon(Icons.business_rounded, size: 40),
                ),
                const SizedBox(height: 12),
                // Company & person names are proper nouns — kept literal in
                // every language, consistent with how they appear inline in
                // the translated body copy elsewhere on this screen.
                const Text(
                  'Bharat Cloud Technologies',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                Text(context.tr('ceo_label'), style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5, letterSpacing: 1)),
                const SizedBox(height: 4),
                const Text(
                  'Mr. Anik Kesharwani',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Image.asset(
                  'assets/signature.png',
                  height: 72,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---------------- Footer ----------------
          Center(
            child: Text(
              _fmt(context.tr('about_footer_rights'), DateTime.now().year),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Replaces the first "%d"/"%s" in a translated template with a value —
// AppStrings templates use them as plain placeholders, not real printf.
String _fmt(String template, Object value) => template.replaceFirst('%d', '$value').replaceFirst('%s', '$value');

// ---------------- Helper models ----------------

class _Feature {
  final IconData icon;
  final String titleKey;
  final String descKey;
  const _Feature({required this.icon, required this.titleKey, required this.descKey});
}

class _Step {
  final String number;
  final String titleKey;
  final String descKey;
  const _Step({required this.number, required this.titleKey, required this.descKey});
}

class _Platform {
  final String emoji;
  final String name;
  final String descKey;
  const _Platform({required this.emoji, required this.name, required this.descKey});
}

// ---------------- Helper widgets ----------------

class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.green.withOpacity(0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(feature.icon, color: AppColors.green, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(feature.titleKey),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                context.tr(feature.descKey),
                style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final _Step step;
  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
          child: Center(
            child: Text(
              step.number,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(step.titleKey),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                context.tr(step.descKey),
                style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlatformRow extends StatelessWidget {
  final _Platform platform;
  const _PlatformRow({required this.platform});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.purple.withOpacity(0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(platform.emoji, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform brand name (YouTube/Facebook) — proper
              // noun, kept literal; only the description is translated.
              Text(platform.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(context.tr(platform.descKey), style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _WhyRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _WhyRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.purple, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: context.surfaces.textDim, fontSize: 13, height: 1.45),
          ),
        ),
      ],
    );
  }
}