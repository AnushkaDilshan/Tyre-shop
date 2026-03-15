import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'login_screen.dart';
import '../dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
            parent: _controller, curve: Curves.easeIn));
    _scaleAnim =
        Tween<double>(begin: 0.7, end: 1).animate(CurvedAnimation(
            parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    _navigate();
  }

  void _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      _goToDashboard();
    } else {
      // wait for Firebase auth to respond
      auth.addListener(() {
        if (!mounted) return;
        if (auth.status == AuthStatus.authenticated) {
          _goToDashboard();
        } else if (auth.status == AuthStatus.unauthenticated) {
          _goToLogin();
        }
      });
      if (auth.status == AuthStatus.unauthenticated) _goToLogin();
    }
  }

  void _goToDashboard() {
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  void _goToLogin() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.tire_repair,
                      size: 56, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'TYRE SHOP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'MANAGER',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.accentColor,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.accentColor.withOpacity(0.7),
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