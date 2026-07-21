import 'dart:async';
import 'package:app1/Pages/settings.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:app1/utils/debugger.dart';
import 'package:app1/utils/offline_queue.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

DateTime? lastUpdateTime;

class Synchronizer {
  static final Synchronizer _instance = Synchronizer._internal();
  factory Synchronizer() => _instance;
  Synchronizer._internal();
  
  
  late StreamSubscription entriesSub;
  late StreamSubscription memberStateSub;

  final DatabaseService _dbService = DatabaseService();
  bool isUpdateReq = false;

 

  final memberStateRef = FirebaseDatabase.instance.ref('MemberState');
  final memberRef = FirebaseDatabase.instance.ref('Member');
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
        AppLogger.instance.log("Fetching members once.");
        await fetchMemberssOnce();
      } catch (e, stack) {
        AppLogger.instance.log("Failed to fetch members: $e");
        AppLogger.instance.log("Error stack: $stack");
      }

      //This one here is disabled because we don't need intant changes. f5 can get all the changes.
      // try {
      //   AppLogger.instance.log("Initializing pull listeners.");
      //   await initSyncPullListeners();
        
      // } catch(e, stack) {
      //   AppLogger.instance.log("Failed to initialize pull listeners: $e");
      //   AppLogger.instance.log("Error stack: $stack");
      // }
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


  void initSyncPushListeners() {
    memberStateSub = Hive.box(memberStateBox).watch().listen((event) async {
      if (event.deleted) return;
      final key = event.key;
      final value = parseToMemberState(event.value);

      if (value != null){
        final path = "MemberState/${key.toString()}";
        final data = MemberState.toMap(value);

        try {
          await _dbService.updateDB(path: path, data: data);
        } catch (e) {
          await QueueHelper.addToSyncQueue(path, data);
          
          AppLogger.instance.showOverlay("Bir öğrenci verisi veritabanına aktarılamadı! Daha sonra işlenmek üzere yerel olarak kaydedildi. \n İnternet bağlantınızı kontrol edin!", LogLevel.error);
          AppLogger.instance.error("Bir öğrenci verisi veritabanına aktarılamadı! Daha sonra işlenmek üzere yerel olarak kaydedildi. \n İnternet bağlantınızı kontrol edin!");
        }
      }
    });

    entriesSub = Hive.box(entryBox).watch().listen((event) async {
      if (event.deleted) return;
      final key = event.key;
      final value = parseToEntry(event.value);

      if (value != null){
        final path = "Entry/${key.toString()}";
        final data = Entry.toMap(value);

        try {
          await _dbService.updateDB(path: path, data: data);
        } catch (e) {
          await QueueHelper.addToSyncQueue(path, data);
        }

      }
    });
  }

  Future<void> fetchMemberssOnce() async {
    AppLogger.instance.log("Fetching members (one-shot)...");

    final snapshot = await memberRef.get(); // ✅ sadece 1 kez

    if (!snapshot.exists) {
      AppLogger.instance.warn("No members found.");
      return;
    }

    final data = snapshot.value;

    if (data is! Map) {
      AppLogger.instance.error("Unexpected data format.");
      return;
    }

    final Map<dynamic, dynamic> membersMap = data;

    for (final entry in membersMap.entries) {
      final key = entry.key;
      final value = entry.value;

      AppLogger.instance.log("Got member with key: $key");

      final member = parseToMember(value);

      if (member != null) {
        _dbService.updateHive(
          path: "${member.group}_${member.number}",
          data: Member.toMap(member),
          b: Hive.box(memberBox),
        );
      } else {
        AppLogger.instance.error("Could not parse member!");
      }
    }

    lastUpdateTime = DateTime.now();
  } 


}