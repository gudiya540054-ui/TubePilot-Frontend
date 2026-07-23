import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../services/push_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'username_setup_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = false; // default: Sign Up screen shows first for new users
  bool loading = false;
  bool googleLoading = false;
  bool obscurePassword = true;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _goNext(Map<String, dynamic>? user) {
    final username = user?['username'];
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => (username == null || username == '') ? const UsernameSetupScreen() : const DashboardScreen(),
    ));
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    final auth = context.read<AuthProvider>();
    try {
      if (isLogin) {
        await auth.emailLogin(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
      } else {
        await auth.emailSignup(name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
      }
      if (!mounted) return;
      PushService.initAfterLogin();
      _goNext(auth.user);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => googleLoading = true);
    final auth = context.read<AuthProvider>();
    try {
      await auth.googleLogin();
      if (!mounted) return;
      PushService.initAfterLogin();
      _goNext(auth.user);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => googleLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showToast(context, 'Enter a valid email first', isError: true);
      return;
    }
    try {
      await ApiService.instance.forgotPassword(email);
      if (mounted) showToast(context, 'If that email exists, a reset link has been sent', isSuccess: true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(14)),
                    child: const Center(child: Text('▶️', style: TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(height: 20),
                  Text(isLogin ? 'Welcome Back!' : 'Create Account',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(isLogin ? 'Sign in to continue' : 'Start scheduling in seconds',
                      style: TextStyle(color: context.surfaces.textDim)),
                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: googleLoading ? null : _submitGoogle,
                      icon: googleLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Image.network(
                              'https://developers.google.com/identity/images/g-logo.png',
                              width: 18, height: 18,
                              errorBuilder: (_, __, ___) => const Text('🔵', style: TextStyle(fontSize: 16)),
                            ),
                      label: Text(isLogin ? 'Continue with Google' : 'Sign up with Google'),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(children: [
                      Expanded(child: Divider(color: context.surfaces.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or continue with email', style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5)),
                      ),
                      Expanded(child: Divider(color: context.surfaces.border)),
                    ]),
                  ),

                  if (!isLogin) ...[
                    _buildLabel('Full Name'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(hintText: 'Your full name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 14),
                  ],

                  _buildLabel('Email'),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'you@example.com'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your email';
                      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Password'),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                  ),

                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Forgot Password?', style: TextStyle(color: AppColors.purple, fontSize: 13)),
                      ),
                    ),

                  const SizedBox(height: 10),
                  GradientButton(
                    label: isLogin ? 'Login' : 'Sign Up',
                    loading: loading,
                    onPressed: _submitEmailAuth,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isLogin ? "Don't have an account? " : 'Already have an account? ',
                          style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
                      GestureDetector(
                        onTap: () => setState(() => isLogin = !isLogin),
                        child: Text(isLogin ? 'Sign Up' : 'Login',
                            style: const TextStyle(color: AppColors.purpleLight, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('By continuing, you agree to our Terms & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(text, style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
        ),
      );
}
