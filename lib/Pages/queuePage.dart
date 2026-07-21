import 'package:app1/utils/offline_queue.dart';
import 'package:flutter/material.dart';
import 'package:app1/utils/database_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});  

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  @override
  Widget build(BuildContext context) {
    final box = Hive.box(queueBox);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sync Queue"),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        
        builder: (context, Box box, _) {
        if (box.isEmpty) {
          return const Center(
            child: Text("Queue boş"),
          );
        }

        final keys = box.keys.toList();

        return Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Toplam ${box.length} kayıt",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  FutureBuilder<bool>(
                    future: DatabaseService().hasInternet(),
                    builder: (context, snapshot) {
                      final online = snapshot.data ?? false;

                      return Row(
                        children: [
                          Icon(
                            online ? Icons.wifi : Icons.wifi_off,
                            color: online ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 12),

                          ElevatedButton.icon(
                            onPressed: () async {
                              await QueueHelper().syncQueue();
                              setState(() {});
                            },
                            icon: const Icon(Icons.sync),
                            label: const Text("Eşitle"),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final key = keys[index];
                  final item = Map<String, dynamic>.from(box.get(key));

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ID : $key",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text("Path : ${item["path"]}"),

                          const SizedBox(height: 6),

                          const Text(
                            "Data",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          SelectableText(
                            item["data"].toString(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      ),
    );
  }
}

