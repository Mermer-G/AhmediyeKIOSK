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
}