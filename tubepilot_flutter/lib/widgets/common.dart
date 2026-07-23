import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ---------------- Toast ----------------
void showToast(BuildContext context, String message, {bool isError = false, bool isSuccess = false}) {
  final color = isError ? AppColors.red : (isSuccess ? AppColors.green : Theme.of(context).colorScheme.surface);
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError || isSuccess ? color.withOpacity(0.15) : null,
      content: Text(
        message,
        style: TextStyle(color: isError ? AppColors.red : (isSuccess ? AppColors.green : null)),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

void showApiError(BuildContext context, Object err) {
  showToast(context, err.toString().replaceFirst('ApiException: ', ''), isError: true);
}

// ---------------- Gradient Button ----------------
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const GradientButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null && !loading ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: loading ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
                          Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Badge ----------------
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  const AppBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ---------------- Balance Banner ----------------
class BalanceBanner extends StatelessWidget {
  final int balance;
  final VoidCallback onBuy;
  const BalanceBanner({super.key, required this.balance, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Diamond Balance', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              const SizedBox(height: 4),
              Row(children: [
                const Text('💎 ', style: TextStyle(fontSize: 20)),
                Text('$balance', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              ]),
            ],
          ),
          ElevatedButton(
            onPressed: onBuy,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.22),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('+ Buy', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ---------------- Stat Card ----------------
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? change;
  const StatCard({super.key, required this.label, required this.value, this.change});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: context.surfaces.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          if (change != null) ...[
            const SizedBox(height: 2),
            Text(change!, style: const TextStyle(color: AppColors.green, fontSize: 11.5)),
          ],
        ],
      ),
    );
  }
}

// ---------------- Bottom Nav ----------------
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: Theme.of(context).colorScheme.surface,
      indicatorColor: AppColors.purple.withOpacity(0.15),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.purple), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.upload_outlined), selectedIcon: Icon(Icons.upload, color: AppColors.purple), label: 'Upload'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month, color: AppColors.purple), label: 'Videos'),
        NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart, color: AppColors.purple), label: 'Analytics'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppColors.purple), label: 'Profile'),
      ],
    );
  }
}

// ---------------- Loading / Empty states ----------------
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: AppColors.purple));
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Icon(icon, size: 40, color: context.surfaces.textDim),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: context.surfaces.textDim), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

String formatDateTime(String? iso) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  final local = d.toLocal();
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final ampm = local.hour >= 12 ? 'PM' : 'AM';
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]} - $hour12:$minute $ampm';
}

String formatDate(String? iso) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
