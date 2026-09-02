import 'package:app1/utils/database_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Kendi dosya yollarına göre düzenle
import 'package:app1/utils/database_models.dart';

class OperatorManagementScreen extends StatefulWidget {
  const OperatorManagementScreen({super.key});

  @override
  State<OperatorManagementScreen> createState() =>
      _OperatorManagementScreenState();
}

class _OperatorManagementScreenState
    extends State<OperatorManagementScreen> {

  late Box box;

  @override
  void initState() {
    super.initState();

    box = Hive.box(operatorBox);
  }

  List<Operator> get operators {
    return box.values
        .map(
          (value) => Operator.fromMap(
            Map<dynamic, dynamic>.from(value),
          ),
        )
        .toList();
  }

  bool _usernameExists(
    String username, {
    String? exceptID,
  }) {
    final normalizedUsername = username.trim().toLowerCase();

    return operators.any(
      (operator) =>
          operator.id != exceptID &&
          operator.username.trim().toLowerCase() == normalizedUsername,
    );
  }

  Future<Map<String, String>?> _showOperatorDialog({
    Operator? operator,
  }) async {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return _OperatorDialog(
          operator: operator,
        );
      },
    );
  }

  Future<void> _addOperator() async {
    final result = await _showOperatorDialog();

    if (result == null) return;

    final username = result['username']!;
    final password = result['password']!;

    if (_usernameExists(username)) {
      _showError('Bu kullanıcı adı zaten kullanılıyor.');
      return;
    }

    final operator = Operator(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      password: password,
    );

    await box.put(
      operator.id,
      Operator.toMap(operator),
    );

    setState(() {});
  }

  Future<void> _editOperator(Operator operator) async {
    final result = await _showOperatorDialog(
      operator: operator,
    );

    if (result == null) return;

    final username = result['username']!;
    final password = result['password']!;

    if (_usernameExists(
      username,
      exceptID: operator.id,
    )) {
      _showError('Bu kullanıcı adı zaten kullanılıyor.');
      return;
    }

    final updatedOperator = Operator(
      id: operator.id,
      username: username,
      password: password,
    );

    await box.put(
      operator.id,
      Operator.toMap(updatedOperator),
    );

    setState(() {});
  }

  Future<void> _deleteOperator(Operator operator) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Operatörü Sil'),
          content: Text(
            '"${operator.username}" adlı operatörü silmek istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await box.delete(operator.id);

    setState(() {});
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
    final operatorList = operators;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operatör Yönetimi'),
      ),

      body: operatorList.isEmpty
          ? const Center(
              child: Text(
                'Henüz kayıtlı operatör bulunmuyor.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: operatorList.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final operator = operatorList[index];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),

                    title: Text(
                      operator.username,
                    ),

                    subtitle: const Text(
                      'Operatör',
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Düzenle',
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _editOperator(operator);
                          },
                        ),

                        IconButton(
                          tooltip: 'Sil',
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _deleteOperator(operator);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addOperator,
        icon: const Icon(Icons.add),
        label: const Text('Operatör Ekle'),
      ),
    );
  }
}

class _OperatorDialog extends StatefulWidget {
  final Operator? operator;

  const _OperatorDialog({
    this.operator,
  });

  @override
  State<_OperatorDialog> createState() => _OperatorDialogState();
}

class _OperatorDialogState extends State<_OperatorDialog> {
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;

  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();

    usernameController = TextEditingController(
      text: widget.operator?.username ?? '',
    );

    passwordController = TextEditingController(
      text: widget.operator?.password ?? '',
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  void _save() {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      return;
    }

    Navigator.pop(
      context,
      {
        'username': username,
        'password': password,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.operator != null;

    return AlertDialog(
      title: Text(
        isEditing
            ? 'Operatörü Düzenle'
            : 'Operatör Ekle',
      ),

      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı adı',
                prefixIcon: Icon(Icons.person),
              ),
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
                      obscurePassword = !obscurePassword;
                    });
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('İptal'),
        ),

        ElevatedButton(
          onPressed: _save,
          child: Text(
            isEditing ? 'Kaydet' : 'Ekle',
          ),
        ),
      ],
    );
  }
}
