import 'package:app1/Theme/dashboard_theme.dart';
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
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 440,
                ),
                child: GlassPanel(
                  title: isEditing
                      ? 'Kullanıcıyı Düzenle'
                      : 'Kullanıcı Ekle',
                  icon: isEditing
                      ? Icons.edit_rounded
                      : Icons.person_add_rounded,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: usernameController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: GlassTheme.cyan,
                        decoration: InputDecoration(
                          labelText: 'Kullanıcı adı',
                          labelStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: GlassTheme.cyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            size: 19,
                            color: Colors.white70,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.14),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: GlassTheme.cyan,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: GlassTheme.cyan,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          labelStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: GlassTheme.cyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 19,
                            color: Colors.white70,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.14),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: GlassTheme.cyan,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<UserRole>(
                        value: role,
                        dropdownColor: const Color(0xFF151D2E),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Rol',
                          labelStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: GlassTheme.cyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            size: 19,
                            color: Colors.white70,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.14),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: GlassTheme.cyan,
                              width: 1.2,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: UserRole.admin,
                            child: Text(
                              'Admin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: UserRole.operator,
                            child: Text(
                              'Operatör',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            role = value;
                          });
                        },
                      ),

                      const SizedBox(height: 22),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                            child: const Text(
                              'İptal',
                              style: TextStyle(
                                fontSize: 13,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  GlassTheme.cyan.withOpacity(0.14),
                              foregroundColor: GlassTheme.cyan,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: GlassTheme.cyan.withOpacity(0.22),
                                ),
                              ),
                            ),
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
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: GlassTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(width: 4),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kullanıcı Yönetimi',
                            style: TextStyle(
                              color: GlassTheme.textPrimary,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Sistem kullanıcılarını ve rollerini yönetin',
                            style: TextStyle(
                              color: GlassTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Kullanıcı ekle
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _addUser,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: GlassTheme.cyan.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: GlassTheme.cyan.withOpacity(0.18),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                color: GlassTheme.cyan,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Kullanıcı Ekle',
                                style: TextStyle(
                                  color: GlassTheme.cyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Kullanıcı listesi
                GlassPanel(
                  title: 'Kullanıcılar',
                  icon: Icons.people_alt_rounded,
                  child: users.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 28,
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person_off_rounded,
                                  size: 30,
                                  color: GlassTheme.textSecondary,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Kullanıcı bulunamadı.',
                                  style: TextStyle(
                                    color: GlassTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < users.length; i++) ...[
                              _UserTile(
                                user: users[i],
                                onEdit: () => _editUser(users[i]),
                                onDelete: () => _deleteUser(users[i]),
                              ),

                              if (i != users.length - 1)
                                Divider(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.06),
                                ),
                            ],
                          ],
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

class _UserTile extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserTile({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == UserRole.admin;

    final roleColor = isAdmin
        ? const Color(0xFFB388FF)
        : GlassTheme.cyan;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 12,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: roleColor.withOpacity(0.14),
              ),
            ),
            child: Icon(
              isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.person_rounded,
              color: roleColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Kullanıcı bilgisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    color: GlassTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: roleColor.withOpacity(0.12),
                    ),
                  ),
                  child: Text(
                    isAdmin ? 'Admin' : 'Operatör',
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Düzenle
          IconButton(
            onPressed: onEdit,
            tooltip: 'Düzenle',
            icon: const Icon(
              Icons.edit_rounded,
              size: 18,
              color: GlassTheme.textSecondary,
            ),
          ),

          // Sil
          IconButton(
            onPressed: onDelete,
            tooltip: 'Sil',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 19,
              color: Color(0xFFE57373),
            ),
          ),
        ],
      ),
    );
  }
}