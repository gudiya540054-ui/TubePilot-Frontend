import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _features = [
    'Schedule and auto-upload videos to YouTube directly from your phone — no desktop needed.',
    'AI-generated titles, descriptions, and tags so every upload is optimized in seconds.',
    'Upload as Public, Unlisted, or Private, with automatic "go public" scheduling for unlisted videos.',
    'Real-time push notifications the moment your video finishes uploading or goes live.',
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
              width: 84, height: 84,
              decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(22)),
              child: const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40)),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('TubePilot', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
          const SizedBox(height: 4),
          Center(
            child: Text('Schedule & Auto-Upload to YouTube', style: TextStyle(color: context.surfaces.textDim, fontSize: 13.5)),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('About TubePilot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                ..._features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(f, style: TextStyle(color: context.surfaces.textDim, fontSize: 13.5, height: 1.4))),
                        ],
                      ),
                    )),
                Divider(color: context.surfaces.border, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.purple, size: 18),
                    const SizedBox(width: 8),
                    Text('App Version: 1.0.0', style: TextStyle(color: context.surfaces.textDim, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.surfaces.border),
              boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              children: [
                Text('Developed & Powered by', style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5, letterSpacing: 0.3)),
                const SizedBox(height: 12),
                Image.asset(
                  'assets/companylogo.png',
                  height: 48,
                  errorBuilder: (_, __, ___) => const Icon(Icons.business_rounded, size: 40),
                ),
                const SizedBox(height: 12),
                const Text('Bharat Cloud Technologies', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                const SizedBox(height: 22),
                Text('CEO', style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5, letterSpacing: 1)),
                const SizedBox(height: 4),
                const Text('Mr. Anik Kesharwani', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Image.asset(
                  'assets/signature.png',
                  height: 40,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}