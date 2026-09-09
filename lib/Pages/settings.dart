import 'package:app1/Pages/new_home.dart';
import 'package:app1/Theme/dashboard_theme.dart';
import 'package:app1/main.dart';
import 'package:app1/utils/auth_service.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:app1/utils/debugger.dart';
import 'package:app1/utils/command.dart';
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
      section: 'Bağlantı',
      title: 'Veri Tabanını Dürt',
      description:
          'Veri Tabanına ping göndererek bağlantıyı kontrol eder.',
      label: 'Bağlantıyı kontrol et.',
      icon: Icons.wifi,
      color: Colors.green,
      confirmTitle: 'Ping gönderilsin mi?',
      confirmMessage:
          'Ping göndermek üzeresiniz.',
      onConfirm: _testFirebase,
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
      section: 'Veri Çekme',
      title: 'Üyeleri Veritabanından Çek',
      description:
          'Veritabanındaki üye verilerini yerel depolamaya çeker.',
      label: 'Üye verilerini veritabanından yeniden al.',
      icon: Icons.download_rounded,
      color: Colors.blue,
      confirmTitle: 'Üyeler çekilsin mi?',
      confirmMessage:
          'Veritabanındaki üye verileri yerel verilerle değiştirilecek.\nDevam etmek istiyor musun?',
      onConfirm: _pullMembers,
    ),
    _SettingsAction(
      section: 'Veri Çekme',
      title: 'Giriş-Çıkış Verilerini Çek',
      description:
          'Veritabanındaki tüm giriş-çıkış kayıtlarını yerel depolamaya çeker.',
      label: 'Giriş-çıkış verilerini veritabanından yeniden al.',
      icon: Icons.download_rounded,
      color: Colors.blue,
      confirmTitle: 'Giriş-çıkış verileri çekilsin mi?',
      confirmMessage:
          'Yerel giriş-çıkış verileri silinecek ve veritabanındaki veriler yeniden çekilecek.\nDevam etmek istiyor musun?',
      onConfirm: _pullEntries,
    ),
    _SettingsAction(
      section: 'Veri İtme',
      title: 'Tüm Üyeleri Veritabanına Gönder',
      description:
          'Yerel üye ve üye durumlarını veritabanına gönderir.',
      label: 'Tüm üye verilerini veritabanına gönder.',
      icon: Icons.upload_rounded,
      color: Colors.orange,
      confirmTitle: 'Tüm üyeler gönderilsin mi?',
      confirmMessage:
          'Yerel Member ve MemberState verileri veritabanındaki kayıtlarla güncellenecek.\nDevam etmek istiyor musun?',
      onConfirm: _pushAllMembers,
    ),
    _SettingsAction(
      section: 'Veri Silme',
      title: 'Yerel Üyeleri Sil',
      description:
          'Hive üzerinde tutulan tüm yerel üye verilerini siler.',
      label: 'Tüm yerel üye verilerini sil.',
      icon: Icons.delete_outline_rounded,
      color: Colors.red,
      confirmTitle: 'Üyeler silinsin mi?',
      confirmMessage:
          'Yerel olarak tutulan tüm üye verileri silinecek.\nBu işlem geri alınamaz!',
      onConfirm: _deleteAllMembersFromHive,
    ),
    _SettingsAction(
      section: 'Veri Silme',
      title: 'Yerel Üye Durumlarını Sil',
      description:
          'Hive üzerinde tutulan tüm yerel üye durumlarını siler.',
      label: 'Tüm yerel üye durumlarını sil.',
      icon: Icons.delete_outline_rounded,
      color: Colors.red,
      confirmTitle: 'Üye durumları silinsin mi?',
      confirmMessage:
          'Yerel olarak tutulan tüm MemberState verileri silinecek.\nBu işlem geri alınamaz!',
      onConfirm: _deleteAllMemberStatesFromHive,
    ),
    _SettingsAction(
      section: 'Veri Silme',
      title: 'Yerel Giriş-Çıkış Kayıtlarını Sil',
      description:
          'Hive üzerinde tutulan tüm yerel giriş-çıkış kayıtlarını siler.',
      label: 'Tüm yerel giriş-çıkış kayıtlarını sil.',
      icon: Icons.delete_outline_rounded,
      color: Colors.red,
      confirmTitle: 'Giriş-çıkış kayıtları silinsin mi?',
      confirmMessage:
          'Yerel olarak tutulan tüm Entry verileri silinecek.\nBu işlem geri alınamaz!',
      onConfirm: _deleteAllEntriesFromHive,
    ),
    _SettingsAction(
      section: 'Veri Çekme',
      title: 'Son Giriş-Çıkış Kayıtlarını Çek',
      description:
          'Veritabanındaki son N adet giriş-çıkış kaydını yerel depolamaya çeker.',
      label: 'Kaç kayıt çekileceğini işlem öncesinde belirle.',
      icon: Icons.download_rounded,
      color: Colors.blue,
      confirmTitle: 'Son kayıtları çek',
      confirmMessage:
          'Kaç adet giriş-çıkış kaydı çekmek istediğini belirleyebilirsin.',
      onConfirm: () async {
        final n = await showDialog<int>(
          context: context,
          builder: (dialogContext) {
            final controller = TextEditingController();

            return AlertDialog(
              title: const Text('Kaç kayıt çekilsin?'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kayıt sayısı',
                  hintText: 'Örneğin: 50',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = int.tryParse(controller.text);

                    if (value == null || value <= 0) return;

                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text('Devam'),
                ),
              ],
            );
          },
        );

        if (n == null) {
          return ActionResult.cancelled;
        }

        return await _pullEntriesRecentN(n);
      },
    ),
    _SettingsAction(
      section: 'Veri Çekme',
      title: 'Tarihten Sonraki Giriş-Çıkışları Çek',
      description:
          'Belirtilen tarihten sonraki giriş-çıkış kayıtlarını yerel depolamaya çeker.',
      label: 'Başlangıç tarihini işlem öncesinde belirle.',
      icon: Icons.date_range_rounded,
      color: Colors.blue,
      confirmTitle: 'Tarihten sonraki kayıtları çek',
      confirmMessage:
          'Hangi tarihten sonraki kayıtların çekileceğini belirleyebilirsin.',
      onConfirm: () async {
        final date = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDate: DateTime.now(),
        );

        if (date == null) {
          return ActionResult.cancelled;
        }

        return await _pullEntriesSinceDate(date);
      },
    ),
    _SettingsAction(
      section: 'Veri Silme',
      title: 'Üyeye Ait Giriş-Çıkışları Sil',
      description:
          'Belirtilen üyeye ait YEREL giriş-çıkış kayıtlarının tamamını siler.',
      label: 'Silinecek üyenin ID bilgisini işlem öncesinde belirle.',
      icon: Icons.person_remove_rounded,
      color: Colors.red,
      confirmTitle: 'Üyenin kayıtlarını sil',
      confirmMessage:
          'Hangi üyenin yerel giriş-çıkış kayıtlarını silmek istediğini belirleyebilirsin.',
      onConfirm: () async {
        final memberId = await showDialog<String>(
          context: context,
          builder: (dialogContext) {
            final controller = TextEditingController();

            return AlertDialog(
              title: const Text('Member ID'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Member ID',
                  hintText: 'Örneğin: B_1',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim();

                    if (value.isEmpty) return;

                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text('Devam'),
                ),
              ],
            );
          },
        );

        if (memberId == null) {
          return ActionResult.cancelled;
        }

        return await _deleteEntriesForMember(memberId);
      },
    ),   
    _SettingsAction(
      section: 'Veri İtme',
      title: 'Seçili Üyeyi Firebase\'e Gönder',
      description:
          'Belirtilen üyenin Member ve MemberState verilerini Firebase\'e gönderir.',
      label: 'Gönderilecek üyenin ID bilgisini işlem öncesinde belirle.',
      icon: Icons.upload_rounded,
      color: Colors.blue,
      confirmTitle: 'Üyeyi Firebase\'e gönder',
      confirmMessage:
          'Göndermek istediğin üyenin ID bilgisini belirleyebilirsin.',
      onConfirm: () async {
        final memberId = await showDialog<String>(
          context: context,
          builder: (dialogContext) {
            final controller = TextEditingController();

            return AlertDialog(
              title: const Text('Member ID'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Member ID',
                  hintText: 'Örneğin: B_1',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim();

                    if (value.isEmpty) return;

                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text('Gönder'),
                ),
              ],
            );
          },
        );

        if (memberId == null) {
          return ActionResult.cancelled;
        }

        return await _pushSelectedMember(memberId);
      },
    ),
    _SettingsAction(
      section: 'Sıfırlama',
      title: 'Firebase Üyelerini Sil',
      description:
          'Firebase üzerindeki tüm Member kayıtlarını siler.',
      label: 'Firebase üyeleri silindi.',
      icon: Icons.delete_forever_rounded,
      color: Colors.red,
      confirmTitle: 'Firebase üyelerini sil',
      confirmMessage:
          'Firebase üzerindeki TÜM üye kayıtları silinecek.\n'
          'Bu işlem geri alınamaz!',
      onConfirm: _deleteAllMembersFromFirebase,
    ),
    _SettingsAction(
      section: 'Sıfırlama',
      title: 'Firebase Giriş-Çıkış Kayıtlarını Sil',
      description:
          'Firebase üzerindeki tüm Entry kayıtlarını siler.',
      label: 'Firebase giriş-çıkış kayıtları silindi.',
      icon: Icons.delete_forever_rounded,
      color: Colors.red,
      confirmTitle: 'Firebase giriş-çıkış kayıtlarını sil',
      confirmMessage:
          'Firebase üzerindeki TÜM giriş-çıkış kayıtları silinecek.\n'
          'Bu işlem geri alınamaz!',
      onConfirm: _deleteAllEntriesFromFirebase,
    ), 
    _SettingsAction(
      section: 'Veri İtme',
      title: 'Tüm Giriş-Çıkışları Firebase\'e Gönder',
      description:
          'Yerel depolamadaki tüm giriş-çıkış kayıtlarını Firebase\'e gönderir.',
      label: 'Tüm yerel giriş-çıkış kayıtlarını Firebase\'e gönder.',
      icon: Icons.file_upload_rounded,
      color: Colors.purple,
      confirmTitle: 'Tüm kayıtları Firebase\'e gönder',
      confirmMessage:
          'Yerel depolamadaki TÜM giriş-çıkış kayıtları Firebase\'e gönderilecek.',
      onConfirm: _pushAllEntries,
    ),  
    _SettingsAction(
      section: 'Veri İtme',
      title: 'Son Giriş-Çıkışları Firebase\'e Gönder',
      description:
          'Yerel depolamadaki son N adet giriş-çıkış kaydını Firebase\'e gönderir.',
      label: 'Kaç kayıt gönderileceğini işlem öncesinde belirle.',
      icon: Icons.file_upload_rounded,
      color: Colors.purple,
      confirmTitle: 'Son kayıtları Firebase\'e gönder',
      confirmMessage:
          'Kaç adet giriş-çıkış kaydının Firebase\'e gönderileceğini belirleyebilirsin.',
      onConfirm: () async {
        final n = await showDialog<int>(
          context: context,
          builder: (dialogContext) {
            final controller = TextEditingController();

            return AlertDialog(
              title: const Text('Kaç kayıt gönderilsin?'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kayıt sayısı',
                  hintText: 'Örneğin: 50',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = int.tryParse(controller.text);

                    if (value == null || value <= 0) return;

                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text('Gönder'),
                ),
              ],
            );
          },
        );

        if (n == null) {
          return ActionResult.cancelled;
        }

        return await _pushEntriesLatestN(n);
      },
    ),  
    _SettingsAction(
      section: 'Veri İtme',
      title: 'Tarihten Sonraki Giriş-Çıkışları Firebase\'e Gönder',
      description:
          'Belirtilen tarihten sonraki yerel giriş-çıkış kayıtlarını Firebase\'e gönderir.',
      label: 'Başlangıç tarihini işlem öncesinde belirle.',
      icon: Icons.file_upload_rounded,
      color: Colors.purple,
      confirmTitle: 'Tarihten sonraki kayıtları gönder',
      confirmMessage:
          'Hangi tarihten sonraki giriş-çıkış kayıtlarının Firebase\'e gönderileceğini belirleyebilirsin.',
      onConfirm: () async {
        final date = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDate: DateTime.now(),
        );

        if (date == null) {
          return ActionResult.cancelled;
        }

        return await _pushEntriesSinceDate(date);
      },
    ), 
    if(AuthService.instance.currentUser!.role == UserRole.admin)...[
      _SettingsAction(
        section: 'Komut',
        title: 'Test Komutu Gönder',
        description:
            'Firebase üzerinden test amaçlı bir command oluşturur.',
        label: 'Test command gönderildi.',
        icon: Icons.send_rounded,
        color: Colors.blue,
        confirmTitle: 'Test komutu gönder',
        confirmMessage:
            'Tablete test amaçlı bir command gönderilecek.',
        onConfirm: _sendTestCommand,
      ),   
      _SettingsAction(
        section: 'Komut',
        title: 'Giriş-Çıkış Sil',
        description:
            'Belirtilen Giriş-Çıkış kaydının silinmesi için tablete komut gönderir.',
        label: 'Giriş-Çıkış silme komutu gönderildi.',
        icon: Icons.delete_forever_rounded,
        color: Colors.red,
        confirmTitle: 'Giriş-Çıkış silme komutu gönder',
        confirmMessage:
            'Silmek istediğin Giriş-Çıkış ID\'sini gireceksin. '
            'Silme işlemi tablet tarafından gerçekleştirilecek.',
        onConfirm: _sendEntryDeleteCommand,
      ),
      _SettingsAction(
        section: 'Komut',
        title: 'Üye Sil',
        description:
            'Belirtilen Üye kaydının silinmesi için tablete komut gönderir.',
        label: 'Üye silme komutu gönderildi.',
        icon: Icons.person_remove,
        color: Colors.red,
        confirmTitle: 'Üye silme komutu gönder',
        confirmMessage:
            'Silmek istediğin Üye ID\'sini gireceksin. '
            'Örneğin: B_1\n\n'
            'Silme işlemi tablet tarafından gerçekleştirilecek.',
        onConfirm: _sendMemberDeleteCommand,
      ),
      _SettingsAction(
        section: 'Komut',
        title: 'Member Düzenle',
        description:
            'Belirtilen Member kaydının düzenlenmesi için tablete komut gönderir.',
        label: 'Member düzenleme komutu gönderildi.',
        icon: Icons.edit,
        color: Colors.blue,
        confirmTitle: 'Member düzenleme komutu gönder',
        confirmMessage:
            'Düzenlemek istediğin Member ID\'sini gireceksin.\n\n'
            'Örneğin: B_1\n\n'
            'Düzenleme işlemi tablet tarafından gerçekleştirilecek.',
        onConfirm: _sendMemberEditCommand,
      ),
      _SettingsAction(
        section: 'Komut',
        title: 'Entry Düzenle',
        description:
            'Belirtilen Entry kaydının düzenlenmesi için tablete komut gönderir.',
        label: 'Entry düzenleme komutu gönderildi.',
        icon: Icons.edit,
        color: Colors.blue,
        confirmTitle: 'Entry düzenleme komutu gönder',
        confirmMessage:
            'Düzenlemek istediğin Entry ID\'sini gireceksin.\n\n'
            'Örneğin: 1788170089538\n\n'
            'Düzenleme işlemi tablet tarafından gerçekleştirilecek.',
        onConfirm: _sendEntryEditCommand,
      ),
      _SettingsAction(
        section: 'Komut',
        title: 'Geçmiş Entry Ekle',
        description:
            'Belirtilen Member için geçmiş tarihli bir Entry kaydı oluşturur.',
        label: 'Geçmiş Entry ekleme komutu gönderildi.',
        icon: Icons.history,
        color: Colors.orange,
        confirmTitle: 'Geçmiş Entry ekle',
        confirmMessage:
            'Geçmiş kayıt eklemek istediğin Member ID\'sini gireceksin.\n\n'
            'Örneğin: B_1\n\n'
            'Kayıt, seçilen ExitTime üzerinden benzersiz bir Entry ID ile oluşturulacaktır.',
        onConfirm: _sendEntryHistoricalAddCommand,
      )
    ]
 
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

  //// ==================== SETTINGS OPTIONS ====================

  Future<ActionResult> _testFirebase() async {
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
    return ActionResult.success;
  }

  Future<ActionResult> _verifyOutsideEntries() async {
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
      return ActionResult.error;
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
    return ActionResult.success;
  }


  Future<ActionResult> _pullMembers() async {
    DatabaseService db = DatabaseService();
    List<Member> tempMembers =
        await _fetchMemberDataFromFirebase(db);

    memberMap.clear();

    for (var member in tempMembers) {
      memberMap["${member.group}_${member.number}"] = member;
    }

    tempMembers.clear();

    List<Member> members = [];

    List<MemberState> memberStates =
        await _fetchMemberStateDataFromFireBase(db);

    for (var memberState in memberStates) {
      final key = "${memberState.group}_${memberState.number}";
      final member = memberMap.remove(key);

      if (member == null) continue;

      member.state = memberState.state.name;
      member.entryID = memberState.lastEntryID;

      members.add(member);
    }

    memberMap.forEach((key, member) {
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

    await Hive.box(memberBox).clear();

    for (final member in members) {
      db.updateHive(
        path: "${member.group}_${member.number}",
        data: Member.toMap(member),
        b: Hive.box(memberBox),
      );
    }

    await Hive.box(memberStateBox).clear();

    for (final state in memberStates) {
      db.updateHive(
        path: "${state.group}_${state.number}",
        data: MemberState.toMap(state),
        b: Hive.box(memberStateBox),
      );
    }
    return ActionResult.success;
  }

  Future<ActionResult> _pullEntries() async {
    DatabaseService db = DatabaseService();
    List<Entry> entries =
        await _fetchEntryDataFromFirebase(db);

    Hive.box(entryBox).clear();

    for (final entry in entries) {
      db.updateHive(
        path: entry.entryID.toString(),
        data: Entry.toMap(entry),
        b: Hive.box(entryBox),
      );
    }
    return ActionResult.success;
  }

  Future<ActionResult>  _pushAllMembers() async {
    final db = DatabaseService();

    final members = Hive.box(memberBox).values;

    for (final memberData in members) {
      final member = Member.fromMap(
        Map<String, dynamic>.from(memberData),
      );

      final key = "${member.group}_${member.number}";

      await db.updateDB(
        path: "Member/$key",
        data: Member.toMap(member),
      );

      final memberState = MemberState(
        group: member.group,
        number: member.number,
        state: member.state == "outside"
            ? MemberStateEnum.outside
            : MemberStateEnum.inside,
        lastEntryID: member.entryID,
      );

      await db.updateDB(
        path: "MemberState/$key",
        data: MemberState.toMap(memberState),
      );
    }
    return ActionResult.success;
  }

  Future<ActionResult> _deleteAllMembersFromHive() async {
    await Hive.box(memberBox).clear();
    return ActionResult.success;
  }

  Future<ActionResult> _deleteAllMemberStatesFromHive() async {
    await Hive.box(memberStateBox).clear();
    return ActionResult.success;
  }

  Future<ActionResult> _deleteAllEntriesFromHive() async {
    await Hive.box(entryBox).clear();
    return ActionResult.success;
  }

  Future<ActionResult> _pullEntriesRecentN(int n) async {
    final db = DatabaseService();

    final snapshot = await db.firebaseDatabase
        .ref()
        .child('Entry')
        .orderByKey()
        .limitToLast(n)
        .get();

    if (!snapshot.exists) {
      return ActionResult.success;
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    for (final item in data.entries) {
      final entry = Entry.fromMap(
        Map<String, dynamic>.from(item.value),
      );

      db.updateHive(
        path: item.key,
        data: Entry.toMap(entry),
        b: Hive.box(entryBox),
      );
    }

    return ActionResult.success;
  }

  Future<ActionResult> _pullEntriesSinceDate(DateTime date) async {
    final db = DatabaseService();

    final startId = date.millisecondsSinceEpoch.toString();

    final snapshot = await db.firebaseDatabase
        .ref()
        .child('Entry')
        .orderByKey()
        .startAt(startId)
        .get();

    print("START ID: $startId");
    print("EXISTS: ${snapshot.exists}");
    print("VALUE: ${snapshot.value}");

    if (!snapshot.exists) {
      return ActionResult.error;
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    for (final item in data.entries) {
      final entry = Entry.fromMap(
        Map<String, dynamic>.from(item.value),
      );

      await db.updateHive(
        path: item.key,
        data: Entry.toMap(entry),
        b: Hive.box(entryBox),
      );
    }

    return ActionResult.success;
  }

  Future<ActionResult> _deleteEntriesForMember(String memberId) async {
    final box = Hive.box(entryBox);

    final entriesToDelete = <dynamic>[];

    for (final key in box.keys) {
      final data = box.get(key);

      if (data == null) continue;

      final entry = Entry.fromMap(
        Map<String, dynamic>.from(data),
      );

      final entryMemberId = '${entry.group}_${entry.number}';

      if (entryMemberId == memberId) {
        entriesToDelete.add(key);
      }
    }

    await box.deleteAll(entriesToDelete);

    return ActionResult.success;
  }

  Future<ActionResult> _pushSelectedMember(String memberId) async {
    final db = DatabaseService();

    final memberBoxData = Hive.box(memberBox).get(memberId);
    final memberStateBoxData = Hive.box(memberStateBox).get(memberId);

    if (memberBoxData == null) {
      throw Exception('Member bulunamadı: $memberId');
    }

    if (memberStateBoxData == null) {
      throw Exception('MemberState bulunamadı: $memberId');
    }

    final member = Member.fromMap(
      Map<String, dynamic>.from(memberBoxData),
    );

    final memberState = MemberState.fromMap(
      Map<String, dynamic>.from(memberStateBoxData),
    );

    await db.updateDB(
      path: 'Member/$memberId',
      data: Member.toMap(member),
    );

    await db.updateDB(
      path: 'MemberState/$memberId',
      data: MemberState.toMap(memberState),
    );

    return ActionResult.success;
  }

  Future<ActionResult> _deleteAllMembersFromFirebase() async {
    final db = DatabaseService();

    await db.firebaseDatabase
        .ref()
        .child('Member')
        .remove();

    return ActionResult.success;
  }

  Future<ActionResult> _deleteAllEntriesFromFirebase() async {
    final db = DatabaseService();

    await db.firebaseDatabase
        .ref()
        .child('Entry')
        .remove();

    return ActionResult.success;
  }

  Future<ActionResult> _pushAllEntries() async {
    final db = DatabaseService();
    final box = Hive.box(entryBox);

    for (final key in box.keys) {
      final data = box.get(key);

      if (data == null) continue;

      final entry = Entry.fromMap(
        Map<String, dynamic>.from(data),
      );

      await db.updateDB(
        path: 'Entry/$key',
        data: Entry.toMap(entry),
      );
    }

    return ActionResult.success;
  }

  Future<ActionResult> _pushEntriesLatestN(int n) async {
    final db = DatabaseService();
    final box = Hive.box(entryBox);

    final keys = box.keys.toList();

    keys.sort(
      (a, b) => int.parse(b.toString()).compareTo(
        int.parse(a.toString()),
      ),
    );

    final latestKeys = keys.take(n);

    for (final key in latestKeys) {
      final data = box.get(key);

      if (data == null) continue;

      final entry = Entry.fromMap(
        Map<String, dynamic>.from(data),
      );

      await db.updateDB(
        path: 'Entry/$key',
        data: Entry.toMap(entry),
      );
    }

    return ActionResult.success;
  }

  Future<ActionResult> _pushEntriesSinceDate(DateTime date) async {
    final db = DatabaseService();
    final box = Hive.box(entryBox);

    final startId = date.millisecondsSinceEpoch;

    for (final key in box.keys) {
      final entryId = int.tryParse(key.toString());

      if (entryId == null || entryId < startId) {
        continue;
      }

      final data = box.get(key);

      if (data == null) continue;

      final entry = Entry.fromMap(
        Map<String, dynamic>.from(data),
      );

      await db.updateDB(
        path: 'Entry/$key',
        data: Entry.toMap(entry),
      );
    }

    return ActionResult.success;
  }

//======================================================================================================
//======================================== COMMANDS ====================================================
//======================================================================================================

  Future<ActionResult> _sendTestCommand() async {
    final db = DatabaseService();

    final command = Command(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      admin: AuthService.instance.currentUser!.username,
      type: CommandType.test,
      status: CommandStatus.pending,
      data: {
        'message': 'Hello from web!',
      },
      createdAt: DateTime.now().millisecondsSinceEpoch,
      receivedDevices: {deviceID: "completed"}
    );

    await db.sendCommand(command);

    return ActionResult.success;
  }

  Future<ActionResult> _sendEntryDeleteCommand() async {
    final entryID = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();

        return AlertDialog(
          title: const Text('Entry Sil'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Entry ID',
              hintText: 'Örneğin: 1788170089538',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) return;

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Gönder'),
            ),
          ],
        );
      },
    );

    if (entryID == null) {
      return ActionResult.cancelled;
    }

    final db = DatabaseService();

    final command = Command(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      admin: AuthService.instance.currentUser!.username,
      type: CommandType.entryDelete,
      status: CommandStatus.pending,
      data: {
        'entryID': entryID,
      },
      createdAt: DateTime.now().millisecondsSinceEpoch,
      receivedDevices: {deviceID: "completed"}
    );

    await db.sendCommand(command);

    await Hive.box(entryBox).delete(entryID);

    return ActionResult.success;
  }

  Future<ActionResult> _sendMemberDeleteCommand() async {
    final memberID = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();

        return AlertDialog(
          title: const Text('Member Sil'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Member ID',
              hintText: 'Örneğin: B_1',
            ),
            textInputAction: TextInputAction.done,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) return;

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Gönder'),
            ),
          ],
        );
      },
    );

    if (memberID == null) {
      return ActionResult.cancelled;
    }

    final db = DatabaseService();

    final command = Command(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      admin: AuthService.instance.currentUser!.username,
      type: CommandType.memberDelete,
      status: CommandStatus.pending,
      data: {
        'memberID': memberID,
      },
      createdAt: DateTime.now().millisecondsSinceEpoch,
      receivedDevices: {deviceID: "completed"}
    );

    await db.sendCommand(command);

    await Hive.box(memberBox).delete(memberID);
    await Hive.box(memberStateBox).delete(memberID);  

    return ActionResult.success;
  }



  Future<ActionResult> _sendMemberEditCommand() async {
    // 1. Member ID al
    final memberID = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var value = '';

        return AlertDialog(
          title: const Text('Member Düzenle'),
          content: TextFormField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Member ID',
              hintText: 'Örneğin: B_1',
            ),
            onChanged: (text) {
              value = text.trim();
            },
            onFieldSubmitted: (text) {
              final id = text.trim();

              if (id.isNotEmpty) {
                Navigator.pop(dialogContext, id);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (value.isEmpty) return;

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Devam'),
            ),
          ],
        );
      },
    );

    if (memberID == null) {
      return ActionResult.cancelled;
    }

    // 2. Member'ı Hive'dan bul
    final box = Hive.box(memberBox);

    final memberData = box.get(memberID);

    if (memberData == null) {
      throw Exception(
        'Member bulunamadı: $memberID',
      );
    }

    final member = Member.fromMap(
      Map<String, dynamic>.from(memberData),
    );

    // 3. Member bilgilerini düzenle
    final editedMember = await showDialog<Member>(
      context: context,
      builder: (dialogContext) {
        var name = member.name;
        var number = member.number.toString();
        var group = member.group;
        var supervisor = member.supervisor;
        var dorm = member.dorm ?? '';
        var phone = member.phone ?? '';

        return AlertDialog(
          title: Text('Member Düzenle: $memberID'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                  ),
                  onChanged: (value) => name = value,
                ),

                TextFormField(
                  initialValue: number,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Numara',
                  ),
                  onChanged: (value) => number = value,
                ),

                TextFormField(
                  initialValue: group,
                  decoration: const InputDecoration(
                    labelText: 'Grup',
                  ),
                  onChanged: (value) => group = value,
                ),

                TextFormField(
                  initialValue: supervisor,
                  decoration: const InputDecoration(
                    labelText: 'Sorumlu',
                  ),
                  onChanged: (value) => supervisor = value,
                ),

                TextFormField(
                  initialValue: dorm,
                  decoration: const InputDecoration(
                    labelText: 'Yurt',
                  ),
                  onChanged: (value) => dorm = value,
                ),

                TextFormField(
                  initialValue: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                  ),
                  onChanged: (value) => phone = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsedNumber = int.tryParse(number.trim());

                if (parsedNumber == null) return;

                Navigator.pop(
                  dialogContext,
                  Member(
                    name: name.trim(),
                    number: parsedNumber,
                    group: group.trim(),
                    supervisor: supervisor.trim(),
                    dorm: dorm.trim(),
                    phone: phone.trim(),
                    entryID: member.entryID,
                  ),
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (editedMember == null) {
      return ActionResult.cancelled;
    }

    // 4. Tablete Member Edit komutu gönder
    final db = DatabaseService();

    final command = Command(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      admin: AuthService.instance.currentUser!.username,
      type: CommandType.memberEdit,
      status: CommandStatus.pending,
      data: {
        'memberID': memberID,
        'member': Member.toMap(editedMember),
      },
      createdAt: DateTime.now().millisecondsSinceEpoch,
      receivedDevices: {deviceID: "completed"}
    );

    await db.sendCommand(command);

    // 5. Web tarafındaki lokal Hive kaydını hemen güncelle
    await box.put(
      memberID,
      Member.toMap(editedMember),
    );

    return ActionResult.success;
  }

  Future<ActionResult> _sendEntryEditCommand() async {
    final entryID = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var value = '';

        return AlertDialog(
          title: const Text('Entry Düzenle'),
          content: TextFormField(
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Entry ID',
              hintText: 'Örneğin: 1788170089538',
            ),
            onChanged: (text) {
              value = text.trim();
            },
            onFieldSubmitted: (text) {
              final id = text.trim();

              if (id.isNotEmpty) {
                Navigator.pop(dialogContext, id);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (value.isEmpty) return;

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Devam'),
            ),
          ],
        );
      },
    );

    if (entryID == null) {
      return ActionResult.cancelled;
    }

    final box = Hive.box(entryBox);

    final entryData = box.get(entryID);

    if (entryData == null) {
      throw Exception(
        'Entry bulunamadı: $entryID',
      );
    }

    final entry = Entry.fromMap(
      Map<dynamic, dynamic>.from(entryData),
    );

    final editedEntry = await showDialog<Entry>(
      context: context,
      builder: (dialogContext) {
        var entryTime = entry.entryTime ?? '';
        var exitTime = entry.exitTime;
        var selectedReason = entry.reason ?? '';
        var selectedPermission = entry.permission ?? '';
        var otherReason = entry.otherReason == 'Yok'
            ? ''
            : (entry.otherReason ?? '');

        final reasonB = Hive.box(reasonBox);
        final permissionB = Hive.box(permissionBox);

        final reasonNames = reasonB.values
            .map(
              (data) => Reason.fromMap(
                Map<dynamic, dynamic>.from(data),
              ).name,
            )
            .toList();

        reasonNames.add('Diğer...');

        final permissionNames = permissionB.values
            .map(
              (data) => Permission.fromMap(
                Map<dynamic, dynamic>.from(data),
              ).name,
            )
            .toList();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isOtherReason = selectedReason == 'Diğer...';

            return AlertDialog(
              title: Text('Entry Düzenle: $entryID'),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // GİRİŞ VAKTİ
                    TextFormField(
                      initialValue: entryTime,
                      decoration: const InputDecoration(
                        labelText: 'Giriş Vakti',
                      ),
                      onChanged: (value) {
                        entryTime = value;
                      },
                    ),

                    // ÇIKIŞ VAKTİ
                    TextFormField(
                      initialValue: exitTime,
                      decoration: const InputDecoration(
                        labelText: 'Çıkış Vakti',
                      ),
                      onChanged: (value) {
                        exitTime = value;
                      },
                    ),

                    const SizedBox(height: 12),

                    // SEBEP
                    DropdownButtonFormField<String>(
                      value: reasonNames.contains(selectedReason)
                          ? selectedReason
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Sebep',
                      ),
                      items: reasonNames
                          .map(
                            (reason) => DropdownMenuItem<String>(
                              value: reason,
                              child: Text(reason),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedReason = value;

                          // Diğer'den normal sebebe geçildiyse
                          // diğer sebebi temizle.
                          if (selectedReason != 'Diğer...') {
                            otherReason = '';
                          }
                        });
                      },
                    ),

                    // DİĞER SEBEP
                    if (isOtherReason) ...[
                      const SizedBox(height: 12),

                      TextFormField(
                        initialValue: otherReason,
                        decoration: const InputDecoration(
                          labelText: 'Diğer Sebep',
                        ),
                        onChanged: (value) {
                          otherReason = value;
                        },
                      ),
                    ],

                    const SizedBox(height: 12),

                    // İZİN
                    DropdownButtonFormField<String>(
                      value: permissionNames.contains(selectedPermission)
                          ? selectedPermission
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'İzin',
                      ),
                      items: permissionNames
                          .map(
                            (permission) => DropdownMenuItem<String>(
                              value: permission,
                              child: Text(permission),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedPermission = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('İptal'),
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      Entry(
                        // DEĞİŞTİRİLMEMESİ GEREKEN ALANLAR
                        entryID: entry.entryID,
                        group: entry.group,
                        number: entry.number,
                        name: entry.name,
                        operator: entry.operator,

                        // DÜZENLENEBİLEN ALANLAR
                        entryTime: entryTime,
                        exitTime: exitTime,
                        permission: selectedPermission,
                        reason: selectedReason,

                        // Diğer seçiliyse yazılan değeri,
                        // değilse "Yok" kaydet.
                        otherReason: selectedReason == 'Diğer...'
                            ? otherReason
                            : 'Yok',
                      ),
                    );
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    if (editedEntry == null) {
      return ActionResult.cancelled;
    }

    final db = DatabaseService();

    final command = Command(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      admin: AuthService.instance.currentUser!.username,
      type: CommandType.entryEdit,
      status: CommandStatus.pending,
      data: {
        'entryID': entryID,
        'entry': Entry.toMap(editedEntry),
      },
      createdAt: DateTime.now().millisecondsSinceEpoch,
      receivedDevices: {deviceID: "completed"}
    );

    await db.sendCommand(command);

    await box.put(
      entryID,
      Entry.toMap(editedEntry),
    );

    return ActionResult.success;
  }



  Future<ActionResult> _sendEntryHistoricalAddCommand() async {
    final memberID = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var value = '';

        return AlertDialog(
          title: const Text('Geçmiş Entry Ekle'),
          content: TextFormField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Member ID',
              hintText: 'Örneğin: B_1',
            ),
            onChanged: (text) {
              value = text.trim();
            },
            onFieldSubmitted: (text) {
              final id = text.trim();

              if (id.isNotEmpty) {
                Navigator.pop(dialogContext, id);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (value.isEmpty) return;

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Devam'),
            ),
          ],
        );
      },
    );

    if (memberID == null) {
      return ActionResult.cancelled;
    }

    final memberBoxInstance = Hive.box(memberBox);

    final memberData = memberBoxInstance.get(memberID);

    if (memberData == null) {
      throw Exception(
        'Member bulunamadı: $memberID',
      );
    }

    final member = Member.fromMap(
      Map<String, dynamic>.from(memberData),
    );

    final entry = await showDialog<Entry>(
      context: context,
      builder: (dialogContext) {
        DateTime? entryTime;
        DateTime? exitTime;

        var selectedReason = '';
        var selectedPermission = '';
        var otherReason = '';

        final reasonBoxInstance = Hive.box(reasonBox);
        final permissionBoxInstance = Hive.box(permissionBox);

        final reasonNames = reasonBoxInstance.values
            .map(
              (data) => Reason.fromMap(
                Map<dynamic, dynamic>.from(data),
              ).name,
            )
            .toList();

        if (!reasonNames.contains('Diğer...')) {
          reasonNames.add('Diğer...');
        }

        final permissionNames = permissionBoxInstance.values
            .map(
              (data) => Permission.fromMap(
                Map<dynamic, dynamic>.from(data),
              ).name,
            )
            .toList();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Geçmiş Entry Ekle: $memberID'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: member.name,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                      ),
                    ),

                    TextFormField(
                      initialValue: member.number.toString(),
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Numara',
                      ),
                    ),

                    TextFormField(
                      initialValue: member.group,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Grup',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Giriş Vakti
                    OutlinedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: entryTime ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (date == null) return;

                        final time = await showTimePicker(
                          context: dialogContext,
                          initialTime: entryTime != null
                              ? TimeOfDay.fromDateTime(entryTime!)
                              : TimeOfDay.now(),
                        );

                        if (time == null) return;

                        setDialogState(() {
                          entryTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      child: Text(
                        entryTime == null
                            ? 'Giriş Vakti Seç'
                            : entryTime.toString(),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Çıkış Vakti
                    OutlinedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: exitTime ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (date == null) return;

                        final time = await showTimePicker(
                          context: dialogContext,
                          initialTime: exitTime != null
                              ? TimeOfDay.fromDateTime(exitTime!)
                              : TimeOfDay.now(),
                        );

                        if (time == null) return;

                        setDialogState(() {
                          exitTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      child: Text(
                        exitTime == null
                            ? 'Çıkış Vakti Seç'
                            : exitTime.toString(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Sebep
                    DropdownButtonFormField<String>(
                      value: reasonNames.contains(selectedReason)
                          ? selectedReason
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Sebep',
                      ),
                      items: reasonNames
                          .map(
                            (reason) => DropdownMenuItem<String>(
                              value: reason,
                              child: Text(reason),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedReason = value;

                          if (selectedReason != 'Diğer...') {
                            otherReason = '';
                          }
                        });
                      },
                    ),

                    // Diğer Sebep
                    if (selectedReason == 'Diğer...')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Diğer Sebep',
                          ),
                          onChanged: (value) {
                            otherReason = value;
                          },
                        ),
                      ),

                    const SizedBox(height: 12),

                    // İzin
                    DropdownButtonFormField<String>(
                      value: permissionNames.contains(selectedPermission)
                          ? selectedPermission
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'İzin',
                      ),
                      items: permissionNames
                          .map(
                            (permission) => DropdownMenuItem<String>(
                              value: permission,
                              child: Text(permission),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedPermission = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (entryTime == null) return;
                    if (exitTime == null) return;
                    if (selectedReason.isEmpty) return;
                    if (selectedPermission.isEmpty) return;

                    Navigator.pop(
                      dialogContext,
                      Entry(
                        entryID: exitTime!.millisecondsSinceEpoch,
                        group: member.group,
                        number: member.number,
                        name: member.name,
                        operator: 'Geçmiş Kayıt',
                        entryTime: entryTime!.toString(),
                        exitTime: exitTime!.toString(),
                        permission: selectedPermission,
                        reason: selectedReason,
                        otherReason: selectedReason == 'Diğer...'
                            ? otherReason
                            : 'Yok',
                      ),
                    );
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );

    if (entry == null) {
      return ActionResult.cancelled;
    }

    final db = DatabaseService();

    var finalExitTime = DateTime.parse(entry.exitTime);

    while (true) {
      final candidateEntryID =
          finalExitTime.millisecondsSinceEpoch;

      final snapshot = await db.firebaseDatabase
          .ref()
          .child('Entry')
          .child(candidateEntryID.toString())
          .get();

      if (!snapshot.exists) {
        final finalEntry = Entry(
          entryID: candidateEntryID,
          group: entry.group,
          number: entry.number,
          name: entry.name,
          operator: entry.operator,
          entryTime: entry.entryTime,
          exitTime: finalExitTime.toString(),
          permission: entry.permission,
          reason: entry.reason,
          otherReason: entry.otherReason,
        );

        final command = Command(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          admin: AuthService.instance.currentUser!.username,
          type: CommandType.entryCreateExisting,
          status: CommandStatus.pending,
          data: {
            'entryID': candidateEntryID,
            'entry': Entry.toMap(finalEntry),
          },
          createdAt: DateTime.now().millisecondsSinceEpoch,
          receivedDevices: {deviceID: "completed"}
        );

        await db.sendCommand(command);

        // Web Hive'a da hemen ekle.
        await Hive.box(entryBox).put(
          candidateEntryID.toString(),
          Entry.toMap(finalEntry),
        );

        return ActionResult.success;
      }

      // ID zaten kullanılıyor.
      // ExitTime'ı 1 saniye ileri al ve tekrar dene.
      finalExitTime = finalExitTime.add(
        const Duration(seconds: 1),
      );
    }
  }

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

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            bottom: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ───────────────── HEADER ─────────────────

              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: GlassTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ayarlar',
                          style: TextStyle(
                            color: GlassTheme.textPrimary,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Veri, bağlantı ve sistem işlemleri',
                          style: TextStyle(
                            color: GlassTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ───────────────── SEARCH ─────────────────

              _SearchField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // ───────────────── ACTIONS ─────────────────

              if (grouped.isEmpty)
                const GlassPanel(
                  title: 'Sonuç',
                  icon: Icons.search_off_rounded,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Sonuç bulunamadı.',
                        style: TextStyle(
                          color: GlassTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ...grouped.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassPanel(
                      title: entry.key,
                      icon: _sectionIcon(entry.key),
                      child: Column(
                        children: [
                          for (int i = 0;
                              i < entry.value.length;
                              i++) ...[
                            _ActionTile(
                              action: entry.value[i],
                              onTap: _isRunning
                                  ? null
                                  : () => _showConfirmDialog(
                                        context,
                                        entry.value[i],
                                      ),
                            ),

                            if (i != entry.value.length - 1)
                              Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.06),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _sectionIcon(String section) {
    switch (section) {
      case 'Bağlantı':
        return Icons.wifi_rounded;

      case 'Veri Yönetimi':
        return Icons.manage_search_rounded;

      case 'Veri Çekme':
        return Icons.download_rounded;

      case 'Veri İtme':
        return Icons.upload_rounded;

      case 'Veri Silme':
        return Icons.delete_outline_rounded;

      case 'Sıfırlama':
        return Icons.restart_alt_rounded;

      case 'Komut':
        return Icons.terminal_rounded;

      default:
        return Icons.settings_rounded;
    }
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

  Future<void> _runAction(
    BuildContext context,
    _SettingsAction action,
  ) async {
    setState(() => _isRunning = true);

    try {
      final result = await action.onConfirm();

      if (result == ActionResult.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.red.shade600,
            content: Text('Hata: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  // =================================================================================================

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

enum ActionResult {
  success,
  cancelled,
  error,
}

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
  final Future<ActionResult> Function() onConfirm;

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

  const _SearchField({
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.09),
        ),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(
          color: GlassTheme.textPrimary,
          fontSize: 13,
        ),
        cursorColor: GlassTheme.cyan,
        decoration: InputDecoration(
          hintText: 'Aksiyon ara...',
          hintStyle: const TextStyle(
            color: GlassTheme.textSecondary,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: GlassTheme.textSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
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

  const _ActionTile({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ICON
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(
                    disabled ? 0.04 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: action.color.withOpacity(
                      disabled ? 0.05 : 0.13,
                    ),
                  ),
                ),
                child: Icon(
                  action.icon,
                  size: 18,
                  color: action.color.withOpacity(
                    disabled ? 0.35 : 1,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            action.title,
                            style: TextStyle(
                              color: GlassTheme.textPrimary.withOpacity(
                                disabled ? 0.45 : 1,
                              ),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        if (action.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: action.color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: action.color.withOpacity(0.12),
                              ),
                            ),
                            child: Text(
                              action.badge!,
                              style: TextStyle(
                                color: action.color,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      action.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: GlassTheme.textSecondary.withOpacity(
                          disabled ? 0.35 : 1,
                        ),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: GlassTheme.textSecondary.withOpacity(
                  disabled ? 0.2 : 0.6,
                ),
              ),
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