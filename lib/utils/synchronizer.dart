import 'dart:async';
import 'package:app1/Pages/settings.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:app1/utils/debugger.dart';
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

 

  final studentStateRef = FirebaseDatabase.instance.ref('StudentState');
  final studentRef = FirebaseDatabase.instance.ref('Student');
  final entriesRef  = FirebaseDatabase.instance.ref('Entry');

  void reset() {
    started = false;
  }
  
  bool started = false;
  Future<void> start() async {
    if(started) return;
    started = true;
    AppLogger.instance.log("Inside Synchronizer().start()");

    if(kIsWeb){
      AppLogger.instance.log("kIsWeb.");
      try {
        AppLogger.instance.log("Fetching students once.");
        await fetchStudentsOnce();
      } catch (e, stack) {
        AppLogger.instance.log("Failed to fetch students: $e");
        AppLogger.instance.log("Error stack: $stack");
      }

      try {
        AppLogger.instance.log("Initializing pull listeners.");
        await initSyncPullListeners();
        
      } catch(e, stack) {
        AppLogger.instance.log("Failed to initialize pull listeners: $e");
        AppLogger.instance.log("Error stack: $stack");
      }
    }
    else{
      AppLogger.instance.log("kIs NOT web.");
      try {
        AppLogger.instance.log("Initializing push listeners.");
        initSyncPushListeners();
        
      } catch(e, stack) {
        AppLogger.instance.log("Failed to initialize push listeners: $e");
        AppLogger.instance.log("Error stack: $stack");
      }
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

  Future<void> fetchStudentsOnce() async {
    AppLogger.instance.log("Fetching students (one-shot)...");

    final snapshot = await studentRef.get(); // ✅ sadece 1 kez

    if (!snapshot.exists) {
      AppLogger.instance.warn("No students found.");
      return;
    }

    final data = snapshot.value;

    if (data is! Map) {
      AppLogger.instance.error("Unexpected data format.");
      return;
    }

    final Map<dynamic, dynamic> studentsMap = data;

    for (final entry in studentsMap.entries) {
      final key = entry.key;
      final value = entry.value;

      AppLogger.instance.log("Got student with key: $key");

      final student = parseToStudent(value);

      if (student != null) {
        _dbService.updateHive(
          path: "${student.group}_${student.number}",
          data: Student.toMap(student),
          b: Hive.box(studentBox),
        );
      } else {
        AppLogger.instance.error("Could not parse student!");
      }
    }

    lastUpdateTime = DateTime.now();
  }

  Future<void> initSyncPullListeners() async {
    int totalBytes = 0;

    int existingStudentStateCount = 0;
    int existingEntryCount = 0;

    AppLogger.instance.log("📥 Fetching initial data...");

    // ─────────────────────────────
    // Student State
    // ─────────────────────────────
    
    final studentStateSnapshot = await studentStateRef.get();

    if (studentStateSnapshot.exists) {
      final jsonString = jsonEncode(studentStateSnapshot.value);
      final bytes = utf8.encode(jsonString).length;

      totalBytes += bytes;

      AppLogger.instance.log("📦 StudentState Download Size: $bytes bytes");

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

    AppLogger.instance.log("✅ Loaded $existingStudentStateCount student states");

    // ─────────────────────────────
    // Entries
    // ─────────────────────────────


    
    final entrySnapshot = await entriesRef
      .orderByChild(entryIDDB)
      .limitToLast(entryPullLimit)
      .get();

    if (entrySnapshot.exists) {
      final jsonString = jsonEncode(entrySnapshot.value);
      final bytes = utf8.encode(jsonString).length;

      totalBytes += bytes;

      AppLogger.instance.log("📦 Entries Download Size: $bytes bytes");

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

    AppLogger.instance.log("✅ Loaded $existingEntryCount entries");

    // ─────────────────────────────
    // Students
    // ─────────────────────────────
    final studentSnapshot = await studentRef.get();

    if (studentSnapshot.exists) {
      final jsonString = jsonEncode(studentSnapshot.value);
      final bytes = utf8.encode(jsonString).length;

      totalBytes += bytes;

      AppLogger.instance.warn("📦 Students Download Size: $bytes bytes");

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

    AppLogger.instance.log("📊 TOTAL DOWNLOAD: $totalBytes bytes");
    AppLogger.instance.log("📊 TOTAL DOWNLOAD: ${(totalBytes / 1024).toStringAsFixed(2)} KB");
    AppLogger.instance.log("📊 TOTAL DOWNLOAD: ${(totalBytes / (1024 * 1024)).toStringAsFixed(4)} MB");

    // Listenerlar aynen devam eder
    AppLogger.instance.log("👂 Setting up listeners...");

    studentStateRef.onChildAdded.listen((event) {});
    studentStateRef.onChildChanged.listen((event) {});
    entriesRef.onChildAdded.listen((event) {});
    entriesRef.onChildChanged.listen((event) {});
  }
  
}