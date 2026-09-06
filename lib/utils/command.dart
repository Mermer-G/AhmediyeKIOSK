import "dart:async";
import "package:app1/Pages/home.dart";
import "package:app1/utils/database_service.dart";
import "package:app1/utils/debugger.dart";
import "package:firebase_database/firebase_database.dart";
import "package:flutter/foundation.dart";
import "package:hive/hive.dart";
import 'database_service.dart';

class CommandListener {
  StreamSubscription<DatabaseEvent>? _subscription;

  void start() {
    final db = DatabaseService();

    final ref = db.firebaseDatabase
        .ref()
        .child('Command');

    _subscription = ref.onChildAdded.listen((event) async {
      if (!event.snapshot.exists) return;

      try {
        final data = Map<String, dynamic>.from(
          event.snapshot.value as Map,
        );

        final command = Command.fromMap(data);

        if (command.status != CommandStatus.pending) return;

        await _handleCommand(ref, command);
      } catch (e) {
        AppLogger.instance.error(
          'Command okunamadı: $e',
        );
      }
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _handleCommand(
    DatabaseReference ref,
    Command command,
  ) async {
    if(kIsWeb){
      if(command.receivedDevices.containsKey(deviceID)) 
        return;
    }
    
    
    AppLogger.instance.log(
      'Yeni command algılandı: ${command.id}',
    );

    AppLogger.instance.showOverlay(
      'Yeni bir komut algılandı.',
      LogLevel.info,
    );

    try {
      await _setProcessing(ref, command);

      await _executeCommand(command);

      await _setCompleted(ref, command);
    } catch (e) {
      await _setFailed(ref, command, e);
    }
    
    try{
      // WEB COMMAND RECEIVED
      if (kIsWeb) {
        final dbService = DatabaseService();
        await dbService.updateDB(
          path: 'Command/${command.id}/receivedDevices',
          data: {
            deviceID: 'completed',
          },
        );

        AppLogger.instance.log("Sent completed for received command: ${command.id}",level: LogLevel.warning);
      }
    } catch (e) {
      // ortak command hata yönetimi
      rethrow;
    }
  }

  Future<void> _setProcessing(
    DatabaseReference ref,
    Command command,
  ) async {
    await ref.child(command.id).update({
      'status': CommandStatus.processing.name,
    });

    AppLogger.instance.log(
      'Command processing durumuna geçirildi: ${command.id}',
    );
  }

  Future<void> _executeCommand(Command command) async {
    switch (command.type) {
      case CommandType.test:
        await _executeTestCommand(command);
        break;

      case CommandType.entryDelete:
        await _executeEntryDeleteCommand(command);
        break;

      case CommandType.entryEdit:
        await _executeEntryEditCommand(command);
        break;

      case CommandType.entryCreateExisting:
        await _executeEntryCreateExistingCommand(command);
        break;
      case CommandType.memberDelete:
        await _executeMemberDeleteCommand(command);
        break;
      case CommandType.memberEdit:
        await _executeMemberEditCommand(command);
        break;
    }
  }

  Future<void> _executeTestCommand(Command command) async {
    AppLogger.instance.log(
      'Test command işleniyor: ${command.id}',
    );

    AppLogger.instance.showOverlay(
      command.data["message"],
      LogLevel.warning,
    );
    //TODO: Bunu bir mesaj window haline getir. Dialog zorunlu ya da zorunsuz olsun.
  }

  Future<void> _executeEntryDeleteCommand(Command command) async {
    final entryID = command.data['entryID'];

    if (entryID == null) {
      throw Exception('EntryDelete command içinde EntryID bulunamadı.');
    }

    final entryKey = entryID.toString();
    final db = DatabaseService();

    // HIVE
    try {
      final box = Hive.box(entryBox);

      if (!box.containsKey(entryKey)) {
        AppLogger.instance.log(
          'Entry Hive üzerinde bulunamadı: $entryKey',
        );
      } else {
        await box.delete(entryKey);

        AppLogger.instance.log(
          'Entry Hive üzerinden silindi: $entryKey',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Entry Hive silme hatası: $entryKey - $e',
      );

      throw Exception(
        'Entry Hive üzerinden silinemedi: $e',
      );
    }
    if (!kIsWeb) {
      // FIREBASE
      try {
        final ref = db.firebaseDatabase
            .ref()
            .child('Entry')
            .child(entryKey);

        final snapshot = await ref.get();

        if (!snapshot.exists) {
          AppLogger.instance.log(
            'Entry Firebase üzerinde bulunamadı: $entryKey',
          );
        } else {
          await ref.remove();

          AppLogger.instance.log(
            'Entry Firebase üzerinden silindi: $entryKey',
          );
        }
      } catch (e, stackTrace) {
        AppLogger.instance.error(
          'Entry Firebase silme hatası: $entryKey - $e',
        );

        throw Exception(
          'Entry Firebase üzerinden silinemedi: $e',
        );
      }
    }
  }

  Future<void> _executeEntryEditCommand(Command command) async {
    final entryID = command.data['entryID'];
    final entryData = command.data['entry'];

    if (entryID == null) {
      throw Exception(
        'EntryEdit command içinde EntryID bulunamadı.',
      );
    }

    if (entryData == null) {
      throw Exception(
        'EntryEdit command içinde Entry verisi bulunamadı.',
      );
    }

    final entryKey = entryID.toString();

    try {
      final box = Hive.box(entryBox);

      if (!box.containsKey(entryKey)) {
        throw Exception(
          'Düzenlenecek Entry Hive üzerinde bulunamadı: $entryKey',
        );
      }

      final entryMap = Map<String, dynamic>.from(entryData);

      await box.put(
        entryKey,
        entryMap,
      );

      AppLogger.instance.log(
        'Entry Hive üzerinde güncellendi: $entryKey',
      );
    } catch (e) {
      AppLogger.instance.error(
        'Entry Hive güncelleme hatası: $entryKey - $e',
      );

      throw Exception(
        'Entry Hive üzerinde güncellenemedi: $e',
      );
    }

    if (!kIsWeb) {
      try {
        final ref = DatabaseService()
            .firebaseDatabase
            .ref()
            .child('Entry')
            .child(entryKey);

        final snapshot = await ref.get();

        if (!snapshot.exists) {
          throw Exception(
            'Düzenlenecek Entry Firebase üzerinde bulunamadı: $entryKey',
          );
        }

        final entryMap = Map<String, dynamic>.from(entryData);

        await ref.update(entryMap);

        AppLogger.instance.log(
          'Entry Firebase üzerinde güncellendi: $entryKey',
        );
      } catch (e) {
        AppLogger.instance.error(
          'Entry Firebase güncelleme hatası: $entryKey - $e',
        );

        throw Exception(
          'Entry Firebase üzerinde güncellenemedi: $e',
        );
      }
    }
  }

  Future<void> _executeEntryCreateExistingCommand(Command command) async {
    final entryID = command.data['entryID'];
    final entryData = command.data['entry'];

    if (entryID == null) {
      throw Exception(
        'EntryCreateExisting command içinde EntryID bulunamadı.',
      );
    }

    if (entryData == null) {
      throw Exception(
        'EntryCreateExisting command içinde Entry verisi bulunamadı.',
      );
    }

    final entryKey = entryID.toString();
    final entryMap = Map<String, dynamic>.from(entryData);

    final db = DatabaseService();

    // ------------------------------------------------------------
    // 1. Hive kontrolü
    // ------------------------------------------------------------

    try {
      final box = Hive.box(entryBox);

      if (box.containsKey(entryKey)) {
        throw Exception(
          'Entry zaten Hive üzerinde mevcut: $entryKey',
        );
      }

      await box.put(
        entryKey,
        entryMap,
      );

      AppLogger.instance.log(
        'Yeni Entry Hive üzerine eklendi: $entryKey',
      );
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Entry Hive ekleme hatası: $entryKey - $e',
      );

      throw Exception(
        'Entry Hive üzerine eklenemedi: $e',
      );
    }

    if(!kIsWeb){
      // ------------------------------------------------------------
      // 2. Firebase kontrolü + ekleme
      // ------------------------------------------------------------

      try {
        final ref = db.firebaseDatabase
            .ref()
            .child('Entry')
            .child(entryKey);

        final snapshot = await ref.get();

        // Mevcut Entry'nin üzerine kesinlikle yazma.
        if (snapshot.exists) {
          // Hive'a biraz önce eklediğimiz kaydı da geri al.
          await Hive.box(entryBox).delete(entryKey);

          throw Exception(
            'Entry zaten Firebase üzerinde mevcut: $entryKey',
          );
        }

        await ref.set(entryMap);

        AppLogger.instance.log(
          'Yeni Entry Firebase üzerine eklendi: $entryKey',
        );
      } catch (e, stackTrace) {
        AppLogger.instance.error(
          'Entry Firebase ekleme hatası: $entryKey - $e',
        );

        // Firebase işlemi başarısız olduysa Hive'daki
        // henüz senkronize edilmemiş kaydı da kaldır.
        try {
          await Hive.box(entryBox).delete(entryKey);
        } catch (_) {}

        throw Exception(
          'Entry Firebase üzerine eklenemedi: $e',
        );
      }
    }
  }

  Future<void> _executeMemberDeleteCommand(Command command) async {
    final memberID = command.data['memberID'];

    if (memberID == null) {
      throw Exception(
        'MemberDelete command içinde memberID bulunamadı.',
      );
    }

    final memberKey = memberID.toString();

    final db = DatabaseService();

    // =========================
    // Hive
    // =========================

    try {
      await Hive.box(memberBox).delete(memberKey);
      await Hive.box(memberStateBox).delete(memberKey);

      AppLogger.instance.log(
        'Member ve MemberState Hive üzerinden silindi: $memberKey',
      );
    } catch (e) {
      AppLogger.instance.error(
        'Member Hive silme hatası: $memberKey - $e',
      );

      throw Exception(
        'Member Hive üzerinden silinemedi: $e',
      );
    }
    if(!kIsWeb){
      // =========================
      // Firebase
      // =========================

      try {
        await db.firebaseDatabase
            .ref()
            .child('Member')
            .child(memberKey)
            .remove();

        await db.firebaseDatabase
            .ref()
            .child('MemberState')
            .child(memberKey)
            .remove();

        AppLogger.instance.log(
          'Member ve MemberState Firebase üzerinden silindi: $memberKey',
        );
      } catch (e) {
        AppLogger.instance.error(
          'Member Firebase silme hatası: $memberKey - $e',
        );

        throw Exception(
          'Member Firebase üzerinden silinemedi: $e',
        );
      }
    }
  }

  Future<void> _executeMemberEditCommand(Command command) async {
    final memberID = command.data['memberID'];
    final memberData = command.data['member'];

    if (memberID == null) {
      throw Exception(
        'MemberEdit command içinde MemberID bulunamadı.',
      );
    }

    if (memberData == null) {
      throw Exception(
        'MemberEdit command içinde Member verisi bulunamadı.',
      );
    }

    final memberKey = memberID.toString();
    final db = DatabaseService();

    final memberMap = Map<String, dynamic>.from(memberData);

    // HIVE
    try {
      final box = Hive.box(memberBox);

      if (!box.containsKey(memberKey)) {
        AppLogger.instance.log(
          'Member Hive üzerinde bulunamadı: $memberKey',
        );
      }

      await box.put(
        memberKey,
        memberMap,
      );

      AppLogger.instance.log(
        'Member Hive üzerinde güncellendi: $memberKey',
      );
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Member Hive güncelleme hatası: $memberKey - $e',
      );

      throw Exception(
        'Member Hive üzerinde güncellenemedi: $e',
      );
    }
    if(!kIsWeb){
      // FIREBASE
      try {
        final ref = db.firebaseDatabase
            .ref()
            .child('Member')
            .child(memberKey);

        final snapshot = await ref.get();

        if (!snapshot.exists) {
          AppLogger.instance.log(
            'Member Firebase üzerinde bulunamadı: $memberKey',
          );
        }

        await ref.update(memberMap);

        AppLogger.instance.log(
          'Member Firebase üzerinde güncellendi: $memberKey',
        );
      } catch (e, stackTrace) {
        AppLogger.instance.error(
          'Member Firebase güncelleme hatası: $memberKey - $e',
        );

        throw Exception(
          'Member Firebase üzerinde güncellenemedi: $memberKey',
        );
      }
    }
  }

  Future<void> _setCompleted(
    DatabaseReference ref,
    Command command,
  ) async {
    await ref.child(command.id).update({
      'status': CommandStatus.completed.name,
      'completedAt': DateTime.now().millisecondsSinceEpoch,
    });

    AppLogger.instance.log(
      'Command tamamlandı: ${command.id}',
    );
  }

  Future<void> _setFailed(
    DatabaseReference ref,
    Command command,
    Object error,
  ) async {
    await ref.child(command.id).update({
      'status': CommandStatus.failed.name,
      'error': error.toString(),
    });

    AppLogger.instance.error(
      'Command başarısız: ${command.id} - $error',
    );
  }

}

class Command {
  final String id;
  final String admin;
  final CommandType type;
  final CommandStatus status;
  final Map<String, dynamic> data;
  final Map<String, dynamic> receivedDevices;
  final int createdAt;
  final int? completedAt;
  final String? error;

  Command({
    required this.id,
    required this.admin,
    required this.type,
    required this.status,
    required this.data,
    required this.createdAt,
    required this.receivedDevices,
    this.completedAt,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'admin': admin,
      'type': type.name,
      'status': status.name,
      'data': data,
      'receivedDevices': receivedDevices,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'error': error,
    };
  }

  factory Command.fromMap(Map<String, dynamic> map) {
    return Command(
      id: map['id'],
      admin: map['admin'],
      type: CommandType.values.byName(map['type']),
      status: CommandStatus.values.byName(map['status']),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      receivedDevices: Map<String, dynamic>.from(map['receivedDevices'] ?? {}),
      createdAt: map['createdAt'],
      completedAt: map['completedAt'],
      error: map['error'],
    );
  }
}

enum CommandStatus {
  pending,
  processing,
  completed,
  failed,
}

enum CommandType {
  test,
  entryEdit,
  entryDelete,
  entryCreateExisting,
  memberDelete,
  memberEdit,
}