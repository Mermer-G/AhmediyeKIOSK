import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class EntryInfoPage extends StatefulWidget {
  final Entry entry; //for showing data

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

  void initializeFields(){
    DatabaseService _dbService = DatabaseService();
    ent = widget.entry;
    setState(() {
      //If possible get the lastPushID (this will come from lister page)
      //If not skip below 
      final raw = _dbService.readFromHive(path: "${ent.group}_${ent.number}", b: Hive.box(studentBox)); 
      if (raw == null){
      print("AA");
        throw Exception("There is no student for this entry data!");
      }
      st = Student.fromMap(raw);
    });
  }

  @override
  void initState() {
    super.initState();
    initializeFields();
  }

  @override
  Widget build(BuildContext context) {
    //Öğrenciyi çekecek,
    //Ad soyad, grup, numara, Çıkış tarihi, Giriş tarihi, sebep ve izin gösterecek
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giriş-Çıkış Bilgileri"),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// 🟨 BAĞLAM
              _infoCard("Adı Soyadı:", st.name),
              _infoCard("Grubu:", ent.group.toString()),
              _infoCard("Numarası:", ent.number.toString()),
              _infoCard("Çıkış Sebebi:", ent.reason),
              _infoCard("İzin Alınan Hoca:", ent.permission),
              _infoCard("Çıkış Zamanı:", ent.exitTime.split('.')[0]),
              _infoCard("Giriş Zamanı:", (ent.entryTime == null || ent.entryTime == "") ? "Daha yurda giriş yapmadı." : ent.entryTime!.split('.')[0])
            ],
          ),
        ],
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
}
