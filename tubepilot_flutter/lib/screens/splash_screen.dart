import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/storage_service.dart';
import '../services/push_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    final auth = context.read<AuthProvider>();
    await auth.loadSession();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    Widget next;
    if (auth.isLoggedIn) {
      next = const DashboardScreen();
      PushService.initAfterLogin();
    } else {
      final onboarded = await StorageService.isOnboarded();
      next = onboarded ? const LoginScreen() : const OnboardingScreen();
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(26)),
              child: const Center(child: Text('▶️', style: TextStyle(fontSize: 42))),
            ),
            const SizedBox(height: 22),
            const Text('YT Uploader', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Schedule. Upload. Relax.', style: TextStyle(color: context.surfaces.textDim)),
            const SizedBox(height: 34),
            const CircularProgressIndicator(color: AppColors.purple),
          ],
        ),
      ),
    );
  }
}
