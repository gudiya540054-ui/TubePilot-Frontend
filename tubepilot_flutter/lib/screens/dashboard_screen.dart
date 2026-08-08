import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/brand_icons.dart';
import 'upload_screen.dart';
import 'upcoming_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'diamond_store_screen.dart';
import 'notifications_screen.dart';
import 'preview_screen.dart';
import 'rate_us_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _DashboardHome(),
      const UploadScreen(embedded: true),
      const UpcomingScreen(embedded: true),
      const AnalyticsScreen(embedded: true),
      const ProfileScreen(embedded: true),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _tabIndex, children: screens),
      bottomNavigationBar: AppBottomNav(currentIndex: _tabIndex, onTap: (i) => setState(() => _tabIndex = i)),
    );
  }
}

class _DashboardHome extends StatefulWidget {
  const _DashboardHome();
  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  Map<String, dynamic>? data;
  List<dynamic> notifications = [];
  int unreadCount = 0;

  // Connected-account status, one entry per platform card in the grid.
  // NOTE: Instagram intentionally removed from this screen's UI per product
  // decision — only YouTube, Facebook, and Drive are shown here now.
  Map<String, dynamic>? youtubeChannel;
  Map<String, dynamic>? driveStatus;
  Map<String, dynamic>? facebookStatus;

  // Flattened, time-sorted list of platform-level publish events built from
  // /api/videos?status=queued (each item: {videoId, platform, title,
  // scheduledAt, thumbnailUrl}).
  List<Map<String, dynamic>> upcomingEvents = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load().then((_) {
      if (mounted) maybeShowRateUsPopup(context);
    });
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) setState(() => loading = true);
    try {
      final results = await Future.wait([
        ApiService.instance.dashboard(),
        ApiService.instance.getNotifications(),
        ApiService.instance.getYoutubeChannel().catchError((_) => <String, dynamic>{}),
        ApiService.instance.getDriveStatus().catchError((_) => <String, dynamic>{}),
        ApiService.instance.getMetaStatus().catchError((_) => <String, dynamic>{}),
        ApiService.instance.listVideos(status: 'queued').catchError((_) => <String, dynamic>{}),
      ]);

      final dash = results[0]['data'];
      final notifRes = results[1];
      final ytRes = results[2];
      final driveRes = results[3];
      final metaRes = results[4];
      final videosRes = results[5];

      final events = <Map<String, dynamic>>[];
      final videos = (videosRes['videos'] as List?) ?? [];
      for (final v in videos) {
        final platforms = (v['platforms'] as List?) ?? [];
        for (final p in platforms) {
          if (p['status'] != 'pending' && p['status'] != 'queued') continue;
          events.add({
            'videoId': v['_id'],
            'platform': p['platform'],
            'title': p['platform'] == 'youtube'
                ? (p['title'] ?? 'Untitled')
                : ((p['caption'] ?? '').toString().isNotEmpty ? p['caption'] : 'Untitled'),
            'scheduledAt': p['scheduledAt'],
            'thumbnailUrl': p['thumbnailUrl'] ?? '',
            'status': p['status'],
          });
        }
      }
      events.sort((a, b) {
        final aTime = a['scheduledAt'] as String?;
        final bTime = b['scheduledAt'] as String?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return -1; // "publish now" items float to top
        if (bTime == null) return 1;
        return aTime.compareTo(bTime);
      });

      setState(() {
        data = dash;
        notifications = (notifRes['notifications'] as List?) ?? [];
        unreadCount = notifRes['unreadCount'] ?? 0;
        youtubeChannel = ytRes['success'] == true ? ytRes['channel'] : null;
        driveStatus = driveRes['success'] == true ? driveRes['drive'] : null;
        facebookStatus = metaRes['facebook'];
        upcomingEvents = events.take(5).toList();
      });
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (showLoader && mounted) setState(() => loading = false);
    }
  }

  void _goToProfile() {
    // Every "Connect" action for every platform already lives in
    // ProfileScreen (single source of truth for OAuth flows) — the
    // dashboard's Connected Accounts grid links there instead of
    // duplicating the connect logic.
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => _load(showLoader: false));
  }

  void _openPreview(Map<String, dynamic> event) {
    // Preview needs the shared video file URL, which lives on the parent
    // Video document, not the per-platform target — reusing UpcomingScreen
    // for playback avoids duplicating that lookup here.
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpcomingScreen())).then((_) => _load(showLoader: false));
  }

  static const _platformMeta = {
    'youtube': (label: 'YouTube', color: AppColors.red),
    'facebook': (label: 'Facebook', color: AppColors.diamond),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TubePilot'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())).then((_) => _load(showLoader: false)),
              ),
              if (unreadCount > 0)
                Positioned(right: 10, top: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle))),
            ],
          ),
        ],
      ),
      body: loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: () => _load(showLoader: false),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  // ---------------- Quick Upload banner ----------------
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Diamond Balance', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Text('💎 ', style: TextStyle(fontSize: 18)),
                                  Text('${data?['diamondBalance'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                                ]),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiamondStoreScreen())).then((_) => _load(showLoader: false)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.22),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              ),
                              child: const Text('+ Buy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UploadScreen())).then((_) => _load(showLoader: false)),
                            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                            label: const Text('Quick Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white, width: 1.3),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---------------- Connected Accounts row ----------------
                  // Only YouTube, Facebook, Drive — shown side-by-side (parallel
                  // row) with real brand icons, per product decision. Instagram
                  // is intentionally excluded from this screen.
                  const Text('Connected Accounts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _accountCard(
                          icon: const YoutubeIcon(size: 20),
                          label: youtubeChannel != null ? (youtubeChannel!['channelTitle'] ?? 'YouTube') : 'YouTube',
                          connected: youtubeChannel != null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _accountCard(
                          icon: const FacebookIcon(size: 20),
                          label: facebookStatus != null ? (facebookStatus!['pageName'] ?? 'Facebook') : 'Facebook',
                          connected: facebookStatus != null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _accountCard(
                          icon: const DriveIcon(size: 20),
                          label: 'Drive',
                          connected: driveStatus != null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ---------------- Stats grid ----------------
                  const Text('Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.7,
                    children: [
                      StatCard(label: 'Free Uploads Left', value: '${data?['remainingFreeUploads'] ?? 0}'),
                      StatCard(label: 'Diamond Balance', value: '${data?['diamondBalance'] ?? 0}'),
                      StatCard(label: 'Videos Published', value: '${data?['totalUploadedVideos'] ?? 0}'),
                      StatCard(label: 'Scheduled', value: '${upcomingEvents.length}'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ---------------- Upcoming Schedule timeline ----------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Upcoming Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpcomingScreen())),
                        child: Text('See all ›', style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTimeline(),
                  const SizedBox(height: 24),

                  // ---------------- Recent Activity ----------------
                  const Text('Recent Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _buildRecentActivity(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _accountCard({required Widget icon, required String label, required bool connected}) {
    return GestureDetector(
      onTap: _goToProfile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: context.surfaces.card2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (connected ? AppColors.green : context.surfaces.textDim).withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: icon,
            ),
            const SizedBox(height: 8),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: connected ? AppColors.green : context.surfaces.textDim, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(connected ? 'Connected' : 'Connect', style: TextStyle(color: context.surfaces.textDim, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    if (upcomingEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
        child: Text('No upcoming publishes. Tap "Quick Upload" to schedule one.', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
      );
    }

    return Column(
      children: List.generate(upcomingEvents.length, (i) {
        final event = upcomingEvents[i];
        final meta = _platformMeta[event['platform']] ?? (label: event['platform'].toString(), color: AppColors.purple);
        final isLast = i == upcomingEvents.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline rail: colored dot + connecting line down to the next item.
              Column(
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(color: meta.color, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2)),
                  ),
                  if (!isLast)
                    Expanded(child: Container(width: 2, color: context.surfaces.border)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openPreview(event),
                  child: Container(
                    margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        _platformBadgeIcon(event['platform']),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meta.label, style: TextStyle(color: context.surfaces.textDim, fontSize: 11, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(event['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                              const SizedBox(height: 4),
                              Text(
                                event['scheduledAt'] != null ? formatDateTime(event['scheduledAt']) : 'Publishing now',
                                style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        AppBadge(label: event['status'] == 'pending' ? 'Scheduled' : 'Queued', color: meta.color),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _platformBadgeIcon(String? platform) {
    switch (platform) {
      case 'youtube':
        return const YoutubeIcon(size: 16);
      case 'facebook':
        return const FacebookIcon(size: 16);
      default:
        return const Icon(Icons.movie_outlined, size: 16);
    }
  }

  Widget _buildRecentActivity() {
    final recent = notifications.take(4).toList();
    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
        child: Text('No recent activity yet.', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: List.generate(recent.length, (i) {
          final n = recent[i];
          final isRead = n['isRead'] == true;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: (isRead ? context.surfaces.textDim : AppColors.purple).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    n['type']?.toString().contains('failed') == true ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                    color: isRead ? context.surfaces.textDim : AppColors.purple,
                    size: 17,
                  ),
                ),
                title: Text(n['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(n['message'] ?? '', style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                dense: true,
              ),
              if (i != recent.length - 1) Divider(height: 1, color: context.surfaces.border),
            ],
          );
        }),
      ),
    );
  }
}