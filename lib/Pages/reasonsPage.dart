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
  
  @override
  void initState() {
    super.initState();

    reasons = getReasons(reasonBox);
  }

  final db = DatabaseService(); 
  final box = Hive.box(reasonBox);
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  List<Reason> reasons = [];



  int? editingIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sebep Yönetimi"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Sebep Bilgileri",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Sebep Adı",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Aktif Günler",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allDays.map((day) {
                          return FilterChip(
                            label: Text(day),
                            selected: selectedDays.contains(day),
                            onSelected: (value) {
                              setState(() {
                                if (value) {
                                  selectedDays.add(day);
                                } else {
                                  selectedDays.remove(day);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(
                                    hour: 0,
                                    minute: 0,
                                  ),
                                );

                                if (result != null) {
                                  setState(() {
                                    startTime = result;
                                  });
                                }
                              },
                              child: Text(
                                startTime == null
                                    ? "Başlangıç"
                                    : startTime!.format(context),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(
                                    hour: 0,
                                    minute: 0,
                                  ),
                                );

                                if (result != null) {
                                  setState(() {
                                    endTime = result;
                                  });
                                }
                              },
                              child: Text(
                                endTime == null
                                    ? "Bitiş"
                                    : endTime!.format(context),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: Text(
                            editingIndex == null
                                ? "KAYDET"
                                : "GÜNCELLE",
                          ),
                          onPressed: () async {
                            // EKLEME
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

                                editingIndex = null;
                                nameController.clear();
                                selectedDays.clear();
                                startTime = null;
                                endTime = null;
                              });
                            }

                            // DÜZENLEME
                            else {
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
                                editingIndex = null;
                                nameController.clear();
                                selectedDays.clear();
                                startTime = null;
                                endTime = null;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Card(
                child: Column(
                  children: [
                    const SizedBox(height: 15),

                    const Text(
                      "Kayıtlı Sebepler",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    Expanded(
                      child: ListView.builder(
                        itemCount: reasons.length,
                        itemBuilder: (
                          context,
                          index,
                        ) {
                          return ListTile(
                            leading: const Icon(
                              Icons.schedule,
                            ),
                            title: Text(
                              reasons[index].name,
                            ),
                            trailing: Wrap(
                              children: [
                                // DÜZENLE
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      editingIndex = index;

                                      final reason =
                                          reasons[index];

                                      nameController.text =
                                          reason.name;

                                      startTime =
                                          reason.startTime != null
                                              ? stringToTimeOfDay(
                                                  reason.startTime!,
                                                )
                                              : null;

                                      endTime =
                                          reason.endTime != null
                                              ? stringToTimeOfDay(
                                                  reason.endTime!,
                                                )
                                              : null;

                                      selectedDays.clear();

                                      for (var day
                                          in reason.days) {
                                        if (day >= 1 &&
                                            day <= allDays.length) {
                                          selectedDays.add(
                                            allDays[day - 1],
                                          );
                                        }
                                      }
                                    });
                                  },
                                ),

                                // SİL
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                  ),
                                  onPressed: () async {
                                    final reasonID = reasons[index].id;
                                    await db.firebaseDatabase
                                        .ref()
                                        .child("Reason")
                                        .child(reasonID)
                                        .remove();

                                    await box.delete(reasonID);

                                    setState(() {
                                      reasons.removeAt(index);

                                      if (editingIndex == index) {
                                        editingIndex = null;
                                        nameController.clear();
                                        selectedDays.clear();
                                        startTime = null;
                                        endTime = null;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
