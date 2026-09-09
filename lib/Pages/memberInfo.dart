import 'package:app1/Pages/entryInfo.dart';
import 'package:app1/Pages/new_home.dart';
import 'package:app1/Pages/permissionPage.dart';
import 'package:app1/Pages/reasonsPage.dart';
import 'package:app1/Pages/settings.dart';
import 'package:app1/Theme/dashboard_theme.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/debugger.dart';
import 'package:app1/utils/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/database_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MemberInfoPage extends StatefulWidget {
  final String? pushID; //for reading entry 
  final Member member; //for showing data

  const MemberInfoPage({
    super.key,
    required this.pushID,
    required this.member,
  });

  @override
  State<MemberInfoPage> createState() => _MemberInfoPageState();
}

bool isTimeInRange(
    TimeOfDay now,
    TimeOfDay start,
    TimeOfDay end,
) {
  final nowMinutes = now.hour * 60 + now.minute;
  final startMinutes = start.hour * 60 + start.minute;
  final endMinutes = end.hour * 60 + end.minute;

  return nowMinutes >= startMinutes &&
      nowMinutes <= endMinutes;
}

const STATEIN = "Inside";
const STATEOUT = "Outside";

class _MemberInfoPageState extends State<MemberInfoPage> {
  final _dbService = DatabaseService();
  late Member st;
  Entry? entry;

  @override
  void initState() {
    super.initState();
    initializeFields();
  }

  void initializeFields(){
    st = widget.member;
    DatabaseService _dbService = DatabaseService();
    setState(() {
      if(st.entryID == null){
        AppLogger.instance.warn("Member has no entry ID");
        return;
      } 
      AppLogger.instance.warn("Member has state: ${st.state}");
      final entryMap = _dbService.readFromHive(path: st.entryID!.toString(), b: Hive.box(entryBox)); 
      if(entryMap == null){
        AppLogger.instance.warn("Member entry was null");
        return;
      }
      AppLogger.instance.warn("Entry ID:${st.entryID}");
      entry = Entry.fromMap(entryMap);
    });
  }

  bool get hasPhone => st.phone != null;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: GlassTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Üye Detayı',
                      style: TextStyle(
                        color: GlassTheme.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // BODY CONTENT
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    // KİMLİK KARTI
                    _identityCard(),

                    const SizedBox(height: 16),

                    // BAĞLAM & BİLGİLER
                    _infoCard("Yatakhane", st.dorm, Icons.single_bed_rounded),
                    _infoCard("Açıklama / Sebep", entry?.reason, Icons.notes_rounded),
                    if (entry?.reason == "Diğer...")
                      _infoCard("Diğer Sebep", entry?.otherReason, Icons.more_horiz_rounded),

                    const SizedBox(height: 16),

                    // DURUM + İŞLEM BUTONLARI
                    _statusCard(),

                    const SizedBox(height: 16),

                    // İLETİŞİM
                    _contactButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────
  // KİMLİK KARTI
  Widget _identityCard() {
    final bool isInside = (st.state ?? "").toLowerCase() == STATEIN.toLowerCase();

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  st.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isInside
                      ? Colors.greenAccent.withOpacity(0.15)
                      : Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isInside ? Colors.greenAccent : Colors.redAccent,
                    width: 1,
                  ),
                ),
                child: Text(
                  st.state == null
                      ? "Belirsiz"
                      : st.state!.toLowerCase() == STATEIN.toLowerCase()
                          ? "İçeride"
                          : "Dışarıda",
                  style: TextStyle(
                    color: isInside ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildBadge(Icons.groups_rounded, "Grup: ${st.group}"),
              const SizedBox(width: 10),
              _buildBadge(Icons.tag_rounded, "No: ${st.number}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GlassTheme.cyan),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────
  // ENTRY DIALOG WINDOW
  Future<bool> showEntry(BuildContext context, Member member) async {
    final List<Reason> reasons = getReasons(reasonBox); 
    final newReason = Reason(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: "Diğer...",
      days: [1, 2, 3, 4, 5, 6, 7],
    );

    reasons.add(newReason);

    final now = TimeOfDay.now();
    final currentDay = DateTime.now().weekday; // 1-7

    final List<Permission> permisions = getPermissions(permissionBox); 

    final otherReason = TextEditingController();
    String? selectedReason = reasons.any((r) => r.name == NewHomePage.reason) ? NewHomePage.reason : null;
    String? selectedPermission = permisions.any((r) => r.name == NewHomePage.permission) ? NewHomePage.permission : null;

    

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
                backgroundColor: const Color(0xFF111827),
                surfaceTintColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(16),
              child: GlassPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.directions_walk_rounded, color: GlassTheme.cyan),
                        SizedBox(width: 8),
                        Text(
                          "Üye Dışarı Çıkıyor",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Çıkış Tarihi: ${formatDateTime(DateTime.now())}",
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    const SizedBox(height: 16),

                    // REASON DROPDOWN
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF1E2638),
                      value: selectedReason,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _dialogInputDecoration("Sebep Seçiniz", Icons.help_outline_rounded),
                      items: reasons
                          .where((reason) {
                            if (!reason.days.contains(currentDay)) return false;
                            if(reason.startTime != null && reason.endTime != null){
                              final start = stringToTimeOfDay(reason.startTime!);
                              final end = stringToTimeOfDay(reason.endTime!);
                              return isTimeInRange(now, start, end);
                            }
                            return true;
                          })
                          .map((reason) {
                            return DropdownMenuItem<String>(
                              value: reason.name,
                              child: Text(reason.name),
                            );
                          })
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          NewHomePage.reason = value;
                        });
                        setDialogState(() {
                          selectedReason = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // PERMISSION DROPDOWN
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF1E2638),
                      value: selectedPermission,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _dialogInputDecoration("İzin Veren Hoca", Icons.person_outline_rounded),
                      items: permisions
                          .map((item) => DropdownMenuItem(
                                value: item.name, 
                                child: Text(item.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          NewHomePage.permission = value;
                        });
                        setDialogState(() {
                          selectedPermission = value;
                        });
                      },
                    ),

                    if (selectedReason == "Diğer...") ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: otherReason,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _dialogInputDecoration("Diğer Sebebi Giriniz", Icons.edit_note_rounded),
                      ),
                    ],

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("İptal", style: TextStyle(color: Colors.white60)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlassTheme.cyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            if (selectedPermission == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Lütfen izin veren hocayı seçiniz.")),
                              );
                              return;
                            }

                            if (selectedReason == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Lütfen sebep seçiniz.")),
                              );
                              return;
                            }

                            if (selectedReason == "Diğer..." && otherReason.text == "") {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Lütfen diğer sebebi giriniz.")),
                              );
                              return;
                            }

                            final entryID = _dbService.createPushID(); 

                            entry = Entry( 
                              entryID: entryID, 
                              group: member.group, 
                              number: member.number, 
                              name: member.name,
                              operator: AuthService.instance.currentUser!.username,
                              exitTime: DateTime.now().toString(), 
                              entryTime: null, 
                              permission: selectedPermission, 
                              reason: selectedReason,
                              otherReason: otherReason.text
                            ); 

                            await _dbService.putToHive(
                              pushID: entryID.toString(), 
                              data: Entry.toMap(entry!), 
                              b: Hive.box(entryBox)
                            ); 
                            
                            setState(() { 
                              member.entryID = entryID; 
                              member.state = STATEOUT; 
                              widget.member.entryID = entryID;
                            }); 

                            MemberState memberState = MemberState(
                              group: member.group, 
                              number: member.number, 
                              state: MemberStateEnum.values.byName(member.state!.toLowerCase()), 
                              lastEntryID: entryID
                            );

                            await _dbService.updateHive(
                              path: "${member.group}_${member.number}", 
                              data: MemberState.toMap(memberState), b: Hive.box(memberStateBox)
                            ); 
                            Navigator.pop(context, true);
                          },
                          child: const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    return result ?? false;
  }

  InputDecoration _dialogInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
      prefixIcon: Icon(icon, color: GlassTheme.cyan, size: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GlassTheme.cyan),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  // ────────────────────────────────
  // BİLGİ SATIRI
  Widget _infoCard(String title, String? value, IconData icon) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GlassTheme.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: GlassTheme.cyan, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────
  // DURUM + İÇERİ / DIŞARI
  Widget _statusCard() {
    final isInside = (st.state ?? "").toLowerCase() == STATEIN.toLowerCase();

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry != null && !isInside) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Colors.white60),
                      const SizedBox(width: 6),
                      Text(
                        "Çıkış Zamanı: ${formatDateTime(DateTime.tryParse(entry!.exitTime)!)}",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 14, color: Colors.white60),
                      const SizedBox(width: 6),
                      Text(
                        "İzin Veren: ${entry!.permission}",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: GlassTheme.cyan.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openEntryInfo(entry),
                icon: const Icon(Icons.receipt_long_rounded, size: 16, color: GlassTheme.cyan),
                label: const Text(
                  "Giriş Çıkış Bilgilerini Görüntüle",
                  style: TextStyle(color: GlassTheme.cyan, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!kIsWeb)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInside
                      ? Colors.redAccent.withOpacity(0.85)
                      : Colors.greenAccent.withOpacity(0.85),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _toggleStatus,
                icon: Icon(
                  isInside ? Icons.logout_rounded : Icons.login_rounded,
                  size: 18,
                ),
                label: Text(
                  isInside ? "Dışarı Çıkar" : "İçeri Al",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────
  // İLETİŞİM
  Widget _contactButtons() {
    if (!kIsWeb) return SizedBox();
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: hasPhone ? "" : "Numara kayıtlı değil",
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.06),
                  foregroundColor: hasPhone ? Colors.white : Colors.white30,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                onPressed: hasPhone ? _call : null,
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text("Ara"),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Tooltip(
            message: hasPhone ? "" : "Numara kayıtlı değil",
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.2),
                  foregroundColor: hasPhone ? Colors.greenAccent : Colors.white30,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.greenAccent.withOpacity(0.3)),
                  ),
                ),
                onPressed: hasPhone ? _whatsapp : null,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text("WhatsApp"),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────
  // STATE LOGIC (DOKUNULMADI)
  void _openEntryInfo(Entry? entry) async {
    if (entry == null){
      AppLogger.instance.error("Entry was null");
      return;
    }
    AppLogger.instance.log("Member Info'dan --> Entry Info'ya geçildi");
    await Navigator.push(context, MaterialPageRoute(builder: (context) => EntryInfoPage(entry: entry)));
  }

  void _toggleStatus() async {

    if(AuthService.instance.currentUser != null){
      if(AuthService.instance.currentUser!.role != UserRole.operator){
        AppLogger.instance.error("User role is not operator!");
        AppLogger.instance.showOverlay("Adminler giriş çıkış yapamazlar! Lütfen bir operatör seçiniz.", LogLevel.error);
        return;
      }
    }
    else{
      AppLogger.instance.error("User is null!");
      throw Exception("NULL USER EXCEPTION");
    }

    if (st.state!.toLowerCase() == STATEOUT.toLowerCase()) {
      // Dışardayken direkt içeri gir

      setState(() {
        st.state = STATEIN;
        entry!.entryTime = DateTime.now().toString();
        widget.member.state = st.state;
      });

      _dbService.updateHive(path: st.entryID!.toString(), data: Entry.toMap(entry!), b: Hive.box(entryBox));

      MemberState memberState = MemberState(
        group: st.group, 
        number: st.number, 
        state: MemberStateEnum.values.byName(st.state!.toLowerCase()), 
        lastEntryID: null
      );

      _dbService.updateHive(path: "${st.group}_${st.number}", data: MemberState.toMap(memberState), b: Hive.box(memberStateBox));
      setState(() {
        st.entryID = null;
      });
      
      return;
    }

    // İçerideyse dışarı çıkış için onay al
    await showEntry(context, st);
  }

  void readEntryAndReload(Member st){
    final stud = _dbService.readFromHive(path: "${st.group}_${st.number}" ,b: Hive.box(memberBox));

    final realStud = Member.fromMap(stud!);
    if (realStud.entryID == null) {
      AppLogger.instance.warn("Member has no entry ID.");
      return;
    }

    final rawEntryData = _dbService.readFromHive(path: realStud.entryID!.toString(), b: Hive.box(entryBox));

    if (rawEntryData == null) {
      AppLogger.instance.warn("No entry found for ID in Hive: $st.entryID");
      return;
    }

    final entry = Entry.fromMap(rawEntryData);

    AppLogger.instance.log("Entry read successfully:");
    AppLogger.instance.log("Group      : ${entry.group}");
    AppLogger.instance.log("Number     : ${entry.number}");
    AppLogger.instance.log("Entry Time : ${entry.entryTime}");
    AppLogger.instance.log("Exit Time  : ${entry.exitTime}");
    AppLogger.instance.log("Permission : ${entry.permission}");
    AppLogger.instance.log("Reason     : ${entry.reason}");
    
    setState(() {
    });
  }

// ────────────────────────────────
  // İLETİŞİM METOTLARI
  
  String _cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  Future<void> _call() async {
    if (st.phone == null || st.phone!.isEmpty) return;

    final cleanedPhone = _cleanPhoneNumber(st.phone!);
    final Uri uri = Uri(scheme: 'tel', path: cleanedPhone);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Arama başlatılamadı.")),
          );
        }
      }
    } catch (e) {
      AppLogger.instance.error("Arama hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Arama hatası: $e")),);
    }
  }

  Future<void> _whatsapp() async {
    if (st.phone == null || st.phone!.isEmpty) return;

    var cleanedPhone = _cleanPhoneNumber(st.phone!);

    // Türkiye numaraları için başında ülke kodu eksikse (+90 / 90) ekleme mantığı
    if (cleanedPhone.startsWith('0')) {
      cleanedPhone = '90${cleanedPhone.substring(1)}';
    } else if (!cleanedPhone.startsWith('90')) {
      cleanedPhone = '90$cleanedPhone';
    }

    // Mobil web ve uygulamalarda en kararlı çalışan API URL'i
    final Uri uri = Uri.parse("https://wa.me/$cleanedPhone");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Mobil web'de doğrudan WhatsApp uygulamasını/webini tetikler
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("WhatsApp açılamadı.")),
          );
        }
      }
    } catch (e) {
      AppLogger.instance.error("WhatsApp hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("WhatsApp hatası: $e")),);
    }
  }
}