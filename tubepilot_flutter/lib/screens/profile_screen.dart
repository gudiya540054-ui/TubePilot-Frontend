import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'wallet_screen.dart';
import 'diamond_store_screen.dart';
import 'notifications_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';
import 'refer_earn_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'rate_us_screen.dart';

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
    'Account / Login Issue',
    'App Bug or Crash',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AuthProvider>().refreshUser());
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

  Future<void> _connectYoutube() async {
    try {
      final res = await ApiService.instance.getYoutubeOAuthUrl();
      if (res['url'] != null) await launchUrl(Uri.parse(res['url']), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.user ?? {};
    final channel = user['youtubeChannel'];
    final avatar = user['avatar'];

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
                    : const Center(child: Text('🙂', style: TextStyle(fontSize: 28))),
              ),
              const SizedBox(height: 10),
              Text('@${user['username'] ?? user['userId'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(user['name'] ?? user['email'] ?? '', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: channel == null ? _connectYoutube : null,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  channel != null && (channel['thumbnail'] ?? '').toString().isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            channel['thumbnail'],
                            width: 32, height: 32, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Text('📺', style: TextStyle(fontSize: 20)),
                          ),
                        )
                      : const Text('📺', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(channel?['channelTitle'] ?? 'Connect Channel', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (channel != null) Text('${channel['subscriberCount'] ?? 0} Subscribers', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
                  ]),
                ]),
                Text(channel == null ? 'Connect ›' : 'Connected', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Menu order: Buy Diamonds is now the first (most-used) action, followed
          // by Subscription & Wallet and the rest. Each row now shows a small
          // colored icon chip for a cleaner, one-item-per-line look.
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

          // App info group: About, Privacy Policy, Rate Us
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