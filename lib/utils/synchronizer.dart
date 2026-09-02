import 'dart:async';
import 'dart:convert';
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

    AppLogger.instance.log(
      "Synchronizer reset.",
    );
  }
  
  bool started = false;
  Future<void> start() async {
    if (started) {
      AppLogger.instance.log(
        "Synchronizer.start() zaten başlatılmış, işlem atlandı.",
      );
      return;
    }

    started = true;

    AppLogger.instance.log(
      "========== Synchronizer START ==========",
    );

    try {
      if (kIsWeb) {
        AppLogger.instance.log(
          "Platform: WEB",
        );

        // WEB:
        // Firebase → Hive
        AppLogger.instance.log(
          "Web initial pull başlatılıyor...",
        );

        await initInitialPull();

        AppLogger.instance.log(
          "Web initial pull başarıyla tamamlandı.",
        );

        AppLogger.instance.log(
          "Pull listenerlar başlatıldı.",
        );

      } else {
        AppLogger.instance.log(
          "Platform: MOBILE / TABLET",
        );

        // TABLET:
        // Hive → Firebase
        AppLogger.instance.log(
          "Tablet push listener'ları başlatılıyor...",
        );

        initSyncPushListeners();

        AppLogger.instance.log(
          "Tablet push listener'ları başarıyla başlatıldı.",
        );
      }
    } catch (e, stack) {
      AppLogger.instance.error(
        "Synchronizer.start() başarısız oldu: $e",
      );

      AppLogger.instance.error(
        "Synchronizer stack trace: $stack",
      );

      // Başlatma başarısız olduysa tekrar denenebilmesine izin ver.
      started = false;
    }

    AppLogger.instance.log(
      "========== Synchronizer END ==========",
    );
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
          
          AppLogger.instance.showOverlay("Bir üye verisi veritabanına aktarılamadı! Daha sonra işlenmek üzere yerel olarak kaydedildi. \n İnternet bağlantınızı kontrol edin!", LogLevel.error);
          AppLogger.instance.error("Bir üye verisi veritabanına aktarılamadı! Daha sonra işlenmek üzere yerel olarak kaydedildi. \n İnternet bağlantınızı kontrol edin!");
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

  Future<void> initInitialPull() async {
    int totalBytes = 0;

    AppLogger.instance.log(
      "========== INITIAL PULL START ==========",
    );

    // ─────────────────────────────
    // Member State
    // ─────────────────────────────

    try {
      AppLogger.instance.log("📥 Fetching MemberState...");

      final snapshot = await memberStateRef.get();

      if (snapshot.exists) {
        final jsonString = jsonEncode(snapshot.value);
        final bytes = utf8.encode(jsonString).length;
        totalBytes += bytes;

        AppLogger.instance.log(
          "📦 MemberState Download Size: $bytes bytes",
        );

        final data = snapshot.value;

        if (data is Map) {
          int count = 0;

          for (final entry in data.entries) {
            final memberState = parseToMemberState(entry.value);

            if (memberState == null) {
              AppLogger.instance.error(
                "Could not parse MemberState: ${entry.key}",
              );
              continue;
            }

            final path =
                "${memberState.group}_${memberState.number}";

            _dbService.updateHive(
              path: path,
              data: MemberState.toMap(memberState),
              b: Hive.box(memberStateBox),
            );

            count++;
          }

          AppLogger.instance.log(
            "✅ Loaded $count member states.",
          );
        } else {
          AppLogger.instance.error(
            "Unexpected MemberState data format.",
          );
        }
      } else {
        AppLogger.instance.log(
          "No MemberState data found.",
        );
      }
    } catch (e, stack) {
      AppLogger.instance.error(
        "Failed to pull MemberState: $e",
      );
      AppLogger.instance.error(
        "Stack: $stack",
      );
    }

    // ─────────────────────────────
    // Entries
    // ─────────────────────────────

    try {
      AppLogger.instance.log(
        "📥 Fetching last $entryPullLimit entries...",
      );

      final snapshot = await entriesRef
          .orderByChild(entryIDDB)
          .limitToLast(entryPullLimit)
          .get();

      if (snapshot.exists) {
        final jsonString = jsonEncode(snapshot.value);
        final bytes = utf8.encode(jsonString).length;
        totalBytes += bytes;

        AppLogger.instance.log(
          "📦 Entries Download Size: $bytes bytes",
        );

        final data = snapshot.value;

        if (data is Map) {
          int count = 0;

          for (final entry in data.entries) {
            final entryObj = parseToEntry(entry.value);

            if (entryObj == null) {
              AppLogger.instance.error(
                "Could not parse Entry: ${entry.key}",
              );
              continue;
            }

            _dbService.updateHive(
              path: entryObj.entryID.toString(),
              data: Entry.toMap(entryObj),
              b: Hive.box(entryBox),
            );

            count++;
          }

          AppLogger.instance.log(
            "✅ Loaded $count entries.",
          );
        } else {
          AppLogger.instance.error(
            "Unexpected Entry data format.",
          );
        }
      } else {
        AppLogger.instance.log(
          "No Entry data found.",
        );
      }
    } catch (e, stack) {
      AppLogger.instance.error(
        "Failed to pull Entries: $e",
      );
      AppLogger.instance.error(
        "Stack: $stack",
      );
    }

    // ─────────────────────────────
    // Members
    // ─────────────────────────────

    try {
      AppLogger.instance.log(
        "📥 Fetching Members...",
      );

      final snapshot = await memberRef.get();

      if (snapshot.exists) {
        final jsonString = jsonEncode(snapshot.value);
        final bytes = utf8.encode(jsonString).length;
        totalBytes += bytes;

        AppLogger.instance.log(
          "📦 Members Download Size: $bytes bytes",
        );

        final data = snapshot.value;

        if (data is Map) {
          int count = 0;

          for (final entry in data.entries) {
            final member = parseToMember(entry.value);

            if (member == null) {
              AppLogger.instance.error(
                "Could not parse Member: ${entry.key}",
              );
              continue;
            }

            _dbService.updateHive(
              path: "${member.group}_${member.number}",
              data: Member.toMap(member),
              b: Hive.box(memberBox),
            );

            count++;
          }

          lastUpdateTime = DateTime.now();

          AppLogger.instance.log(
            "✅ Loaded $count members.",
          );
        } else {
          AppLogger.instance.error(
            "Unexpected Member data format.",
          );
        }
      } else {
        AppLogger.instance.log(
          "No Member data found.",
        );
      }
    } catch (e, stack) {
      AppLogger.instance.error(
        "Failed to pull Members: $e",
      );
      AppLogger.instance.error(
        "Stack: $stack",
      );
    }

    // ─────────────────────────────
    // Download summary
    // ─────────────────────────────

    AppLogger.instance.log(
      "📊 TOTAL DOWNLOAD: $totalBytes bytes",
    );

    AppLogger.instance.log(
      "📊 TOTAL DOWNLOAD: "
      "${(totalBytes / 1024).toStringAsFixed(2)} KB",
    );

    AppLogger.instance.log(
      "📊 TOTAL DOWNLOAD: "
      "${(totalBytes / (1024 * 1024)).toStringAsFixed(4)} MB",
    );

    AppLogger.instance.log(
      "========== INITIAL PULL END ==========",
    );
  }



}