import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tabs;
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../providers/language_provider.dart';
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

  // ⚠️ FIX: this call previously only passed `dailyUploadTime`, which was
  // fine on this end — but api_service.dart's OLD updateDriveSettings()
  // always attached `folderId`/`folderName` to the request body as `null`
  // even when not passed in, and the backend read that explicit `null` as
  // "clear the folder". That silently wiped the user's selected folder
  // every time they only meant to change the time. Fixed at the
  // api_service.dart layer (folderId/folderName are now omitted entirely
  // unless the caller means to touch them) — no change needed here, but
  // kept as a single, explicit call so the intent stays obvious.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null || !mounted) return;
    final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    try {
      await ApiService.instance.updateDriveSettings(dailyUploadTime: formatted);
      if (mounted) {
        showToast(context, context.tr('daily_upload_time_set').replaceAll('%s', formatted), isSuccess: true);
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
    final isWholeDrive = result.isEmpty;
    try {
      await ApiService.instance.updateDriveSettings(
        folderId: isWholeDrive ? null : result['id'],
        folderName: isWholeDrive ? null : result['name'],
        // Explicit intent to reset to "Whole Drive" — this is the ONLY
        // place folderId/folderName should ever be sent as null, so it's
        // marked explicitly instead of relying on a null value alone.
        clearFolder: isWholeDrive,
      );
      if (mounted) {
        showToast(
          context,
          isWholeDrive ? context.tr('now_uploading_whole_drive') : context.tr('folder_set_to').replaceAll('%s', result['name'] ?? ''),
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
        title: Text(context.tr('disconnect_drive_confirm_title')),
        content: Text(context.tr('disconnect_drive_confirm_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('disconnect_drive'), style: const TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.instance.disconnectDrive();
      if (mounted) {
        showToast(context, context.tr('google_drive_disconnected'), isSuccess: true);
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
          title: Text(context.tr('connect_another_drive_confirm_title')),
          content: Text(context.tr('connect_another_drive_confirm_body').replaceAll('%d', '$_nextConnectCost')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('${context.tr('continue_btn_lower')} ($_nextConnectCost 💎)')),
          ],
        ),
      );
      if (confirm != true) return;
    }
    try {
      final res = await ApiService.instance.getDriveOAuthUrl();
      final url = res['url'];
      if (url != null) {
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
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('drive_settings_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drive == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(context.tr('no_drive_connected'), style: TextStyle(color: context.surfaces.textDim)),
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
                            Text(_drive!['displayName'] ?? _drive!['email'] ?? context.tr('connected_fallback'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
                          title: Text(context.tr('upload_folder')),
                          subtitle: Text(_drive!['folderName'] ?? context.tr('whole_drive')),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _pickFolder,
                        ),
                        Divider(height: 1, color: context.surfaces.border),
                        ListTile(
                          leading: const Icon(Icons.schedule_rounded, color: AppColors.purple),
                          title: Text(context.tr('daily_upload_time')),
                          subtitle: Text(_drive!['dailyUploadTime'] ?? context.tr('not_set')),
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
                          _nextConnectCost > 0 ? '${context.tr('connect_another_drive')} ($_nextConnectCost 💎)' : context.tr('connect_another_drive'),
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
                        label: Text(context.tr('disconnect_drive'), style: const TextStyle(color: AppColors.red)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.red)),
                      ),
                    ),
                  ],
                ),
    );
  }
}