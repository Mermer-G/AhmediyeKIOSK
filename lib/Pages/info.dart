import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/database_service.dart';
import 'package:firebase_database/firebase_database.dart';

class InfoPage extends StatefulWidget {
  final List<Map<String, String>> data;

  const InfoPage({
    super.key,
    required this.data,
  });

  @override
  State<InfoPage> createState() => _InfoPageState();
}

const STATEIN = "Inside";
const STATEOUT = "Outside";

class _InfoPageState extends State<InfoPage> {
  final dbService = DatabaseService();

  /// Tek öğrenci
  Map<String, String> get student => widget.data.first;
  late bool isInside;
  //TODO: These will change like the is inside and make a general method for these.
  DateTime? exitTime;
  String? reason;
  String? permission;
  Future<void> initializeFields() async {
    isInside = (student["State"]?.toLowerCase() == STATEIN.toLowerCase());
    
    //TODO: Get this to work with local data.
    //Entry içerisinde veriyi bul
    String path = "Entry/${student["Group"]}${student["Number"]}";
    String? futurePath = await dbService.getLastEntryKey(path);
    path = path + "/" + futurePath! + "/Exit";
    DataSnapshot? snapshot = await dbService.read(path: path);

    if (snapshot != null && snapshot.value != null) {
      String value = snapshot.value as String;

      exitTime = DateFormat("dd.MM.yyyy HH:mm").parse(value);
      print("exitTime: $exitTime");
    }
    else print("Could not get Exit Time");
    
    //TODO: Get this to work with local data.
    path = "Entry/${student["Group"]}${student["Number"]}";
    futurePath = await dbService.getLastEntryKey(path);
    path = path + "/" + futurePath! + "/Reason";
    snapshot = await dbService.read(path: path);

    if (snapshot != null && snapshot.value != null) {
      reason = snapshot.value as String;
      print("Reason: $reason");
    }
    else print("Could not get Reason");

    //TODO: Get this to work with local data.
    path = "Entry/${student["Group"]}${student["Number"]}";
    futurePath = await dbService.getLastEntryKey(path);
    path = path + "/" + futurePath! + "/Permission";
    snapshot = await dbService.read(path: path);

    if (snapshot != null && snapshot.value != null) {
      permission = snapshot.value as String;
      print("Permission: $permission");
    }
    else print("Could not get Reason");

    setState(() {});
  }

  bool get hasPhone =>
      student["Phone"] != null &&
      student["Phone"]!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    initializeFields();
    
  }

  @override
  Widget build(BuildContext context) {
    
    print("İsInside: $isInside");
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
          _infoCard("Yatakhane", student["Dorm"]),
          _infoCard("Açıklama", permission),

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
              student["Name"] ?? "—",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("Grup: ${student["Group"] ?? "—"}"),
            Text("Numara: ${student["Number"] ?? "—"}"),
            const SizedBox(height: 8),
            Chip(
              label: Text(student["State"] ?? "—"),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────
  // Entry window
  Future<bool> showEntry(BuildContext context, Map<String, String> data) async {
    final sebepCtrl = TextEditingController();
    final hocaCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Talebe Dışarı Çıkıyor"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Çıkış Tarihi:\n${DateTime.now()}",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: sebepCtrl,
                decoration: const InputDecoration(
                  labelText: "Sebep",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: hocaCtrl,
                decoration: const InputDecoration(
                  labelText: "İzin Alınan Hoca",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // ❌ iptal
              },
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                final kayit = {
                  "Group": data["Group"] ?? "",
                  "Number": data["Number"] ?? "",
                  "Exit": DateFormat("dd.MM.yyyy HH:mm").format(DateTime.now()),
                  "Entry": "",
                  "Reason": sebepCtrl.text,
                  "Permission": hocaCtrl.text,
                };

                final group = data["Group"] ?? "";
                final number = data["Number"] ?? "";
                String path = "Entry/$group$number";

                //Entry kaydı oluştur
                dbService.add(path: path, data: kayit);

                //Student içerisinde veriyi bul
                path = "STUDENT/${group}_$number";

                //State değiştir
                dbService.update(path: path, data: {"State": STATEOUT});

                reason = hocaCtrl.text;
                data["DURUMU"] = "Dışarıda";
                Navigator.pop(context, true); // ✅ başarılı
              },
              child: const Text("Çıkışı Kaydet"),
            ),
          ],
        );
      },
    );

  return result ?? false;
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
                  ? "Giriş zamanı: ${_formatTime(exitTime)}"
                  : "Çıkış zamanı: ${_formatTime(exitTime)}\nİzin veren: ${reason ?? "—"}",
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
  void _toggleStatus() async {
    if (!isInside) {
      // Dışardayken direkt içeri gir


      setState(() {
        isInside = true;
        student["State"] = STATEIN;
      });
        //Student içerisinde veriyi bul
        String? path = "STUDENT/${student["Group"]}_${student["Number"]}";

        //State değiştir
        dbService.update(path: path, data: {"State": STATEIN});

        //Entry içerisinde veriyi bul
        path = "Entry/${student["Group"]}${student["Number"]}";
        
        //State değiştir
        String? futurePath = await dbService.getLastEntryKey(path);
        path = path + "/" + futurePath!;

        dbService.updateNullable(path: path, data: {"Entry": DateFormat("dd.MM.yyyy HH:mm").format(DateTime.now())});
      return;
    }

    // İçerideyse dışarı çıkış için onay al
    bool apply = await showEntry(context, student);

    if (!apply) return; // Onay yoksa iptal et

    setState(() {
      // Dışarı çıkıyor
      isInside = false;
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
