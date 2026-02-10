import 'package:ahmediye_kiosk/utils/database_models.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/database_service.dart';
import '../utils/cache_revert_button.dart';

class StudentInfoPage extends StatefulWidget {
  final String? pushID;
  final Student student;

  const StudentInfoPage({
    super.key,
    required this.pushID,
    required this.student,
  });

  @override
  State<StudentInfoPage> createState() => _StudentInfoPageState();
}

class _StudentInfoPageState extends State<StudentInfoPage> {
  final _dbService = DatabaseService();
  late Student st;
  Entry? entry;

  @override
  void initState() {
    super.initState();
    initializeFields();
  }

  void initializeFields() {
    st = widget.student;
    DatabaseService dbService = DatabaseService();
    setState(() {
      if (st.entryID == null) return;
      final entryMap = dbService.readFromHive(path: st.entryID!, b: Hive.box(entryBox));
      if (entryMap == null) return;
      entry = Entry.fromFireBase(entryMap);
    });
  }

  bool get hasPhone => st.phone != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ogrenci Bilgileri"),
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _identityCard(),
                  const SizedBox(height: 20),
                  _infoCard("Yatakhane", st.dorm),
                  _infoCard("Aciklama", entry?.reason),
                  const SizedBox(height: 20),
                  _statusCard(),
                  const SizedBox(height: 24),
                  _contactButtons(),
                ],
              ),
            ),
          ),
          const CacheRevertButton(),
        ],
      ),
    );
  }

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
              st.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("Grup: ${st.group}"),
            Text("Numara: ${st.number}"),
            const SizedBox(height: 8),
            Chip(label: Text(st.state)),
          ],
        ),
      ),
    );
  }

  Future<bool> showEntry(BuildContext context, Student student) async {
    final sebepCtrl = TextEditingController();
    String? selectedReason;
    String? selectedPermission;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Talebe Disari Cikiyor"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Cikis Tarihi:\n${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}.${DateTime.now().second}",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: selectedReason,
                    hint: const Text("Sebep Seciniz."),
                    items: ["Hastane", "Hizmet", "Sohbet", "Diger..."].map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedReason = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (selectedReason == "Diger...")
                    TextField(
                      controller: sebepCtrl,
                      decoration: const InputDecoration(
                        labelText: "Lutfen izin sebebinizi aciklayin:",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  if (selectedReason == "Diger...")
                    const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedPermission,
                    hint: const Text("Izin alinan hocayi seciniz."),
                    items: ["Ruchan Emre Aksay", "Hamza BoyaciOglu", "Ismet Enes Tandogac", "Eren Kahrman"].map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPermission = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text("Iptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final entryID = _dbService.createPushID();
                    Entry entry = Entry(
                      entryID: entryID,
                      group: student.group,
                      number: student.number,
                      exitTime: DateTime.now().toString(),
                      entryTime: null,
                      permission: selectedPermission,
                      reason: selectedReason,
                    );
                    await _dbService.putToHive(pID: entryID, data: Entry.toFireBase(entry), b: Hive.box(entryBox));

                    setState(() {
                      student.entryID = entryID;
                      student.state = STATEOUT;
                      widget.student.entryID = entryID;
                    });

                    _dbService.updateHive(path: "${student.group}_${student.number}", data: Student.toFireBase(student), b: Hive.box(studentBox));
                    Navigator.pop(context, true);
                  },
                  child: const Text("Cikisi Kaydet"),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  Widget _infoCard(String title, String? value) {
    return value != null && value != ""
        ? Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(title),
              subtitle: Text(value),
            ),
          )
        : const SizedBox();
  }

  Widget _statusCard() {
    return Card(
      color: st.state == STATEIN ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              st.state == STATEIN
                  ? ""
                  : "Cikis zamani: ${formatTime(DateTime.tryParse(entry == null ? "" : entry!.exitTime))}\nIzin veren: ${entry == null ? "" : entry!.permission}",
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: st.state == STATEIN ? Colors.red : Colors.green,
                ),
                onPressed: _toggleStatus,
                child: Text(st.state == STATEIN ? "Disari Cikar" : "Iceri Al"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        Tooltip(
          message: hasPhone ? "" : "Numara kayitli degil",
          child: ElevatedButton.icon(
            onPressed: hasPhone ? _call : null,
            icon: const Icon(Icons.call),
            label: const Text("Ara"),
          ),
        ),
        Tooltip(
          message: hasPhone ? "" : "Numara kayitli degil",
          child: ElevatedButton.icon(
            onPressed: hasPhone ? _whatsapp : null,
            icon: const Icon(Icons.message),
            label: const Text("WhatsApp"),
          ),
        ),
      ],
    );
  }

  void _toggleStatus() async {
    if (st.state == STATEOUT) {
      setState(() {
        st.state = STATEIN;
        entry!.entryTime = DateTime.now().toString();
        widget.student.state = STATEIN;
      });

      _dbService.updateHive(path: st.entryID!, data: Entry.toFireBase(entry!), b: Hive.box(entryBox));
      _dbService.updateHive(path: "${st.group}_${st.number}", data: Student.toFireBase(st), b: Hive.box(studentBox));
      setState(() {
        st.entryID = null;
      });

      return;
    }

    await showEntry(context, st);
  }

  void _call() {
    // TODO: url_launcher tel:
  }

  void _whatsapp() {
    // TODO: whatsapp://send
  }
}

String formatTime(DateTime? t) {
  if (t == null) return "—";
  return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
}
