import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tabs;
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/brand_icons.dart';
import 'wallet_screen.dart';
import 'diamond_store_screen.dart';
import 'notifications_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';
import 'refer_earn_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'rate_us_screen.dart';
import 'drive_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _supportCategories = [
    'Payment / Diamonds Issue',
    'Video Upload Failed or Stuck',
    'YouTube Connection Issue',
    'Facebook Connection Issue',
    'Account / Login Issue',
    'App Bug or Crash',
    'Other',
  ];

  Map<String, dynamic>? _metaStatus; // { facebook: {...}|null }
  bool _loadingMeta = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AuthProvider>().refreshUser());
    _loadMetaStatus();
  }

  Future<void> _loadMetaStatus() async {
    try {
      final res = await ApiService.instance.getMetaStatus();
      setState(() => _metaStatus = res);
    } catch (_) {
      setState(() => _metaStatus = null);
    } finally {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  Future<void> _openSupport() async {
    final category = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: context.surfaces.border, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('What do you need help with?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
                ..._supportCategories.map((c) => ListTile(
                      title: Text(c, style: const TextStyle(fontSize: 14)),
                      trailing: Icon(Icons.chevron_right, color: context.surfaces.textDim, size: 18),
                      onTap: () => Navigator.pop(sheetContext, c),
                    )),
              ],
            ),
          ),
        );
      },
    );

    if (category == null || !mounted) return;
    await _sendSupportEmail(category);
  }

  Future<void> _sendSupportEmail(String category) async {
    final user = context.read<AuthProvider>().user ?? {};
    final uri = Uri(
      scheme: 'mailto',
      path: 'anikkesharwani37@gmail.com',
      query: 'subject=${Uri.encodeComponent('TubePilot Support: $category')}'
          '&body=${Uri.encodeComponent('User ID: ${user['userId'] ?? '-'}\nEmail: ${user['email'] ?? '-'}\nCategory: $category\n\nDescribe your issue below:\n')}',
    );
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        showToast(context, 'No email app found. Contact anikkesharwani37@gmail.com directly.', isError: true);
      }
    } catch (_) {
      if (mounted) showToast(context, 'No email app found. Contact anikkesharwani37@gmail.com directly.', isError: true);
    }
  }

  Future<void> _launchOAuth(String url) async {
    await custom_tabs.launchUrl(
      Uri.parse(url),
      customTabsOptions: custom_tabs.CustomTabsOptions(
        shareState: custom_tabs.CustomTabsShareState.off,
        urlBarHidingEnabled: true,
        showTitle: true,
      ),
      safariVCOptions: const custom_tabs.SafariViewControllerOptions(
        barCollapsingEnabled: true,
        dismissButtonStyle: custom_tabs.SafariViewControllerDismissButtonStyle.close,
      ),
    );
  }

  Future<void> _connectYoutube() async {
    try {
      final res = await ApiService.instance.getYoutubeOAuthUrl();
      if (res['url'] != null) await _launchOAuth(res['url']);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  // Shown when tapping an already-connected YouTube tile. A compact
  // bottom-sheet (matches _openSupport's style) with the channel name and a
  // single "Disconnect" action — kept small since YouTube has no other
  // per-account settings to manage here (unlike Drive, which gets its own
  // full screen for folder/time settings).
  Future<void> _openYoutubeOptions(Map<String, dynamic> channel) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: context.surfaces.border, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    channel['thumbnail'] != null && channel['thumbnail'].toString().isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              channel['thumbnail'],
                              width: 36, height: 36, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const YoutubeIcon(size: 20),
                            ),
                          )
                        : const YoutubeIcon(size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(channel['channelTitle'] ?? 'YouTube', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${channel['subscriberCount'] ?? 0} Subscribers', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                Divider(color: context.surfaces.border, height: 1),
                ListTile(
                  leading: const Icon(Icons.link_off_rounded, color: AppColors.red),
                  title: const Text('Disconnect', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(sheetContext, 'disconnect'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'disconnect') await _disconnectYoutube();
  }

  Future<void> _disconnectYoutube() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect YouTube?'),
        content: const Text('You will need to reconnect and grant permissions again to upload videos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Disconnect', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.instance.disconnectYoutube();
      if (mounted) {
        showToast(context, 'YouTube channel disconnected', isSuccess: true);
        context.read<AuthProvider>().refreshUser();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _connectDrive() async {
    try {
      final res = await ApiService.instance.getDriveOAuthUrl();
      if (res['url'] != null) await _launchOAuth(res['url']);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _connectMeta() async {
    try {
      final res = await ApiService.instance.getMetaOAuthUrl();
      if (res['url'] != null) await _launchOAuth(res['url']);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _disconnectFacebook() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Facebook?'),
        content: const Text('You will need to reconnect to publish Facebook Reels again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Disconnect', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.instance.disconnectFacebook();
      if (mounted) {
        showToast(context, 'Facebook disconnected', isSuccess: true);
        _loadMetaStatus();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  /// Compact side-by-side account tile — used for the 3-across YouTube /
  /// Drive / Facebook row so Connected Accounts reads as one parallel group
  /// instead of three stacked full-width rows.
  Widget _connectTile({
    required Widget icon,
    required String label,
    required String status,
    required bool connected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (connected ? AppColors.green : context.surfaces.textDim).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: icon,
              ),
              const SizedBox(height: 8),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: connected ? AppColors.green : context.surfaces.textDim, fontSize: 10.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.user ?? {};
    final channel = user['youtubeChannel'];
    final drive = user['connectedDrive'];
    final avatar = user['avatar'];

    final facebook = _metaStatus?['facebook'];

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          Center(
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
                child: avatar != null && avatar != ''
                    ? ClipOval(child: Image.network(avatar, fit: BoxFit.cover))
                    : const Center(child: Icon(Icons.person_rounded, color: Colors.white, size: 34)),
              ),
              const SizedBox(height: 10),
              Text('@${user['username'] ?? user['userId'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(user['name'] ?? user['email'] ?? '', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 20),

          Text('Connected Accounts', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
          const SizedBox(height: 8),

          // ---------------- YouTube / Drive / Facebook side-by-side ----------------
          if (_loadingMeta)
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(color: AppColors.purple)))
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _connectTile(
                  icon: channel != null && (channel['thumbnail'] ?? '').toString().isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            channel['thumbnail'],
                            width: 40, height: 40, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const YoutubeIcon(size: 20),
                          ),
                        )
                      : const YoutubeIcon(size: 20),
                  label: channel?['channelTitle'] ?? 'YouTube',
                  status: channel == null ? 'Connect' : 'Connected',
                  connected: channel != null,
                  onTap: channel == null ? _connectYoutube : () => _openYoutubeOptions(channel),
                ),
                const SizedBox(width: 12),
                _connectTile(
                  icon: const DriveIcon(size: 20),
                  label: drive == null ? 'Drive' : (drive['displayName'] ?? 'Drive'),
                  status: drive == null ? 'Connect' : 'Manage',
                  connected: drive != null,
                  onTap: drive == null
                      ? _connectDrive
                      : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DriveSettingsScreen())),
                ),
                const SizedBox(width: 12),
                _connectTile(
                  icon: const FacebookIcon(size: 20),
                  label: facebook?['pageName'] ?? 'Facebook',
                  status: facebook == null ? 'Connect' : 'Connected',
                  connected: facebook != null,
                  onTap: facebook == null ? _connectMeta : _disconnectFacebook,
                ),
              ],
            ),
          if (channel != null) ...[
            const SizedBox(height: 8),
            Text('${channel['subscriberCount'] ?? 0} Subscribers', style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5)),
          ],
          if (drive != null && drive['dailyUploadTime'] != null) ...[
            const SizedBox(height: 4),
            Text('Drive daily upload at ${drive['dailyUploadTime']}', style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5)),
          ],
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _menuRow(Icons.shopping_bag_rounded, 'Buy Diamonds', AppColors.diamond,
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiamondStoreScreen()))),
              _divider(),
              _menuRow(Icons.diamond_rounded, 'Subscription & Wallet', AppColors.purple,
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen()))),
              _divider(),
              _menuRow(Icons.card_giftcard_rounded, 'Refer & Earn', AppColors.green,
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferEarnScreen()))),
              _divider(),
              _menuRow(Icons.notifications_rounded, 'Notifications', AppColors.purpleLight,
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
              _divider(),
              _menuRow(Icons.help_rounded, 'Help & Support', AppColors.purple, _openSupport),
              if (auth.isAdmin) ...[
                _divider(),
                _menuRow(Icons.admin_panel_settings_rounded, 'Admin Panel', AppColors.red,
                    () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminScreen()))),
              ],
            ]),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _menuRow(Icons.info_rounded, 'About', AppColors.purpleLight,
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()))),
              _divider(),
              _menuRow(Icons.privacy_tip_rounded, 'Privacy Policy', AppColors.purple,
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
              _divider(),
              _menuRow(Icons.star_rounded, 'Rate Us', AppColors.diamond,
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RateUsScreen()))),
            ]),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('Default is Light', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
              value: themeProvider.isDark,
              activeColor: AppColors.purple,
              onChanged: (v) => themeProvider.setDark(v),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.red, size: 18),
              label: const Text('Logout', style: TextStyle(color: AppColors.red)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.red)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 17),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: context.surfaces.textDim),
      onTap: onTap,
    );
  }

  Widget _divider() => Divider(height: 1, color: context.surfaces.border);
}