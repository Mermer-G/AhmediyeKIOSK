import 'dart:async';


import 'package:app1/utils/database_service.dart';
import 'package:hive/hive.dart';


class Synchronizer {
  static final Synchronizer _instance = Synchronizer._internal();
  factory Synchronizer() => _instance;
  Synchronizer._internal();

  final DatabaseService _dbService = DatabaseService();
  Timer? _timer;
  bool isUpdateReq = true;

  void start(){
    print("Timer has started");
    Hive.box(entryBox).watch().listen((event) {
      isUpdateReq = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (t) => sync());
  }

  
  
   
  void stop(){
    if (_timer != null){
      _timer!.cancel();
      _timer = null;
    }
  }

  void sync(){
    if (!isUpdateReq) return;
    isUpdateReq = false;
    final eB = Hive.box(entryBox);
    final entryMap = Map<String, dynamic>.from(eB.toMap());
    _dbService.updateDB(path: "EntryTest", data: entryMap);

    final sB = Hive.box(studentBox);
    final studentMap = Map<String, dynamic>.from(sB.toMap());
    _dbService.updateDB(path: "StudentTest", data: studentMap);
    print("Synced!");
  }
}