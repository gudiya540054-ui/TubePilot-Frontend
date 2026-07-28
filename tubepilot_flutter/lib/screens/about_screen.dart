import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Core feature list — kept in sync with what the app actually does today:
  // manual + bulk YouTube upload, Drive auto-upload, AI content tools,
  // scheduling, and real-time notifications.
  static const _features = [
    _Feature(
      icon: Icons.cloud_upload_rounded,
      title: 'Direct YouTube Upload',
      description: 'Upload single or multiple videos to YouTube straight from your phone — no desktop or laptop needed.',
    ),
    _Feature(
      icon: Icons.folder_special_rounded,
      title: 'Google Drive Auto-Upload',
      description: 'Connect your Google Drive, pick a daily time, and TubePilot automatically uploads your next pending video to YouTube every day — completely hands-free.',
    ),
    _Feature(
      icon: Icons.auto_awesome_rounded,
      title: 'AI-Generated Titles, Descriptions & Tags',
      description: 'Skip the writer\'s block — generate optimized titles, descriptions, and tags for every video in seconds.',
    ),
    _Feature(
      icon: Icons.lock_clock_rounded,
      title: 'Flexible Privacy & Scheduling',
      description: 'Upload as Public, Unlisted, or Private, with automatic "go public" scheduling for videos you want to release later.',
    ),
    _Feature(
      icon: Icons.notifications_active_rounded,
      title: 'Real-Time Push Notifications',
      description: 'Get notified the instant your video finishes uploading, goes live, or if an upload needs your attention.',
    ),
    _Feature(
      icon: Icons.diamond_rounded,
      title: 'Simple Credit System',
      description: 'Free monthly uploads plus a straightforward diamond wallet for extra uploads — no hidden charges, no confusing tiers.',
    ),
    _Feature(
      icon: Icons.card_giftcard_rounded,
      title: 'Refer & Earn',
      description: 'Invite friends and earn diamonds when they join using your referral code.',
    ),
    _Feature(
      icon: Icons.dark_mode_rounded,
      title: 'Light & Dark Mode',
      description: 'A clean interface that adapts to how you like to work, day or night.',
    ),
  ];

  // Short "how it works" steps shown as a numbered flow, so new users
  // understand the core loop (connect -> upload/schedule -> relax) at a glance.
  static const _steps = [
    _Step(
      number: '1',
      title: 'Connect Your Channel',
      description: 'Sign in with Google and link your YouTube channel in a few taps.',
    ),
    _Step(
      number: '2',
      title: 'Upload or Auto-Connect Drive',
      description: 'Upload videos manually, in bulk, or connect Google Drive for fully automatic daily uploads.',
    ),
    _Step(
      number: '3',
      title: 'Sit Back & Get Notified',
      description: 'TubePilot handles the upload queue and pings you the moment each video goes live.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About App')),
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
          const Center(
            child: Text(
              'TubePilot',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Schedule & Auto-Upload to YouTube',
              style: TextStyle(color: context.surfaces.textDim, fontSize: 13.5),
            ),
          ),
          const SizedBox(height: 24),

          // ---------------- What is TubePilot ----------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What is TubePilot?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(
                  'TubePilot is your personal YouTube upload assistant — built for creators who want their videos '
                  'live without babysitting an upload progress bar. Upload directly, schedule for later, or hand it '
                  'over to Drive auto-upload and let TubePilot take care of the rest.',
                  style: TextStyle(color: context.surfaces.textDim, fontSize: 13.5, height: 1.5),
                ),
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
                const Text('Features', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
                      'App Version: 1.0.0',
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
                const Text('How It Works', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                for (int i = 0; i < _steps.length; i++) ...[
                  _StepRow(step: _steps[i]),
                  if (i != _steps.length - 1) const SizedBox(height: 18),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---------------- Why TubePilot ----------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Why Creators Use TubePilot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _WhyRow(
                  icon: Icons.speed_rounded,
                  text: 'Uploads that used to take a desktop and a browser tab now happen from your pocket.',
                ),
                const SizedBox(height: 10),
                _WhyRow(
                  icon: Icons.auto_mode_rounded,
                  text: 'Drive auto-upload means a full content queue can go out daily without you opening the app.',
                ),
                const SizedBox(height: 10),
                _WhyRow(
                  icon: Icons.support_agent_rounded,
                  text: 'A real support team behind every account — reach out any time from the Help & Support menu.',
                ),
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
                  'Developed & Powered by',
                  style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5, letterSpacing: 0.3),
                ),
                const SizedBox(height: 12),
                Image.asset(
                  'assets/companylogo.png',
                  height: 48,
                  errorBuilder: (_, __, ___) => const Icon(Icons.business_rounded, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bharat Cloud Technologies',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                Text('CEO', style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5, letterSpacing: 1)),
                const SizedBox(height: 4),
                const Text(
                  'Mr. Anik Kesharwani',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                // Signature enlarged: 40 -> 72
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
              '© ${DateTime.now().year} Bharat Cloud Technologies. All rights reserved.',
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

// ---------------- Helper models ----------------

class _Feature {
  final IconData icon;
  final String title;
  final String description;
  const _Feature({required this.icon, required this.title, required this.description});
}

class _Step {
  final String number;
  final String title;
  final String description;
  const _Step({required this.number, required this.title, required this.description});
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
                feature.title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                feature.description,
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
                step.title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                step.description,
                style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5, height: 1.4),
              ),
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