import 'package:app1/Pages/entryList.dart';
import 'package:app1/Pages/passwordPage.dart';
import 'package:app1/Pages/studentInfo.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:app1/utils/debugger.dart';
import 'package:app1/utils/synchronizer.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'studentList.dart';
import 'dart:async';

String settingsPassword = "365";
int lastTimeStamp = 0;
ValueNotifier studentsValueListener = ValueNotifier<List<Student>>([]);

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
  int outA = 0;
  int outB = 0;
  late Map<String, Student> studentMap = {};
  

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // Future<void> _initialize() async {
  //   print("🔥 INIT START");

  //   print("🔥 BEFORE HIVE");
  //   lastTimeStamp = Hive.box(metaBox).get("lastEntryTimestamp") ?? 0;

  //   print("🔥 BEFORE TIMER");
  //   _updateTime();
  //   _timer = Timer.periodic(
  //     const Duration(seconds: 1),
  //     (_) => _updateTime(),
  //   );

  //   print("🔥 BEFORE SYNC");
  //   await Synchronizer().start();

  //   print("🔥 AFTER SYNC");

  //   print("🔥 BEFORE STUDENTS");
  //   await _fetchStudentDataFromHive();

  //   print("🔥 BEFORE STATES");
  //   await _fetchStudentStateDataFromHive();

  //   print("🔥 MERGE");
  //   mergeStudentData();

  //   print("🔥 INIT DONE");
  // }

  
  // @override
  // Widget build(BuildContext context) {
  //   return LayoutBuilder(
  //     builder: (context, constraints) {
  //       final bool isWide = constraints.maxWidth > 700;

  //       return Scaffold(
  //         appBar: appBarM(),

  //         // 📱 DAR EKRAN → DRAWER VAR
  //         drawer: isWide
  //             ? null
  //             : Drawer(
  //                 width: 150,
  //                 child: SafeArea(
  //                   child: Column(
  //                     children: [
  //                       SizedBox(height: 20),
  //                       menuButtons(context, isWide),
  //                     ],
  //                   ),
  //                 ),
  //               ),

  //         body: Padding(
  //           padding: const EdgeInsets.all(20),
  //           child: isWide
  //               ? Row(
  //                   children: [
  //                     Expanded(
  //                       child: Align(
  //                         alignment: Alignment.topCenter,
  //                         child: menuButtons(context, isWide),
  //                       ),
  //                     ),
  //                     Expanded(child: notificationsArea()),
  //                   ],
  //                 )
  //               : Center(child: notificationsArea()), // 📱 Telefonda sadece içerik
  //         ),
  //       );
  //     },
  //   );
  // }

  
  final List<String> logs = []; // Logların tutulduğu liste

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
      AppLogger.instance.log("BEFORE STUDENTS: Hive'dan öğrenci verileri...");
      await _fetchStudentDataFromHive();
      AppLogger.instance.log("STUDENTS DATA FETCHED");

      AppLogger.instance.log("BEFORE STATES: Durum verileri çekiliyor...");
      await _fetchStudentStateDataFromHive();
      AppLogger.instance.log("STATES DATA FETCHED");

      // 5. MERGE
      AppLogger.instance.log("MERGE: Veriler birleştiriliyor...");
      mergeStudentData();
      AppLogger.instance.log("MERGE DONE");

      

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

  //this will change into both student and studentState or maybe 2 methods
  Future<void> _fetchStudentDataFromHive() async{
    try {
      AppLogger.instance.log('===== VERİ ÇEKME BAŞLADI: Student =====');
      final rawMap = Hive.box(studentBox).toMap();
      
      rawMap.forEach((k,v){
        Map<String, dynamic> valuesMap = Map<String, dynamic>.from(v as Map);
        final student = Student.fromMap(valuesMap);
        studentMap["${student.group}_${student.number}"] = student;

        AppLogger.instance.log("Added student for: ${student.group}_${student.number}");
      });
    } 
      
    catch (e, stack) {
      AppLogger.instance.error("HATA: $e");
      AppLogger.instance.error(stack.toString());
    }
  }

  Future<void> _fetchStudentStateDataFromHive() async{
    try {
      AppLogger.instance.log('===== VERİ ÇEKME BAŞLADI: StudentState =====');
      final rawMap = Hive.box(studentStateBox).toMap();
      
      AppLogger.instance.log("Rawmap has: ${rawMap.length} elements");

      rawMap.forEach((k,v){
        Map<String, dynamic> valuesMap = Map<String, dynamic>.from(v as Map);
        final state = StudentState.fromMap(valuesMap);

        final key = "${state.group}_${state.number}";

        if (studentMap.containsKey(key)) {
          studentMap[key]!.state = state.state.name;
          studentMap[key]!.entryID = state.lastEntryID;
        } else {
          AppLogger.instance.error("⚠ STATE GELDİ AMA STUDENT YOK: $key");
        }
        
        AppLogger.instance.log("Added student state for ${state.group}_${state.number} State: ${state.state}, entry id: ${state.lastEntryID}");
      });
    } 
      
    catch (e, stack) {
      AppLogger.instance.error("HATA: $e");
      AppLogger.instance.error(stack.toString());
    }
  }

  void mergeStudentData(){
    studentMap.forEach((key, student) {
      student.state ??= StudentStateEnum.inside.name;
    });
    studentsValueListener.value = studentMap.values.toList();
  }

  void _updateTime() {
    if (!mounted) return;   // ✅ KRİTİK

    final now = DateTime.now();
    setState(() {
      _currentTime =
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}";
      
      outA = countOutsideByGroup(studentsValueListener.value, "A");
      outB = countOutsideByGroup(studentsValueListener.value, "B");
    });
  }

  int countOutsideByGroup(List<Student> students, String group) {
    return students.where((st) =>
        st.group.toLowerCase() == group.toLowerCase() &&
        (st.state ?? "").toLowerCase() == STATEOUT.toLowerCase()
    ).length;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
              MaterialPageRoute(builder: (_) => StudentListerPage(students: studentsValueListener.value, sortColumnIndex: 1, sortAscending: true, groupFilter: ""),),
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
      ],
    ) : 
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _menuButton(
          icon: Icons.list_alt_rounded,
          text: "Talebe Listesi",
          onTap: () { 
            AppLogger.instance.log("Talebe Listesi'ne tıklandı.");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StudentListerPage(students: studentsValueListener.value, sortColumnIndex: 1, sortAscending: true, groupFilter: ""),),
            );
          }
        ),
        const SizedBox(width: 12),
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
        const SizedBox(width: 12),
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
        buildOutsideButtons(context, studentsValueListener.value),
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

  Widget buildOutsideButtons(BuildContext context, List<Student> students) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _groupButton(
              context: context,
              group: "A",
              count: outA,
              students: students,
              sortIndex: 3
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _groupButton(
              context: context,
              group: "B",
              count: outB,
              students: students,
              sortIndex: 3
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupButton({
    required BuildContext context,
    required String group,
    required int count,
    required int sortIndex,
    required List<Student> students,
  }) {
    final hasStudents = count > 0;

    return ElevatedButton(
      onPressed: hasStudents
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentListerPage(students: students, sortColumnIndex: sortIndex, sortAscending: false, groupFilter: group),
                ),
              );
            }
          : null, // ✅ pasif
      style: ElevatedButton.styleFrom(
        backgroundColor: hasStudents ? const Color.fromARGB(255, 177, 120, 116) : Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(
        hasStudents
            ? "$group • $count kişi"
            : "$group grubunda dışarıda öğrenci yok",
        textAlign: TextAlign.center,
      ),
    );
  }

}
