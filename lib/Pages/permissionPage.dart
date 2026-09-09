import 'package:app1/Theme/dashboard_theme.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

List<Permission> getPermissions(String boxName) {
  final box = Hive.box(boxName);
  final List<Permission> permissions = [];

  for (var key in box.keys) {
    final person = box.get(key);

    if (person != null) {
      permissions.add(
        Permission.fromMap(
          Map<dynamic, dynamic>.from(person),
        ),
      );
    }
  }

  return permissions;
}

final db = DatabaseService();

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  final TextEditingController nameController =
      TextEditingController();

  final box = Hive.box(permissionBox);

  List<Permission> permissions = [];

  int? editingIndex;

  @override
  void initState() {
    super.initState();

    permissions = getPermissions(permissionBox);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = nameController.text.trim();

    if (name.isEmpty) return;

    // EKLEME
    if (editingIndex == null) {
      final permission = Permission(
        id: DateTime.now()
            .millisecondsSinceEpoch
            .toString(),
        name: name,
      );

      await box.put(
        permission.id,
        Permission.toMap(permission),
      );

      await db.updateDB(
        path: "Permission/${permission.id}",
        data: Permission.toMap(permission),
      );

      if (!mounted) return;

      setState(() {
        permissions.add(permission);
        nameController.clear();
      });
    }

    // DÜZENLEME
    else {
      final permission = permissions[editingIndex!];

      permission.name = name;

      await box.put(
        permission.id,
        Permission.toMap(permission),
      );

      await db.updateDB(
        path: "Permission/${permission.id}",
        data: Permission.toMap(permission),
      );

      if (!mounted) return;

      setState(() {
        editingIndex = null;
        nameController.clear();
      });
    }
  }

  void _editPermission(int index) {
    setState(() {
      editingIndex = index;
      nameController.text = permissions[index].name;
    });
  }

  Future<void> _deletePermission(int index) async {
    final permissionID = permissions[index].id;

    await db.firebaseDatabase
        .ref()
        .child("Permission")
        .child(permissionID)
        .remove();

    await box.delete(permissionID);

    if (!mounted) return;

    setState(() {
      permissions.removeAt(index);

      if (editingIndex == index) {
        editingIndex = null;
        nameController.clear();
      } else if (editingIndex != null &&
          editingIndex! > index) {
        editingIndex = editingIndex! - 1;
      }
    });
  }

  void _cancelEditing() {
    setState(() {
      editingIndex = null;
      nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                // HEADER
                Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: GlassTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İzin Yönetimi',
                            style: TextStyle(
                              color:
                                  GlassTheme.textPrimary,
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'İzin verenleri ekle, düzenle ve yönet',
                            style: TextStyle(
                              color:
                                  GlassTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // PANELS
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // SOL PANEL
                    Expanded(
                      flex: 2,
                      child: GlassPanel(
                        title: editingIndex == null
                            ? 'İzin Bilgileri'
                            : 'İzni Düzenle',
                        icon: editingIndex == null
                            ? Icons.person_add_alt_1_rounded
                            : Icons.edit_rounded,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: nameController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                              cursorColor:
                                  GlassTheme.cyan,
                              decoration:
                                  InputDecoration(
                                labelText: 'Ad Soyad',
                                labelStyle:
                                    const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                floatingLabelStyle:
                                    const TextStyle(
                                  color:
                                      GlassTheme.cyan,
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                                prefixIcon:
                                    const Icon(
                                  Icons.person_outline_rounded,
                                  size: 19,
                                  color: Colors.white70,
                                ),
                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          12),
                                  borderSide:
                                      BorderSide(
                                    color: Colors.white
                                        .withOpacity(0.14),
                                  ),
                                ),
                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          12),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        GlassTheme.cyan,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => _save(),
                            ),

                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.end,
                              children: [
                                if (editingIndex != null)
                                  TextButton(
                                    onPressed:
                                        _cancelEditing,
                                    style:
                                        TextButton.styleFrom(
                                      foregroundColor:
                                          Colors.white70,
                                    ),
                                    child:
                                        const Text(
                                      'İptal',
                                      style:
                                          TextStyle(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),

                                const SizedBox(width: 8),

                                ElevatedButton.icon(
                                  onPressed: _save,
                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor:
                                        GlassTheme.cyan
                                            .withOpacity(
                                                0.12),
                                    foregroundColor:
                                        GlassTheme.cyan,
                                    elevation: 0,
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 16,
                                      vertical: 11,
                                    ),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(10),
                                      side: BorderSide(
                                        color: GlassTheme
                                            .cyan
                                            .withOpacity(
                                                0.22),
                                      ),
                                    ),
                                  ),
                                  icon: Icon(
                                    editingIndex == null
                                        ? Icons
                                            .person_add_alt_1_rounded
                                        : Icons
                                            .save_rounded,
                                    size: 17,
                                  ),
                                  label: Text(
                                    editingIndex == null
                                        ? 'Kaydet'
                                        : 'Güncelle',
                                    style:
                                        const TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // SAĞ PANEL
                    Expanded(
                      flex: 3,
                      child: GlassPanel(
                        title: 'İzinler',
                        icon: Icons.groups_rounded,
                        child: permissions.isEmpty
                            ? const Padding(
                                padding:
                                    EdgeInsets.symmetric(
                                  vertical: 28,
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons
                                            .person_off_rounded,
                                        color:
                                            GlassTheme
                                                .textSecondary,
                                        size: 28,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Henüz izinli kişi yok.',
                                        style: TextStyle(
                                          color: GlassTheme
                                              .textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (int i = 0;
                                      i <
                                          permissions
                                              .length;
                                      i++) ...[
                                    _PermissionTile(
                                      permission:
                                          permissions[i],
                                      isEditing:
                                          editingIndex ==
                                              i,
                                      onEdit: () =>
                                          _editPermission(
                                              i),
                                      onDelete: () =>
                                          _deletePermission(
                                              i),
                                    ),
                                    if (i !=
                                        permissions
                                                .length -
                                            1)
                                      Divider(
                                        height: 1,
                                        color: Colors.white
                                            .withOpacity(
                                                0.06),
                                      ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final Permission permission;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PermissionTile({
    required this.permission,
    required this.isEditing,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: isEditing
            ? GlassTheme.cyan.withOpacity(0.045)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: GlassTheme.cyan.withOpacity(0.07),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color:
                    GlassTheme.cyan.withOpacity(0.13),
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: GlassTheme.cyan,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              permission.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GlassTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            onPressed: onEdit,
            tooltip: 'Düzenle',
            splashRadius: 20,
            icon: const Icon(
              Icons.edit_rounded,
              size: 18,
              color: GlassTheme.textSecondary,
            ),
          ),

          IconButton(
            onPressed: onDelete,
            tooltip: 'Sil',
            splashRadius: 20,
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