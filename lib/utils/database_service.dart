import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'cache_helper.dart';

String studentBox = "StudentBox";
String entryBox = "EntryBox";

class DatabaseService {
  final FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;
  final CacheHelper _cacheHelper = CacheHelper.instance;

  Timer? _syncTimer;
  bool _autoSyncEnabled = true;

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
    required String path,
    required Map<String, String> data,
  }) async {
    final DatabaseReference ref = firebaseDatabase.ref().child(path);
    await ref.update(data);
  }

  Future<void> updateNullableDB({
    required String? path,
    required Map<String, String> data,
  }) async {
    if (path == null || path.isEmpty) return;
    await updateDB(path: path, data: data);
  }

  Future<void> addToDB({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final baseRef = firebaseDatabase.ref(path);
    final newEntryRef = baseRef.push();
    await newEntryRef.set(data);
  }

  Future<String?> getLastEntryKeyFromDB(String path) async {
    final baseRef = firebaseDatabase.ref(path);
    final query = baseRef.orderByKey().limitToLast(1);
    final snapshot = await query.get();

    if (snapshot.exists && snapshot.children.isNotEmpty) {
      return snapshot.children.first.key;
    }
    return null;
  }

  // ===============================
  // HIVE READ
  // ===============================
  Map<String, dynamic>? readFromHive({required Box b, String? path}) {
    dynamic data;

    if (path == null || path.isEmpty) {
      print("The path: $path from box: $b is null or empty!");
      return null;
    }

    data = b.get(path);
    if (data == null) return null;

    return Map<String, dynamic>.from(data);
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

  Future<String> putToHive({
    required Map<String, dynamic> data,
    required Box b,
    String? path
  }) async {
    final pushId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final fullPath = (path == null || path.isEmpty) ? pushId : '$path/$pushId';

    // _cacheHelper.schedule(() async {
      await b.put(fullPath, data);
    // });

    return pushId;
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
