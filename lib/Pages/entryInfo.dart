import 'package:ahmediye_kiosk/utils/database_models.dart';
import 'package:ahmediye_kiosk/utils/database_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class EntryInfoPage extends StatefulWidget {
  final Entry entry;

  const EntryInfoPage({
    super.key,
    required this.entry,
  });

  @override
  State<EntryInfoPage> createState() => _EntryInfoPageState();
}

class _EntryInfoPageState extends State<EntryInfoPage> {
  late Student st;
  late Entry ent;

  void initializeFields() {
    DatabaseService dbService = DatabaseService();
    ent = widget.entry;
    setState(() {
      final raw = dbService.readFromHive(path: "${ent.group}_${ent.number}", b: Hive.box(studentBox));
      if (raw == null) {
        throw Exception("There is no student for this entry data!");
      }
      st = Student.fromFireBase(raw);
    });
  }

  @override
  void initState() {
    super.initState();
    initializeFields();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giris-Cikis Bilgileri"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _infoCard("Adi Soyadi:", st.name),
              _infoCard("Grubu:", ent.group.toString()),
              _infoCard("Numarasi:", ent.number.toString()),
              _infoCard("Cikis Sebebi:", ent.reason),
              _infoCard("Izin Alinan Hoca:", ent.permission),
              _infoCard("Cikis Zamani:", ent.exitTime.split('.')[0]),
              _infoCard("Giris Zamani:", (ent.entryTime == null || ent.entryTime == "") ? "Daha yurda giris yapmadi." : ent.entryTime!.split('.')[0]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String? value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value ?? "—"),
      ),
    );
  }
}
