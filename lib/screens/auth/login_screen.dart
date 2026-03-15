import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(_emailCtrl.text, _passCtrl.text);
    if (ok && mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.tire_repair,
                    size: 36, color: Colors.white),
              ),
              const SizedBox(height: 28),
              const Text('Welcome Back!',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 6),
              Text('Sign in to manage your tyre shop',
                  style: TextStyle(
                      fontSize: 14, color: AppTheme.textMuted)),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon:
                            Icon(Icons.email_outlined, color: AppTheme.textMuted),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined,
                            color: AppTheme.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.textMuted),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 28),
                    Consumer<AuthProvider>(
                      builder: (_, auth, __) => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: auth.status == AuthStatus.loading
                              ? null
                              : _login,
                          child: auth.status == AuthStatus.loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Text('Sign In'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<AuthProvider>(
                      builder: (_, auth, __) {
                        if (auth.errorMessage == null) return const SizedBox();
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.errorColor.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppTheme.errorColor, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(auth.errorMessage!,
                                      style: const TextStyle(
                                          color: AppTheme.errorColor,
                                          fontSize: 13))),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: TextStyle(color: AppTheme.textMuted)),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: const Text('Register',
                        style: TextStyle(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}