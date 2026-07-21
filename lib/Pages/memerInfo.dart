import 'package:app1/Pages/entryInfo.dart';
import 'package:app1/Pages/home.dart';
import 'package:app1/Pages/permissionPage.dart';
import 'package:app1/Pages/reasonsPage.dart';
import 'package:app1/Pages/settings.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/debugger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/database_service.dart';

class MemberInfoPage extends StatefulWidget {
  final String? pushID; //for reading entry 
  final Member member; //for showing data

  const MemberInfoPage({
    super.key,
    required this.pushID,
    required this.member,
  });

  @override
  State<MemberInfoPage> createState() => _MemberInfoPageState();
}

bool isTimeInRange(
    TimeOfDay now,
    TimeOfDay start,
    TimeOfDay end,
) {
  final nowMinutes = now.hour * 60 + now.minute;
  final startMinutes = start.hour * 60 + start.minute;
  final endMinutes = end.hour * 60 + end.minute;

  return nowMinutes >= startMinutes &&
      nowMinutes <= endMinutes;
}

const STATEIN = "Inside";
const STATEOUT = "Outside";

class _MemberInfoPageState extends State<MemberInfoPage> {
  final _dbService = DatabaseService();
  late Member st;
  Entry? entry;



  //Get state values from hive

  //TODO: These will change like the is inside and make a general method for these.
  @override
  void initState() {
    super.initState();
    initializeFields();
  }

  void initializeFields(){
    st = widget.member;
    DatabaseService _dbService = DatabaseService();
    setState(() {
      //If possible get the lastPushID (this will come from lister page)
      //If not skip below
      if(st.entryID == null){
        AppLogger.instance.warn("Member has no entry ID");
        return;
      } 
      AppLogger.instance.warn("Member has state: ${st.state}");
      final entryMap = _dbService.readFromHive(path: st.entryID!.toString(), b: Hive.box(entryBox)); 
      if(entryMap == null){
        AppLogger.instance.warn("Member entry was null");
        return;
      }
      AppLogger.instance.warn("Entry ID:${st.entryID}");
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
              if(entry?.reason == "Diğer...") _infoCard("Diğer sebep:", entry?.otherReason),

              const SizedBox(height: 20),

              /// 🟥 DURUM + BUTON
              _statusCard(),

              const SizedBox(height: 24),

              /// 🟩 İLETİŞİM
              _contactButtons(),
            ],
          ),
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
  Future<bool> showEntry(BuildContext context, Member member) async {
    final List<Reason> reasons = getReasons(reasonBox); 
    final newReason = Reason();
    newReason.name = "Diğer...";
    newReason.days = [1,2,3,4,5,6,7];
    reasons.add(newReason);

    final now = TimeOfDay.now();
    final currentDay = DateTime.now().weekday; // 1-7

    
    final List<Permission> permisions = getPermissions(permissionBox); 

    final otherReason = TextEditingController();
    String? selectedReason = reasons.any((r) => r.name == HomePage.reason) ? HomePage.reason : null;
    String? selectedPermission = permisions.any((r) => r.name == HomePage.permission) ? HomePage.permission : null;
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
                        "Çıkış Tarihi:\n${formatDateTime(DateTime.now())}",
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),

                      const SizedBox(height: 12),

                      DropdownButton<String>(
                        value: selectedReason,
                        hint: const Text("Sebep seçiniz."),
                        isExpanded: true,
                        items: reasons
                              .where((reason) {

                                // Gün kontrolü
                                if (!reason.days.contains(currentDay)) {
                                  return false;
                                }

                                // Saat kontrolü
                                if(reason.startTime != null && reason.endTime != null){
                                  final start = stringToTimeOfDay(reason.startTime!);
                                  final end = stringToTimeOfDay(reason.endTime!);
                                  return isTimeInRange(now, start, end);
                                }
                                
                                return true;
                              })
                              .map((reason) {
                                return DropdownMenuItem<String>(
                                  value: reason.name,
                                  child: Text(reason.name),
                                );
                              })
                              .toList(),
                        onChanged: (value) {
                          setState(() {
                            HomePage.reason = value;
                          });
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
                            .map((item) => DropdownMenuItem(
                              value: item.name, 
                              child: Text(item.name)
                              ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            HomePage.permission = value;
                          });
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

                              entry = Entry( 
                                entryID: entryID, 
                                group: member.group, 
                                number: member.number, 
                                name: member.name,
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
                                data: Entry.toMap(entry!), 
                                b: Hive.box(entryBox)
                              ); 
                              
                              setState(() { 
                                member.entryID = entryID; 
                                member.state = STATEOUT; 
                                widget.member.entryID = entryID;
                              }); 

                              MemberState memberState = MemberState(
                                group: member.group, 
                                number: member.number, 
                                state: MemberStateEnum.values.byName(member.state!.toLowerCase()), 
                                lastEntryID: entryID
                              );

                              //MemberState güncellenecek.
                              await _dbService.updateHive(
                                path: "${member.group}_${member.number}", 
                                data: MemberState.toMap(memberState), b: Hive.box(memberStateBox)
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
            if (entry != null) ...[
              Text(
                st.state == STATEIN
                    ? ""
                    : "Çıkış zamanı: ${formatDateTime(DateTime.tryParse(entry!.exitTime)!)}\nİzin veren: ${entry!.permission}",
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () => _openEntryInfo(entry),
                  child: Text("Giriş Çıkış Bilgilerini Görüntüle."),
                ),
              ),
            ],
            if (!kIsWeb) const SizedBox(height: 16),
            if (!kIsWeb)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInside ? Colors.red : Colors.green,
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
  void _openEntryInfo(Entry? entry) async{
    if (entry == null){
      AppLogger.instance.error("Entry was null");
      return;
    }
    AppLogger.instance.log("Member Info'dan --> Entry Info'ya geçildi");
    await Navigator.push(context, MaterialPageRoute(builder: (context) => EntryInfoPage(entry: entry))); // yeni info page gelecek buraya.
  }

  void _toggleStatus() async {
    if (st.state!.toLowerCase() == STATEOUT.toLowerCase()) {
      // Dışardayken direkt içeri gir

      setState(() {
        st.state = STATEIN;
        entry!.entryTime = DateTime.now().toString();
        widget.member.state = st.state;
      });

      _dbService.updateHive(path: st.entryID!.toString(), data: Entry.toMap(entry!), b: Hive.box(entryBox));

      MemberState memberState = MemberState(
        group: st.group, 
        number: st.number, 
        state: MemberStateEnum.values.byName(st.state!.toLowerCase()), 
        lastEntryID: null
      );

      _dbService.updateHive(path: "${st.group}_${st.number}", data: MemberState.toMap(memberState), b: Hive.box(memberStateBox));
      setState(() {
        st.entryID = null;
      });
      
      return;
    }

    // İçerideyse dışarı çıkış için onay al
    await showEntry(context, st);
  }




  void readEntryAndReload(Member st){
    final stud = _dbService.readFromHive(path: "${st.group}_${st.number}" ,b: Hive.box(memberBox));

    final realStud = Member.fromMap(stud!);
    if (realStud.entryID == null) {
      AppLogger.instance.warn("Member has no entry ID.");
      return;
    }

    final rawEntryData = _dbService.readFromHive(path: realStud.entryID!.toString(), b: Hive.box(entryBox));

    if (rawEntryData == null) {
      AppLogger.instance.warn("No entry found for ID in Hive: $st.entryID");
      return;
    }

    final entry = Entry.fromMap(rawEntryData);

    AppLogger.instance.log("Entry read successfully:");
    AppLogger.instance.log("Group      : ${entry.group}");
    AppLogger.instance.log("Number     : ${entry.number}");
    AppLogger.instance.log("Entry Time : ${entry.entryTime}");
    AppLogger.instance.log("Exit Time  : ${entry.exitTime}");
    AppLogger.instance.log("Permission : ${entry.permission}");
    AppLogger.instance.log("Reason     : ${entry.reason}");
    
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

