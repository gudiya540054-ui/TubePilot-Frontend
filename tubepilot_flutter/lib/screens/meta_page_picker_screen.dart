import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

// Shown only when a user's Facebook account manages MORE THAN ONE Page —
// the backend can't guess which Page to connect, so it stores the raw list
// (see routes/meta.js -> GET /api/meta/pages) and this screen lets the user
// pick one. Triggered from main.dart when the "meta_connected" deep link
// arrives with multiple_pages=1.
class MetaPagePickerScreen extends StatefulWidget {
  const MetaPagePickerScreen({super.key});
  @override
  State<MetaPagePickerScreen> createState() => _MetaPagePickerScreenState();
}

class _MetaPagePickerScreenState extends State<MetaPagePickerScreen> {
  List<dynamic> _pages = [];
  bool _loading = true;
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.instance.getMetaPendingPages();
      setState(() => _pages = res['pages'] ?? []);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectPage(String pageId) async {
    setState(() => _selecting = true);
    try {
      await ApiService.instance.selectMetaPage(pageId);
      if (mounted) {
        showToast(context, 'Facebook Page connected!', isSuccess: true);
        context.read<AuthProvider>().refreshUser();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Facebook Page')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'You manage multiple Facebook Pages. Pick the one TubePilot should publish to.',
                    style: TextStyle(color: context.surfaces.textDim, fontSize: 13, height: 1.4),
                  ),
                ),
                Expanded(
                  child: _pages.isEmpty
                      ? Center(child: Text('No pending pages found', style: TextStyle(color: context.surfaces.textDim)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _pages.length,
                          itemBuilder: (context, index) {
                            final page = _pages[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                leading: const Icon(Icons.facebook_rounded, color: AppColors.purple),
                                title: Text(page['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                trailing: _selecting
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.chevron_right),
                                onTap: _selecting ? null : () => _selectPage(page['id']),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}