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

  // Per-tab video cache + loading state, so swiping between tabs (via
  // TabBarView below) shows each tab's own data instantly instead of
  // flashing whatever the previously-active tab had loaded.
  final Map<String, List<dynamic>> videosByTab = {};
  final Map<String, bool> loadingByTab = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statusMap.length, vsync: this);
    _tabController.addListener(() {
      // Fires both on tab-bar tap AND on swipe (TabBarView drives the same
      // controller), once the transition settles.
      if (!_tabController.indexIsChanging) {
        _load(statusMap.keys.elementAt(_tabController.index));
      }
    });
    _load(statusMap.keys.first);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load(String tabKey) async {
    setState(() => loadingByTab[tabKey] = true);
    try {
      final statuses = statusMap[tabKey]!;
      final results = await Future.wait(statuses.map((s) => ApiService.instance.listVideos(status: s)));
      final all = results.expand((r) => (r['videos'] as List)).toList();
      all.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
      if (!mounted) return;
      setState(() => videosByTab[tabKey] = all);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => loadingByTab[tabKey] = false);
    }
  }

  Future<void> _cancel(String id, String tabKey) async {
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
      _load(tabKey);
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

  Widget _buildTabBody(String tabKey) {
    final loading = loadingByTab[tabKey] ?? true;
    final videos = videosByTab[tabKey] ?? [];
    final isUpcoming = tabKey == 'Upcoming';

    if (loading && videos.isEmpty) {
      return const LoadingView();
    }

    return RefreshIndicator(
      onRefresh: () => _load(tabKey),
      child: videos.isEmpty
          ? ListView(children: const [EmptyView(message: 'No videos in this tab yet.', icon: Icons.video_library_outlined)])
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: videos.length,
              itemBuilder: (_, i) {
                final v = videos[i];
                final (color, label) = _statusBadge(v['status'] ?? '');
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
                            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _cancel(v['_id'], tabKey)),
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
    );
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
      // TabBarView bound to the same controller as the TabBar above — this is
      // what enables left/right swipe between Upcoming / Completed / Drafts /
      // Failed, in addition to tapping the tab labels. Swiping drives
      // _tabController.index exactly like a tap does, so the existing
      // listener in initState() loads that tab's data automatically.
      body: TabBarView(
        controller: _tabController,
        children: statusMap.keys.map(_buildTabBody).toList(),
      ),
    );
  }
}