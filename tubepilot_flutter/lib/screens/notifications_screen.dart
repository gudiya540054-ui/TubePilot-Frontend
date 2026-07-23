import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool loading = true;

  final icons = const {
    'payment_approved': '✅', 'payment_rejected': '❌', 'upload_completed': '📤',
    'upload_failed': '⚠️', 'schedule_started': '⏳', 'schedule_finished': '🎬',
    'subscription_expiring': '⏰', 'free_upload_reset': '🎁',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.instance.getNotifications();
      setState(() => notifications = res['notifications']);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.instance.markAllNotificationsRead();
      if (mounted) showToast(context, 'All marked as read', isSuccess: true);
      _load();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), actions: [
        IconButton(icon: const Icon(Icons.done_all), onPressed: _markAllRead),
      ]),
      body: loading
          ? const LoadingView()
          : notifications.isEmpty
              ? const Center(child: EmptyView(message: 'No notifications yet', icon: Icons.notifications_none))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (_, i) {
                      final n = notifications[i];
                      return Opacity(
                        opacity: n['isRead'] == true ? 0.6 : 1,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(icons[n['type']] ?? '🔔', style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(n['message'] ?? '', style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5)),
                                    const SizedBox(height: 4),
                                    Text(formatDateTime(n['createdAt']), style: TextStyle(color: context.surfaces.textDim, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
