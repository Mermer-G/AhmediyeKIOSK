import 'package:app1/Pages/new_home.dart';
import 'package:app1/Pages/settings.dart';
import 'package:app1/Theme/dashboard_theme.dart';
import 'package:flutter/material.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final TextEditingController _controller = TextEditingController();

  final String correctPassword = settingsPassword;

  String? error;

  void checkPassword() {
    if (_controller.text == correctPassword) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SettingsPage(),
        ),
      );
    } else {
      setState(() {
        error = 'Şifre yanlış';
      });

      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 420,
                    ),
                    child: GlassPanel(
                      title: 'Ayarlar',
                      icon: Icons.lock_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Yönetici şifresini girin',
                            style: TextStyle(
                              color: GlassTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Ayarlar bölümüne erişmek için şifre gerekiyor.',
                            style: TextStyle(
                              color: GlassTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 20),

                          TextField(
                            controller: _controller,
                            obscureText: true,
                            autofocus: true,
                            onSubmitted: (_) => checkPassword(),
                            style: const TextStyle(
                              color: GlassTheme.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              errorText: error,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 19,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  _controller.clear();

                                  setState(() {
                                    error = null;
                                  });
                                },
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: checkPassword,
                              icon: const Icon(
                                Icons.login_rounded,
                                size: 18,
                              ),
                              label: const Text('Giriş'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Geri butonu
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: GlassTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}