import 'package:app1/utils/database_models.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/database_service.dart';
import '../utils/cache_revert_button.dart';

class StudentInfoPage extends StatefulWidget {
  final String? pushID; //for reading entry 
  final Student student; //for showing data

  const StudentInfoPage({
    super.key,
    required this.pushID,
    required this.student,
  });

  @override
  State<StudentInfoPage> createState() => _StudentInfoPageState();
}

const STATEIN = "Inside";
const STATEOUT = "Outside";



class _StudentInfoPageState extends State<StudentInfoPage> {
  final _dbService = DatabaseService();
  late Student st;
  Entry? entry;



  //Get state values from hive

  //TODO: These will change like the is inside and make a general method for these.
  @override
  void initState() {
    super.initState();
    initializeFields();
    
  }

  void initializeFields(){
    st = widget.student;
    DatabaseService _dbService = DatabaseService();
    setState(() {
      //If possible get the lastPushID (this will come from lister page)
      //If not skip below
      if(st.entryID == null){
        print("Student has no entry ID");
        return;
      } 

      final entryMap = _dbService.readFromHive(path: st.entryID!, b: Hive.box(entryBox)); 
      if(entryMap == null){
        print("It was null");
      }
      print("Entry ID:${st.entryID}");
      entry = Entry.fromFireBase(entryMap!);
      print("B");
    });
  }

  bool get hasPhone => st.phone != null;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Öğrenci Bilgileri"),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// 🟦 KİMLİK
              _identityCard(),

              const SizedBox(height: 20),

              /// 🟨 BAĞLAM
              _infoCard("Yatakhane", st.dorm),
              _infoCard("Açıklama", entry?.reason),

              const SizedBox(height: 20),

              /// 🟥 DURUM + BUTON
              _statusCard(),

              const SizedBox(height: 24),

              /// 🟩 İLETİŞİM
              _contactButtons(),
            ],
          ),

          /// 🔴 Floating cache kontrolü
          const CacheRevertButton(),
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
            Chip(
              label: Text(st.state),
            ),
          ],
        ),
      ),
    );
  }

  //────────────────────────────────
  // Entry window
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
              return AlertDialog(title: const Text("Talebe Dışarı Çıkıyor"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Çıkış Tarihi:\n${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}.${DateTime.now().second}",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
            
                  DropdownButton<String>(
                    value: selectedReason,
                    hint: const Text("Sebep Seçiniz."),
                    items: ["Hastane", "Hizmet", "Sohbet", "Diğer..."].map((item) {
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
            
            
                  if(selectedReason == "Diğer...")
                    TextField(
                    controller: sebepCtrl,
                    decoration: const InputDecoration(
                      labelText: "Lütfen izin sebebinizi açıklayın:",
                      border: OutlineInputBorder(),
                      ),
                    ),
                  if(selectedReason == "Diğer...")
                    const SizedBox(height: 10),
            
                  DropdownButton<String>(
                    value: selectedPermission,
                    hint: const Text("İzin alınan hocayı seçiniz."),
                    items: ["Ruçhan Emre Aksay", "Hamza BoyacıOğlu", "İsmet Enes Tandoğaç", "Eren Kahrman"].map((item) {
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
                    Navigator.pop(context, false); // ❌ iptal
                  },
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    //Entry datası oluşturulur.
                    final entryID = _dbService.createPushID();
                    Entry entry = Entry(
                      entryID: entryID,
                      group: student.group, 
                      number: student.number, 
                      exitTime: DateTime.now().toString(), 
                      entryTime: null, 
                      permission: selectedPermission, 
                      reason: selectedReason
                    );
                    //Entry Hive'a yazılır.
                    await _dbService.putToHive(pID: entryID, data: Entry.toFireBase(entry), b: Hive.box(entryBox));
            
                    setState(() {
                      student.entryID = entryID;
                      student.state = STATEOUT;
                      widget.student.entryID = entryID;
                    });
            
                    _dbService.updateHive(path: "${student.group}_${student.number}", data: Student.toFireBase(student), b: Hive.box(studentBox));
                    Navigator.pop(context, true); // ✅ başarılı
                  },
                  child: const Text("Çıkışı Kaydet"),
                ),
              ]
            );
          }
        );
      },
    );

  return result ?? false;
}
  
  // ────────────────────────────────
  // BİLGİ SATIRI
  Widget _infoCard(String title, String? value) {
    return value != null && value != "" ? Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
      ),
    ) : SizedBox();
  }

  // ────────────────────────────────
  // DURUM + İÇERİ / DIŞARI
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
                  ? "" : "Çıkış zamanı: ${formatTime(DateTime.tryParse(entry == null ? "" : entry!.exitTime))}\nİzin veren: ${entry == null  ? "" : entry!.permission}",
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      st.state == STATEIN ? Colors.red : Colors.green,
                ),
                onPressed: _toggleStatus,
                child: Text(st.state == STATEIN ? "Dışarı Çıkar" : "İçeri Al"),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:Colors.yellow,
                ),
                onPressed: () => addTestEntry(st),
                child: Text("Add test value to hive."),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                onPressed: () => readEntryAndReload(st),
                child: Text("Read the test values and update"),
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
    if (st.state == STATEOUT) {
      // Dışardayken direkt içeri gir


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

    // İçerideyse dışarı çıkış için onay al
    await showEntry(context, st);
  }

  Future<void> addTestEntry(Student st) async {
    final Entry entry = Entry(entryID: _dbService.createPushID(), group: st.group, number: st.number, exitTime: DateTime.now().toString(), entryTime: null, permission: "Test", reason: "Test Reason");
    final data = Entry.toFireBase(entry); 
    final lastEntryKey = entry.entryID;
    await _dbService.putToHive(pID: lastEntryKey, path: null, data: data, b: Hive.box(entryBox));
    setState(() {
      st.entryID = lastEntryKey;
      st.state = STATEOUT;
    });
    print("Entry for student : ${st.group}_${st.number} has been created under the ID: $lastEntryKey");
    final path = "${st.group}_${st.number}";
    await _dbService.updateHive(path: path, data: {entryIDDB: st.entryID}, b: Hive.box(studentBox));
    await _dbService.updateHive(path: path, data: {stateDB: st.state}, b: Hive.box(studentBox));
    print("Students Entry ID has been updated");
  }

  void readEntryAndReload(Student st){
    final stud = _dbService.readFromHive(path: "${st.group}_${st.number}" ,b: Hive.box(studentBox));

    final realStud = Student.fromFireBase(stud!);
    if (realStud.entryID == null) {
      print("Student has no entry ID.");
      return;
    }

    final rawEntryData = _dbService.readFromHive(path: realStud.entryID!, b: Hive.box(entryBox));

    if (rawEntryData == null) {
      print("No entry found for ID in Hive: $st.entryID");
      return;
    }

    final entry = Entry.fromFireBase(rawEntryData);

    print("Entry read successfully:");
    print("Group      : ${entry.group}");
    print("Number     : ${entry.number}");
    print("Entry Time : ${entry.entryTime}");
    print("Exit Time  : ${entry.exitTime}");
    print("Permission : ${entry.permission}");
    print("Reason     : ${entry.reason}");
    
    setState(() {
    });
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