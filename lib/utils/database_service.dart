import 'dart:async';
import 'dart:convert';
import 'package:app1/utils/byte_calculator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'cache_helper.dart';

const String studentBox = "StudentBox";
const String entryBox = "EntryBox";
const String studentStateBox = "StudentStateBox";
const String metaBox = "StudentStateBox";

int byteSizeOf(Map<String, dynamic> data) {
  final jsonString = jsonEncode(data);
  return utf8.encode(jsonString).length;
}

class DatabaseService {
  final FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;
  final CacheHelper _cacheHelper = CacheHelper.instance;

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
      print('Timeout veya hata: $e');
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
      print("The path: $path from box: ${b.name} is null or empty!");
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

  // ===============================
  // 🔄 SYNC ENGINE
  // ===============================
  // void startAutoSync() {
  //   if (!_autoSyncEnabled) return;

  //   _syncTimer?.cancel();
  //   _syncTimer = Timer.periodic(
  //     const Duration(minutes: 1),
  //     (_) => syncNow(),
  //   );
  // }

  // void stopAutoSync() {
  //   _syncTimer?.cancel();
  // }

  // void setAutoSync(bool enabled) {
  //   _autoSyncEnabled = enabled;
  //   enabled ? startAutoSync() : stopAutoSync();
  // }

  // Future<void> syncNow() async {
  //   print("🔄 Sync başladı");
  //   await _syncFromFirebaseToHive();
  //   await _syncFromHiveToFirebase();
  //   print("✅ Sync tamamlandı");
  // }

  // ===============================
  // FIREBASE → HIVE (UPDATE ONLY)
  // ===============================
  Future<void> _syncFromFirebaseToHive(Box b) async {
    //TODO: This should not be hard coded
    final snapshot = await readFromDB(path: 'STUDENT');
    if (snapshot == null || snapshot.value == null) return;

    final remoteData =
        Map<String, dynamic>.from(snapshot.value as Map);

    for (final entry in remoteData.entries) {
      final key = entry.key;
      final remoteValue = Map<String, dynamic>.from(entry.value);

      final localKey = 'STUDENT/$key';
      final localValue = b.get(localKey);

      if (localValue != null) {
        final updated = Map<String, dynamic>.from(localValue)
          ..addAll(remoteValue);

        await b.put(localKey, updated);
      }
    }
  }

  // ===============================
  // HIVE → FIREBASE
  // ===============================
  Future<void> _syncFromHiveToFirebase( Box b) async {
    final hiveData = b.toMap();

    for (final entry in hiveData.entries) {
      final key = entry.key;
      if (key is! String) continue;
      if (!key.startsWith('STUDENT/')) continue;

      final value = Map<String, dynamic>.from(entry.value);

      await firebaseDatabase
          .ref(key)
          .update(toStringMap(value));
    }
  }

  Map<String, String>? mapDynamicToString(Map<String, dynamic>? data) {
  return data?.map(
    (key, value) => MapEntry(
      key,
      value == null ? '' : value.toString(),
    ),
  );
}
}

String formatTimeString(String? t) {
  if (t == null) return "—";
  return t.split('.').first;
}