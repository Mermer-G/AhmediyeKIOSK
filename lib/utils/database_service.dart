import 'dart:async';
import 'dart:convert';
import 'package:app1/main.dart';
import 'package:app1/utils/byte_calculator.dart';
import 'package:app1/utils/debugger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'command.dart';

const String memberBox = "StudentBox";
const String memberStateBox = "StudentStateBox";
const String entryBox = "EntryBox";
const String metaBox = "MetaBox";
const String queueBox = "QueueBox";
const String reasonBox = "ReasonBox";
const String permissionBox = "PermissionBox";

int byteSizeOf(Map<String, dynamic> data) {
  final jsonString = jsonEncode(data);
  return utf8.encode(jsonString).length;
}

class DatabaseService {
  late final FirebaseDatabase firebaseDatabase;

  Future<bool> hasInternet() async {
    try {
      final snapshot = await firebaseDatabase
          .ref("ping")
          .get()
          .timeout(const Duration(seconds: 3));

      return snapshot.exists;
    } catch (_) {
      return false;
    }
  }

  DatabaseService() {
    try {
      firebaseDatabase = FirebaseDatabase.instanceFor(
      app: Firebase.app(fireBaseAppName),
      databaseURL: Firebase.app(fireBaseAppName).options.databaseURL!,
    );
    } catch (e, track) {
      AppLogger.instance.log("DataBase Service Can't be instenced:  $e");
      AppLogger.instance.log("Track:  $track");
    }
  }

  // ===============================
  // FIREBASE READ
  // ===============================
  Future<DataSnapshot?> readFromDB({required String path}) async {
    final DatabaseReference ref = firebaseDatabase.ref().child(path);
    
    try {
      final DataSnapshot snapshot =
          await ref.get().timeout(const Duration(seconds: 10));
      return snapshot.exists ? snapshot : null;
    } catch (e) {
      AppLogger.instance.error('Timeout veya hata: $e path: $path');
      return null;
    }
  }

  // ===============================
  // FIREBASE UPDATE
  // ===============================
  Future<void> updateDB({
    //Table Name is included in this path. So it can not be null.
    required String path,
    required Map<String, dynamic> data,
  }) async {

    final online = await hasInternet();
    AppLogger.instance.log("Connection was: $online");

    if (!online) {
      AppLogger.instance.error("No Internet!");
      AppLogger.instance.showOverlay("İşlem tamamlanamadı! İnternet bağlantınızı kontrol ediniz.", LogLevel.error);
      throw Exception("NO INTERNET");
      
    }

    final DatabaseReference ref = firebaseDatabase.ref().child(path);
    await ref.update(data);
    ByteAccumulator.addData(data);
  }

  // ===============================
  // HIVE READ
  // ===============================
  Map<String, dynamic>? readFromHive({required Box b, String? path}) {
    dynamic data;

    if (path == null || path.isEmpty) {
      AppLogger.instance.error("The path: $path from box: ${b.name} is null or empty!");
      return null;
    }

    data = b.get(path);
    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  }

  ///Returns the whole box as a Map<String, dynamic>
  ///[String] --> the node keys of elements
  ///[dynamic] --> the map that has the value and field names.
  Map<String, dynamic> readBoxFromHive({required Box b}){
    return Map<String, dynamic>.from(b.toMap());
  }

  // ===============================
  // HIVE UPDATE (SCHEDULED)
  // ===============================
  Future<void> updateHive({
    required String path,
    required Map<String, dynamic> data,
    required Box b
  }) async {
    // _cacheHelper.schedule(() async {
      final existing = b.get(path);

      if (existing is Map) {
        final updated = Map<String, dynamic>.from(existing.cast())..addAll(data);
        await b.put(path, updated);
      } else {
        await b.put(path, Map<String, dynamic>.from(data));
      }
    // });
  }

  ///This method is for only PUSHING! Use updateHive for creating and updating values in hive! 
  Future<void> putToHive({
    required Map<String, dynamic> data,
    required Box b,
    required String pushID,
    String? path
  }) async {
    final pushId = pushID;
    
    final fullPath = (path == null || path.isEmpty) ? pushId : '$path/$pushId';

    // _cacheHelper.schedule(() async {
      await b.put(fullPath, data);
    // });
  }

  int createPushID(){
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<String?> getLastEntryKeyFromHive(String path, Box b) async {
    final keys = b.keys
        .whereType<String>()
        .where((k) => k.startsWith('$path/'))
        .toList();

    if (keys.isEmpty) return null;
    keys.sort();
    return keys.last.split('/').last;
  }

  // ===============================
  // STRING MAP CONVERTER
  // ===============================
  Map<String, String> toStringMap(Map<String, dynamic> data) {
    return data.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );
  }

  Future<void> sendCommand(Command command) async {
  await firebaseDatabase
      .ref()
      .child('Command')
      .child(command.id)
      .set(command.toMap());
}
}

String formatTimeString(String? t) {
  if (t == null) return "—";
  return t.split('.').first;
}