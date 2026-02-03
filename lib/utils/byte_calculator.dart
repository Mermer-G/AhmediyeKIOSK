import 'dart:async';
import 'dart:convert';

class ByteAccumulator {
  static int _totalBytes = 0;
  static DateTime? _lastUpdate;
  static Timer? _timer;

  static void addData(Map<String, dynamic> data) {
    // Map'i JSON'a çevirip byte hesabı
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString).length;

    _totalBytes += bytes;
    _lastUpdate = DateTime.now();

    _timer?.cancel();

    _timer = Timer(const Duration(seconds: 2), () {
      final diff = DateTime.now().difference(_lastUpdate!);

      if (diff.inSeconds >= 2) {
        print("Toplam gönderilen veri: $_totalBytes byte");

        // reset
        _totalBytes = 0;
        _lastUpdate = null;
      }
    });
  }
}