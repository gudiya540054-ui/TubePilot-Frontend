import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingStep {
  final String icon;
  final String title;
  final String desc;
  const _OnboardingStep(this.icon, this.title, this.desc);
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _steps = const [
    _OnboardingStep('☁️⬆️', 'Schedule videos from anywhere.', 'Set a date and time, and TubePilot uploads it for you automatically.'),
    _OnboardingStep('📱☁️', 'Phone off? Video still uploads.', 'Our cloud storage system holds your video safely until upload time.'),
    _OnboardingStep('💎', 'Earn time, not stress.', 'AI titles, tags, and descriptions save hours of manual work.'),
  ];
  int _step = 0;

  void _finish() async {
    await StorageService.setOnboarded();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final s = _steps[_step];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _finish, child: Text('Skip', style: TextStyle(color: context.surfaces.textDim))),
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 210, height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [AppColors.purple.withOpacity(0.25), Colors.transparent]),
                      ),
                      child: Center(child: Text(s.icon, style: const TextStyle(fontSize: 76))),
                    ),
                    const SizedBox(height: 18),
                    Text(s.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(s.desc, textAlign: TextAlign.center, style: TextStyle(color: context.surfaces.textDim)),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _step ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _step ? AppColors.purpleLight : context.surfaces.border,
                    borderRadius: BorderRadius.circular(5),
                  ),
                )),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_step < _steps.length - 1) {
                      setState(() => _step++);
                    } else {
                      _finish();
                    }
                  },
                  child: Text(_step == _steps.length - 1 ? 'Get Started' : 'Next'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
