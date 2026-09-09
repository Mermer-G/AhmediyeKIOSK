import 'package:app1/Theme/dashboard_theme.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ReasonPage extends StatefulWidget {
  const ReasonPage({super.key});

  @override
  State<ReasonPage> createState() => _ReasonPageState();
}

TimeOfDay stringToTimeOfDay(String time) {
  final parts = time.split(":");

  return TimeOfDay(
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1]),
  );
}

List<Reason> getReasons(String boxName) {
  final box = Hive.box(boxName);
  final List<Reason> reasons = [];

  for (var key in box.keys) {
    final reason = box.get(key);

    if (reason != null) {
      reasons.add(
        Reason.fromMap(
          Map<dynamic, dynamic>.from(reason),
        ),
      );
    }
  }

  return reasons;
}

class _ReasonPageState extends State<ReasonPage> {
  final TextEditingController nameController =
      TextEditingController();

  final List<String> selectedDays = [];

  final List<String> allDays = [
    "Pzt",
    "Sal",
    "Çrş",
    "Prş",
    "Cum",
    "Cmt",
    "Paz",
  ];

  final db = DatabaseService();
  final box = Hive.box(reasonBox);

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  List<Reason> reasons = [];

  int? editingIndex;

  @override
  void initState() {
    super.initState();
    reasons = getReasons(reasonBox);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _clearForm() {
    nameController.clear();
    selectedDays.clear();
    startTime = null;
    endTime = null;
    editingIndex = null;
  }

  Future<void> _selectStartTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: startTime ??
          const TimeOfDay(
            hour: 0,
            minute: 0,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              surface: Color(0xFF101827),
              primary: GlassTheme.cyan,
              onPrimary: Colors.black,
              onSurface: Colors.white,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFF101827),

              hourMinuteColor: Colors.white.withOpacity(0.06),
              hourMinuteTextColor: Colors.white,

              // AM / PM
              dayPeriodColor: GlassTheme.cyan.withOpacity(0.16),
              dayPeriodTextColor: GlassTheme.cyan,

              dialBackgroundColor: Colors.white.withOpacity(0.045),
              dialHandColor: GlassTheme.cyan,
              dialTextColor: Colors.white,

              entryModeIconColor: Colors.white70,

              hourMinuteTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w500,
              ),

              dayPeriodTextStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),

              dialTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        startTime = result;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: endTime ??
          const TimeOfDay(
            hour: 0,
            minute: 0,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              surface: Color(0xFF101827),
              primary: GlassTheme.cyan,
              onPrimary: Colors.black,
              onSurface: Colors.white,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFF101827),

              hourMinuteColor: Colors.white.withOpacity(0.06),
              hourMinuteTextColor: Colors.white,

              // AM / PM
              dayPeriodColor: GlassTheme.cyan.withOpacity(0.16),
              dayPeriodTextColor: GlassTheme.cyan,

              dialBackgroundColor: Colors.white.withOpacity(0.045),
              dialHandColor: GlassTheme.cyan,
              dialTextColor: Colors.white,

              entryModeIconColor: Colors.white70,

              hourMinuteTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w500,
              ),

              dayPeriodTextStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),

              dialTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        endTime = result;
      });
    }
  }

  void _editReason(int index) {
    final reason = reasons[index];

    setState(() {
      editingIndex = index;

      nameController.text = reason.name;

      startTime = reason.startTime != null
          ? stringToTimeOfDay(reason.startTime!)
          : null;

      endTime = reason.endTime != null
          ? stringToTimeOfDay(reason.endTime!)
          : null;

      selectedDays.clear();

      for (var day in reason.days) {
        if (day >= 1 && day <= allDays.length) {
          selectedDays.add(allDays[day - 1]);
        }
      }
    });
  }

  Future<void> _deleteReason(int index) async {
    final reason = reasons[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: GlassPanel(
              title: 'Sebebi Sil',
              icon: Icons.delete_outline_rounded,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${reason.name}" sebebini silmek istediğinize emin misiniz?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFE57373).withOpacity(0.12),
                          foregroundColor:
                              const Color(0xFFE57373),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: const Color(0xFFE57373)
                                  .withOpacity(0.22),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Sil',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    final reasonID = reason.id;

    await db.firebaseDatabase
        .ref()
        .child("Reason")
        .child(reasonID)
        .remove();

    await box.delete(reasonID);

    setState(() {
      reasons.removeAt(index);

      if (editingIndex == index) {
        _clearForm();
      } else if (editingIndex != null &&
          editingIndex! > index) {
        editingIndex = editingIndex! - 1;
      }
    });
  }

  Future<void> _saveReason() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      return;
    }

    if (editingIndex == null) {
      final reason = Reason(
        id: DateTime.now()
            .millisecondsSinceEpoch
            .toString(),
        name: nameController.text,
        days: selectedDays
            .map(
              (day) => allDays.indexOf(day) + 1,
            )
            .toList(),
        startTime: startTime == null
            ? null
            : "${startTime!.hour}:${startTime!.minute}",
        endTime: endTime == null
            ? null
            : "${endTime!.hour}:${endTime!.minute}",
      );

      await box.put(
        reason.id,
        Reason.toMap(reason),
      );

      await db.updateDB(
        path: "Reason/${reason.id}",
        data: Reason.toMap(reason),
      );

      setState(() {
        reasons.add(reason);
        _clearForm();
      });
    } else {
      final reason = reasons[editingIndex!];

      reason.name = nameController.text;

      reason.days = selectedDays
          .map(
            (day) => allDays.indexOf(day) + 1,
          )
          .toList();

      reason.startTime = startTime == null
          ? null
          : "${startTime!.hour}:${startTime!.minute}";

      reason.endTime = endTime == null
          ? null
          : "${endTime!.hour}:${endTime!.minute}";

      await box.put(
        reason.id,
        Reason.toMap(reason),
      );

      await db.updateDB(
        path: "Reason/${reason.id}",
        data: Reason.toMap(reason),
      );

      setState(() {
        _clearForm();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = editingIndex != null;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20,
            ),
            child: Column(
              children: [
                // HEADER
                Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: GlassTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sebep Yönetimi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Giriş ve çıkış sebeplerini yönetin',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isEditing)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _clearForm();
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 17,
                        ),
                        label: const Text(
                          'Düzenlemeyi İptal Et',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 18),

                // ANA İÇERİK
                Expanded(
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      // SOL PANEL
                      Expanded(
                        flex: 5,
                        child: GlassPanel(
                          title: isEditing
                              ? 'Sebebi Düzenle'
                              : 'Yeni Sebep',
                          icon: isEditing
                              ? Icons.edit_rounded
                              : Icons.add_circle_outline_rounded,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: nameController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                cursorColor:
                                    GlassTheme.cyan,
                                decoration: InputDecoration(
                                  labelText: 'Sebep Adı',
                                  labelStyle:
                                      const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  floatingLabelStyle:
                                      const TextStyle(
                                    color: GlassTheme.cyan,
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                  prefixIcon:
                                      const Icon(
                                    Icons.label_outline_rounded,
                                    size: 19,
                                    color: Colors.white70,
                                  ),
                                  enabledBorder:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white
                                          .withOpacity(0.14),
                                    ),
                                  ),
                                  focusedBorder:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(
                                      color:
                                          GlassTheme.cyan,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              const Text(
                                'Aktif Günler',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: allDays.map((day) {
                                  final selected = selectedDays.contains(day);

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (selected) {
                                          selectedDays.remove(day);
                                        } else {
                                          selectedDays.add(day);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 140),
                                      curve: Curves.easeOut,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 13,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? GlassTheme.cyan.withOpacity(0.10)
                                            : Colors.white.withOpacity(0.035),
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(
                                          color: selected
                                              ? GlassTheme.cyan.withOpacity(0.45)
                                              : Colors.white.withOpacity(0.10),
                                          width: selected ? 1.1 : 1,
                                        ),
                                        boxShadow: selected
                                            ? [
                                                BoxShadow(
                                                  color: GlassTheme.cyan.withOpacity(0.08),
                                                  blurRadius: 10,
                                                  spreadRadius: 0,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        day,
                                        style: TextStyle(
                                          color: selected
                                              ? GlassTheme.cyan
                                              : Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 22),

                              const Text(
                                'Saat Aralığı',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  Expanded(
                                    child: _TimeButton(
                                      label: 'Başlangıç',
                                      time: startTime,
                                      onTap: _selectStartTime,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _TimeButton(
                                      label: 'Bitiş',
                                      time: endTime,
                                      onTap: _selectEndTime,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: _saveReason,
                                  icon: Icon(
                                    isEditing
                                        ? Icons.save_rounded
                                        : Icons.add_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isEditing
                                        ? 'GÜNCELLE'
                                        : 'KAYDET',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor:
                                        GlassTheme.cyan
                                            .withOpacity(0.12),
                                    foregroundColor:
                                        GlassTheme.cyan,
                                    elevation: 0,
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(11),
                                      side: BorderSide(
                                        color: GlassTheme.cyan
                                            .withOpacity(0.22),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // SAĞ PANEL
                      Expanded(
                        flex: 6,
                        child: GlassPanel(
                          title: 'Kayıtlı Sebepler',
                          icon: Icons.schedule_rounded,
                          child: reasons.isEmpty
                              ? const _EmptyReasons()
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (int i = 0;
                                        i < reasons.length;
                                        i++) ...[
                                      _ReasonTile(
                                        reason: reasons[i],
                                        isEditing:
                                            editingIndex == i,
                                        onEdit: () =>
                                            _editReason(i),
                                        onDelete: () =>
                                            _deleteReason(i),
                                      ),
                                      if (i != reasons.length - 1)
                                        Divider(
                                          height: 1,
                                          color: Colors.white
                                              .withOpacity(0.06),
                                        ),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.045),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: time != null
                  ? GlassTheme.cyan.withOpacity(0.20)
                  : Colors.white.withOpacity(0.11),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 18,
                color: time != null
                    ? GlassTheme.cyan
                    : Colors.white70,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time == null
                          ? 'Seçiniz'
                          : time!.format(context),
                      style: TextStyle(
                        color: time != null
                            ? Colors.white
                            : Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final Reason reason;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReasonTile({
    required this.reason,
    required this.isEditing,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasTime =
        reason.startTime != null || reason.endTime != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isEditing
            ? GlassTheme.cyan.withOpacity(0.035)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: GlassTheme.cyan.withOpacity(0.08),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: GlassTheme.cyan.withOpacity(0.14),
              ),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: GlassTheme.cyan,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  reason.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    if (reason.days.isNotEmpty)
                      _InfoBadge(
                        icon: Icons.calendar_today_rounded,
                        text: _formatDays(reason.days),
                      ),
                    if (hasTime)
                      _InfoBadge(
                        icon: Icons.access_time_rounded,
                        text: _formatTimeRange(reason),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            onPressed: onEdit,
            tooltip: 'Düzenle',
            icon: const Icon(
              Icons.edit_rounded,
              size: 18,
              color: Colors.white70,
            ),
          ),

          IconButton(
            onPressed: onDelete,
            tooltip: 'Sil',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 19,
              color: Color(0xFFE57373),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDays(List<int> days) {
    const names = [
      "Pzt",
      "Sal",
      "Çrş",
      "Prş",
      "Cum",
      "Cmt",
      "Paz",
    ];

    final validDays = days
        .where((day) => day >= 1 && day <= 7)
        .map((day) => names[day - 1])
        .toList();

    return validDays.join(', ');
  }

  String _formatTimeRange(Reason reason) {
    if (reason.startTime != null &&
        reason.endTime != null) {
      return '${reason.startTime} - ${reason.endTime}';
    }

    if (reason.startTime != null) {
      return 'Başlangıç ${reason.startTime}';
    }

    return 'Bitiş ${reason.endTime}';
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: Colors.white60,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReasons extends StatelessWidget {
  const _EmptyReasons();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: const Icon(
              Icons.schedule_outlined,
              size: 25,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Henüz sebep eklenmedi.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Yeni bir sebep oluşturmak için soldaki formu kullanın.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}