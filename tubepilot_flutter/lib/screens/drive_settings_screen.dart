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
// auto-upload folder, change the daily upload time, switch between
// Scheduled (06:00 IST) / Live (instant test) upload mode, disconnect, or
// connect a DIFFERENT Drive account (2nd+ connect costs diamonds — see
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
  bool _updatingMode = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  // 'scheduled' or 'live' — defaults to 'scheduled' (fixed 06:00 IST) if
  // the backend hasn't sent a value yet (older accounts / not-yet-migrated).
  String get _uploadMode => (_drive?['uploadMode'] as String?) ?? 'scheduled';

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
    final current = _drive?['dailyUploadTime'] as String?;
    TimeOfDay initial = TimeOfDay.now();
    if (current != null && current.contains(':')) {
      final parts = current.split(':');
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) initial = TimeOfDay(hour: h, minute: m);
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
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

  Future<void> _setUploadMode(String mode) async {
    if (mode == _uploadMode || _updatingMode) return;
    setState(() => _updatingMode = true);
    try {
      await ApiService.instance.updateDriveSettings(uploadMode: mode);
      if (mounted) {
        showToast(
          context,
          mode == 'live'
              ? 'Live Upload ON — checking your Drive right now, watch server logs.'
              : '6:00 Upload mode — daily auto-upload restored.',
          isSuccess: true,
        );
        context.read<AuthProvider>().refreshUser();
        _loadStatus();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _updatingMode = false);
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

                    // ---------------- Folder ----------------
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const Icon(Icons.folder_rounded, color: AppColors.diamond),
                        title: Text(context.tr('upload_folder')),
                        subtitle: Text(_drive!['folderName'] ?? context.tr('whole_drive')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickFolder,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ---------------- Digital-clock style time display ----------------
                    Text(context.tr('daily_upload_time'), style: TextStyle(color: context.surfaces.textDim, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14181F),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.purple.withOpacity(0.35), width: 1.2),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _drive!['dailyUploadTime'] ?? '--:--',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded, size: 13, color: Colors.white.withOpacity(0.55)),
                                const SizedBox(width: 5),
                                Text(
                                  _drive!['dailyUploadTime'] == null ? context.tr('not_set') : 'Tap to change',
                                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---------------- Upload mode toggle: 6:00 Upload / Live Upload ----------------
                    // Default is ALWAYS "6:00 Upload" (scheduled — fixed 06:00 IST
                    // daily pull, goes public at Daily Upload Time above). Switching
                    // to "Live Upload" is a TEST mode: the backend checks this
                    // account every minute and publishes any new Drive video
                    // immediately (no 06:00 wait, no unlisted staging) — use it to
                    // verify the pipeline without waiting for the real daily trigger.
                    Container(
                      decoration: BoxDecoration(
                        color: context.surfaces.card2,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        children: [
                          Expanded(
                            child: _modeButton(
                              context,
                              label: '🕕  6:00 Upload',
                              selected: _uploadMode != 'live',
                              onTap: () => _setUploadMode('scheduled'),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: _modeButton(
                              context,
                              label: '⚡  Live Upload',
                              selected: _uploadMode == 'live',
                              onTap: () => _setUploadMode('live'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _uploadMode == 'live'
                          ? 'Testing mode — checks your Drive every minute and uploads any new video immediately (published right away, no waiting).'
                          : 'Default mode — pulls from Drive at 06:00 IST daily, uploads unlisted, then goes public at the time above.',
                      style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5),
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

  Widget _modeButton(BuildContext context, {required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: _updatingMode ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: _updatingMode && selected
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : context.surfaces.textDim,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}