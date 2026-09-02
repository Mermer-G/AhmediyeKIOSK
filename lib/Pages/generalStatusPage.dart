import 'dart:io';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genel Durum'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : _loadStatistics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // MEMBER
                  // ------------------------------------------------

                  const Text(
                    'Member Bilgileri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _StatusCard(
                    icon: Icons.people,
                    title: 'Toplam Member',
                    value: memberCount.toString(),
                  ),

                  const SizedBox(height: 8),

                  _StatusCard(
                    icon: Icons.groups,
                    title: 'Toplam Grup',
                    value: groupCount.toString(),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Gruplara Göre Member Sayısı',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ...groups.entries.map(
                    (group) => _StatusCard(
                      icon: Icons.group,
                      title: group.key,
                      value: group.value.toString(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // ENTRY
                  // ------------------------------------------------

                  const Text(
                    'Giriş-Çıkış Bilgileri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _StatusCard(
                    icon: Icons.swap_horiz,
                    title: 'Toplam Giriş-Çıkış',
                    value: totalEntryCount.toString(),
                  ),

                  const SizedBox(height: 8),

                  _StatusCard(
                    icon: Icons.today,
                    title: 'Günlük Giriş-Çıkış',
                    value: todayEntryCount.toString(),
                  ),

                  const SizedBox(height: 8),

                  _StatusCard(
                    icon: Icons.date_range,
                    title: 'Haftalık Giriş-Çıkış',
                    value: weeklyEntryCount.toString(),
                  ),

                  const SizedBox(height: 8),

                  _StatusCard(
                    icon: Icons.calendar_month,
                    title: 'Aylık Giriş-Çıkış',
                    value: monthlyEntryCount.toString(),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // STORAGE
                  // ------------------------------------------------

                  const Text(
                    'Veri Boyutu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _StatusCard(
                    icon: Icons.storage,
                    title: 'Giriş-Çıkış Verileri',
                    value: _formatBytes(entryStorageSize),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}