import 'dart:async';
import 'package:app1/Pages/settings.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

DateTime? lastUpdateTime;

class Synchronizer {
  static final Synchronizer _instance = Synchronizer._internal();
  factory Synchronizer() => _instance;
  Synchronizer._internal();

  late StreamSubscription entriesSub;
  late StreamSubscription studentStateSub;

  final DatabaseService _dbService = DatabaseService();
  Timer? _timer;
  bool isUpdateReq = false;

  final studentRef = FirebaseDatabase.instance.ref('Student');
  final studentStateRef = FirebaseDatabase.instance.ref('StudentState');
  final entriesRef  = FirebaseDatabase.instance.ref('Entry');
  bool started = false;

  Future<void> start() async{
    if(started) return;
    
    started = true;

    if(kIsWeb){
      // await fetchStudentsOnce(); 
      // initSyncPullListeners();
      await initSyncPullListeners2();
    }
    

    else{
      initSyncPushListeners();
    }
  }

  void stop(){
    if (_timer != null){
      _timer!.cancel();
      _timer = null;
    }
  }


  //TODO: This method will change. It will push only listened data. So there might not be any need for timers.
  //updateDB method can update both the whole table or a single value inside of it. It just depends the value you push and the path.
  void initSyncPushListeners(){
    studentStateSub = Hive.box(studentStateBox).watch().listen((event) {
      if (event.deleted) return;
      final key = event.key;
      final value = parseToStudentState(event.value);

      if (value != null){
        _dbService.updateDB(path: "StudentState/${key.toString()}", data: StudentState.toMap(value));
      }
    });

    entriesSub = Hive.box(entryBox).watch().listen((event){
      if (event.deleted) return;
      final key = event.key;
      final value = parseToEntry(event.value);

      if (value != null){
        _dbService.updateDB(path: "Entry/${key.toString()}", data: Entry.toMap(value));
      }
    });
  }

  void initSyncPullListeners() async{
    studentStateRef.onChildAdded.listen((event) {
      print("Got an update from student with key: ${event.snapshot.key}");
      final value = event.snapshot.value;

      final studentState = parseToStudentState(value); 
      if(studentState != null){
        final path = "${studentState.group}_${studentState.number}";
        _dbService.updateHive(path: path, data: StudentState.toMap(studentState), b: Hive.box(studentBox));

        // _dbService.updateHive(path: path, data: StudentState.toMap(studentState), b: Hive.box(studentBox));
      }
      else{
        print("Could not parse a student state!");
      }
      lastUpdateTime = DateTime.now();
    });

    studentStateRef.onChildChanged.listen((event) {
      print("Got an update from student with key: ${event.snapshot.key}");
      final value = event.snapshot.value;

      final studentState = parseToStudentState(value); 

      if(studentState != null){
        _dbService.updateHive(path: "${studentState.group}_${studentState.number}", data: StudentState.toMap(studentState), b: Hive.box(studentBox));
      }
      else{
        print("Could not parse a student state!");
      }
      lastUpdateTime = DateTime.now();
    });

    //This is where querries will be!!!!
    entriesRef.onChildAdded.listen((event) {
      print("Got an update from entry with key: ${event.snapshot.key}");
      final value = event.snapshot.value;

      final entry = parseToEntry(value); 

      if(entry != null){
        _dbService.updateHive(path: entry.entryID.toString(), data: Entry.toMap(entry), b: Hive.box(entryBox));
      }
      else{
        print("Could not parse a entry!");
      }
      lastUpdateTime = DateTime.now();
    });

    entriesRef.onChildChanged.listen((event) {
      print("Got an update from entry with key: ${event.snapshot.key}");
      final value = event.snapshot.value;

      final entry = parseToEntry(value); 

      if(entry != null){
        _dbService.updateHive(path: entry.entryID.toString(), data: Entry.toMap(entry), b: Hive.box(entryBox));
      }
      else{
        print("Could not parse a entry!");
      }
      lastUpdateTime = DateTime.now();
    });
  }

  Future<void> fetchStudentsOnce() async {
    print("Fetching students (one-shot)...");

    final snapshot = await studentRef.get(); // ✅ sadece 1 kez

    if (!snapshot.exists) {
      print("No students found.");
      return;
    }

    final data = snapshot.value;

    if (data is! Map) {
      print("Unexpected data format.");
      return;
    }

    final Map<dynamic, dynamic> studentsMap = data;

    for (final entry in studentsMap.entries) {
      final key = entry.key;
      final value = entry.value;

      print("Got student with key: $key");

      final student = parseToStudent(value);

      if (student != null) {
        _dbService.updateHive(
          path: "${student.group}_${student.number}",
          data: Student.toMap(student),
          b: Hive.box(studentBox),
        );
      } else {
        print("Could not parse student!");
      }
    }

    lastUpdateTime = DateTime.now();
  }

  Future<void> initSyncPullListeners2() async {
    int totalBytes = 0;

    int existingStudentStateCount = 0;
    int existingEntryCount = 0;

    print("📥 Fetching initial data...");

    // ─────────────────────────────
    // Student State
    // ─────────────────────────────
    final studentStateSnapshot = await studentStateRef.get();

    if (studentStateSnapshot.exists) {
      final jsonString = jsonEncode(studentStateSnapshot.value);
      final bytes = utf8.encode(jsonString).length;

      totalBytes += bytes;

      print("📦 StudentState Download Size: $bytes bytes");

      final data = studentStateSnapshot.value;
      if (data is Map) {
        for (final entry in data.entries) {
          existingStudentStateCount++;

          final studentState = parseToStudentState(entry.value);
          if (studentState != null) {
            final path = "${studentState.group}_${studentState.number}";
            _dbService.updateHive(
              path: path,
              data: StudentState.toMap(studentState),
              b: Hive.box(studentStateBox),
            );
          }
        }
      }
    }

    print("✅ Loaded $existingStudentStateCount student states");

    // ─────────────────────────────
    // Entries
    // ─────────────────────────────
    final entrySnapshot = await entriesRef.get();

    if (entrySnapshot.exists) {
      final jsonString = jsonEncode(entrySnapshot.value);
      final bytes = utf8.encode(jsonString).length;

      totalBytes += bytes;

      print("📦 Entries Download Size: $bytes bytes");

      final data = entrySnapshot.value;
      if (data is Map) {
        for (final entry in data.entries) {
          existingEntryCount++;

          final entryObj = parseToEntry(entry.value);
          if (entryObj != null) {
            _dbService.updateHive(
              path: entryObj.entryID.toString(),
              data: Entry.toMap(entryObj),
              b: Hive.box(entryBox),
            );
          }
        }
      }
    }

    print("✅ Loaded $existingEntryCount entries");

    // ─────────────────────────────
    // Students
    // ─────────────────────────────
    final studentSnapshot = await studentRef.get();

    if (studentSnapshot.exists) {
      final jsonString = jsonEncode(studentSnapshot.value);
      final bytes = utf8.encode(jsonString).length;

      totalBytes += bytes;

      print("📦 Students Download Size: $bytes bytes");

      final data = studentSnapshot.value;
      if (data is Map) {
        for (final entry in data.entries) {
          final student = parseToStudent(entry.value);
          if (student != null) {
            _dbService.updateHive(
              path: "${student.group}_${student.number}",
              data: Student.toMap(student),
              b: Hive.box(studentBox),
            );
          }
        }
      }
    }

    print("📊 TOTAL DOWNLOAD: $totalBytes bytes");
    print("📊 TOTAL DOWNLOAD: ${(totalBytes / 1024).toStringAsFixed(2)} KB");
    print("📊 TOTAL DOWNLOAD: ${(totalBytes / (1024 * 1024)).toStringAsFixed(4)} MB");

    // Listenerlar aynen devam eder
    print("👂 Setting up listeners...");

    studentStateRef.onChildAdded.listen((event) {});
    studentStateRef.onChildChanged.listen((event) {});
    entriesRef.onChildAdded.listen((event) {});
    entriesRef.onChildChanged.listen((event) {});
  }

  void syncStudentsFromDB(){
    //get a value from db and check the last update time
    //if it does not exist put there one, and read it.
    //if it is later then local last update time pull.
    
  }

  
}