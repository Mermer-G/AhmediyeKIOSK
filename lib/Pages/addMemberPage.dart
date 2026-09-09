import 'package:app1/Theme/dashboard_theme.dart';
import 'package:app1/utils/database_service.dart';
import 'package:flutter/material.dart';

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

    final databaseService = DatabaseService();

    final group =
        _groupController.text.trim().toUpperCase();
    final number = _numberController.text.trim();

    final key = "${group}_$number";

    final Map<String, dynamic> st = {
      "Dorm": _dormController.text.trim(),
      "Group": group,
      "Name": _nameController.text.trim(),
      "Number": number,
      "Phone": _phoneController.text.trim(),
      "State": "Inside",
      "Supervisor": _supervisorController.text.trim(),
    };

    await databaseService.updateDB(
      path: "Member/$key",
      data: st,
    );

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
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: GlassTheme.cyan,
        textCapitalization: TextCapitalization.words,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "$label boş bırakılamaz.";
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
          floatingLabelStyle: const TextStyle(
            color: GlassTheme.cyan,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            icon,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.redAccent.withOpacity(0.55),
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 1.2,
            ),
          ),
          errorStyle: const TextStyle(
            color: Colors.redAccent,
            fontSize: 10,
          ),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color:
                            GlassTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yeni Üye',
                            style: TextStyle(
                              color: GlassTheme
                                  .textPrimary,
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Sisteme yeni bir üye kaydet',
                            style: TextStyle(
                              color: GlassTheme
                                  .textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // FORM
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 760,
                    ),
                    child: GlassPanel(
                      title: 'Üye Bilgileri',
                      icon: Icons.person_add_alt_1_rounded,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            // Üst satır
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: buildField(
                                    controller:
                                        _groupController,
                                    label: 'Grup',
                                    icon: Icons
                                        .groups_rounded,
                                  ),
                                ),
                                const SizedBox(
                                  width: 14,
                                ),
                                Expanded(
                                  child: buildField(
                                    controller:
                                        _numberController,
                                    label: 'Numara',
                                    icon: Icons
                                        .tag_rounded,
                                    keyboardType:
                                        TextInputType
                                            .number,
                                  ),
                                ),
                              ],
                            ),

                            // İsim
                            buildField(
                              controller:
                                  _nameController,
                              label: 'İsim',
                              icon: Icons
                                  .person_outline_rounded,
                            ),

                            // Telefon
                            buildField(
                              controller:
                                  _phoneController,
                              label: 'Telefon',
                              icon: Icons
                                  .phone_outlined,
                              keyboardType:
                                  TextInputType.phone,
                            ),

                            // Alt satır
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: buildField(
                                    controller:
                                        _dormController,
                                    label: 'Yatakhane',
                                    icon: Icons
                                        .home_outlined,
                                  ),
                                ),
                                const SizedBox(
                                  width: 14,
                                ),
                                Expanded(
                                  child: buildField(
                                    controller:
                                        _supervisorController,
                                    label: 'Sorumlu',
                                    icon: Icons
                                        .supervisor_account_outlined,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // BUTTON
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _saveMember,
                                  style:
                                      ElevatedButton
                                          .styleFrom(
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
                                      horizontal: 18,
                                      vertical: 12,
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
                                  icon: const Icon(
                                    Icons.save_rounded,
                                    size: 17,
                                  ),
                                  label: const Text(
                                    'Kaydet',
                                    style: TextStyle(
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