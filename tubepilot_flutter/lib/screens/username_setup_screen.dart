import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/brand_icons.dart';
import 'dashboard_screen.dart';

class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});
  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final _usernameCtrl = TextEditingController();
  String _language = 'English';
  bool _loading = false;

  final _languages = const ['English', 'Hindi', 'Hinglish', 'Tamil', 'Telugu', 'Bengali'];

  @override
  void initState() {
    super.initState();
    _prefillSuggestedUsername();
  }

  // Auto-suggests a username from the user's name/email so they don't have to think one up.
  void _prefillSuggestedUsername() {
    final user = context.read<AuthProvider>().user ?? {};
    String base = (user['name'] ?? '').toString().trim();
    if (base.isEmpty) {
      final email = (user['email'] ?? '').toString();
      base = email.contains('@') ? email.split('@').first : 'creator';
    }
    base = base.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (base.length < 3) base = 'creator';
    if (base.length > 15) base = base.substring(0, 15);
    final suffix = (DateTime.now().millisecondsSinceEpoch % 900 + 100).toString();
    _usernameCtrl.text = '${base}_$suffix';
  }

  Future<void> _save() async {
    final username = _usernameCtrl.text.trim().replaceFirst('@', '');
    if (username.length < 3) {
      showToast(context, 'Username must be at least 3 characters', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().setupUsername(username: username, language: _language);
      if (!mounted) return;
      await _showWelcomeFlow();
    } catch (e) {
      showApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Step 1: Welcome + 20 free credits popup. Step 2: prompt to connect YouTube channel now.
  Future<void> _showReferralDialog() async {
    final referralCtrl = TextEditingController();
    bool submitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Have a referral code?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter a friend\'s code and you\'ll both get 5 bonus diamonds.'),
              const SizedBox(height: 14),
              TextField(
                controller: referralCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'e.g. 102458XK9F2'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final code = referralCtrl.text.trim();
                      if (code.isEmpty) {
                        Navigator.pop(dialogContext);
                        return;
                      }
                      setDialogState(() => submitting = true);
                      try {
                        final res = await ApiService.instance.applyReferralCode(code);
                        if (mounted) showToast(context, res['message'] ?? 'Referral applied!', isSuccess: true);
                      } catch (e) {
                        if (mounted) showApiError(context, e);
                      } finally {
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWelcomeFlow() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: const [
          Icon(Icons.celebration_rounded, color: AppColors.purple, size: 22),
          SizedBox(width: 8),
          Expanded(child: Text('Welcome to Tube Pilot!')),
        ]),
        content: const Text("You've got 20 free video upload credits and 10 bonus diamonds to get started."),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Let\'s go')),
        ],
      ),
    );
    if (!mounted) return;

    await _showReferralDialog();
    if (!mounted) return;

    final connectNow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: const [
          YoutubeIcon(size: 22),
          SizedBox(width: 10),
          Expanded(child: Text('Connect your YouTube channel')),
        ]),
        content: const Text('Connect now so Tube Pilot can upload and schedule videos straight to your channel.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Connect Channel')),
        ],
      ),
    );

    if (connectNow == true) {
      try {
        final res = await ApiService.instance.getYoutubeOAuthUrl();
        if (res['url'] != null) await launchUrl(Uri.parse(res['url']), mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) showApiError(context, e);
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final avatar = auth.user?['avatar'];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text("Let's set up\nyour profile 👋", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 82, height: 82,
                  decoration: BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
                  child: avatar != null && avatar.toString().isNotEmpty
                      ? ClipOval(child: Image.network(avatar, fit: BoxFit.cover))
                      : const Center(child: Icon(Icons.person_rounded, color: Colors.white, size: 36)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Username', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
              const SizedBox(height: 4),
              Text('We suggested one for you — feel free to change it', style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(hintText: '@tech_creator', prefixIcon: Icon(Icons.alternate_email_rounded, size: 18)),
              ),
              const SizedBox(height: 16),
              Text('Select Language', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _language,
                items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setState(() => _language = v ?? 'English'),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.language_rounded, size: 18)),
              ),
              const SizedBox(height: 30),
              GradientButton(label: 'Continue', loading: _loading, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}