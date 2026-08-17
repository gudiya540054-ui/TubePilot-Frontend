import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

// Lets the user browse their Google Drive folder tree and pick ONE folder to
// scope auto-upload to — or explicitly choose "Whole Drive" (no restriction).
//
// Returns via Navigator.pop:
//   null                          -> user backed out, no change
//   <String,String>{}             -> "Whole Drive" selected (clear folder)
//   {'id': ..., 'name': ...}      -> a specific folder selected
class DriveFolderPickerScreen extends StatefulWidget {
  const DriveFolderPickerScreen({super.key});
  @override
  State<DriveFolderPickerScreen> createState() => _DriveFolderPickerScreenState();
}

class _DriveFolderPickerScreenState extends State<DriveFolderPickerScreen> {
  // Breadcrumb stack of {id, name}. Empty = Drive root.
  final List<Map<String, String>> _path = [];
  List<dynamic> _folders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final parentId = _path.isNotEmpty ? _path.last['id'] : null;
      final res = await ApiService.instance.listDriveFolders(parentId: parentId);
      setState(() => _folders = res['folders'] ?? []);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openFolder(dynamic folder) {
    setState(() => _path.add({'id': folder['id'], 'name': folder['name']}));
    _load();
  }

  void _goBack() {
    setState(() => _path.removeLast());
    _load();
  }

  void _selectWholeDrive() => Navigator.of(context).pop(<String, String>{});

  void _selectCurrentFolder() {
    if (_path.isEmpty) {
      _selectWholeDrive();
      return;
    }
    Navigator.of(context).pop(_path.last);
  }

  @override
  Widget build(BuildContext context) {
    final title = _path.isEmpty ? context.tr('my_drive_title') : _path.last['name']!;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: _path.isEmpty ? null : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
      ),
      body: Column(
        children: [
          // Always-available option — no folder restriction at all.
          ListTile(
            leading: const Icon(Icons.folder_open_rounded, color: AppColors.purple),
            title: Text(context.tr('use_whole_drive'), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('use_whole_drive_subtitle')),
            onTap: _selectWholeDrive,
          ),
          Divider(color: context.surfaces.border, height: 1),
          if (_path.isNotEmpty) ...[
            ListTile(
              leading: const Icon(Icons.check_circle_rounded, color: AppColors.green),
              title: Text('${context.tr('select_folder_prefix')} "${_path.last['name']}"', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(context.tr('select_folder_subtitle')),
              onTap: _selectCurrentFolder,
            ),
            Divider(color: context.surfaces.border, height: 1),
          ],
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _folders.isEmpty
                    ? Center(child: Text(context.tr('no_subfolders'), style: TextStyle(color: context.surfaces.textDim)))
                    : ListView.builder(
                        itemCount: _folders.length,
                        itemBuilder: (context, index) {
                          final folder = _folders[index];
                          return ListTile(
                            leading: const Icon(Icons.folder_rounded, color: AppColors.diamond),
                            title: Text(folder['name'] ?? ''),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _openFolder(folder),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}