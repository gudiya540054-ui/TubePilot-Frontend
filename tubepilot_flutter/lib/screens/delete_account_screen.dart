import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

/// Self-service account deletion — required by Google Play's Account
/// Deletion policy (any app that lets users create an account must offer an
/// in-app way to delete it, not just a "contact support" email link).
///
/// This is the USER-initiated version of what the admin panel already does
/// for admins deleting a user. Same consequences, different trigger:
///   - Deletes the user's Video, Transaction, and Notification docs
///   - Deletes their uploaded files from Cloudinary
///   - Disconnects (not deletes) their Google Drive — we only ever had
///     drive.readonly access, so we can't touch their Drive files anyway
///   - Deletes the User document itself
/// If they sign up again later, it's a completely fresh account.
///
/// Backend: expects DELETE /api/auth/delete-account (or wherever
/// ApiService.instance.deleteMyAccount() is wired up) to run that same
/// cascade against req.user — NOT the admin route, which requires
/// adminOnly and takes a target id. This screen deletes the CALLER's own
/// account only.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _confirmCtrl = TextEditingController();
  bool _deleting = false;
  bool _understood = false;

  static const _consequences = [
    'Your profile, username, and diamond balance',
    'All videos you\'ve uploaded or converted',
    'Your payment and transaction history',
    'Your YouTube, Google Drive, and Facebook connections',
    'Your referral code and referral history',
  ];

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _expectedConfirmText(Map<String, dynamic> user) {
    return (user['username'] ?? user['email'] ?? user['userId'] ?? 'DELETE').toString();
  }

  Future<void> _submitDelete(Map<String, dynamic> user) async {
    final expected = _expectedConfirmText(user);
    if (_confirmCtrl.text.trim() != expected) {
      showToast(context, 'Text doesn\'t match. Please type it exactly.', isError: true);
      return;
    }

    setState(() => _deleting = true);
    try {
      await ApiService.instance.deleteMyAccount();
      if (!mounted) return;
      // Account is gone server-side — clear local session and drop them at
      // login. Don't call the normal logout()/refreshUser() flow since
      // there's no account left to refresh.
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      showToast(context, 'Your account has been permanently deleted', isSuccess: true);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user ?? {};
    final expected = _expectedConfirmText(user);
    final canDelete = _understood && _confirmCtrl.text.trim() == expected && !_deleting;

    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.red.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_rounded, color: AppColors.red, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This permanently deletes your account. This action cannot be undone.',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.red),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('What gets deleted', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: context.surfaces.card2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.surfaces.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: _consequences.map((c) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.close_rounded, size: 16, color: AppColors.red),
                      const SizedBox(width: 10),
                      Expanded(child: Text(c, style: const TextStyle(fontSize: 13.5))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Diamonds are not refundable. If you had an active subscription, it will not be refunded either.',
            style: TextStyle(color: context.surfaces.textDim, fontSize: 12),
          ),
          const SizedBox(height: 24),

          CheckboxListTile(
            value: _understood,
            onChanged: (v) => setState(() => _understood = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.red,
            title: const Text(
              'I understand this is permanent and cannot be undone',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),

          Text('Type "$expected" to confirm', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.surfaces.card2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.surfaces.border),
            ),
            child: TextField(
              controller: _confirmCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: expected,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canDelete ? () => _submitDelete(user) : null,
              icon: _deleting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.delete_forever, size: 18),
              label: Text(_deleting ? 'Deleting...' : 'Delete My Account Permanently'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _deleting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel, keep my account'),
            ),
          ),
        ],
      ),
    );
  }
}