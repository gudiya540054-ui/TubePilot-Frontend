import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class UpcomingScreen extends StatefulWidget {
  final bool embedded;
  const UpcomingScreen({super.key, this.embedded = false});
  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, List<String>> statusMap = const {
    'Upcoming': ['scheduled', 'queued', 'processing', 'uploading_storage'],
    'Completed': ['uploaded'],
    'Drafts': ['draft'],
    'Failed': ['failed'],
  };
  List<dynamic> videos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statusMap.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _load();
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final tabKey = statusMap.keys.elementAt(_tabController.index);
      final statuses = statusMap[tabKey]!;
      final results = await Future.wait(statuses.map((s) => ApiService.instance.listVideos(status: s)));
      final all = results.expand((r) => (r['videos'] as List)).toList();
      all.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
      setState(() => videos = all);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _cancel(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel this upload?'),
        content: const Text('Your credit will be refunded.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.instance.cancelVideo(id);
      if (mounted) showToast(context, 'Upload cancelled, credit refunded', isSuccess: true);
      _load();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  (Color, String) _statusBadge(String status) {
    switch (status) {
      case 'scheduled': return (AppColors.diamond, 'Scheduled');
      case 'queued': return (AppColors.diamond, 'Queued');
      case 'processing': return (AppColors.diamond, 'Uploading');
      case 'uploading_storage': return (AppColors.diamond, 'Saving');
      case 'uploaded': return (AppColors.green, 'Live');
      case 'failed': return (AppColors.red, 'Failed');
      case 'draft': return (AppColors.diamond, 'Draft');
      default: return (AppColors.diamond, status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Videos'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12.5),
          labelColor: AppColors.purple,
          indicatorColor: AppColors.purple,
          tabs: statusMap.keys.map((k) => Tab(text: k)).toList(),
        ),
      ),
      body: loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _load,
              child: videos.isEmpty
                  ? ListView(children: const [EmptyView(message: 'No videos in this tab yet.', icon: Icons.video_library_outlined)])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: videos.length,
                      itemBuilder: (_, i) {
                        final v = videos[i];
                        final (color, label) = _statusBadge(v['status'] ?? '');
                        final isUpcoming = statusMap.keys.elementAt(_tabController.index) == 'Upcoming';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 54, height: 54,
                                    decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(10)),
                                    child: const Center(child: Text('🎬', style: TextStyle(fontSize: 18))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(v['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text(v['scheduledAt'] != null ? formatDateTime(v['scheduledAt']) : formatDate(v['createdAt']), style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
                                        const SizedBox(height: 6),
                                        Wrap(spacing: 6, children: [
                                          AppBadge(label: (v['diamondsCharged'] ?? 0) > 0 ? '💎 ${v['diamondsCharged']} Diamond' : 'Free Upload', color: (v['diamondsCharged'] ?? 0) > 0 ? AppColors.diamond : AppColors.green),
                                          AppBadge(label: label, color: color),
                                        ]),
                                      ],
                                    ),
                                  ),
                                  if (isUpcoming)
                                    IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _cancel(v['_id'])),
                                ],
                              ),
                              if (v['status'] == 'failed' && v['failReason'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text('Reason: ${v['failReason']}', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
