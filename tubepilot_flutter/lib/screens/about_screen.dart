import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(20)),
                child: const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34)),
              ),
              const SizedBox(height: 14),
              const Text('TubePilot', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Version 1.0.0', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
            child: Text(
              'TubePilot helps creators schedule, upload, and manage their YouTube videos directly from their phone — with AI-assisted titles, descriptions, and tags to save time on every upload.',
              style: TextStyle(color: context.surfaces.textDim, fontSize: 13.5, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _infoRow('App Version', '1.0.0'),
              Divider(height: 1, color: context.surfaces.border),
              _infoRow('Developer', 'TubePilot Team'),
              Divider(height: 1, color: context.surfaces.border),
              _infoRow('Contact', 'anikkesharwani37@gmail.com'),
            ]),
          ),
          const SizedBox(height: 20),
          Text(
            '© ${DateTime.now().year} TubePilot. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 13.5)),
        ],
      ),
    );
  }
}