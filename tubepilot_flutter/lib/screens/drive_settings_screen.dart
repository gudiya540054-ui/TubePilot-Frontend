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

  // Opens the digital wheel time picker (hour/minute scroll columns) with a
  // small upload-mode dropdown built in. Saves BOTH the time and the mode
  // together when the user taps OK.
  Future<void> _pickTime() async {
    final current = _drive?['dailyUploadTime'] as String?;
    int initialHour = TimeOfDay.now().hour;
    int initialMinute = TimeOfDay.now().minute;
    if (current != null && current.contains(':')) {
      final parts = current.split(':');
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null) initialHour = h;
      if (m != null) initialMinute = m;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _DigitalTimePickerDialog(
        initialHour: initialHour,
        initialMinute: initialMinute,
        initialMode: _uploadMode == 'live' ? 'live' : 'scheduled',
      ),
    );
    if (result == null || !mounted) return;

    final hour = result['hour'] as int;
    final minute = result['minute'] as int;
    final mode = result['mode'] as String;
    final formatted = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    try {
      await ApiService.instance.updateDriveSettings(dailyUploadTime: formatted, uploadMode: mode);
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

                    // ---------------- Compact, theme-colored time chip ----------------
                    // Small tap target (not a big black card) that matches the app's
                    // purple theme. Opens the digital wheel picker + mode dropdown.
                    Text(context.tr('daily_upload_time'), style: TextStyle(color: context.surfaces.textDim, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.purple.withOpacity(0.35), width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 18, color: AppColors.purple),
                              const SizedBox(width: 8),
                              Text(
                                _drive!['dailyUploadTime'] ?? '--:--',
                                style: const TextStyle(
                                  color: AppColors.purple,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.edit_rounded, size: 14, color: AppColors.purple.withOpacity(0.6)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Upload-mode (6:00 / Live) is chosen inside the time picker
                    // popup now — see _DigitalTimePickerDialog below.

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

// ---------------- Digital wheel time picker + upload-mode dropdown ----------------
// Two scrollable number columns (hour 00-23, minute 00-59) — scroll up to
// increase, scroll down to decrease, no drag-a-clock-hand dial. A small
// dropdown icon (same footprint as the old keyboard-toggle icon) lets the
// user pick "6:00 Upload" or "Live Upload" in the same popup. OK saves both
// the chosen time and the chosen mode together. Defaults to "6:00 Upload"
// unless the drive is already set to Live.
class _DigitalTimePickerDialog extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final String initialMode; // 'scheduled' or 'live'

  const _DigitalTimePickerDialog({
    required this.initialHour,
    required this.initialMinute,
    required this.initialMode,
  });

  @override
  State<_DigitalTimePickerDialog> createState() => _DigitalTimePickerDialogState();
}

class _DigitalTimePickerDialogState extends State<_DigitalTimePickerDialog> {
  late int _hour;
  late int _minute;
  late String _mode;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  static const double _itemExtent = 44;
  static const double _wheelHeight = 160;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
    _mode = widget.initialMode;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  Widget _wheelColumn({
    required FixedExtentScrollController controller,
    required int itemCount,
    required int selectedValue,
    required ValueChanged<int> onChanged,
  }) {
    return SizedBox(
      width: 70,
      height: _wheelHeight,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _itemExtent,
        perspective: 0.003,
        diameterRatio: 1.4,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) {
            final selected = index == selectedValue;
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: selected ? 30 : 19,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? AppColors.purple : Colors.grey.withOpacity(0.45),
                  fontFamily: 'monospace',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('select_time'),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.surfaces.textDim),
            ),
            const SizedBox(height: 14),

            // ---- Digital scroll wheels ----
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: _itemExtent,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _wheelColumn(
                      controller: _hourController,
                      itemCount: 24,
                      selectedValue: _hour,
                      onChanged: (v) => setState(() => _hour = v),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(':', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    ),
                    _wheelColumn(
                      controller: _minuteController,
                      itemCount: 60,
                      selectedValue: _minute,
                      onChanged: (v) => setState(() => _minute = v),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ---- Upload-mode dropdown (small, same footprint as old keyboard icon) ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _mode == 'live' ? '⚡  Live Upload' : '🕕  6:00 Upload',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.purple),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Upload mode',
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.expand_more_rounded, size: 22, color: AppColors.purple),
                  onSelected: (v) => setState(() => _mode = v),
                  itemBuilder: (ctx) => [
                    CheckedPopupMenuItem<String>(
                      value: 'scheduled',
                      checked: _mode == 'scheduled',
                      child: const Text('🕕  6:00 Upload'),
                    ),
                    CheckedPopupMenuItem<String>(
                      value: 'live',
                      checked: _mode == 'live',
                      child: const Text('⚡  Live Upload'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('cancel')),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => Navigator.pop(context, {
                    'hour': _hour,
                    'minute': _minute,
                    'mode': _mode,
                  }),
                  child: const Text('OK', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}