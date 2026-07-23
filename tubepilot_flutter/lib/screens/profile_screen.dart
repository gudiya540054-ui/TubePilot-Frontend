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

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AuthProvider>().refreshUser());
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
        padding: const EdgeInsets.all(20),
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
                  const Text('📺', style: TextStyle(fontSize: 20)),
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

          Container(
            decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _menuRow(Icons.diamond_outlined, 'Subscription & Wallet', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen()))),
              _divider(),
              _menuRow(Icons.card_giftcard_outlined, 'Refer & Earn (${user['referralCode'] ?? '-'})', () {}),
              _divider(),
              _menuRow(Icons.shopping_bag_outlined, 'Buy Diamonds', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiamondStoreScreen()))),
              _divider(),
              _menuRow(Icons.notifications_outlined, 'Notifications', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
              _divider(),
              _menuRow(Icons.help_outline, 'Help & Support', () => showToast(context, 'Contact support@tubepilot.com')),
              if (auth.isAdmin) ...[
                _divider(),
                _menuRow(Icons.admin_panel_settings_outlined, 'Admin Panel', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminScreen()))),
              ],
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

  Widget _menuRow(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: context.surfaces.textDim, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Icon(Icons.chevron_right, color: context.surfaces.textDim),
      onTap: onTap,
    );
  }

  Widget _divider() => Divider(height: 1, color: context.surfaces.border);
}
