import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddMemberPage extends StatefulWidget {
  const AddMemberPage({super.key});

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _formKey = GlobalKey<FormState>();

  final _groupController = TextEditingController();
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dormController = TextEditingController();
  final _supervisorController = TextEditingController();

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    DatabaseService databaseService = DatabaseService();

    final group = _groupController.text.trim().toUpperCase();
    final number = _numberController.text.trim();

    final key = "${group}_$number";

    Map<String, dynamic> st = {
      "Dorm": _dormController.text.trim(),
      "Group": group,
      "Name": _nameController.text.trim(),
      "Number": number,
      "Phone": _phoneController.text.trim(),
      "State": "Inside",
      "Supervisor": _supervisorController.text.trim(),
    };

    databaseService.updateDB(path: "Member/${group}_$number", data: st);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Member başarıyla eklendi."),
      ),
    );

    Navigator.pop(context);
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "$label boş bırakılamaz.";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _groupController.dispose();
    _numberController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dormController.dispose();
    _supervisorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Member"),
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  buildField(
                    controller: _groupController,
                    label: "Group",
                  ),
                  buildField(
                    controller: _numberController,
                    label: "Number",
                    keyboardType: TextInputType.number,
                  ),
                  buildField(
                    controller: _nameController,
                    label: "Name",
                  ),
                  buildField(
                    controller: _phoneController,
                    label: "Phone",
                    keyboardType: TextInputType.phone,
                  ),
                  buildField(
                    controller: _dormController,
                    label: "Dorm",
                  ),
                  buildField(
                    controller: _supervisorController,
                    label: "Supervisor",
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveMember,
                      icon: const Icon(Icons.save),
                      label: const Text("Kaydet"),
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