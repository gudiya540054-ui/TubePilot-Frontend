import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'drive_folder_picker_screen.dart';

// Manage an already-connected Google Drive: view account, change the
// auto-upload folder, change the daily upload time, disconnect, or connect a
// DIFFERENT Drive account (2nd+ connect costs diamonds — see
// backend routes/drive.js -> DRIVE_RECONNECT_DIAMOND_COST).
class DriveSettingsScreen extends StatefulWidget {
  const DriveSettingsScreen({super.key});
  @override
  State<DriveSettingsScreen> createState() => _DriveSettingsScreenState();
}

class _DriveSettingsScreenState extends State<DriveSettingsScreen> {
  Map<String, dynamic>? _drive;
  int _nextConnectCost = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance.getDriveStatus();
      setState(() {
        _drive = res['drive'];
        _nextConnectCost = res['nextConnectDiamondCost'] ?? 0;
      });
    } catch (_) {
      setState(() => _drive = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null || !mounted) return;
    final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    try {
      await ApiService.instance.updateDriveSettings(dailyUploadTime: formatted);
      if (mounted) {
        showToast(context, 'Daily upload time set to $formatted', isSuccess: true);
        context.read<AuthProvider>().refreshUser();
        _loadStatus();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _pickFolder() async {
    final result = await Navigator.of(context).push<Map<String, String>?>(
      MaterialPageRoute(builder: (_) => const DriveFolderPickerScreen()),
    );
    if (result == null || !mounted) return; // user backed out
    try {
      await ApiService.instance.updateDriveSettings(
        folderId: result.isEmpty ? null : result['id'],
        folderName: result.isEmpty ? null : result['name'],
      );
      if (mounted) {
        showToast(
          context,
          result.isEmpty ? 'Now uploading from your whole Drive' : 'Folder set to "${result['name']}"',
          isSuccess: true,
        );
        context.read<AuthProvider>().refreshUser();
        _loadStatus();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Google Drive?'),
        content: const Text('Daily auto-upload from Drive will stop until you connect again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Disconnect', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.instance.disconnectDrive();
      if (mounted) {
        showToast(context, 'Google Drive disconnected', isSuccess: true);
        context.read<AuthProvider>().refreshUser();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _connectAnotherDrive() async {
    if (_nextConnectCost > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Connect Another Drive?'),
          content: Text('Connecting a different Google Drive account costs $_nextConnectCost diamonds. Continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Continue ($_nextConnectCost 💎)')),
          ],
        ),
      );
      if (confirm != true) return;
    }
    try {
      final res = await ApiService.instance.getDriveOAuthUrl();
      final url = res['url'];
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drive Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drive == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('No Google Drive connected', style: TextStyle(color: context.surfaces.textDim)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        const Text('📁', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_drive!['displayName'] ?? _drive!['email'] ?? 'Connected', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            if (_drive!['email'] != null) Text(_drive!['email'], style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [
                        ListTile(
                          leading: const Icon(Icons.folder_rounded, color: AppColors.diamond),
                          title: const Text('Upload Folder'),
                          subtitle: Text(_drive!['folderName'] ?? 'Whole Drive'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _pickFolder,
                        ),
                        Divider(height: 1, color: context.surfaces.border),
                        ListTile(
                          leading: const Icon(Icons.schedule_rounded, color: AppColors.purple),
                          title: const Text('Daily Upload Time'),
                          subtitle: Text(_drive!['dailyUploadTime'] ?? 'Not set'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _pickTime,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _connectAnotherDrive,
                        icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.purple, size: 18),
                        label: Text(
                          _nextConnectCost > 0 ? 'Connect Another Drive ($_nextConnectCost 💎)' : 'Connect Another Drive',
                          style: const TextStyle(color: AppColors.purple),
                        ),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.purple)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _disconnect,
                        icon: const Icon(Icons.link_off_rounded, color: AppColors.red, size: 18),
                        label: const Text('Disconnect Drive', style: TextStyle(color: AppColors.red)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.red)),
                      ),
                    ),
                  ],
                ),
    );
  }
}