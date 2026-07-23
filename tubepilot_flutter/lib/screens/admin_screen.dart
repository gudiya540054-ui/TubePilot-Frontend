import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? stats;
  List<dynamic> payments = [];
  bool loading = true;
  final tabs = const ['pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadPayments();
    });
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.instance.adminDashboard();
      setState(() => stats = res['stats']);
      await _loadPayments();
    } catch (e) {
      if (mounted) showApiError(context, e);
      if (mounted) Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadPayments() async {
    try {
      final res = await ApiService.instance.adminPayments(status: tabs[_tabController.index]);
      setState(() => payments = res['transactions']);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _approve(String id) async {
    try {
      await ApiService.instance.approvePayment(id);
      if (mounted) showToast(context, 'Approved — diamonds credited', isSuccess: true);
      _loadAll();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _reject(String id) async {
    final ctrl = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject payment'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Reason (optional)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Reject')),
        ],
      ),
    );
    if (note == null) return;
    try {
      await ApiService.instance.rejectPayment(id, note);
      if (mounted) showToast(context, 'Payment rejected');
      _loadAll();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(controller: _tabController, labelColor: AppColors.purple, indicatorColor: AppColors.purple,
          tabs: tabs.map((t) => Tab(text: t[0].toUpperCase() + t.substring(1))).toList()),
      ),
      body: loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      StatCard(label: 'Total Users', value: '${stats?['totalUsers'] ?? 0}'),
                      StatCard(label: 'Active Users', value: '${stats?['activeUsers'] ?? 0}'),
                      StatCard(label: 'Revenue', value: '₹${stats?['revenue'] ?? 0}'),
                      StatCard(label: 'Upload Queue', value: '${stats?['uploadQueue'] ?? 0}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (payments.isEmpty)
                    EmptyView(message: 'No ${tabs[_tabController.index]} payments', icon: Icons.payments_outlined)
                  else
                    ...payments.map((t) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(t['userDisplayId'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(t['user']?['email'] ?? '', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
                                ]),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('₹${t['amountINR']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text('${t['diamondPackage']} 💎', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
                                ]),
                              ]),
                              const Divider(height: 20),
                              Text('UTR: ${t['utrNumber'] ?? '-'}', style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5)),
                              Text('Time: ${formatDateTime(t['createdAt'])}', style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5)),
                              if (tabs[_tabController.index] == 'pending') ...[
                                const SizedBox(height: 12),
                                Row(children: [
                                  Expanded(child: ElevatedButton(onPressed: () => _approve(t['_id']), child: const Text('Approve'))),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _reject(t['_id']),
                                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red)),
                                      child: const Text('Reject'),
                                    ),
                                  ),
                                ]),
                              ] else
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: AppBadge(
                                    label: tabs[_tabController.index],
                                    color: tabs[_tabController.index] == 'approved' ? AppColors.green : AppColors.red,
                                  ),
                                ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
