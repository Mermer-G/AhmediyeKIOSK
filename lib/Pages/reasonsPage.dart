import 'package:app1/utils/database_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'reasonsPage.g.dart';

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

List<Reason> getReasons(String boxName){
  final box = Hive.box<Reason>(boxName);
  final List<Reason> reasons = [];

  for (var key in box.keys) {
    final reason = box.get(key);

    if (reason != null)
      reasons.add(reason);
  }
  return reasons;
}

@HiveType(typeId: 0)
class Reason extends HiveObject {

  @HiveField(0)
  String id = "";

  @HiveField(1)
  String name = "";

  @HiveField(2)
  List<int> days = [];

  @HiveField(3)
  String? startTime;

  @HiveField(4)
  String? endTime;
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

  final box = Hive.box<Reason>(reasonBox);
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                        children:
                            allDays.map((day) {
                              return FilterChip(
                                label: Text(day),
                                selected:
                                    selectedDays.contains(day),
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
                                final result =
                                    await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(hour: 0, minute: 0),
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
                                    : startTime!
                                        .format(context),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final result =
                                    await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(hour: 0, minute: 0),
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
                                    : endTime!
                                        .format(context),
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
                          onPressed: () {
                            setState(() {
                              //Adding
                              if (editingIndex == null) {

                                var reason = Reason();
                                reason.id = DateTime.now().millisecondsSinceEpoch.toString();
                                reason.name = nameController.text;
                                for (var day in selectedDays){
                                  final index = allDays.indexOf(day) + 1;
                                  reason.days.add(index);
                                }
                                if(startTime != null)
                                {
                                  reason.startTime = "${startTime!.hour}:${startTime!.minute}";
                                }
                                if(endTime != null)
                                {
                                  reason.endTime = "${endTime!.hour}:${endTime!.minute}";
                                }

                                reasons.add(reason);

                                //TODO: Hive box put with id
                                box.put(reason.id, reason);
                              } 

                              //Editing
                              else {
                                reasons[editingIndex!].name = nameController.text;
                                reasons[editingIndex!].days.clear();
                                for (var day in selectedDays){
                                  final index = allDays.indexOf(day) + 1;
                                  reasons[editingIndex!].days.add(index);
                                }
                                if(startTime != null)
                                {
                                  reasons[editingIndex!].startTime = "${startTime!.hour}:${startTime!.minute}";
                                }
                                if(endTime != null)
                                {
                                  reasons[editingIndex!].endTime = "${endTime!.hour}:${endTime!.minute}";
                                }

                                box.put(reasons[editingIndex!].id, reasons[editingIndex!]);
                              }

                              editingIndex = null;

                              nameController.clear();

                              selectedDays.clear();

                              startTime = null;
                              endTime = null;
                            });
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
                            leading:
                                const Icon(
                                  Icons.schedule,
                                ),
                            title:
                                Text(reasons[index].name),
                            trailing: Wrap(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      editingIndex = index;

                                      nameController.text = reasons[index].name;

                                      if(reasons[index].startTime != null){
                                        startTime = stringToTimeOfDay(reasons[index].startTime!);
                                      }
                                      if(reasons[index].endTime != null){
                                        endTime = stringToTimeOfDay(reasons[index].endTime!);
                                      }

                                      if(reasons[index].days.isNotEmpty){
                                        setState(() {
                                          selectedDays.clear();
                                          for (var day in reasons[index].days){
                                            selectedDays.add(allDays[day-1]);
                                          }
                                        });
                                      }

                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                  ),
                                  onPressed: () {
                                    box.delete(reasons[index].id);

                                    setState(() {
                                      reasons.removeAt(
                                        index,
                                      );

                                      if (editingIndex == index) {
                                        editingIndex = null;
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
