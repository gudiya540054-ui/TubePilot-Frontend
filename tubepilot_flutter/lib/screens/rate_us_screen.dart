import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class RateUsScreen extends StatefulWidget {
  const RateUsScreen({super.key});
  @override
  State<RateUsScreen> createState() => _RateUsScreenState();
}

class _RateUsScreenState extends State<RateUsScreen> {
  int _stars = 0;
  late final TextEditingController _reviewCtrl;
  late final TextEditingController _emailCtrl;
  bool _reviewManuallyEdited = false;

  static const Map<int, String> _autoReviews = {
    1: "I had a rough experience with the app and think it needs real improvement.",
    2: "The app has potential but ran into issues that affected my experience.",
    3: "The app works okay overall, though a few things could be better.",
    4: "I've enjoyed using the app — it's been helpful with a couple of minor hiccups.",
    5: "Great app! It's made scheduling and uploading my YouTube videos so much easier.",
  };

  @override
  void initState() {
    super.initState();
    _reviewCtrl = TextEditingController();
    final user = context.read<AuthProvider>().user ?? {};
    _emailCtrl = TextEditingController(text: user['email'] ?? '');
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _selectStars(int stars) {
    setState(() {
      _stars = stars;
      // Only auto-fill the review text if the user hasn't typed their own —
      // once they edit it manually, we stop overwriting it on star changes.
      if (!_reviewManuallyEdited) {
        _reviewCtrl.text = _autoReviews[stars] ?? '';
      }
    });
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      showToast(context, 'Please select a star rating first', isError: true);
      return;
    }

    final user = context.read<AuthProvider>().user ?? {};
    final uri = Uri(
      scheme: 'mailto',
      path: 'anikkesharwani37@gmail.com',
      query: 'subject=${Uri.encodeComponent('TubePilot Rating: $_stars★')}'
          '&body=${Uri.encodeComponent('User ID: ${user['userId'] ?? '-'}\nEmail: ${_emailCtrl.text.trim()}\nRating: $_stars / 5\n\nReview:\n${_reviewCtrl.text.trim()}')}',
    );
    try {
      final launched = await launchUrl(uri);
      if (!mounted) return;
      if (launched) {
        Navigator.of(context).maybePop();
      } else {
        showToast(context, 'No email app found. Contact anikkesharwani37@gmail.com directly.', isError: true);
      }
    } catch (_) {
      if (mounted) showToast(context, 'No email app found. Contact anikkesharwani37@gmail.com directly.', isError: true);
    }
  }

  void _skip() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Us'),
        actions: [
          TextButton(onPressed: _skip, child: const Text('Skip')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
                child: const Center(child: Icon(Icons.star_rounded, color: Colors.white, size: 30)),
              ),
              const SizedBox(height: 14),
              const Text('Enjoying TubePilot?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Let us know how we\'re doing', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              final filled = starIndex <= _stars;
              return GestureDetector(
                onTap: () => _selectStars(starIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    color: filled ? AppColors.diamond : context.surfaces.textDim,
                    size: 38,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          Text('Your Review', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _reviewCtrl,
            maxLines: 5,
            onChanged: (_) => _reviewManuallyEdited = true,
            decoration: const InputDecoration(hintText: 'Select a star rating to auto-fill, or write your own review...'),
          ),
          const SizedBox(height: 14),

          Text('Your Email', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'you@example.com'),
          ),
          const SizedBox(height: 24),

          GradientButton(label: 'Submit Rating', onPressed: _submit),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _skip,
              child: Text('Not now', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}