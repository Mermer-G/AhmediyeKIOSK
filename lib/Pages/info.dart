import 'package:flutter/material.dart';

class InfoPage extends StatefulWidget {
  final List<Map<String, String>> data;

  const InfoPage({
    super.key,
    required this.data,
  });

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  bool isInside = true;
  DateTime? lastActionTime;
  String? izinVerenHoca;

  /// Tek öğrenci
  Map<String, String> get student => widget.data.first;

  bool get hasPhone =>
      student["TELEFONU"] != null &&
      student["TELEFONU"]!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    lastActionTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Öğrenci Bilgileri"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// 🟦 KİMLİK
          _identityCard(),

          const SizedBox(height: 20),

          /// 🟨 BAĞLAM
          _infoCard("Yatakhane", student["YATAKHANESİ"]),
          _infoCard("Açıklama", student["Açıklama"]),

          const SizedBox(height: 20),

          /// 🟥 DURUM + BUTON
          _statusCard(),

          const SizedBox(height: 24),

          /// 🟩 İLETİŞİM
          _contactButtons(),
        ],
      ),
    );
  }

  // ────────────────────────────────
  // KİMLİK KARTI
  Widget _identityCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student["ADI SOYADI"] ?? "—",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("Grup: ${student["GRUBU"] ?? "—"}"),
            Text("Numara: ${student["NUMARASI"] ?? "—"}"),
            const SizedBox(height: 8),
            Chip(
              label: Text(student["DURUMU"] ?? "—"),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────
  // BİLGİ SATIRI
  Widget _infoCard(String title, String? value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value ?? "—"),
      ),
    );
  }

  // ────────────────────────────────
  // DURUM + İÇERİ / DIŞARI
  Widget _statusCard() {
    return Card(
      color: isInside ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isInside
                  ? "Öğrenci yurda giriş yaptı."
                  : "Öğrenci yurttan çıkış yaptı.",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isInside ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isInside
                  ? "Giriş zamanı: ${_formatTime(lastActionTime)}"
                  : "Çıkış zamanı: ${_formatTime(lastActionTime)}\nİzin veren: ${izinVerenHoca ?? "—"}",
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isInside ? Colors.red : Colors.green,
                ),
                onPressed: _toggleStatus,
                child: Text(isInside ? "Dışarı Çıkar" : "İçeri Al"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────
  // İLETİŞİM
  Widget _contactButtons() {
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: hasPhone ? "" : "Numara kayıtlı değil",
            child: ElevatedButton.icon(
              onPressed: hasPhone ? _call : null,
              icon: const Icon(Icons.call),
              label: const Text("Ara"),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Tooltip(
            message: hasPhone ? "" : "Numara kayıtlı değil",
            child: ElevatedButton.icon(
              onPressed: hasPhone ? _whatsapp : null,
              icon: const Icon(Icons.message),
              label: const Text("WhatsApp"),
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────
  // STATE
  void _toggleStatus() {
    setState(() {
      isInside = !isInside;
      lastActionTime = DateTime.now();
      if (!isInside) izinVerenHoca = "Ahmet Hoca"; // mock
    });
  }

  String _formatTime(DateTime? t) {
    if (t == null) return "—";
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  void _call() {
    // TODO: url_launcher tel:
  }

  void _whatsapp() {
    // TODO: whatsapp://send
  }
}
