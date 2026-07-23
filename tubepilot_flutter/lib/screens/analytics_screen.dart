import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AnalyticsScreen extends StatefulWidget {
  final bool embedded;
  const AnalyticsScreen({super.key, this.embedded = false});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? analytics;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.instance.getAnalytics();
      setState(() => analytics = res['analytics']);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(label: 'Total Uploaded', value: '${analytics?['uploadCount'] ?? 0}'),
                      StatCard(label: 'Free Uploads Left', value: '${analytics?['freeUploadsLeft'] ?? 0}'),
                      StatCard(label: 'Diamond Balance', value: '💎 ${analytics?['remainingUploadCredits'] ?? 0}'),
                      StatCard(label: 'Scheduled Queue', value: '${analytics?['scheduledQueue'] ?? 0}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Failed Uploads', style: TextStyle(fontWeight: FontWeight.w700)),
                          AppBadge(label: '${analytics?['failedUploads'] ?? 0}', color: AppColors.red),
                        ]),
                        const SizedBox(height: 10),
                        Text(
                          'Real view/watch-time/subscriber analytics will appear here once your connected YouTube channel has data via the YouTube Analytics API.',
                          style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
