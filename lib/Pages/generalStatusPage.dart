import 'package:app1/Theme/dashboard_theme.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class GeneralStatusPage extends StatefulWidget {
  const GeneralStatusPage({super.key});

  @override
  State<GeneralStatusPage> createState() => _GeneralStatusPageState();
}

class _GeneralStatusPageState extends State<GeneralStatusPage> {
  int memberCount = 0;
  int groupCount = 0;

  Map<String, int> groups = {};

  int totalEntryCount = 0;
  int todayEntryCount = 0;
  int weeklyEntryCount = 0;
  int monthlyEntryCount = 0;

  int entryStorageSize = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      isLoading = true;
    });

    final memberBoxInstance = Hive.box(memberBox);
    final entryBoxInstance = Hive.box(entryBox);

    // ------------------------------------------------------------
    // Member bilgileri
    // ------------------------------------------------------------

    final memberGroups = <String, int>{};

    for (final data in memberBoxInstance.values) {
      if (data == null) continue;

      final member = Member.fromMap(
        Map<String, dynamic>.from(data),
      );

      memberGroups[member.group] =
          (memberGroups[member.group] ?? 0) + 1;
    }

    // ------------------------------------------------------------
    // Entry bilgileri
    // ------------------------------------------------------------

    final entries = <Entry>[];

    for (final data in entryBoxInstance.values) {
      if (data == null) continue;

      entries.add(
        Entry.fromMap(
          Map<dynamic, dynamic>.from(data),
        ),
      );
    }

    final now = DateTime.now();

    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final weekStart = todayStart.subtract(
      Duration(days: todayStart.weekday - 1),
    );

    final monthStart = DateTime(
      now.year,
      now.month,
      1,
    );

    int today = 0;
    int weekly = 0;
    int monthly = 0;

    for (final entry in entries) {
      final exitTime = DateTime.tryParse(entry.exitTime);

      if (exitTime == null) continue;

      if (!exitTime.isBefore(todayStart)) {
        today++;
      }

      if (!exitTime.isBefore(weekStart)) {
        weekly++;
      }

      if (!exitTime.isBefore(monthStart)) {
        monthly++;
      }
    }

    // ------------------------------------------------------------
    // Gerçek Hive dosya boyutu
    // ------------------------------------------------------------

    final storageSize = _getEntryDataSize();

    if (!mounted) return;

    setState(() {
      memberCount = memberBoxInstance.length;

      groups = memberGroups;
      groupCount = memberGroups.length;

      totalEntryCount = entries.length;
      todayEntryCount = today;
      weeklyEntryCount = weekly;
      monthlyEntryCount = monthly;

      entryStorageSize = storageSize;

      isLoading = false;
    });
  }

  int _getEntryDataSize() {
    final box = Hive.box(entryBox);

    int totalBytes = 0;

    for (final data in box.values) {
      if (data == null) continue;

      final entryMap = Map<dynamic, dynamic>.from(data);

      for (final value in entryMap.values) {
        if (value == null) continue;

        totalBytes += value.toString().length;
      }
    }

    return totalBytes;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: GlassTheme.cyan,
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------------------------------------
                    // HEADER
                    // ------------------------------------------------
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
                          child: Text(
                            'Genel Durum',
                            style: TextStyle(
                              color: GlassTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _loadStatistics,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: GlassTheme.cyan,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ------------------------------------------------
                    // MEMBER BILGILERI
                    // ------------------------------------------------
                    GlassPanel(
                      title: 'Üye Bilgileri',
                      icon: Icons.badge_rounded,
                      child: Column(
                        children: [
                          _GlassStatusCard(
                            icon: Icons.people_alt_rounded,
                            title: 'Toplam Üye Adedi',
                            value: memberCount.toString(),
                          ),
                          const SizedBox(height: 8),
                          _GlassStatusCard(
                            icon: Icons.groups_rounded,
                            title: 'Toplam Grup Adedi',
                            value: groupCount.toString(),
                          ),
                          if (groups.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Gruplara Göre Üye Sayısı',
                                style: TextStyle(
                                  color: GlassTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...groups.entries.map(
                              (group) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _GlassStatusCard(
                                  icon: Icons.group_work_rounded,
                                  title: group.key,
                                  value: group.value.toString(),
                                  isSubItem: true,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ------------------------------------------------
                    // GİRİŞ-ÇIKIŞ BİLGİLERİ
                    // ------------------------------------------------
                    GlassPanel(
                      title: 'Giriş-Çıkış Bilgileri',
                      icon: Icons.swap_horizontal_circle_rounded,
                      child: Column(
                        children: [
                          _GlassStatusCard(
                            icon: Icons.swap_horiz_rounded,
                            title: 'Toplam Giriş-Çıkış',
                            value: totalEntryCount.toString(),
                          ),
                          const SizedBox(height: 8),
                          _GlassStatusCard(
                            icon: Icons.today_rounded,
                            title: 'Günlük Giriş-Çıkış',
                            value: todayEntryCount.toString(),
                          ),
                          const SizedBox(height: 8),
                          _GlassStatusCard(
                            icon: Icons.date_range_rounded,
                            title: 'Haftalık Giriş-Çıkış',
                            value: weeklyEntryCount.toString(),
                          ),
                          const SizedBox(height: 8),
                          _GlassStatusCard(
                            icon: Icons.calendar_month_rounded,
                            title: 'Aylık Giriş-Çıkış',
                            value: monthlyEntryCount.toString(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ------------------------------------------------
                    // VERİ BOYUTU
                    // ------------------------------------------------
                    GlassPanel(
                      title: 'Veri Boyutu',
                      icon: Icons.data_usage_rounded,
                      child: _GlassStatusCard(
                        icon: Icons.storage_rounded,
                        title: 'Giriş-Çıkış Verileri',
                        value: _formatBytes(entryStorageSize),
                        accentValue: true,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ------------------------------------------------------------
// TEMAYA UYGUN GLASS STATUS CARD WIDGET
// ------------------------------------------------------------
class _GlassStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isSubItem;
  final bool accentValue;

  const _GlassStatusCard({
    required this.icon,
    required this.title,
    required this.value,
    this.isSubItem = false,
    this.accentValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isSubItem
            ? Colors.white.withValues(alpha: .02)
            : Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSubItem
              ? Colors.white.withValues(alpha: .05)
              : Colors.white.withValues(alpha: .09),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GlassTheme.cyan.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: GlassTheme.cyan, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isSubItem
                    ? GlassTheme.textSecondary
                    : GlassTheme.textPrimary,
                fontSize: 13,
                fontWeight: isSubItem ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: accentValue ? GlassTheme.cyan : GlassTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: accentValue
                  ? [
                      Shadow(
                        color: GlassTheme.cyan.withValues(alpha: .6),
                        blurRadius: 12,
                      )
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}