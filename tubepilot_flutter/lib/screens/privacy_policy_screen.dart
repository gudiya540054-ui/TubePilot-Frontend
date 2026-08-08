import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  static const _sections = [
    (
      icon: Icons.badge_outlined,
      title: '1. Information We Collect',
      body: 'When you create an account, we collect your name, email address, and '
          'password (encrypted). If you sign in with Google, we receive your name, '
          'email, and profile photo from Google. When you connect your YouTube '
          'channel, we store your channel ID, channel name, subscriber count, and '
          'OAuth access/refresh tokens needed to upload on your behalf. When you '
          'connect Facebook and/or Instagram, we store your Facebook Page ID, Page '
          'name, and Page access token, and — if your Page has a linked Instagram '
          'Business account — your Instagram user ID and username, needed to '
          'publish Reels on your behalf.'
    ),
    (
      icon: Icons.lock_outline_rounded,
      title: '2. Permissions We Request',
      body: '• Photos & Videos (gallery access): to let you pick a video and an '
          'optional thumbnail image for upload. We never access your gallery in '
          'the background — only when you tap "select a video" or "thumbnail".\n\n'
          '• Internet access: required to upload videos, sync your dashboard, and '
          'communicate with YouTube\'s, Meta\'s, and our own servers.\n\n'
          '• Notifications: to alert you when an upload completes, fails, or a '
          'scheduled video goes public on any connected platform. You can disable '
          'this anytime in your device settings.\n\n'
          '• Google Account access (OAuth): to sign you in and, separately, to '
          'upload videos to your connected YouTube channel and/or Google Drive '
          'with your explicit permission via Google\'s consent screen.\n\n'
          '• Facebook Login (Meta OAuth): to let you connect a Facebook Page and, '
          'if linked, an Instagram Business account, so Tube Pilot can publish '
          'Reels to them with your explicit permission via Meta\'s consent screen. '
          'We request the pages_show_list, pages_read_engagement, '
          'pages_manage_posts, instagram_basic, and instagram_content_publish '
          'permissions — used solely to publish the videos you submit, to the '
          'Page/account you choose.\n\n'
          'We do NOT request camera, microphone, contacts, location, or SMS '
          'permissions — the app has no feature that needs them.'
    ),
    (
      icon: Icons.cloud_outlined,
      title: '3. Video Storage & Deletion',
      body: 'When you select a video to upload, it is temporarily transferred to '
          'secure cloud storage (Cloudinary or Google Drive) so it can be pushed '
          'to YouTube, Instagram, and/or Facebook — whichever platforms you '
          'selected. Once the video has been successfully published to every '
          'selected platform (or every attempt has permanently failed), we delete '
          'our temporary copy of the video file from that storage — we do not '
          'retain a copy of your video content after publishing is complete. Only '
          'metadata (title, description, tags, captions, hashtags, thumbnail, '
          'each platform\'s post ID/link, and publish status) is kept in our '
          'database so you can see your upload history inside the app.'
    ),
    (
      icon: Icons.settings_outlined,
      title: '4. How We Use Your Information',
      body: 'Your information is used to authenticate you, publish videos to the '
          'platforms you connect and select (YouTube, Instagram, Facebook), '
          'manage your diamond balance and free-upload quota, and send you status '
          'notifications about your uploads. We do not sell your personal data to '
          'third parties.'
    ),
    (
      icon: Icons.hub_outlined,
      title: '5. Third-Party Services',
      body: 'We use the YouTube Data API and Google Sign-In, the Google Drive API, '
          'and the Meta Graph API (Facebook Login, Facebook Pages, and Instagram '
          'Graph API) — each governed by its provider\'s own privacy policy. We '
          'also use Cloudinary and Google Drive for temporary video storage, and '
          'Firebase Cloud Messaging plus OneSignal for push notifications. Each of '
          'these providers processes data only as needed to provide their '
          'respective service to the app.'
    ),
    (
      icon: Icons.security_rounded,
      title: '6. Data Security',
      body: 'All network requests use encrypted (HTTPS) connections. YouTube and '
          'Meta (Facebook/Instagram) OAuth tokens are stored securely and are '
          'never shared with third parties beyond what\'s required to call the '
          'respective platform\'s API on your behalf.'
    ),
    (
      icon: Icons.fact_check_outlined,
      title: '7. Your Choices & Rights',
      body: 'You can disconnect your YouTube channel, Google Drive, or Facebook/'
          'Instagram connection at any time from the Profile screen — '
          'disconnecting Facebook also disconnects Instagram, since Instagram '
          'publishing uses the same Facebook Page connection. You can request '
          'full account and data deletion by contacting us at the email below — '
          'we will remove your account, connected-platform tokens, and upload '
          'history within a reasonable timeframe.'
    ),
    (
      icon: Icons.child_care_outlined,
      title: '8. Children\'s Privacy',
      body: 'Tube Pilot is not directed at children under 13, and we do not '
          'knowingly collect personal information from children.'
    ),
    (
      icon: Icons.update_rounded,
      title: '9. Changes to This Policy',
      body: 'We may update this Privacy Policy from time to time. Continued use of '
          'the app after changes means you accept the updated policy.'
    ),
    (
      icon: Icons.mail_outline_rounded,
      title: '10. Contact Us',
      body: 'If you have any questions about this Privacy Policy or your data, '
          'reach out to us at anikkesharwani37@gmail.com.'
    ),
  ];

  final _scrollController = ScrollController();
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 400;
      if (shouldShow != _showScrollTop) setState(() => _showScrollTop = shouldShow);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      floatingActionButton: _showScrollTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: AppColors.purple,
              child: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
            )
          : null,
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            Icon(Icons.privacy_tip_outlined, size: 15, color: context.surfaces.textDim),
            const SizedBox(width: 6),
            Text('Last updated: ${DateTime.now().year}', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
          ]),
          const SizedBox(height: 16),
          ..._sections.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 30, height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                        child: Icon(s.icon, size: 16, color: AppColors.purple),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                    ]),
                    const SizedBox(height: 8),
                    Text(s.body, style: TextStyle(color: context.surfaces.textDim, fontSize: 13.5, height: 1.5)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}