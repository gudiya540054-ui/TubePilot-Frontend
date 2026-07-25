import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    (
      title: '1. Information We Collect',
      body: 'When you create an account, we collect your name, email address, and '
          'password (encrypted). If you sign in with Google, we receive your name, '
          'email, and profile photo from Google. When you connect your YouTube '
          'channel, we store your channel ID, channel name, subscriber count, and '
          'OAuth access/refresh tokens needed to upload on your behalf.'
    ),
    (
      title: '2. Permissions We Request',
      body: '• Photos & Videos (gallery access): to let you pick a video and an '
          'optional thumbnail image for upload. We never access your gallery in '
          'the background — only when you tap "select a video" or "thumbnail".\n\n'
          '• Internet access: required to upload videos, sync your dashboard, and '
          'communicate with YouTube\'s servers.\n\n'
          '• Notifications: to alert you when an upload completes, fails, or a '
          'scheduled video goes public. You can disable this anytime in your '
          'device settings.\n\n'
          '• Google Account access (OAuth): to sign you in and, separately, to '
          'upload videos to your connected YouTube channel with your explicit '
          'permission via Google\'s consent screen.\n\n'
          'We do NOT request camera, microphone, contacts, location, or SMS '
          'permissions — the app has no feature that needs them.'
    ),
    (
      title: '3. Video Storage & Deletion',
      body: 'When you select a video to upload, it is temporarily transferred to '
          'secure cloud storage (Cloudinary or Google Drive) so it can be pushed '
          'to YouTube. Once the video has been successfully uploaded to your '
          'YouTube channel, we permanently delete our copy of the video file from '
          'that storage — we do not retain a copy of your video content after it '
          'goes live on YouTube. Only metadata (title, description, tags, '
          'thumbnail, YouTube video ID/link, and upload status) is kept in our '
          'database so you can see your upload history inside the app.'
    ),
    (
      title: '4. How We Use Your Information',
      body: 'Your information is used to authenticate you, upload videos to your '
          'connected YouTube channel, manage your diamond balance and free-upload '
          'quota, and send you status notifications about your uploads. We do not '
          'sell your personal data to third parties.'
    ),
    (
      title: '5. Third-Party Services',
      body: 'We use the YouTube Data API and Google Sign-In (governed by Google\'s '
          'Privacy Policy), Cloudinary and Google Drive for temporary video '
          'storage, and Firebase Cloud Messaging for push notifications. Each of '
          'these providers processes data only as needed to provide their '
          'respective service to the app.'
    ),
    (
      title: '6. Data Security',
      body: 'All network requests use encrypted (HTTPS) connections. YouTube OAuth '
          'tokens are stored securely and are never shared with third parties '
          'beyond what\'s required to call the YouTube API on your behalf.'
    ),
    (
      title: '7. Your Choices & Rights',
      body: 'You can disconnect your YouTube channel at any time from the Profile '
          'screen. You can request full account and data deletion by contacting '
          'us at the email below — we will remove your account, connected-channel '
          'tokens, and upload history within a reasonable timeframe.'
    ),
    (
      title: '8. Children\'s Privacy',
      body: 'TubePilot is not directed at children under 13, and we do not '
          'knowingly collect personal information from children.'
    ),
    (
      title: '9. Changes to This Policy',
      body: 'We may update this Privacy Policy from time to time. Continued use of '
          'the app after changes means you accept the updated policy.'
    ),
    (
      title: '10. Contact Us',
      body: 'If you have any questions about this Privacy Policy or your data, '
          'reach out to us at anikkesharwani37@gmail.com.'
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