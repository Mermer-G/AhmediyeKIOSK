import 'package:ahmediye_kiosk/Pages/home.dart';
import 'package:ahmediye_kiosk/Pages/settings.dart';
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
        error = "Sifre yanlis";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sifre Gir")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _controller,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Sifre",
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: checkPassword,
                  child: const Text("Giris"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
