import 'package:app1/Pages/entryList.dart';
import 'package:app1/Pages/passwordPage.dart';
import 'package:app1/Pages/studentInfo.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:app1/utils/synchronizer.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'studentList.dart';
import 'dart:async';

String settingsPassword = "365";
int lastTimeStamp = 0;

class HomePage extends StatefulWidget {
  const HomePage({super.key});


  @override
  State<HomePage> createState() => _HomePageState();
}
ValueNotifier studentsValueListener = ValueNotifier<List<Student>>([]);
class _HomePageState extends State<HomePage> {
  late String _currentTime;
  Timer? _timer;
  int outA = 0;
  int outB = 0;
  late Map<String, Student> studentMap = {};
  

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    lastTimeStamp = Hive.box(metaBox).get("lastEntryTimestamp") ?? 0;

    _updateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );

    await Synchronizer().start();

    await _fetchStudentDataFromHive();        // ✅ BEKLE
    await _fetchStudentStateDataFromHive();   // ✅ BEKLE

    mergeStudentData();                       // ✅ ARTIK GÜVENLİ
  }

  //this will change into both student and studentState or maybe 2 methods
  Future<void> _fetchStudentDataFromHive() async{
    try {
      print('===== VERİ ÇEKME BAŞLADI: Student =====');
      final rawMap = Hive.box(studentBox).toMap();
      
      rawMap.forEach((k,v){
        Map<String, dynamic> valuesMap = Map<String, dynamic>.from(v as Map);
        final student = Student.fromMap(valuesMap);
        studentMap["${student.group}_${student.number}"] = student;

        print("Added student for: ${student.group}_${student.number}");
      });
    } 
      
    catch (e, stack) {
      print("HATA: $e");
      print(stack);
    }
  }

  Future<void> _fetchStudentStateDataFromHive() async{
    try {
      print('===== VERİ ÇEKME BAŞLADI: StudentState =====');
      final rawMap = Hive.box(studentStateBox).toMap();
      
      print("Rawmap has: ${rawMap.length} elements");

      rawMap.forEach((k,v){
        Map<String, dynamic> valuesMap = Map<String, dynamic>.from(v as Map);
        final state = StudentState.fromMap(valuesMap);

        final key = "${state.group}_${state.number}";

        if (studentMap.containsKey(key)) {
          studentMap[key]!.state = state.state.name;
          studentMap[key]!.entryID = state.lastEntryID;
        } else {
          print("⚠ STATE GELDİ AMA STUDENT YOK: $key");
        }
        
        print("Added student state for ${state.group}_${state.number} State: ${state.state}, entry id: ${state.lastEntryID}");
      });
    } 
      
    catch (e, stack) {
      print("HATA: $e");
      print(stack);
    }
  }

  void mergeStudentData(){
    studentsValueListener.value = studentMap.values.toList();
  }

  void _updateTime() {
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
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentListerPage(students: studentsValueListener.value, sortColumnIndex: 1, sortAscending: true, groupFilter: ""),),
          ),
        ),
        const SizedBox(height: 12),
        _menuButton(
          icon: Icons.list_alt_rounded,
          text: "Giriş-Çıkış Listesi",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => entryListerPage()),
          ),
        ),
        const SizedBox(height: 12),
        _menuButton(
          icon: Icons.settings,
          text: "Ayarlar",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PasswordPage()),
          ),
        ),
      ],
    ) : Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _menuButton(
          icon: Icons.list_alt_rounded,
          text: "Talebe Listesi",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentListerPage(students: studentsValueListener.value, sortColumnIndex: 1, sortAscending: true, groupFilter: "")),
          ),
        ),
        const SizedBox(width: 12),
        _menuButton(
          icon: Icons.list_alt_rounded,
          text: "Giriş-Çıkış Listesi",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => entryListerPage()),
          ),
        ),
        const SizedBox(width: 12),
        _menuButton(
          icon: Icons.settings,
          text: "Ayarlar",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PasswordPage()),
          ),
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
