import 'package:app1/Pages/studentInfo.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:app1/utils/synchronizer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  Map<String, Student> studentMap = {};
  List<Student> studentList = [];

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Emin misin?"),
        content: const Text(
          "Database'deki TÜM veriler silinecek.\nBu işlem geri alınamaz.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async{
              Synchronizer().entriesSub.cancel();
              Synchronizer().studentStateSub.cancel();
              //Student values getting.
              DatabaseService _databaseService = DatabaseService();
              List<Student> tempStudents = await _fetchStudentDataFromFirebase(_databaseService);
              List<Student> students = [];
              for (var student in tempStudents) {
                studentMap["${student.group}_${student.number}"] = student;
              }
              tempStudents.clear();
              List<StudentState> studentStates = await _fetchStudentStateDataFromFireBase(_databaseService);
              //For students that has declared states.
              for(var studentState in studentStates){
                final key = "${studentState.group}_${studentState.number}";
                final student = studentMap.remove(key);
                
                if(student == null){
                  print("Student: $key was null");
                  continue;
                }

                student.state = studentState.state.name;
                student.entryID = studentState.lastEntryID;
                students.add(student);
              }
              //For students that has not declared any states in the table.
              studentMap.forEach((k,student){
                final newState = StudentState(
                  group: student.group, 
                  number: student.number, 
                  state: StudentStateEnum.inside, 
                  lastEntryID: null
                );
                studentStates.add(newState);
                student.state = newState.state.name;
                student.entryID = null;
                students.add(student);
                print("Created a new state for student: $k");
              });

              studentMap.clear();

              Hive.box(studentBox).clear();
              for (final student in students){
                final data = Student.toMap(student);
                final path = "${student.group}_${student.number}";
                _databaseService.updateHive(path: path, data: data, b: Hive.box(studentBox));
              }

              Hive.box(studentStateBox).clear();
              for(final studentState in studentStates){
                final data = StudentState.toMap(studentState);
                final path = "${studentState.group}_${studentState.number}";
                _databaseService.updateHive(path: path, data: data, b: Hive.box(studentStateBox));
              }

              //Entry values getting
              List<Entry> entries = await _fetchEntryDataFromFirebase(_databaseService);
              Hive.box(entryBox).clear();
              for (final entry in entries){
                final value = Entry.toMap(entry);
                final path = entry.entryID.toString();
                _databaseService.updateHive(path: path, data: value, b: Hive.box(entryBox));
              }
              

              await Synchronizer().start();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Veriler veri tabanıyla eşitlendi."),
                ),
              );
              
            },
            child: const Text("Sıfırla"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarM(),
      body: Padding( 
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 500,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Database",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Uygulamada tutulan tüm yerel verileri siler.",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _confirmReset(context),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text("Mevcut verileri sıfırla ve veri tabanından yeni veri al."),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
      )
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

  Future<List<Student>> _fetchStudentDataFromFirebase(DatabaseService _dbService) async {
    try {
      print('===== VERİ ÇEKME BAŞLADI =====');
      final DataSnapshot? snapshot = await _dbService.readFromDB(path: 'Student');
      final raw = snapshot?.value;
      return parseToStudents(raw);
    }
     
    catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Future<List<Entry>> _fetchEntryDataFromFirebase(DatabaseService _dbService) async {
    try {
      print('===== VERİ ÇEKME BAŞLADI =====');
      final DataSnapshot? snapshot = await _dbService.readFromDB(path: 'Entry');
      final raw = snapshot?.value;
      return parseToEntries(raw);
    }
     
    catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Future<List<StudentState>> _fetchStudentStateDataFromFireBase(DatabaseService _dbService) async{
    try {
      print('===== VERİ ÇEKME BAŞLADI: StudentState =====');
      final DataSnapshot? snapshot = await _dbService.readFromDB(path: 'StudentState');
      final raw = snapshot?.value;
      return parseToStudentStates(raw);
    } 
      
    catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  void mergeStudentData(){
    studentList = studentMap.values.toList();
  }

}


List<Student> parseToStudents(Object? raw){
  List<Student> returnList = [];

  if(raw is Map){
    //Here keys are nodeKeys(IDs) of students and the values are value blocks A1 : {Dorm:..., Name:...}
    Map<String, dynamic> stringMap = raw.map((key,value) => MapEntry(key.toString(), value));
    print("A");
    returnList = parseToDataType(stringMap, Student.fromMap);
  }

  else{
    //TODO: Throw error
  }

  return returnList;
}

Student? parseToStudent(Object? raw) {
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    return Student.fromMap(map);
  }
  return null;
}

List<Entry> parseToEntries(Object? raw){
  List<Entry> returnList = [];

  if(raw is Map){
    //Here keys are nodeKeys(IDs) of students and the values are value blocks A1 : {Dorm:..., Name:...}
    Map<String, dynamic> stringMap = raw.map((key,value) => MapEntry(key.toString(), value));
    print("A");
    returnList = parseToDataType(stringMap, Entry.fromMap);
  }

  else{
    //TODO: Throw error
  }

  return returnList;
}

Entry? parseToEntry(Object? raw) {
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    return Entry.fromMap(map);
  }
  return null;
}

List<StudentState> parseToStudentStates(Object? raw) {
  List<StudentState> returnList = [];

  if(raw is Map){
    //Here keys are nodeKeys(IDs) of students and the values are value blocks A1 : {Dorm:..., Name:...}
    Map<String, dynamic> stringMap = raw.map((key,value) => MapEntry(key.toString(), value));
    print("A");
    returnList = parseToDataType(stringMap, StudentState.fromMap);
  }

  else{
    //TODO: Throw error
  }
  return returnList;
}

StudentState? parseToStudentState(Object? raw) {
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    return StudentState.fromMap(map);
  }
  return null;
}

String formatDate(DateTime dt) {
  return "${dt.year.toString().padLeft(4, '0')}-"
         "${dt.month.toString().padLeft(2, '0')}-"
         "${dt.day.toString().padLeft(2, '0')} "
         "${dt.hour.toString().padLeft(2, '0')}:"
         "${dt.minute.toString().padLeft(2, '0')}:"
         "${dt.second.toString().padLeft(2, '0')}";
}

int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}
