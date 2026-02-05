import 'package:app1/Pages/home.dart';
import 'package:app1/Pages/settings.dart';
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
        MaterialPageRoute(builder: (_) => SettingsPage()),
      );
    } else {
      setState(() {
        error = "Şifre yanlış";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Şifre Gir")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Şifre",
                errorText: error,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: checkPassword,
              child: const Text("Giriş"),
            ),
          ],
        ),
      ),
    );
  }
}