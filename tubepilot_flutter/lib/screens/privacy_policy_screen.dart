import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    (
      title: 'Information We Collect',
      body: 'We collect your name, email address, and profile information when you '
          'sign up. When you connect your YouTube channel, we store the channel ID, '
          'title, and OAuth tokens needed to upload videos on your behalf.'
    ),
    (
      title: 'How We Use Your Information',
      body: 'Your information is used to authenticate you, process video uploads to '
          'YouTube, manage your diamond balance and subscription, and send you '
          'notifications about your uploads.'
    ),
    (
      title: 'Video & File Storage',
      body: 'Videos you upload are temporarily stored on our servers/cloud storage '
          'while being processed and pushed to YouTube. We do not use your video '
          'content for any purpose other than delivering it to your connected channel.'
    ),
    (
      title: 'Third-Party Services',
      body: 'We use Google/YouTube APIs to upload and manage videos on your behalf, '
          'and Firebase for push notifications. These services have their own '
          'privacy policies governing how they handle data.'
    ),
    (
      title: 'Data Security',
      body: 'We take reasonable measures to protect your data, including encrypted '
          'connections and secure storage of authentication tokens. However, no '
          'method of transmission over the internet is 100% secure.'
    ),
    (
      title: 'Your Choices',
      body: 'You can disconnect your YouTube channel, delete uploaded videos, or '
          'request account deletion at any time by contacting support.'
    ),
    (
      title: 'Contact Us',
      body: 'If you have any questions about this Privacy Policy, reach out to us at '
          'anikkesharwani37@gmail.com.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Last updated: ${DateTime.now().year}', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
          const SizedBox(height: 16),
          ..._sections.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(s.body, style: TextStyle(color: context.surfaces.textDim, fontSize: 13.5, height: 1.5)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}