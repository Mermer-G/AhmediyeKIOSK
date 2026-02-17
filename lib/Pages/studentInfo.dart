import 'package:app1/Pages/settings.dart';
import 'package:app1/utils/database_models.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
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
      print("${st.state}");
      final entryMap = _dbService.readFromHive(path: st.entryID!.toString(), b: Hive.box(entryBox)); 
      if(entryMap == null){
        print("It was null");
        return;
      }
      print("Entry ID:${st.entryID}");
      entry = Entry.fromMap(entryMap);
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
              label: Text(
                st.state == null
                    ? "Belirsiz"
                    : st.state == "inside"
                        ? "İçeride"
                        : "Dışarıda"
              ),
            ),
          ],
        ),
      ),
    );
  }

  //────────────────────────────────
  // Entry window
  Future<bool> showEntry(BuildContext context, Student student) async {
    final List<String> reasons = [
      "Hastane",
      "Hizmet",
      "Sohbet",
      "Market",
      "Terzi",
      "Gecelik İzin",
      "Şehir Dışı",
      "Diğer...",
    ];

    // Eğer bugün pazar ise ekle
    if (DateTime.now().weekday == DateTime.sunday) {
      reasons.insert(0, "Pazar İzni"); 
    }

    final List<String> permisions = [
      "Ruçhan Emre Aksay",
      "Eren Kahraman",
      "Ahmet Hamza Boyacıoğlu",
      "İsmet Enes Tandoğaç",
      "Salih Çakır",
      "Ahmet Faruk Elemen",
      "Meiirbek Bakhtyiar",
      "Doğukan Işık",
    ];

    // Eğer bugün pazar ise ekle
    if (DateTime.now().weekday == DateTime.sunday) {
      permisions.insert(0, "Pazar İzni"); 
    }

    final otherReason = TextEditingController();
    String? selectedReason;
    String? selectedPermission;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Talebe Dışarı Çıkıyor",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Çıkış Tarihi:\n${formatDate(DateTime.now())}",
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),

                      const SizedBox(height: 12),

                      DropdownButton<String>(
                        value: selectedReason,
                        hint: const Text("Sebep seçiniz."),
                        isExpanded: true,
                        items: reasons.map((item) {
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

                      const SizedBox(height: 12),

                      DropdownButton<String>(
                        value: selectedPermission,
                        hint: const Text("İzin veren hocayı seçiniz."),
                        isExpanded: true,
                        items: permisions
                            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedPermission = value;
                          });
                        },
                      ),

                      if (selectedReason == "Diğer...")
                        TextField(
                          controller: otherReason,
                          decoration: const InputDecoration(
                            hintText: "Diğer sebebi giriniz...",
                          ),
                        ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("İptal"),
                          ),
                          ElevatedButton(
                            onPressed: () async{
                              if (selectedPermission == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Lütfen izin veren hocayı seçiniz."),
                                  ),
                                );
                                return; // ❗ işlemi iptal eder
                              }

                              if (selectedReason == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Lütfen sebep seçiniz."),
                                  ),
                                );
                                return;
                              }

                              if (selectedReason == "Diğer..." && otherReason.text == "") {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Lütfen diğer sebebi giriniz."),
                                  ),
                                );
                                return;
                              }




                              //Entry datası oluşturulur. 
                              final entryID = _dbService.createPushID(); 

                              Entry entry = Entry( 
                                entryID: entryID, 
                                group: student.group, 
                                number: student.number, 
                                name: student.name,
                                operator: "Entegre edilmedi!",
                                exitTime: DateTime.now().toString(), 
                                entryTime: null, 
                                permission: selectedPermission, 
                                reason: selectedReason,
                                otherReason: otherReason.text
                              ); 

                              //Entry Hive'a pushlanır. 
                              await _dbService.putToHive(
                                pushID: entryID.toString(), 
                                data: Entry.toMap(entry), 
                                b: Hive.box(entryBox)
                              ); 
                              
                              setState(() { 
                                student.entryID = entryID; 
                                student.state = STATEOUT; 
                                widget.student.entryID = entryID;
                              }); 

                              StudentState studentState = StudentState(
                                group: student.group, 
                                number: student.number, 
                                state: StudentStateEnum.values.byName(student.state!.toLowerCase()), 
                                lastEntryID: entryID
                              );

                              //StudentState güncellenecek.
                              _dbService.updateHive(
                                path: "${student.group}_${student.number}", 
                                data: StudentState.toMap(studentState), b: Hive.box(studentStateBox)
                              ); 
                              Navigator.pop(context, true); // ✅ başarılı
                            },
                            child: const Text("Kaydet"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
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
    final isInside = (st.state ?? "").toLowerCase() == STATEIN.toLowerCase();
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
                  ? "" : "Çıkış zamanı: ${DateTime.tryParse(entry == null ? "" : formatTimeString(entry!.exitTime))}\nİzin veren: ${entry == null  ? "" : entry!.permission}",
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
    if (st.state!.toLowerCase() == STATEOUT.toLowerCase()) {
      // Dışardayken direkt içeri gir


      setState(() {
        st.state = STATEIN;
        entry!.entryTime = DateTime.now().toString();
        widget.student.state = st.state;
      });

      _dbService.updateHive(path: st.entryID!.toString(), data: Entry.toMap(entry!), b: Hive.box(entryBox));

      StudentState studentState = StudentState(
        group: st.group, 
        number: st.number, 
        state: StudentStateEnum.values.byName(st.state!.toLowerCase()), 
        lastEntryID: null
      );

      _dbService.updateHive(path: "${st.group}_${st.number}", data: StudentState.toMap(studentState), b: Hive.box(studentStateBox));
      setState(() {
        st.entryID = null;
      });
      
      return;
    }

    // İçerideyse dışarı çıkış için onay al
    await showEntry(context, st);
  }

  void readEntryAndReload(Student st){
    final stud = _dbService.readFromHive(path: "${st.group}_${st.number}" ,b: Hive.box(studentBox));

    final realStud = Student.fromMap(stud!);
    if (realStud.entryID == null) {
      print("Student has no entry ID.");
      return;
    }

    final rawEntryData = _dbService.readFromHive(path: realStud.entryID!.toString(), b: Hive.box(entryBox));

    if (rawEntryData == null) {
      print("No entry found for ID in Hive: $st.entryID");
      return;
    }

    final entry = Entry.fromMap(rawEntryData);

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

