import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
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
  bool loading = true;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    // Weekly Rate Us popup check runs once, right after the first successful
    // load — not on pull-to-refresh (that only calls _load directly below).
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
      ]);
      setState(() {
        data = results[0]['data'];
        unreadCount = results[1]['unreadCount'] ?? 0;
      });
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (showLoader && mounted) setState(() => loading = false);
    }
  }

  Future<void> _connectYoutube() async {
    try {
      final res = await ApiService.instance.getYoutubeOAuthUrl();
      final url = res['url'];
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  void _openPreview(Map<String, dynamic> video) {
    final storageUrl = video['storageUrl'] as String? ?? '';
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PreviewScreen(title: video['title'] ?? '', videoUrl: storageUrl),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YT Uploader'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())).then((_) => _load()),
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
                  BalanceBanner(
                    balance: data?['diamondBalance'] ?? 0,
                    onBuy: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiamondStoreScreen())).then((_) => _load()),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Upcoming Videos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpcomingScreen())),
                        child: Text('${data?['scheduledVideos'] ?? 0} ›', style: TextStyle(color: context.surfaces.textDim)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._buildUpcomingList(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      label: '＋ Schedule New Video',
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UploadScreen())).then((_) => _load()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.9,
                    children: [
                      _quickCard(Icons.card_giftcard_rounded, 'Free Uploads', '${data?['remainingFreeUploads'] ?? 0}', () {}),
                      _quickCard(Icons.cloud_done_rounded, 'Uploaded Videos', '${data?['totalUploadedVideos'] ?? 0}', () {}),
                      _quickCard(Icons.trending_up_rounded, 'Analytics', '', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
                      _quickCard(Icons.calendar_month_rounded, 'Calendar', '', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpcomingScreen()))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Your Channel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _buildChannelCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _quickCard(IconData icon, String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surfaces.card2,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.purple.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.purple, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUpcomingList() {
    final history = (data?['uploadHistory'] as List?) ?? [];
    final upcoming = history.where((v) {
      final status = v['status'];
      if (['scheduled', 'queued', 'processing'].contains(status)) return true;
      final isPendingPublicSwitch = status == 'uploaded' &&
          v['targetPrivacyStatus'] == 'public' &&
          v['privacyStatus'] != 'public';
      return isPendingPublicSwitch;
    }).take(3).toList();

    if (upcoming.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
          child: Text('No upcoming videos. Tap "Schedule New Video" to get started.', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
        ),
      ];
    }

    return upcoming.map<Widget>((v) {
      final video = v as Map<String, dynamic>;
      final thumbnailUrl = video['thumbnailUrl'] as String? ?? '';
      final storageUrl = video['storageUrl'] as String? ?? '';
      final canPreview = storageUrl.isNotEmpty;
      final isPendingPublicSwitch = video['status'] == 'uploaded' &&
          video['targetPrivacyStatus'] == 'public' &&
          video['privacyStatus'] != 'public';

      return GestureDetector(
        onTap: canPreview ? () => _openPreview(video) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: context.surfaces.border),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: AppColors.purple.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                clipBehavior: Clip.antiAlias,
                child: thumbnailUrl.isNotEmpty
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.movie_creation_rounded, color: AppColors.purple, size: 22)),
                      )
                    : const Center(child: Icon(Icons.movie_creation_rounded, color: AppColors.purple, size: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      isPendingPublicSwitch
                          ? 'Goes public: ${formatDateTime(video['scheduledAt'])}'
                          : (video['scheduledAt'] != null ? formatDateTime(video['scheduledAt']) : 'Uploading soon'),
                      style: TextStyle(color: context.surfaces.textDim, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    AppBadge(label: '💎 ${video['diamondsCharged'] ?? 0} Diamond', color: AppColors.diamond),
                  ],
                ),
              ),
              if (canPreview) Icon(Icons.play_circle_rounded, color: AppColors.purple, size: 26),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildChannelCard() {
    final channel = data?['connectedYouTubeChannel'];
    if (channel == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text('No YouTube channel connected yet', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
            const SizedBox(height: 14),
            GradientButton(label: 'Connect Channel', icon: Icons.link, onPressed: _connectYoutube),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundColor: context.surfaces.card2, backgroundImage: channel['thumbnail'] != null && channel['thumbnail'] != '' ? NetworkImage(channel['thumbnail']) : null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(channel['channelTitle'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${channel['subscriberCount'] ?? 0} Subscribers', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
              ],
            ),
          ),
          const AppBadge(label: 'Active', color: AppColors.green),
        ],
      ),
    );
  }
}