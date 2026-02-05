import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
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
              DatabaseService _databaseService = DatabaseService();
              List<Student> students = await _fetchStudentDataFromFirebase(_databaseService);
              Hive.box(studentBox).clear();
              for (final student in students){
                final value = Student.toFireBase(student);
                final path = "${student.group}_${student.number}";
                _databaseService.updateHive(path: path, data: value, b: Hive.box(studentBox));
              }


              List<Entry> entries = await _fetchEntryDataFromFirebase(_databaseService);
              Hive.box(entryBox).clear();
              for (final entry in entries){
                final value = Entry.toFireBase(entry);
                final path = entry.entryID;
                _databaseService.updateHive(path: path, data: value, b: Hive.box(entryBox));
              }
              
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

  List<Student> parseToStudents(Object? raw){
    List<Student> returnList = [];

    if(raw is Map){
      //Here keys are nodeKeys(IDs) of students and the values are value blocks A1 : {Dorm:..., Name:...}
      Map<String, dynamic> stringMap = raw.map((key,value) => MapEntry(key.toString(), value));
      print("A");
      returnList = parseToDataType(stringMap, Student.fromFireBase);
    }

    else{
      //TODO: Throw error
    }

    return returnList;
  }

  List<Entry> parseToEntries(Object? raw){
    List<Entry> returnList = [];

    if(raw is Map){
      //Here keys are nodeKeys(IDs) of students and the values are value blocks A1 : {Dorm:..., Name:...}
      Map<String, dynamic> stringMap = raw.map((key,value) => MapEntry(key.toString(), value));
      print("A");
      returnList = parseToDataType(stringMap, Entry.fromFireBase);
    }

    else{
      //TODO: Throw error
    }

    return returnList;
  }

  
}
