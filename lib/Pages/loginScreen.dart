import 'package:app1/utils/auth_service.dart';
import 'package:app1/utils/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app1/utils/database_models.dart';

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

  
  void _login() async{
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

      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Web paneline yalnızca yöneticiler giriş yapabilir.',
          ),
        ),
      );

      return;
    }

    Navigator.pop(
      context,
      AuthService.instance.currentUser,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kullanıcı Girişi'),
        ),
        body: Center(
          child: SizedBox(
            width: 400,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person,
                    size: 64,
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller: usernameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı adı',
                      prefixIcon: Icon(Icons.person),
                    ),
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword =
                                !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: const Text('Giriş Yap'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}