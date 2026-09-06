import 'package:app1/utils/auth_service.dart';
import 'package:app1/utils/database_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app1/utils/database_models.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState
    extends State<UserManagementScreen> {

  final box = Hive.box(userBox);

  void _addUser() {
    _showUserDialog();
  }

  void _editUser(User user) {
    _showUserDialog(user: user);
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kullanıcıyı Sil'),
          content: Text(
            '${user.username} kullanıcısını silmek istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await box.delete(user.id);

    await DatabaseService()
        .firebaseDatabase
        .ref()
        .child('User')
        .child(user.id)
        .remove();

    setState(() {});
  }

  void _showUserDialog({User? user}) {
    final usernameController =
        TextEditingController(text: user?.username ?? '');

    final passwordController =
        TextEditingController(text: user?.password ?? '');

    UserRole role =
        user?.role ?? UserRole.operator;

    final isEditing = user != null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Kullanıcıyı Düzenle'
                    : 'Kullanıcı Ekle',
              ),
              content: Column(
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
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    value: role,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.admin,
                        child: Text('Admin'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.operator,
                        child: Text('Operatör'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        role = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final username =
                        usernameController.text.trim();
                    final password =
                        passwordController.text;

                    if (username.isEmpty ||
                        password.isEmpty) {
                      return;
                    }

                    if (isEditing) {
                      final updatedUser = User(
                        id: user.id,
                        username: username,
                        password: password,
                        role: role,
                      );

                      final data =
                          User.toMap(updatedUser);

                      await box.put(
                        updatedUser.id,
                        data,
                      );

                      await DatabaseService()
                          .firebaseDatabase
                          .ref()
                          .child('User')
                          .child(updatedUser.id)
                          .set(data);
                    } else {
                      final newUser = User(
                        id: DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(),
                        username: username,
                        password: password,
                        role: role,
                      );

                      await AuthService.instance
                          .createUser(newUser);
                    }

                    if (!context.mounted) return;

                    Navigator.pop(context);

                    setState(() {});
                  },
                  child: Text(
                    isEditing ? 'Kaydet' : 'Ekle',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = box.values
        .map(
          (value) => User.fromMap(
            Map<dynamic, dynamic>.from(value),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        child: const Icon(Icons.add),
      ),
      body: users.isEmpty
          ? const Center(
              child: Text('Kullanıcı bulunamadı.'),
            )
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                return ListTile(
                  leading: Icon(
                    user.role == UserRole.admin
                        ? Icons.admin_panel_settings
                        : Icons.person,
                  ),
                  title: Text(user.username),
                  subtitle: Text(
                    user.role == UserRole.admin
                        ? 'Admin'
                        : 'Operatör',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _editUser(user),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () => _deleteUser(user),
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}