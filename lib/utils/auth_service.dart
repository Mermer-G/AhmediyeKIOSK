import 'dart:async';
import 'package:app1/utils/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:app1/utils/database_models.dart';

class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  User? _currentUser;
  Timer? _sessionTimer;

  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(
    String username,
    String password,
  ) async {
    _sessionTimer?.cancel();
    _sessionTimer = null;

    final normalizedUsername =
        username.trim().toLowerCase();

    if (kIsWeb) {
      final snapshot = await DatabaseService()
          .firebaseDatabase
          .ref()
          .child('User')
          .get();

      if (!snapshot.exists) {
        return false;
      }

      final users = Map<dynamic, dynamic>.from(
        snapshot.value as Map,
      );

      for (final value in users.values) {
        final user = User.fromMap(
          Map<dynamic, dynamic>.from(value),
        );

        if (user.username.trim().toLowerCase() ==
                normalizedUsername &&
            user.password == password) {
          _currentUser = user;

          notifyListeners();

          return true;
        }
      }

      return false;
    }

    final box = Hive.box(userBox);

    for (final value in box.values) {
      final user = User.fromMap(
        Map<dynamic, dynamic>.from(value),
      );

      if (user.username.trim().toLowerCase() ==
              normalizedUsername &&
          user.password == password) {
        _currentUser = user;

        if (user.role == UserRole.operator) {
          startSessionTimer();
        }

        notifyListeners();

        return true;
      }
    }

    return false;
  }

  void logout() {
    _sessionTimer?.cancel();
    _sessionTimer = null;

    _currentUser = null;

    notifyListeners();
  }

  Future<void> createUser(User user) async {
    final box = Hive.box(userBox);

    await box.put(
      user.id,
      User.toMap(user),
    );

    await DatabaseService()
        .firebaseDatabase
        .ref()
        .child('User')
        .child(user.id)
        .set(User.toMap(user));
  }

  void startSessionTimer() {
    _sessionTimer?.cancel();

    if (!isLoggedIn ||
        _currentUser!.role != UserRole.operator) {
      return;
    }

    final now = DateTime.now();

    final nextMidnight = DateTime(
      now.year,
      now.month,
      now.day + 1,
    );

    final duration = nextMidnight.difference(now);

    _sessionTimer = Timer(
      duration,
      () {
        logout();
      },
    );
  }

  Future<bool> get hasAdmins async {
    if (!kIsWeb) {
      final box = Hive.box(userBox);

      return box.values.any((value) {
        final user = User.fromMap(
          Map<dynamic, dynamic>.from(value),
        );

        return user.role == UserRole.admin;
      });
    }

    final snapshot = await DatabaseService()
        .firebaseDatabase
        .ref()
        .child('User')
        .get();

    if (!snapshot.exists) {
      return false;
    }

    final users = Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );

    return users.values.any((value) {
      final user = User.fromMap(
        Map<dynamic, dynamic>.from(value),
      );

      return user.role == UserRole.admin;
    });
  }

  bool get hasOperators {
    final box = Hive.box(userBox);

    return box.values.any((value) {
      final user = User.fromMap(
        Map<dynamic, dynamic>.from(value),
      );

      return user.role == UserRole.operator;
    });
  }
}



// ==================================================================
// FIRST OPERATOR SETUP SCREEN
// ==================================================================
class FirstOperatorScreen extends StatefulWidget {
  const FirstOperatorScreen({super.key});

  @override
  State<FirstOperatorScreen> createState() =>
      _FirstOperatorScreenState();
}

class _FirstOperatorScreenState
    extends State<FirstOperatorScreen> {

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void _createOperator() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      return;
    }

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      password: password,
      role: UserRole.operator,
    );

    await AuthService.instance.createUser(user);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('İlk Operatörü Oluştur'),
        ),
        body: Center(
          child: SizedBox(
            width: 400,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı adı',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Şifre',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createOperator,
                      child: const Text('Operatör Oluştur'),
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


// ==================================================================
// FIRST ADMIN SETUP SCREEN
// ==================================================================
class FirstAdminScreen extends StatefulWidget {
  const FirstAdminScreen({super.key});

  @override
  State<FirstAdminScreen> createState() =>
      _FirstAdminScreenState();
}

class _FirstAdminScreenState
    extends State<FirstAdminScreen> {

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void _createAdmin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      return;
    }

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      password: password,
      role: UserRole.admin,
    );

    await AuthService.instance.createUser(user);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('İlk Yöneticiyi Oluştur'),
        ),
        body: Center(
          child: SizedBox(
            width: 400,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı adı',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Şifre',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createAdmin,
                      child: const Text('Yönetici Oluştur'),
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