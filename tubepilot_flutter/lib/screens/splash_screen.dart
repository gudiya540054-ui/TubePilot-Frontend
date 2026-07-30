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
  // Splash stays visible for 7 seconds (within the requested 5-10s range)
  // before navigating away, regardless of how fast the session/auth check
  // finishes underneath.
  static const _minSplashDuration = Duration(seconds: 7);

  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    final auth = context.read<AuthProvider>();
    await Future.wait([
      auth.loadSession(),
      Future.delayed(_minSplashDuration),
    ]);
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
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Splash logo (assets/splash.png), rounded square container.
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/splash.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Text('▶️', style: TextStyle(fontSize: 42))),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('TubePilot', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Schedule. Upload. Relax.', style: TextStyle(color: context.surfaces.textDim)),
                  const SizedBox(height: 34),
                  // Spinning circular loader below the icon.
                  const CircularProgressIndicator(color: AppColors.purple),
                ],
              ),
            ),
            // Bottom-center footer credit.
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Column(
                children: [
                  Text(
                    'Powered By BharatCloudTechnologies',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Made In India',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5),
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