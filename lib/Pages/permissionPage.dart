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

  final box =
      Hive.box(permissionBox);

  List<Permission> permissions = [];

  int? editingIndex;

  @override
  void initState() {
    super.initState();

    permissions = getPermissions(permissionBox);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("İzinli Kişi Yönetimi"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Kişi Bilgileri",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(
                          labelText: "Ad Soyad",
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child:
                            ElevatedButton.icon(
                          icon:
                              const Icon(Icons.save),
                          label: Text(
                            editingIndex == null
                                ? "KAYDET"
                                : "GÜNCELLE",
                          ),
                          onPressed: () async {
                            // EKLEME
                            if (editingIndex == null) {
                              final permission = Permission(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                name: nameController.text,
                              );

                              await box.put(
                                permission.id,
                                Permission.toMap(permission),
                              );

                              await db.updateDB(
                                path: "Permission/${permission.id}",
                                data: Permission.toMap(permission),
                              );

                              setState(() {
                                permissions.add(permission);

                                editingIndex = null;
                                nameController.clear();
                              });
                            }

                            // DÜZENLEME
                            else {
                              final permission = permissions[editingIndex!];

                              permission.name = nameController.text;

                              await box.put(
                                permission.id,
                                Permission.toMap(permission),
                              );

                              await db.updateDB(
                                path: "Permission/${permission.id}",
                                data: Permission.toMap(permission),
                              );

                              setState(() {
                                editingIndex = null;
                                nameController.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Card(
                child: Column(
                  children: [
                    const SizedBox(height: 15),

                    const Text(
                      "İzinli Kişiler",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    Expanded(
                      child: ListView.builder(
                        itemCount:
                            permissions.length,
                        itemBuilder:
                            (context, index) {
                          return ListTile(
                            leading:
                                const Icon(
                              Icons.person,
                            ),
                            title: Text(
                              permissions[
                                      index]
                                  .name,
                            ),
                            trailing: Wrap(
                              children: [
                                IconButton(
                                  icon:
                                      const Icon(
                                    Icons.edit,
                                  ),
                                  onPressed:
                                      () {
                                    setState(
                                      () {
                                        editingIndex =
                                            index;

                                        nameController
                                                .text =
                                            permissions[
                                                    index]
                                                .name;
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon:
                                      const Icon(
                                    Icons.delete,
                                  ),
                                  onPressed: () async {
                                    final permissionID = permissions[index].id;

                                      await db.firebaseDatabase
                                        .ref()
                                        .child("Permission")
                                        .child(permissionID)
                                        .remove();

                                    await box.delete(permissionID);

                                    setState(() {
                                      permissions.removeAt(index);

                                      if (editingIndex == index) {
                                        editingIndex = null;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

