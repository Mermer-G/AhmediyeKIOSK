import 'dart:async';
import 'package:app1/Theme/dashboard_theme.dart';
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

          if(!kIsWeb){
            notifyListeners();
          }

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
  State<FirstOperatorScreen> createState() => _FirstOperatorScreenState();
}

class _FirstOperatorScreenState extends State<FirstOperatorScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool _loading = false;

  Future<void> _createOperator() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      return;
    }

    setState(() => _loading = true);

    try {
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        password: password,
        role: UserRole.operator,
      );

      await AuthService.instance.createUser(user);

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operatör oluşturulamadı: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
        backgroundColor: GlassTheme.background,
        body: GlassBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                ),
                child: GlassPanel(
                  title: 'İlk Operatörü Oluştur',
                  subtitle: 'Sistemi kullanmaya başlamak için operatör hesabı oluşturun',
                  icon: Icons.person_add_alt_1_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: usernameController,
                        style: const TextStyle(
                          color: GlassTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Kullanıcı adı',
                          labelStyle: const TextStyle(
                            color: GlassTheme.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: GlassTheme.cyan,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: .04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: .08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: .08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: GlassTheme.cyan.withValues(alpha: .6),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: const TextStyle(
                          color: GlassTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          labelStyle: const TextStyle(
                            color: GlassTheme.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: GlassTheme.purple,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: .04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: .08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: .08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: GlassTheme.purple.withValues(alpha: .6),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _createOperator,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlassTheme.cyan,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                GlassTheme.cyan.withValues(alpha: .35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Operatör Oluştur',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
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


// ==================================================================
// FIRST ADMIN SETUP SCREEN
// ==================================================================
class FirstAdminScreen extends StatefulWidget {
  const FirstAdminScreen({super.key});

  @override
  State<FirstAdminScreen> createState() => _FirstAdminScreenState();
}

class _FirstAdminScreenState extends State<FirstAdminScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool _loading = false;

  Future<void> _createAdmin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      return;
    }

    setState(() => _loading = true);

    try {
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        password: password,
        role: UserRole.admin,
      );

      await AuthService.instance.createUser(user);

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yönetici oluşturulamadı: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
        backgroundColor: GlassTheme.background,
        body: GlassBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                ),
                child: GlassPanel(
                  title: 'İlk Yönetici Oluştur',
                  subtitle: 'Sistem yönetimi için yönetici hesabı oluşturun',
                  icon: Icons.admin_panel_settings_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: usernameController,
                        style: const TextStyle(
                          color: GlassTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Kullanıcı adı',
                          labelStyle: const TextStyle(
                            color: GlassTheme.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: GlassTheme.cyan,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: .04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: .08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: .08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: GlassTheme.cyan.withValues(alpha: .6),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: const TextStyle(
                          color: GlassTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          labelStyle: const TextStyle(
                            color: GlassTheme.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: GlassTheme.purple,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: .04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: .08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: .08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: GlassTheme.purple.withValues(alpha: .6),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _createAdmin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlassTheme.cyan,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                GlassTheme.cyan.withValues(alpha: .35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Yönetici Oluştur',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
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
