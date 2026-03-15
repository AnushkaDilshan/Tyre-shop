import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../dashboard/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

Future<void> _register() async {
  if (!_formKey.currentState!.validate()) return;
  final auth = context.read<AuthProvider>();
  final ok = await auth.signUp(
    _emailCtrl.text,
    _passCtrl.text,
    shopName: _shopNameCtrl.text.trim(),
  );
  if (ok && mounted) {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Set up your shop',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text('Create an account to get started',
                    style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _shopNameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Shop Name *',
                    prefixIcon:
                        Icon(Icons.store_outlined, color: AppTheme.textMuted),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
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
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon:
                        Icon(Icons.lock_outlined, color: AppTheme.textMuted),
                  ),
                  validator: (v) =>
                      v != _passCtrl.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 32),
                Consumer<AuthProvider>(
                  builder: (_, auth, __) => Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: auth.status == AuthStatus.loading
                              ? null
                              : _register,
                          child: auth.status == AuthStatus.loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Create Account'),
                        ),
                      ),
                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(auth.errorMessage!,
                              style:
                                  const TextStyle(color: AppTheme.errorColor)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
