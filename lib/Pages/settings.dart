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
  Map<String, Member> memberMap = {};

  String _searchQuery = '';
  bool _isRunning = false;

  // ─── Aksiyonlar buraya eklenir ───────────────────────────────────────────
  // Aşağıdaki liste 20 farklı aksiyonu rahatça barındıracak şekilde
  // tasarlandı. Yeni bir aksiyon eklemek için tek yapman gereken
  // listeye yeni bir _SettingsAction eklemek; UI otomatik olarak
  // section'lara göre gruplayıp güzelce render ediyor.

  List<_SettingsAction> get _actions => [
    _SettingsAction(
      section: 'Veri Yönetimi',
      title: 'Yerel Verileri Resetle',
      description:
          'Uygulamada tutulan tüm yerel verileri siler ve veri tabanından yeniden çeker.',
      label: 'Mevcut verileri sıfırla ve veri tabanından yeni veri al.',
      icon: Icons.delete_forever_rounded,
      color: Colors.red,
      confirmTitle: 'Emin misin?',
      confirmMessage:
          'Local verilerin hepsi silinecek ve veri tabanından tekrardan çekilecek.\nBu işlem geri alınamaz!',
      onConfirm: _resetAndSync,
    ),
    _SettingsAction(
      section: 'Veri Yönetimi',
      title: 'Bozuk Verileri Göster',
      description: "Hive'daki outside öğrencilerin Firebase entry kayıtlarını doğrular.",
      label: "Outside öğrencilerin entry kayıtlarını doğrula.",
      icon: Icons.verified_user_rounded,
      color: Colors.blue,
      onConfirm: _verifyOutsideEntries,
    ),
    _SettingsAction(
      section: 'Senkronizasyon',
      title: 'Bütün Üyeleri Pushla',
      description: "Hive'da mevcut bulunan üyeleri RTDB'ye pushlar. (HAZIR DEĞİL)",
      label: 'Üyeleri veri tabanına gönder.',
      icon: Icons.cloud_upload_rounded,
      color: Colors.orange,
      badge: 'HAZIR DEĞİL',
      onConfirm: _testFirebase,
    ),
    // Buraya yeni aksiyon ekle, ör:
    // _SettingsAction(
    //   section: 'Başka Bölüm',
    //   title: 'Kısa Başlık',
    //   description: 'Ne yaptığını anlatan açıklama.',
    //   label: 'Buton üzerindeki metin.',
    //   icon: Icons.refresh_rounded,
    //   color: Colors.teal,
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
      final snapshot = await db.ref('Member').get().timeout(const Duration(seconds: 5));
      AppLogger.instance.log("✅ Snapshot: exists=${snapshot.exists}");
    } catch (e) {
      AppLogger.instance.log("❌ Test hatası: $e");
    }
  }

  Future<void> _verifyOutsideEntries() async {
    final db = DatabaseService();

    // Hive'dan member ve state'leri çek
    final memberRaw = db.readBoxFromHive(b: Hive.box(memberBox));
    final stateRaw = db.readBoxFromHive(b: Hive.box(memberStateBox));

    final members = <String, Member>{};
    for (final entry in memberRaw.entries) {
      final s = parseToMember(entry.value);
      if (s != null) members[entry.key] = s;
    }

    final states = <String, MemberState>{};
    for (final entry in stateRaw.entries) {
      final ss = parseToMemberState(entry.value);
      if (ss != null) states[entry.key] = ss;
    }

    AppLogger.instance.log("👥 Toplam öğrenci: ${members.length}");
    AppLogger.instance.log("📋 Toplam state: ${states.length}");

    // Outside olanları filtrele
    final outsideStates = states.entries.where((e) =>
      e.value.state == MemberStateEnum.outside
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
      final member = members[key];
      final name = member != null
          ? "${member.name}"
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
      Synchronizer().memberStateSub.cancel();
    }

    // Synchronizer'ı sıfırla ki start() tekrar çalışsın
    Synchronizer().reset();

    final db = DatabaseService();

    List<Member> tempMembers = await _fetchMemberDataFromFirebase(db);
    for (var s in tempMembers) {
      memberMap["${s.group}_${s.number}"] = s;
    }
    tempMembers.clear();

    List<Member> members = [];
    List<MemberState> memberStates = await _fetchMemberStateDataFromFireBase(db);

    for (var memberState in memberStates) {
      final key = "${memberState.group}_${memberState.number}";
      final member = memberMap.remove(key);
      if (member == null) continue;
      member.state = memberState.state.name;
      member.entryID = memberState.lastEntryID;
      members.add(member);
    }

    memberMap.forEach((k, member) {
      final newState = MemberState(
        group: member.group,
        number: member.number,
        state: MemberStateEnum.inside,
        lastEntryID: null,
      );
      memberStates.add(newState);
      member.state = newState.state.name;
      member.entryID = null;
      members.add(member);
    });

    memberMap.clear();

    Hive.box(memberBox).clear();
    for (final s in members) {
      db.updateHive(path: "${s.group}_${s.number}", data: Member.toMap(s), b: Hive.box(memberBox));
    }

    Hive.box(memberStateBox).clear();
    for (final ss in memberStates) {
      db.updateHive(path: "${ss.group}_${ss.number}", data: MemberState.toMap(ss), b: Hive.box(memberStateBox));
    }

    List<Entry> entries = await _fetchEntryDataFromFirebase(db);
    Hive.box(entryBox).clear();
    for (final e in entries) {
      db.updateHive(path: e.entryID.toString(), data: Entry.toMap(e), b: Hive.box(entryBox));
    }

    await Synchronizer().start();
  }

  Future<void> _pushMembersToDB() async {}

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _actions
        : _actions.where((a) {
            return a.title.toLowerCase().contains(query) ||
                a.description.toLowerCase().contains(query) ||
                a.section.toLowerCase().contains(query);
          }).toList();

    final Map<String, List<_SettingsAction>> grouped = {};
    for (final action in filtered) {
      grouped.putIfAbsent(action.section, () => []).add(action);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Ahmediye K.I.O.S.K',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2E2E33),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: _SearchField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                Expanded(
                  child: grouped.isEmpty
                      ? const Center(
                          child: Text(
                            'Sonuç bulunamadı.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          children: grouped.entries.map((entry) {
                            return _SettingsSection(
                              title: entry.key,
                              actions: entry.value,
                              onAction: _isRunning
                                  ? null
                                  : (action) => _showConfirmDialog(context, action),
                            );
                          }).toList(),
                        ),
                ),
              ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: action.color),
            const SizedBox(width: 10),
            Expanded(child: Text(action.confirmTitle!)),
          ],
        ),
        content: Text(action.confirmMessage ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _runAction(context, action);
            },
            child: const Text('Onayla', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _runAction(BuildContext context, _SettingsAction action) async {
    setState(() => _isRunning = true);
    try {
      await action.onConfirm();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.green.shade600,
            content: Text('${action.label} tamamlandı.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.red.shade600,
            content: Text('Hata: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  // ─── Firebase fetch metodları ─────────────────────────────────────────────

  Future<List<Member>> _fetchMemberDataFromFirebase(DatabaseService db) async {
    final snapshot = await db.readFromDB(path: 'Member');
    return parseToMembers(snapshot?.value);
  }

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

  Future<List<MemberState>> _fetchMemberStateDataFromFireBase(DatabaseService db) async {
    final snapshot = await db.readFromDB(path: 'MemberState');
    return parseToMemberStates(snapshot?.value);
  }
}

// ─── Yardımcı modeller ────────────────────────────────────────────────────────

class _SettingsAction {
  final String section;
  final String title;
  final String description;
  final String label;
  final IconData icon;
  final Color color;
  final String? confirmTitle;
  final String? confirmMessage;
  final String? badge;
  final Future<void> Function() onConfirm;

  _SettingsAction({
    required this.section,
    required this.title,
    required this.description,
    required this.label,
    required this.icon,
    required this.color,
    required this.onConfirm,
    this.confirmTitle,
    this.confirmMessage,
    this.badge,
  });
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Aksiyon ara...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsAction> actions;
  final void Function(_SettingsAction)? onAction;

  const _SettingsSection({
    required this.title,
    required this.actions,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Color(0xFF6B6B70),
                ),
              ),
            ),
            for (int i = 0; i < actions.length; i++) ...[
              _ActionTile(
                action: actions[i],
                onTap: onAction == null ? null : () => onAction!(actions[i]),
              ),
              if (i != actions.length - 1)
                const Divider(height: 1, indent: 72, endIndent: 16),
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final _SettingsAction action;
  final VoidCallback? onTap;

  const _ActionTile({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            action.title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F1F23),
                            ),
                          ),
                        ),
                        if (action.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              action.badge!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.description,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A8F), height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC4C4C8)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Parse yardımcıları (settings.dart'ta kalabilir) ─────────────────────────

Member? parseToMember(Object? raw) {
  if (raw is Map) return Member.fromMap(Map<String, dynamic>.from(raw));
  return null;
}

Entry? parseToEntry(Object? raw) {
  if (raw is Map) return Entry.fromMap(Map<String, dynamic>.from(raw));
  return null;
}

MemberState? parseToMemberState(Object? raw) {
  if (raw is Map) return MemberState.fromMap(Map<String, dynamic>.from(raw));
  return null;
}

List<Member> parseToMembers(Object? raw) {
  if (raw is! Map) return [];
  return parseToDataType(
    raw.map((k, v) => MapEntry(k.toString(), v)),
    Member.fromMap,
  );
}

List<Entry> parseToEntries(Object? raw) {
  if (raw is! Map) return [];
  return parseToDataType(
    raw.map((k, v) => MapEntry(k.toString(), v)),
    Entry.fromMap,
  );
}

List<MemberState> parseToMemberStates(Object? raw) {
  if (raw is! Map) return [];
  return parseToDataType(
    raw.map((k, v) => MapEntry(k.toString(), v)),
    MemberState.fromMap,
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