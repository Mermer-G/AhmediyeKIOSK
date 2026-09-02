import 'package:app1/Pages/addMemberPage.dart';
import 'package:app1/Pages/entryList.dart';
import 'package:app1/Pages/generalStatusPage.dart';
import 'package:app1/Pages/passwordPage.dart';
import 'package:app1/Pages/permissionPage.dart';
import 'package:app1/Pages/reasonsPage.dart';
import 'package:app1/Pages/memberInfo.dart';
import 'package:app1/utils/command.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:app1/utils/debugger.dart';
import 'package:app1/utils/offline_queue.dart';
import 'package:app1/utils/synchronizer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'memberList.dart';
import 'package:app1/Pages/queuePage.dart';
import 'dart:async';

String settingsPassword = "365";
int lastTimeStamp = 0;
ValueNotifier membersValueListener = ValueNotifier<List<Member>>([]);

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static String? permission;
  static String? reason;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentTime = "0";
  Timer? _timer;
  Map<String, int> groupAndOutside = {};
  late Map<String, Member> memberMap = {};
  

  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  final List<String> logs = []; // Logların tutulduğu liste
  final CommandListener _commandListener = CommandListener();

  Future<void> _initialize() async {
    AppLogger.instance.log("INIT STARTED IN HOME PAGE");

    try {
      // 1. HIVE KONTROLÜ
      AppLogger.instance.log("BEFORE HIVE: MetaBox erişimi deneniyor...");
      final box = Hive.box(metaBox); 
      // Eğer box açık değilse yukarıdaki satır direkt hata fırlatır.
      
      lastTimeStamp = box.get("lastEntryTimestamp") ?? 0;
      AppLogger.instance.log("HIVE OK. LastTS: $lastTimeStamp");

      // 2. TIMER KONTROLÜ
      AppLogger.instance.log("BEFORE TIMER");
      _updateTime();
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateTime(),
      );
      AppLogger.instance.log("TIMER STARTED");

      AppLogger.instance.log("BEFORE SYNC: Synchronizer().start() çağırılıyor...");
      await Synchronizer().start();
      AppLogger.instance.log("AFTER SYNC: Senkronizasyon başarılı.");

      // 4. VERİ ÇEKME
      AppLogger.instance.log("BEFORE MEMBERS: Hive'dan öğrenci verileri...");
      await _fetchMemberDataFromHive();
      AppLogger.instance.log("MEMBERS DATA FETCHED");

      AppLogger.instance.log("BEFORE STATES: Durum verileri çekiliyor...");
      await _fetchMemberStateDataFromHive();
      AppLogger.instance.log("STATES DATA FETCHED");

      // 5. MERGE
      AppLogger.instance.log("MERGE: Veriler birleştiriliyor...");
      mergeMemberData();
      AppLogger.instance.log("MERGE DONE");

      QueueHelper().syncQueue();
      AppLogger.instance.log("OFFLINE SYNC: Kuyruk senkronize edildi.");

      if(!kIsWeb){
        _commandListener.start();
        AppLogger.instance.log("COMMAND LISTENER: Komutlar dinleniyor.");
      }

      AppLogger.instance.log("ALL INIT DONE - Uygulama hazır. \n \n \n");

    } catch (e, stack) {
      // Herhangi bir "Null check" veya "Firebase error" olursa buraya düşer
      AppLogger.instance.log("HATA YAKALANDI: $e");
      AppLogger.instance.log("Hata Kaynağı: ${stack.toString().split('\n').first}"); 
      // Stack trace'in en başındaki satır hatanın dosya ve satır nosunu verir.
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 700;

        return Scaffold(
          appBar: appBarM(),

          // 📱 DAR EKRAN → DRAWER VAR
          drawer: isWide
              ? null
              : Drawer(
                  width: 150,
                  child: SafeArea(
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        menuButtons(context, isWide),
                      ],
                    ),
                  ),
                ),

          body: Padding(
            padding: const EdgeInsets.all(20),
            child: isWide
                ? Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: menuButtons(context, isWide),
                        ),
                      ),
                      Expanded(child: notificationsArea()),
                    ],
                  )
                : Center(child: notificationsArea()), // 📱 Telefonda sadece içerik
          ),
        );
      },
    );
  }

  //this will change into both member and memberState or maybe 2 methods
  Future<void> _fetchMemberDataFromHive() async{
    try {
      AppLogger.instance.log('===== VERİ ÇEKME BAŞLADI: Member =====');
      final rawMap = Hive.box(memberBox).toMap();
      
      rawMap.forEach((k,v){
        Map<String, dynamic> valuesMap = Map<String, dynamic>.from(v as Map);
        final member = Member.fromMap(valuesMap);
        memberMap["${member.group}_${member.number}"] = member;

        AppLogger.instance.log("Added member for: ${member.group}_${member.number}");
      });
    } 
      
    catch (e, stack) {
      AppLogger.instance.error("HATA: $e");
      AppLogger.instance.error(stack.toString());
    }
  }

  Future<void> _fetchMemberStateDataFromHive() async{
    try {
      AppLogger.instance.log('===== VERİ ÇEKME BAŞLADI: MemberState =====');
      final rawMap = Hive.box(memberStateBox).toMap();
      
      AppLogger.instance.log("Rawmap has: ${rawMap.length} elements");

      rawMap.forEach((k,v){
        Map<String, dynamic> valuesMap = Map<String, dynamic>.from(v as Map);
        final state = MemberState.fromMap(valuesMap);

        final key = "${state.group}_${state.number}";

        if (memberMap.containsKey(key)) {
          memberMap[key]!.state = state.state.name;
          memberMap[key]!.entryID = state.lastEntryID;
        } else {
          AppLogger.instance.error("⚠ STATE GELDİ AMA MEMBER YOK: $key");
        }
        
        AppLogger.instance.log("Added member state for ${state.group}_${state.number} State: ${state.state}, entry id: ${state.lastEntryID}");
      });
    } 
      
    catch (e, stack) {
      AppLogger.instance.error("HATA: $e");
      AppLogger.instance.error(stack.toString());
    }
  }

  void mergeMemberData(){
    memberMap.forEach((key, member) {
      member.state ??= MemberStateEnum.inside.name;
    });
    membersValueListener.value = memberMap.values.toList();
  }

  void _updateTime() {
    if (!mounted) return;   // ✅ KRİTİK

    final now = DateTime.now();
    setState(() {
      _currentTime =
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}";
    });
  }

  void countOutsideByGroup(List<Member> members) {
    groupAndOutside.clear();
    for (var i = 0; i < members.length; i++) {
      //First time adding to the map.
      if (!groupAndOutside.containsKey(members[i].group)){
        groupAndOutside[members[i].group] = members[i].state == STATEOUT.toLowerCase() ? 1 : 0; 
      }

      else{
        groupAndOutside[members[i].group] = members[i].state == STATEIN.toLowerCase() 
        ? 
        groupAndOutside[members[i].group]! //Buraya hiç gelmiyor 
        : 
        groupAndOutside[members[i].group]! + 1;  //Buraya hep geliyor.
        //102 öğrencinin hepsi de alt satıra giriyor. Üst satıra giren 3 öğrenci olmalıydı.
      }
      
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
    if(!kIsWeb){
      _commandListener.stop();
    }
  }

  AppBar appBarM() {
    return AppBar(
      centerTitle: true,
      elevation: 10.0,
      title: Text(
        'Ahmediye K.I.O.S.K',
        style: TextStyle(
          color: Colors.white
        ),
        ),
      backgroundColor: const Color.fromARGB(255, 90, 90, 90),
    );
  }

  Widget menuButtons(BuildContext context, bool isWide) {
    return !isWide ?  Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _menuButton(
          icon: Icons.list_alt_rounded,
          text: "Talebe Listesi",
          onTap: () { 
            AppLogger.instance.log("Talebe Listesi'ne tıklandı.");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MemberListerPage(members: membersValueListener.value, sortColumnIndex: 1, sortAscending: true, groupFilter: ""),),
            );
          }
        ),
        const SizedBox(height: 12),
        _menuButton(
          icon: Icons.list_alt_rounded,
          text: "Giriş-Çıkış Listesi",
          onTap: () {
            AppLogger.instance.log("Giriş-Çıkış Listesi'ne tıklandı.");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => entryListerPage()),
            );
          }
        ),
        const SizedBox(height: 12),
        _menuButton(
          icon: Icons.settings,
          text: "Ayarlar",
          onTap: () {
            AppLogger.instance.log("Ayarlar'a tıklandı.");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PasswordPage()),
            );
          }
        ),
        const SizedBox(height: 12),
        _menuButton(
          icon: Icons.settings,
          text: "Ayarlar",
          onTap: () {
            AppLogger.instance.log("Ayarlar'a tıklandı.");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddMemberPage()),
            );
          }
        ),
      ],
    ) : 
    Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _menuButton(
          icon: Icons.list_alt_rounded,
          text: "Talebe Listesi",
          onTap: () { 
            AppLogger.instance.log("Talebe Listesi'ne tıklandı.");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MemberListerPage(members: membersValueListener.value, sortColumnIndex: 1, sortAscending: true, groupFilter: ""),),
            );
          }
        ),
        
        _menuButton(
          icon: Icons.list_alt_rounded,
          text: "Giriş-Çıkış Listesi",
          onTap: () {
            AppLogger.instance.log("Giriş-Çıkış Listesi'ne tıklandı.");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => entryListerPage()),
            );
          }
        ),
        
        _menuButton(
          icon: Icons.settings,
          text: "Ayarlar",
          onTap: () {
            AppLogger.instance.log("Ayarlar'a tıklandı.");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PasswordPage()),
            );
          }
        ),
        
        _menuButton(
        icon: Icons.sync,
        text: "Sync Queue",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const QueuePage(),
            ),
          );
        },
      ),
      
        _menuButton(
          icon: Icons.person,
          text: "Üye ekle",
          onTap: () {
            AppLogger.instance.log("Üye ekleye tıklandı.");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddMemberPage()),
            );
          }
        ),
        
        _menuButton(
          icon: Icons.rule,
          text: "Sebepler",
          onTap: () {
            AppLogger.instance.log("Sebepler menüsüne tıklandı.");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReasonPage()),
            );
          }
        ),

        _menuButton(
          icon: Icons.check_box,
          text: "İzinler",
          onTap: () {
            AppLogger.instance.log("İzinler menüsüne tıklandı.");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PermissionPage()),
            );
          }
        ),

        _menuButton(
          icon: Icons.graphic_eq_rounded,
          text: "Durum Bilgisi",
          onTap: () {
            AppLogger.instance.log("Durum menüsüne tıklandı.");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GeneralStatusPage()),
            );
          }
        ),
      ],
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String text,
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
                const SizedBox(height: 6),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget notificationsArea() {
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
        buildOutsideButtons(context, membersValueListener.value),
        const SizedBox(height: 16),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline),
            SizedBox(width: 6),
            Text("Nöbetçi Hoca: Daha eklenmedi"),
          ],
        ),
      ],
    );
  }

  //Bu method dinamik olacak. Yapacakları:
  //Grupları oku ve kaç grup olduğunu bul.
  //Bu gruplardan kaç kişinin dışarıda olduğunu bul.
  //Bu bilgileri birer buton oluştur ve göster.
  //Butona tıklayınca sorted ve filtered bir şekilde listeyi aç.
  Widget buildOutsideButtons(BuildContext context, List<Member> members) {
    countOutsideByGroup(members);


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
        for (final entry in groupAndOutside.entries)
          ...[
            Expanded(
              child: _groupButton(
                context: context,
                group: entry.key,
                count: entry.value,
                members: members,
                sortIndex: 3,
              ),
            ),
            const SizedBox(width: 12),
          ],
      ],
      ),
    );
  }

  Widget _groupButton({
    required BuildContext context,
    required String group,
    required int count,
    required int sortIndex,
    required List<Member> members,
  }) {
    final hasMembers = count > 0;

    return ElevatedButton(
      onPressed: hasMembers
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemberListerPage(members: members, sortColumnIndex: sortIndex, sortAscending: false, groupFilter: group),
                ),
              );
            }
          : null, // ✅ pasif
      style: ElevatedButton.styleFrom(
        backgroundColor: hasMembers ? const Color.fromARGB(255, 177, 120, 116) : Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(
        hasMembers
            ? "$group • $count kişi"
            : "$group grubunda dışarıda kimse yok",
        textAlign: TextAlign.center,
      ),
    );
  }

}
