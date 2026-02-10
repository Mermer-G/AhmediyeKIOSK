import 'package:ahmediye_kiosk/Pages/entryList.dart';
import 'package:ahmediye_kiosk/Pages/passwordPage.dart';
import 'package:ahmediye_kiosk/Pages/studentInfo.dart';
import 'package:ahmediye_kiosk/utils/database_models.dart';
import 'package:ahmediye_kiosk/utils/database_service.dart';
import 'package:ahmediye_kiosk/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'studentList.dart';
import 'dart:async';

String settingsPassword = "365";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _currentTime;
  Timer? _timer;
  int outsideCount = 0;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}";

      outsideCount = Hive.box(studentBox)
        .values
        .where((s) => Map.from(s)[stateDB] == STATEOUT)
        .length;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _buildNavButton(
          icon: Icons.list_alt_rounded,
          label: "Talebe Listesi",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentListerPage())),
        ),
        _buildNavButton(
          icon: Icons.list_alt_rounded,
          label: "Giris-Cikis\nListesi",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => entryListerPage())),
        ),
        _buildNavButton(
          icon: Icons.settings,
          label: "Ayarlar",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PasswordPage())),
        ),
      ],
    );
  }

  Widget _buildInfoPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          _currentTime,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            outsideCount > 0
                ? "Disaridaki Talebe Sayisi: $outsideCount"
                : "Disarida ogrenci yok",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                "Nobetci Hoca: Daha uygulamaya eklenmedi",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);

    return Scaffold(
      appBar: appBarM(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: compact
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    _buildButtons(),
                    const SizedBox(height: 24),
                    _buildInfoPanel(),
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16, right: 16),
                        child: _buildButtons(),
                      ),
                    ),
                  ),
                  Expanded(child: _buildInfoPanel()),
                ],
              ),
      ),
    );
  }

  AppBar appBarM() {
    return AppBar(
      centerTitle: true,
      elevation: 10.0,
      title: const Text(
        'Ahmediye K.I.O.S.K',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: const Color.fromARGB(255, 90, 90, 90),
    );
  }
}
