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
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.instance.dashboard();
      final notifRes = await ApiService.instance.getNotifications();
      setState(() {
        data = res['data'];
        unreadCount = notifRes['unreadCount'] ?? 0;
      });
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
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
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
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
                      _quickCard('Free Uploads', '${data?['remainingFreeUploads'] ?? 0}', () {}),
                      _quickCard('Uploaded Videos', '${data?['totalUploadedVideos'] ?? 0}', () {}),
                      _quickCard('Analytics', '📈', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
                      _quickCard('Calendar', '📅', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpcomingScreen()))),
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

  Widget _quickCard(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUpcomingList() {
    final history = (data?['uploadHistory'] as List?) ?? [];
    final upcoming = history.where((v) => ['scheduled', 'queued', 'processing'].contains(v['status'])).take(3).toList();

    if (upcoming.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
          child: Text('No upcoming videos. Tap "Schedule New Video" to get started.', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
        ),
      ];
    }

    return upcoming.map<Widget>((v) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('🎬', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(v['scheduledAt'] != null ? formatDateTime(v['scheduledAt']) : 'Uploading soon', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
                const SizedBox(height: 4),
                AppBadge(label: '💎 ${v['diamondsCharged'] ?? 0} Diamond', color: AppColors.diamond),
              ],
            ),
          ),
        ],
      ),
    )).toList();
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
