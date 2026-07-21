import 'dart:async';
import 'package:app1/utils/database_service.dart';
import 'package:app1/utils/debugger.dart';
import 'package:hive/hive.dart';

class QueueItem {
  final String id;
  final String path;
  final Map<String, dynamic> data;
  final int timestamp;

  QueueItem({
    required this.id,
    required this.path,
    required this.data,
    required this.timestamp,
  });
}


class QueueHelper {
  DatabaseService _databaseService = DatabaseService();

  static Future<void> addToSyncQueue(String path, Map<String, dynamic> data) async {
    final box = Hive.box(queueBox);

    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await box.put(id, {
      "path": path,
      "data": data,
    });
    AppLogger.instance.log("Veri sıraya alındı: İd: $id, path: $path, data: $data");
  }

  Future<void> syncQueue() async {
  final box = Hive.box(queueBox);

  for (final key in box.keys.toList()) {
      final item = Map<String, dynamic>.from(box.get(key));

      try {
        await _databaseService.updateDB(
          path: item["path"],
          data: Map<String, dynamic>.from(item["data"]),
        );

        await box.delete(key);

        AppLogger.instance.log("Synced queue item: $key");
      } catch (e) {
        AppLogger.instance.error("Queue sync stopped: $e");
        break;
      }
    }
  }

}