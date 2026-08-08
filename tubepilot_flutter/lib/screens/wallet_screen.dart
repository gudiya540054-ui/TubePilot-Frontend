import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? wallet;
  bool loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.instance.getWallet();
      setState(() => wallet = res['wallet']);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  (Color, String) _statusBadge(String status) {
    switch (status) {
      case 'pending': return (AppColors.diamond, 'Pending');
      case 'approved': return (AppColors.green, 'Approved');
      case 'rejected': return (AppColors.red, 'Rejected');
      case 'completed': return (AppColors.green, 'Completed');
      default: return (AppColors.diamond, status);
    }
  }

  // Real transaction-type icons, replacing any emoji previously used —
  // gives each row a proper Material icon matched to what happened.
  (IconData, Color) _txnIcon(Map t, bool isSpend) {
    if (t['type'] == 'diamond_purchase') return (Icons.diamond_rounded, AppColors.diamond);
    if (isSpend) return (Icons.upload_rounded, AppColors.red);
    return (Icons.replay_rounded, AppColors.green);
  }

  @override
  Widget build(BuildContext context) {
    final all = (wallet?['transactions'] as List?) ?? [];
    final purchasesOnly = all.where((t) => t['type'] == 'diamond_purchase').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        bottom: TabBar(controller: _tabController, labelColor: AppColors.purple, indicatorColor: AppColors.purple, tabs: const [
          Tab(text: 'Transactions'), Tab(text: 'Purchases'),
        ]),
      ),
      body: loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(18)),
                    child: Column(children: [
                      Text('Total Diamonds', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.diamond_rounded, color: AppColors.diamond, size: 24),
                        const SizedBox(width: 8),
                        Text('${wallet?['diamondBalance'] ?? 0}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 6),
                      Text('${wallet?['freeUploadsRemaining'] ?? 0} free uploads remaining this month', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 400,
                    child: TabBarView(controller: _tabController, children: [
                      _buildList(all),
                      _buildList(purchasesOnly),
                    ]),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildList(List list) {
    if (list.isEmpty) return const EmptyView(message: 'No transactions yet', icon: Icons.receipt_long_outlined);
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: list.length,
      itemBuilder: (_, i) {
        final t = list[i];
        final isSpend = t['type'] == 'diamond_spend';
        final label = t['type'] == 'diamond_purchase' ? 'Diamond Pack (${t['diamondPackage']})' : (isSpend ? 'Video Scheduled' : 'Diamond Refund');
        final amount = t['type'] == 'diamond_purchase' ? '+${t['diamondPackage']}' : (isSpend ? '-${t['diamondsForSpend']}' : '+${t['diamondsForSpend']}');
        final (color, statusLabel) = _statusBadge(t['status'] ?? '');
        final (icon, iconColor) = _txnIcon(t, isSpend);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: iconColor.withOpacity(0.14), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(formatDateTime(t['createdAt']), style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(amount, style: TextStyle(fontWeight: FontWeight.w700, color: isSpend ? AppColors.red : AppColors.green)),
                const SizedBox(height: 4),
                AppBadge(label: statusLabel, color: color),
              ]),
            ],
          ),
        );
      },
    );
  }
}