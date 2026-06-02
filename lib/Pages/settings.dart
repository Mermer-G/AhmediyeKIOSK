import 'package:app1/main.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:app1/utils/debugger.dart';
import 'package:app1/utils/synchronizer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

int entryPullLimit = 300;

class SettingsPageState extends State<SettingsPage> {
  Map<String, Student> studentMap = {};

  // ─── Aksiyonlar buraya eklenir ───────────────────────────────────────────

  List<_SettingsAction> get _actions => [
    _SettingsAction(
      section: 'Yerel Verileri Resetle',
      description: 'Uygulamada tutulan tüm yerel verileri siler ve veri tabanından yeniden çeker.',
      label: 'Mevcut verileri sıfırla ve veri tabanından yeni veri al.',
      icon: Icons.delete_forever,
      color: Colors.red,
      confirmTitle: 'Emin misin?',
      confirmMessage: 'Local verilerin hepsi silinecek ve veri tabanından tekrardan çekilecek.\nBu işlem geri alınamaz!',
      onConfirm: _resetAndSync,
    ),
    _SettingsAction(
      section: 'Bozuk Verileri Göster',
      description: 'Hive\'daki outside öğrencilerin Firebase entry kayıtlarını doğrular.',
      label: 'Outside öğrencilerin entry kayıtlarını doğrula',
      icon: Icons.verified_user,
      color: Colors.blue,
      onConfirm: _verifyOutsideEntries,
    ),
    // Buraya yeni aksiyon ekle:
    // _SettingsAction(
    //   section: 'Başka Bölüm',
    //   description: '...',
    //   label: '...',
    //   icon: Icons.refresh,
    //   color: Colors.blue,
    //   onConfirm: _baskaBirMetod,
    // ),
  ];

  // ─── Aksiyon implementasyonları ──────────────────────────────────────────

  Future<void> _testFirebase() async {
    try {
      AppLogger.instance.log("🔥 Test başlıyor...");
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://ahmediye-kiosk-default-rtdb.europe-west1.firebasedatabase.app',
      );
      AppLogger.instance.log("📡 DB URL: ${db.databaseURL}");
      final snapshot = await db.ref('Student').get().timeout(const Duration(seconds: 5));
      AppLogger.instance.log("✅ Snapshot: exists=${snapshot.exists}");
    } catch (e) {
      AppLogger.instance.log("❌ Test hatası: $e");
    }
  }

  Future<void> _verifyOutsideEntries() async {
    final db = DatabaseService();

    // Hive'dan student ve state'leri çek
    final studentRaw = db.readBoxFromHive(b: Hive.box(studentBox));
    final stateRaw = db.readBoxFromHive(b: Hive.box(studentStateBox));

    final students = <String, Student>{};
    for (final entry in studentRaw.entries) {
      final s = parseToStudent(entry.value);
      if (s != null) students[entry.key] = s;
    }

    final states = <String, StudentState>{};
    for (final entry in stateRaw.entries) {
      final ss = parseToStudentState(entry.value);
      if (ss != null) states[entry.key] = ss;
    }

    AppLogger.instance.log("👥 Toplam öğrenci: ${students.length}");
    AppLogger.instance.log("📋 Toplam state: ${states.length}");

    // Outside olanları filtrele
    final outsideStates = states.entries.where((e) =>
      e.value.state == StudentStateEnum.outside
    ).toList();

    AppLogger.instance.log("🚪 Outside olan: ${outsideStates.length}");

    if (outsideStates.isEmpty) {
      AppLogger.instance.log("✅ Outside öğrenci yok.");
      return;
    }

    // Her birinin entry'sini Firebase'den çek
    int success = 0;
    int fail = 0;

    for (final stateEntry in outsideStates) {
      final key = stateEntry.key;
      final state = stateEntry.value;
      final student = students[key];
      final name = student != null
          ? "${student.name}"
          : key;

      final entryID = state.lastEntryID;

      if (entryID == null) {
        AppLogger.instance.log("🔴 $name → entryID null");
        fail++;
        continue;
      }

      final snapshot = await db.readFromDB(path: 'Entry/$entryID');

      if (snapshot != null && snapshot.exists) {
        AppLogger.instance.log("🟢 $name → Entry $entryID bulundu");
        success++;
      } else {
        AppLogger.instance.log("🔴 $name → Entry $entryID bulunamadı");
        fail++;
      }
    }

    AppLogger.instance.log("─────────────────────");
    AppLogger.instance.log("✅ Bulunan: $success  ❌ Bulunamayan: $fail");
  }

  Future<void> _resetAndSync() async {
    // Web'de push listener yok, sadece mobilde
    if (!kIsWeb) {
      Synchronizer().entriesSub.cancel();
      Synchronizer().studentStateSub.cancel();
    }

    // Synchronizer'ı sıfırla ki start() tekrar çalışsın
    Synchronizer().reset();
    
    final db = DatabaseService();

    List<Student> tempStudents = await _fetchStudentDataFromFirebase(db);
    for (var s in tempStudents) {
      studentMap["${s.group}_${s.number}"] = s;
    }
    tempStudents.clear();

    List<Student> students = [];
    List<StudentState> studentStates = await _fetchStudentStateDataFromFireBase(db);

    for (var studentState in studentStates) {
      final key = "${studentState.group}_${studentState.number}";
      final student = studentMap.remove(key);
      if (student == null) continue;
      student.state = studentState.state.name;
      student.entryID = studentState.lastEntryID;
      students.add(student);
    }

    studentMap.forEach((k, student) {
      final newState = StudentState(
        group: student.group,
        number: student.number,
        state: StudentStateEnum.inside,
        lastEntryID: null,
      );
      studentStates.add(newState);
      student.state = newState.state.name;
      student.entryID = null;
      students.add(student);
    });

    studentMap.clear();

    Hive.box(studentBox).clear();
    for (final s in students) {
      db.updateHive(path: "${s.group}_${s.number}", data: Student.toMap(s), b: Hive.box(studentBox));
    }

    Hive.box(studentStateBox).clear();
    for (final ss in studentStates) {
      db.updateHive(path: "${ss.group}_${ss.number}", data: StudentState.toMap(ss), b: Hive.box(studentStateBox));
    }

    List<Entry> entries = await _fetchEntryDataFromFirebase(db);
    Hive.box(entryBox).clear();
    for (final e in entries) {
      db.updateHive(path: e.entryID.toString(), data: Entry.toMap(e), b: Hive.box(entryBox));
    }

    await Synchronizer().start();
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Aksiyonları section'a göre grupla
    final Map<String, List<_SettingsAction>> grouped = {};
    for (final action in _actions) {
      grouped.putIfAbsent(action.section, () => []).add(action);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 10.0,
        title: const Text('Ahmediye K.I.O.S.K', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 90, 90, 90),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 500,
            child: ListView(
              shrinkWrap: true,
              children: grouped.entries.map((entry) {
                return _SettingsSection(
                  title: entry.key,
                  actions: entry.value,
                  onAction: (action) => _showConfirmDialog(context, action),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, _SettingsAction action) {
    if (action.confirmTitle == null) {
      _runAction(context, action);
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(action.confirmTitle!),
        content: Text(action.confirmMessage ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: action.color),
            onPressed: () {
              _runAction(context, action);
              Navigator.pop(context);
            },
            child: const Text('Onayla', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _runAction(BuildContext context, _SettingsAction action) async {
    try {
      await action.onConfirm();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${action.label} tamamlandı.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Firebase fetch metodları ─────────────────────────────────────────────

  Future<List<Student>> _fetchStudentDataFromFirebase(DatabaseService db) async {
    final snapshot = await db.readFromDB(path: 'Student');
    return parseToStudents(snapshot?.value);
  }

  // Future<List<Entry>> _fetchEntryDataFromFirebase(DatabaseService db) async {
  //   final snapshot = await db.readFromDB(path: 'Entry');
  //   return parseToEntries(snapshot?.value);
  // }

  Future<List<Entry>> _fetchEntryDataFromFirebase(DatabaseService db) async {
  final app = Firebase.app(fireBaseAppName);

  final ref = FirebaseDatabase.instanceFor(
    app: app,
    databaseURL: app.options.databaseURL!,
  )
  .ref('Entry')
  .orderByChild(entryIDDB)
  .limitToLast(300);
    final snapshot = await ref.get();

    return parseToEntries(snapshot.value);
  }

  Future<List<StudentState>> _fetchStudentStateDataFromFireBase(DatabaseService db) async {
    final snapshot = await db.readFromDB(path: 'StudentState');
    return parseToStudentStates(snapshot?.value);
  }
}

// ─── Yardımcı modeller ────────────────────────────────────────────────────────

class _SettingsAction {
  final String section;
  final String description;
  final String label;
  final IconData icon;
  final Color color;
  final String? confirmTitle;
  final String? confirmMessage;
  final Future<void> Function() onConfirm;

  _SettingsAction({
    required this.section,
    required this.description,
    required this.label,
    required this.icon,
    required this.color,
    required this.onConfirm,
    this.confirmTitle,
    this.confirmMessage,
  });
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsAction> actions;
  final void Function(_SettingsAction) onAction;

  const _SettingsSection({
    required this.title,
    required this.actions,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...actions.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.description, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => onAction(action),
                    icon: Icon(action.icon),
                    label: Text(action.label),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: action.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}


// ─── Parse yardımcıları (settings.dart'ta kalabilir) ─────────────────────────

Student? parseToStudent(Object? raw) {
  if (raw is Map) return Student.fromMap(Map<String, dynamic>.from(raw));
  return null;
}

Entry? parseToEntry(Object? raw) {
  if (raw is Map) return Entry.fromMap(Map<String, dynamic>.from(raw));
  return null;
}

StudentState? parseToStudentState(Object? raw) {
  if (raw is Map) return StudentState.fromMap(Map<String, dynamic>.from(raw));
  return null;
}

List<Student> parseToStudents(Object? raw) {
  if (raw is! Map) return [];
  return parseToDataType(
    raw.map((k, v) => MapEntry(k.toString(), v)),
    Student.fromMap,
  );
}

List<Entry> parseToEntries(Object? raw) {
  if (raw is! Map) return [];
  return parseToDataType(
    raw.map((k, v) => MapEntry(k.toString(), v)),
    Entry.fromMap,
  );
}

List<StudentState> parseToStudentStates(Object? raw) {
  if (raw is! Map) return [];
  return parseToDataType(
    raw.map((k, v) => MapEntry(k.toString(), v)),
    StudentState.fromMap,
  );
}

String formatDateTime(DateTime dt) {
  const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  
  final day    = dt.day.toString().padLeft(2, '0');
  final month  = dt.month.toString().padLeft(2, '0');
  final year   = dt.year.toString();
  final hour   = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final second = dt.second.toString().padLeft(2, '0');
  final dayName = days[dt.weekday - 1];

  return '$day/$month/$year $hour.$minute.$second $dayName';
}

int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}