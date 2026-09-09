import 'package:app1/Pages/settings.dart';
import 'package:app1/Theme/dashboard_theme.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:app1/utils/debugger.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class EntryInfoPage extends StatefulWidget {
  final Entry entry; // for showing data

  const EntryInfoPage({
    super.key,
    required this.entry,
  });

  @override
  State<EntryInfoPage> createState() => _EntryInfoPageState();
}

class _EntryInfoPageState extends State<EntryInfoPage> {
  late Member st;
  late Entry ent;

  void initializeFields() {
    DatabaseService _dbService = DatabaseService();
    ent = widget.entry;

    setState(() {
      // If possible get the lastPushID (this will come from lister page)
      // If not skip below
      final raw = _dbService.readFromHive(
        path: "${ent.group}_${ent.number}",
        b: Hive.box(memberBox),
      );

      if (raw == null) {
        AppLogger.instance.error(
          "There is no member for this entry data!",
        );
        throw Exception(
          "There is no member for this entry data!",
        );
      }

      st = Member.fromMap(raw);
    });
  }

  @override
  void initState() {
    super.initState();
    initializeFields();
  }

  @override
  Widget build(BuildContext context) {
    // Öğrenciyi çekecek,
    // Ad soyad, grup, numara, Çıkış tarihi, Giriş tarihi, sebep ve izin gösterecek

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
                // ─────────────────────────────
                // HEADER
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giriş - Çıkış Bilgileri',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Giriş ve çıkış kaydının detayları',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ─────────────────────────────
                // ENTRY ID
                GlassPanel(
                  title: 'Kayıt Bilgileri',
                  icon: Icons.receipt_long_rounded,
                  child: Column(
                    children: [
                      _infoCard(
                        "Giriş-Çıkış ID:",
                        ent.entryID.toString(),
                      ),
                      _infoCard(
                        "Adı Soyadı:",
                        st.name,
                      ),
                      _infoCard(
                        "Grubu:",
                        ent.group.toString(),
                      ),
                      _infoCard(
                        "Numarası:",
                        ent.number.toString(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─────────────────────────────
                // EXIT / ENTRY DETAILS
                GlassPanel(
                  title: 'Giriş - Çıkış Detayları',
                  icon: Icons.swap_vertical_circle_rounded,
                  child: Column(
                    children: [
                      _infoCard(
                        "Çıkış Sebebi:",
                        ent.reason,
                      ),
                      if (ent.reason == "Diğer...")
                        _infoCard(
                          "Diğer sebep:",
                          ent.otherReason,
                        ),
                      _infoCard(
                        "İzin Alınan Hoca:",
                        ent.permission,
                      ),
                      _infoCard(
                        "Çıkış Zamanı:",
                        formatDateTime(
                          DateTime.tryParse(ent.exitTime)!,
                        ),
                      ),
                      _infoCard(
                        "Giriş Zamanı:",
                        () {
                          if (ent.entryTime == null || ent.entryTime == "") {
                            return "Daha yurda giriş yapmadı.";
                          }

                          final date = DateTime.tryParse(ent.entryTime!);

                          if (date == null) {
                            return "Geçersiz giriş zamanı.";
                          }

                          return formatDateTime(date);
                        }(),
                      ),
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

  // ─────────────────────────────
  // BİLGİ SATIRI
  Widget _infoCard(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.035),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: SelectableText(
                value ?? "—",
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}