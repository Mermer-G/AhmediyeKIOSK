import 'dart:async';
import 'dart:ui';
import 'package:app1/Pages/memberInfo.dart';
import 'package:app1/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:uuid/uuid.dart';

// Modeller, Servisler ve Diğer Sayfalar
import 'package:app1/Pages/addMemberPage.dart';
import 'package:app1/Pages/entryList.dart';
import 'package:app1/Pages/generalStatusPage.dart';
import 'package:app1/Pages/loginScreen.dart';
import 'package:app1/Pages/passwordPage.dart';
import 'package:app1/Pages/permissionPage.dart';
import 'package:app1/Pages/queuePage.dart';
import 'package:app1/Pages/reasonsPage.dart';
import 'package:app1/Pages/user_management_page.dart';
import 'package:app1/Pages/memberList.dart';

import 'package:app1/utils/auth_service.dart';
import 'package:app1/utils/command.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:app1/utils/debugger.dart';
import 'package:app1/utils/offline_queue.dart';
import 'package:app1/utils/synchronizer.dart';

// Yeni oluşturduğumuz Tasarım Dosyası
import 'package:app1/Theme/dashboard_theme.dart';

final uuid = const Uuid();
const deviceIDKey = 'deviceID';
var deviceID = "";
String settingsPassword = "365";
int lastTimeStamp = 0;
ValueNotifier membersValueListener = ValueNotifier<List<Member>>([]);

class NewHomePage extends StatefulWidget {
  const NewHomePage({super.key});
  static String? permission;
  static String? reason;

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  String _currentTime = "0";
  Timer? _timer;
  Map<String, int> groupAndOutside = {};
  late Map<String, Member> memberMap = {};

  final CommandListener _commandListener = CommandListener();
  final AuthService authService = AuthService.instance;

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_authChanged);
    _initialize();
  }

  void _authChanged() {
    if (!AuthService.instance.isLoggedIn && mounted && !isInLoginScreen) {
      if(routeObserver.currentRoute == '/debug') return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Future<void> _initialize() async {
    AppLogger.instance.log("INIT STARTED IN HOME PAGE");
    try {
      final box = Hive.box(metaBox);
      lastTimeStamp = box.get("lastEntryTimestamp") ?? 0;

      AppLogger.instance.warn("Build Route: ${routeObserver.currentRoute}");

      _updateTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

      await Synchronizer().start();
      await _fetchMemberDataFromHive();
      await _fetchMemberStateDataFromHive();
      mergeMemberData();

      QueueHelper().syncQueue();
      deviceID = await getDeviceID();
      _commandListener.start();

      if (!authService.isLoggedIn && !isInLoginScreen && !(routeObserver.currentRoute == '/debug')) {
        if (!kIsWeb) {
          if (!await authService.hasAdmins) {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const FirstAdminScreen()));
          }
          if (!authService.hasOperators) {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const FirstOperatorScreen()));
          }
          if (!authService.isLoggedIn) {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
        } else {
          if (await authService.hasAdmins && !authService.isLoggedIn) {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
        }
      }
    } catch (e, stack) {
      AppLogger.instance.log("HATA YAKALANDI: $e");
      AppLogger.instance.log("Hata Kaynağı: ${stack.toString().split('\n').first}");
    }
  }

  Future<void> _fetchMemberDataFromHive() async {
    try {
      final rawMap = Hive.box(memberBox).toMap();
      rawMap.forEach((k, v) {
        Map<String, dynamic> valuesMap = Map<String, dynamic>.from(v as Map);
        final member = Member.fromMap(valuesMap);
        memberMap["${member.group}_${member.number}"] = member;
      });
    } catch (e, stack) {
      AppLogger.instance.error("HATA: $e\n$stack");
    }
  }

  Future<String> getDeviceID() async {
    final box = Hive.box(metaBox);
    final existingID = box.get(deviceIDKey);
    if (existingID != null) return existingID.toString();

    var newID = kIsWeb ? const Uuid().v4() : "MAIN";
    await box.put(deviceIDKey, newID);
    return newID;
  }

  Future<void> _fetchMemberStateDataFromHive() async {
    try {
      final rawMap = Hive.box(memberStateBox).toMap();
      rawMap.forEach((k, v) {
        Map<String, dynamic> valuesMap = Map<String, dynamic>.from(v as Map);
        final state = MemberState.fromMap(valuesMap);
        final key = "${state.group}_${state.number}";

        if (memberMap.containsKey(key)) {
          memberMap[key]!.state = state.state.name;
          memberMap[key]!.entryID = state.lastEntryID;
        }
      });
    } catch (e, stack) {
      AppLogger.instance.error("HATA: $e\n$stack");
    }
  }

  void mergeMemberData() {
    memberMap.forEach((key, member) {
      member.state ??= MemberStateEnum.inside.name;
    });
    membersValueListener.value = memberMap.values.toList();
  }

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentTime = "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}";
    });
  }

  void countOutsideByGroup(List<Member> members) {
    groupAndOutside.clear();
    for (var m in members) {
      if (!groupAndOutside.containsKey(m.group)) {
        groupAndOutside[m.group] = m.state == STATEOUT.toLowerCase() ? 1 : 0;
      } else {
        groupAndOutside[m.group] = m.state == STATEIN.toLowerCase()
            ? groupAndOutside[m.group]!
            : groupAndOutside[m.group]! + 1;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    AuthService.instance.removeListener(_authChanged);
    if (!kIsWeb) _commandListener.stop();
    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD & DASHBOARD LAYOUTS
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isPhone = constraints.maxWidth < 700;
        final List<Member> members = (membersValueListener.value as List<Member>);
        countOutsideByGroup(members);

        final int totalCount = members.length;
        final int outsideCount = members.where((m) => m.state == STATEOUT.toLowerCase()).length;
        final int insideCount = totalCount - outsideCount;

        return GlassBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            drawer: isPhone ? _buildDrawer(context) : null,
            appBar: _buildAppBar(isPhone),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: isPhone
                      ? _buildPhoneDashboard(totalCount, insideCount, outsideCount)
                      : _buildTabletDashboard(totalCount, insideCount, outsideCount),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletDashboard(int total, int inside, int outside) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ------------------------------------------------------------
      // SOL KOLON (Flex: 3) -> Karşılama + Hızlı İşlemler
      // ------------------------------------------------------------
      Expanded(
        flex: 3,
        child: Column(
          children: [
            _buildWelcomePanel(),
            const SizedBox(height: 14),
            _buildQuickActionsPanel(),
          ],
        ),
      ),

      const SizedBox(width: 14),

      // ------------------------------------------------------------
      // SAĞ KOLON (Flex: 2) -> Saat + Anlık Durum + Dışarıdakiler
      // ------------------------------------------------------------
      Expanded(
        flex: 2,
        child: Column(
          children: [
            GlassPanel(
              title: 'Saat',
              icon: Icons.schedule_rounded,
              child: Text(
                _currentTime,
                style: const TextStyle(
                  color: GlassTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            GlassPanel(
              title: 'Anlık Durum',
              icon: Icons.insights_rounded,
              child: _buildStats(total, inside, outside),
            ),
            const SizedBox(height: 14),
            _buildOutsidePanel(),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildPhoneDashboard(int total, int inside, int outside) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWelcomePanel(),
        const SizedBox(height: 12),
        GlassPanel(
          title: 'Saat',
          icon: Icons.schedule_rounded,
          child: Text(_currentTime, style: const TextStyle(color: GlassTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        GlassPanel(
          title: 'Bugünkü Durum',
          icon: Icons.insights_rounded,
          child: _buildStats(total, inside, outside),
        ),
        const SizedBox(height: 12),
        _buildOutsidePanel(),
      ],
    );
  }

  // ------------------------------------------------------------
  // SECTION PANELS
  // ------------------------------------------------------------
  Widget _buildWelcomePanel() {
    final String name = authService.currentUser?.username.toUpperCase() ?? 'ADMİN';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'GÜNAYDIN' : (hour < 18 ? 'İYİ GÜNLER' : 'İYİ AKŞAMLAR');

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(colors: [GlassTheme.cyan, GlassTheme.purple]).createShader(bounds),
            child: Text(
              '$greeting, $name',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.6),
            ),
          ),
          const SizedBox(height: 7),
          const Text('Kontrol paneline hoş geldin.', style: TextStyle(color: GlassTheme.textPrimary, fontSize: 21, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('Bugünkü sistemi buradan hızlıca yönetebilirsin.', style: TextStyle(color: GlassTheme.textSecondary.withValues(alpha: .9), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickActionsPanel() {
    final items = _buildMenuActions(context);
    return GlassPanel(
      title: 'Hızlı İşlemler',
      subtitle: 'Sistemdeki işlemlere hızlı erişim',
      icon: Icons.apps_rounded,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.6,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GlassActionTile(
            icon: item.icon,
            title: item.title,
            onTap: item.onTap,
          );
        },
      ),
    );
  }

  Widget _buildStats(int total, int inside, int outside) {
    return Row(
      children: [
        Expanded(child: GlassStat(value: '$total', label: 'Üye')),
        Expanded(child: GlassStat(value: '$inside', label: 'İçeride')),
        Expanded(child: GlassStat(value: '$outside', label: 'Dışarıda', accent: outside > 0)),
      ],
    );
  }

  Widget _buildOutsidePanel() {
    final entries = groupAndOutside.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return GlassPanel(
      title: 'Dışarıdaki Üyeler',
      subtitle: 'Grupların mevcut durumu',
      icon: Icons.directions_walk_rounded,
      child: entries.isEmpty
          ? const Text('Grup verisi bulunamadı', style: TextStyle(color: GlassTheme.textSecondary, fontSize: 12))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries.map((entry) {
                return SizedBox(
                  width: 150,
                  child: GlassGroupCard(
                    group: entry.key,
                    count: entry.value,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MemberListerPage(
                            members: membersValueListener.value,
                            sortColumnIndex: 3,
                            sortAscending: false,
                            groupFilter: entry.key,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ------------------------------------------------------------
  // NAVIGATION & MENU DATA
  // ------------------------------------------------------------
  List<_MenuItem> _buildMenuActions(BuildContext context) {
    final bool isAdmin = authService.currentUser?.role == UserRole.admin;
    return [
      _MenuItem(
        icon: Icons.people_alt_rounded,
        title: 'Üyeler',
        description: 'Üye listesini görüntüle',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberListerPage(members: membersValueListener.value, sortColumnIndex: 1, sortAscending: true, groupFilter: ""))),
      ),
      _MenuItem(
        icon: Icons.swap_horiz_rounded,
        title: 'Giriş / Çıkış',
        description: 'Giriş ve çıkış kayıtları',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => entryListerPage())),
      ),
      if (isAdmin)
      if (!kIsWeb)
        _MenuItem(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Üye Ekle',
          description: 'Yeni üye oluştur',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddMemberPage())),
        ),
      _MenuItem(
        icon: Icons.analytics_rounded,
        title: 'Genel Durum',
        description: 'Sistemin genel durumu',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GeneralStatusPage())),
      ),
      if (!kIsWeb)
      _MenuItem(
        icon: Icons.event_note_rounded,
        title: 'İzinler',
        description: 'İzin kayıtlarını yönet',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PermissionPage())),
      ),
      if (!kIsWeb)
      _MenuItem(
        icon: Icons.label_rounded,
        title: 'Sebepler',
        description: 'Çıkış sebeplerini yönet',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReasonPage())),
      ),
      if (!kIsWeb)
        _MenuItem(
          icon: Icons.sync_rounded,
          title: 'Senkronizasyon',
          description: 'Bekleyen işlemleri senkronize et',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QueuePage())),
        ),
      if (isAdmin)
      if (!kIsWeb)
        _MenuItem(
          icon: Icons.person_2_outlined,
          title: 'Kullanıcı Bilgisi',
          description: 'Operatör ve admin yönetimi',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserManagementScreen())),
        ),
      _MenuItem(
        icon: Icons.settings_rounded,
        title: 'Ayarlar',
        description: 'Uygulama ayarları',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PasswordPage())),
      ),
      _MenuItem(
        icon: Icons.logout_rounded,
        title: 'Çıkış Yap',
        description: 'Oturumu kapat',
        onTap: () async {
          authService.logout();
        },
      ),
    ];
  }

  PreferredSizeWidget _buildAppBar(bool isPhone) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.white.withValues(alpha: .04),
            surfaceTintColor: Colors.transparent,
            shape: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .08), width: 1)),
            leading: isPhone
                ? Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  )
                : null,
            titleSpacing: isPhone ? 0 : 20,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: const LinearGradient(colors: [GlassTheme.cyan, GlassTheme.purple]),
                    boxShadow: [
                      BoxShadow(color: GlassTheme.cyan.withValues(alpha: .55), blurRadius: 250, spreadRadius: 1),
                      BoxShadow(color: GlassTheme.purple.withValues(alpha: .35), blurRadius: 22, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.grid_view_rounded, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(colors: [GlassTheme.cyan, GlassTheme.purple]).createShader(bounds),
                  child: const Text('KIOSK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: .2, color: Colors.white)),
                ),
              ],
            ),
            actions: [
              if (authService.currentUser != null)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: .1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: GlassTheme.cyan,
                          boxShadow: [BoxShadow(color: GlassTheme.cyan.withValues(alpha: .8), blurRadius: 8, spreadRadius: 1)],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(authService.currentUser!.username, style: const TextStyle(fontSize: 12, color: GlassTheme.textSecondary)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final items = _buildMenuActions(context);
    return Drawer(
      width: 290,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220).withValues(alpha: .55),
              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: .08))),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            gradient: const LinearGradient(colors: [GlassTheme.cyan, GlassTheme.purple]),
                            boxShadow: [BoxShadow(color: GlassTheme.cyan.withValues(alpha: .5), blurRadius: 16)],
                          ),
                          child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('K.I.O.S.K', style: TextStyle(color: GlassTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Divider(color: Colors.white.withValues(alpha: .08), height: 1),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 5),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildDrawerMenuItem(item, onTap: () {
                          Navigator.pop(context);
                          item.onTap();
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('K.I.O.S.K', style: TextStyle(color: Colors.white.withValues(alpha: .3), fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerMenuItem(_MenuItem item, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .045),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .07)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: GlassTheme.cyan.withValues(alpha: .15),
          highlightColor: GlassTheme.purple.withValues(alpha: .08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [GlassTheme.cyan.withValues(alpha: .18), GlassTheme.purple.withValues(alpha: .10)]),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: GlassTheme.cyan.withValues(alpha: .2)),
                  ),
                  child: Icon(item.icon, size: 18, color: GlassTheme.cyan),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(color: GlassTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(item.description, style: const TextStyle(color: GlassTheme.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: GlassTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
}