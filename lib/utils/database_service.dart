import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;

  Future<DataSnapshot?> read({required String path}) async {
    final DatabaseReference ref = firebaseDatabase.ref().child(path);
    try {
      final DataSnapshot snapshot = await ref.get().timeout(Duration(seconds: 10));
      return snapshot.exists ? snapshot : null;
    } catch (e) {
      print('Timeout veya hata: $e');
      return null;
    }
  }

  Future<void> update({
    required String path,
    required Map<String,String> data
  }) async{
    final DatabaseReference ref = firebaseDatabase.ref().child(path);
    await ref.update(data);
  }

  Future<void> updateNullable({
  required String? path,
  required Map<String,String> data,
  }) async {
    if (path == null || path.isEmpty) {
      // Null veya boşsa işlem yapma
      return;
    }
    
    final DatabaseReference ref = firebaseDatabase.ref().child(path);
    await ref.update(data);
  }

  // Entry eklemek için genel method
  Future<void> add({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final baseRef = firebaseDatabase.ref(path);
    final newEntryRef = baseRef.push();
    await newEntryRef.set(data);
  }

  // Belirlenen path altındaki son entry'nin child key'ini döner.
  Future<String?> getLastEntryKey(String path) async {
    final baseRef = firebaseDatabase.ref(path);

    final query = baseRef.orderByKey().limitToLast(1);
    final snapshot = await query.get();

    if (snapshot.exists && snapshot.children.isNotEmpty) {
      return snapshot.children.first.key;
    }

    return null; // Kayıt yoksa null döner
  }
}