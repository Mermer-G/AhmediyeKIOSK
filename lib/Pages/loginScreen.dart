import 'package:app1/Theme/dashboard_theme.dart';
import 'package:app1/utils/auth_service.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

bool isInLoginScreen = false;

class _LoginScreenState extends State<LoginScreen> {
  late Box box;

  late final TextEditingController usernameController;
  late final TextEditingController passwordController;

  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();

    box = Hive.box(userBox);

    usernameController = TextEditingController();
    passwordController = TextEditingController();
    isInLoginScreen = true;
  }

  @override
  void dispose() {
    isInLoginScreen = false;

    usernameController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  void _login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showError('Kullanıcı adı ve şifre boş bırakılamaz.');
      return;
    }

    final success = await AuthService.instance.login(
      usernameController.text,
      passwordController.text,
    );

    if (!success) {
      _showError('Kullanıcı adı veya şifre hatalı.');
      return;
    }

    final user = AuthService.instance.currentUser;

    if (kIsWeb && user?.role != UserRole.admin) {
      AuthService.instance.logout();

      _showError('Web paneline yalnızca yöneticiler giriş yapabilir.');
      return;
    }

    if (mounted) {
      Navigator.pop(
        context,
        AuthService.instance.currentUser,
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: GlassTheme.textSecondary, fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: GlassTheme.cyan, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: .04),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GlassTheme.cyan, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GlassBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 400,
                child: GlassPanel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),

                      // Gradient Icon Header
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [GlassTheme.cyan, GlassTheme.purple],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: GlassTheme.cyan.withValues(alpha: .45),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Header Text
                      const Text(
                        'Kullanıcı Girişi',
                        style: TextStyle(
                          color: GlassTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Devam etmek için hesabınıza giriş yapın.',
                        style: TextStyle(
                          color: GlassTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Username Input
                      TextField(
                        controller: usernameController,
                        autofocus: true,
                        style: const TextStyle(color: GlassTheme.textPrimary, fontSize: 14),
                        textInputAction: TextInputAction.next,
                        decoration: _buildInputDecoration(
                          labelText: 'Kullanıcı adı',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password Input
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: const TextStyle(color: GlassTheme.textPrimary, fontSize: 14),
                        decoration: _buildInputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: GlassTheme.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [GlassTheme.cyan, GlassTheme.purple],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: GlassTheme.cyan.withValues(alpha: .3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Giriş Yap',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}