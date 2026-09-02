import 'dart:async';
import 'package:app1/utils/database_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:app1/utils/database_models.dart';

class OperatorService extends ChangeNotifier {
  // ============================================================
  // HIVE
  // ============================================================

  final Box operatorB = Hive.box(operatorBox);


  // ============================================================
  // ACTIVE SESSION
  // ============================================================

  OperatorService._();

  static final OperatorService instance = OperatorService._();

  Operator? _currentOperator;

  Operator? get currentOperator => _currentOperator;

  bool get isLoggedIn => _currentOperator != null;

  String? get currentUsername => _currentOperator?.username;

  Timer? _sessionTimer;

  // ============================================================
  // OPERATOR LIST
  // ============================================================

  List<Operator> get operators {
    return operatorB.values
        .map(
          (value) => Operator.fromMap(
            Map<dynamic, dynamic>.from(value),
          ),
        )
        .toList();
  }

  bool get hasOperators {
    return operatorB.isNotEmpty;
  }

  // ============================================================
  // LOGIN
  // ============================================================

  bool login({
    required String username,
    required String password,
  }) {
    final normalizedUsername = username.trim();

    for (final operator in operators) {
      if (operator.username == normalizedUsername &&
          operator.password == password) {
        _startSession(operator);

        return true;
      }
    }

    return false;
  }

  void _startSession(Operator operator) {
    _sessionTimer?.cancel();

    _currentOperator = operator;

    startSessionTimer();

    notifyListeners();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void logout() {
    _sessionTimer?.cancel();
    _sessionTimer = null;

    _currentOperator = null;
    

    notifyListeners();
  }

  // ============================================================
  // CHANGE OPERATOR
  // ============================================================

  void changeOperator() {
    logout();
  }

  // ============================================================
  // SESSION TIMER
  // ============================================================

  void startSessionTimer() {
    _sessionTimer?.cancel();

    if (!isLoggedIn) {
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

  // ============================================================
  // DAILY OPERATOR CHANGE TIME
  // ============================================================




  // ============================================================
  // FIRST OPERATOR
  // ============================================================

  Future<bool> createFirstOperator({
    required String username,
    required String password,
  }) async {
    if (hasOperators) {
      return false;
    }

    final trimmedUsername = username.trim();

    if (trimmedUsername.isEmpty || password.isEmpty) {
      return false;
    }

    final operator = Operator(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: trimmedUsername,
      password: password,
    );

    await operatorB.put(
      operator.id,
      Operator.toMap(operator),
    );

    notifyListeners();

    return true;
  }

  // ============================================================
  // LOGIN SCREEN
  // ============================================================

  Future<void> showLoginScreen(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) {
          return OperatorLoginScreen(
            operatorService: this,
          );
        },
      ),
    );
  }

  // ============================================================
  // FIRST SETUP SCREEN
  // ============================================================

  Future<void> showFirstOperatorSetup(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) {
          return FirstOperatorScreen(
            operatorService: this,
          );
        },
      ),
    );
  }

  // ============================================================
  // STARTUP
  // ============================================================

  Future<void> initialize(BuildContext context) async {
    if (!hasOperators) {
      await showFirstOperatorSetup(context);
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _sessionTimer?.cancel();

    super.dispose();
  }
}


// ==================================================================
// LOGIN SCREEN
// ==================================================================

class OperatorLoginScreen extends StatefulWidget {
  final OperatorService operatorService;

  const OperatorLoginScreen({
    super.key,
    required this.operatorService,
  });

  @override
  State<OperatorLoginScreen> createState() =>
      _OperatorLoginScreenState();
}

class _OperatorLoginScreenState
    extends State<OperatorLoginScreen> {

  late final TextEditingController usernameController;
  late final TextEditingController passwordController;

  bool obscurePassword = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    usernameController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  void _login() {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Kullanıcı adı ve şifre giriniz.';
      });

      return;
    }

    final success = widget.operatorService.login(
      username: username,
      password: password,
    );

    if (!success) {
      setState(() {
        errorMessage = 'Kullanıcı adı veya şifre hatalı.';
      });

      return;
    }

    // Session başarıyla açıldı.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Operatör Girişi'),
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
                    Icons.lock_person,
                    size: 64,
                  ),
      
                  const SizedBox(height: 24),
      
                  const Text(
                    'Oturum Aç',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
      
                  const SizedBox(height: 32),
      
                  TextField(
                    controller: usernameController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
      
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı adı',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
      
                  const SizedBox(height: 16),
      
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    onSubmitted: (_) => _login(),
      
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock),
      
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
      
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
      
                      border: const OutlineInputBorder(),
                    ),
                  ),
      
                  const SizedBox(height: 16),
      
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
      
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
      
                  SizedBox(
                    width: double.infinity,
      
                    child: ElevatedButton(
                      onPressed: _login,
      
                      child: const Padding(
                        padding: EdgeInsets.all(14),
      
                        child: Text(
                          'Giriş Yap',
                          style: TextStyle(
                            fontSize: 16,
                          ),
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
    );
  }
}


// ==================================================================
// FIRST OPERATOR SETUP SCREEN
// ==================================================================

class FirstOperatorScreen extends StatefulWidget {
  final OperatorService operatorService;

  const FirstOperatorScreen({
    super.key,
    required this.operatorService,
  });

  @override
  State<FirstOperatorScreen> createState() =>
      _FirstOperatorScreenState();
}

class _FirstOperatorScreenState
    extends State<FirstOperatorScreen> {

  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final TextEditingController passwordAgainController;

  bool obscurePassword = true;
  bool obscurePasswordAgain = true;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    usernameController = TextEditingController();
    passwordController = TextEditingController();
    passwordAgainController = TextEditingController();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    passwordAgainController.dispose();

    super.dispose();
  }

  Future<void> _createOperator() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final passwordAgain = passwordAgainController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Tüm alanları doldurunuz.';
      });

      return;
    }

    if (password != passwordAgain) {
      setState(() {
        errorMessage = 'Şifreler eşleşmiyor.';
      });

      return;
    }

    final success =
        await widget.operatorService.createFirstOperator(
      username: username,
      password: password,
    );

    if (!success) {
      setState(() {
        errorMessage =
            'İlk operatör oluşturulamadı.';
      });

      return;
    }

    // Oluşturulduktan sonra login ekranına geç.
    if (!mounted) return;

    Navigator.of(context).pop();

    await widget.operatorService.showLoginScreen(
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('İlk Kurulum'),
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
                  Icons.admin_panel_settings,
                  size: 64,
                ),

                const SizedBox(height: 24),

                const Text(
                  'İlk Operatörü Oluştur',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Uygulamayı kullanabilmek için '
                  'öncelikle bir operatör hesabı oluşturmalısınız.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                TextField(
                  controller: usernameController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,

                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı adı',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.next,

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

                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: passwordAgainController,
                  obscureText: obscurePasswordAgain,
                  onSubmitted: (_) => _createOperator(),

                  decoration: InputDecoration(
                    labelText: 'Şifre tekrar',
                    prefixIcon: const Icon(Icons.lock),

                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePasswordAgain =
                              !obscurePasswordAgain;
                        });
                      },

                      icon: Icon(
                        obscurePasswordAgain
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),

                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),

                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: _createOperator,

                    child: const Padding(
                      padding: EdgeInsets.all(14),

                      child: Text(
                        'Operatörü Oluştur',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
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