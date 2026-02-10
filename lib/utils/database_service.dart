import 'dart:convert';
import 'package:ahmediye_kiosk/utils/byte_calculator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hive_flutter/hive_flutter.dart';

String studentBox = "StudentBox";
String entryBox = "EntryBox";

int byteSizeOf(Map<String, dynamic> data) {
  final jsonString = jsonEncode(data);
  return utf8.encode(jsonString).length;
}

class DatabaseService {
  final FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;

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
      return null;
    }
  }

  // ===============================
  // FIREBASE UPDATE
  // ===============================
  Future<void> updateDB({
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
    if (path == null || path.isEmpty) return null;

    final data = b.get(path);
    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  }

  Map<String, dynamic> readBoxFromHive({required Box b}) {
    return Map<String, dynamic>.from(b.toMap());
  }

  // ===============================
  // HIVE UPDATE
  // ===============================
  Future<void> updateHive({
    required String path,
    required Map<String, dynamic> data,
    required Box b,
  }) async {
    final existing = b.get(path);

    if (existing is Map) {
      final updated = Map<String, dynamic>.from(existing.cast())..addAll(data);
      await b.put(path, updated);
    } else {
      await b.put(path, Map<String, dynamic>.from(data));
    }
  }

  Future<void> putToHive({
    required Map<String, dynamic> data,
    required Box b,
    required String pID,
    String? path,
  }) async {
    final fullPath = (path == null || path.isEmpty) ? pID : '$path/$pID';
    await b.put(fullPath, data);
  }

  String createPushID() {
    return DateTime.now().millisecondsSinceEpoch.toString();
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
}
