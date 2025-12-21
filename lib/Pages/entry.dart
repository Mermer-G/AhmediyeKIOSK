import 'package:flutter/material.dart';

void showCikisDialog(BuildContext context, Map<String, String> talebe) {
  final sebepCtrl = TextEditingController();
  final hocaCtrl = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text("Talebe Dışarı Çıkıyor"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Çıkış Tarihi:\n${DateTime.now()}",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: sebepCtrl,
              decoration: const InputDecoration(
                labelText: "Sebep",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: hocaCtrl,
              decoration: const InputDecoration(
                labelText: "İzin Alınan Hoca",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              final kayit = {
                "grup": talebe["grup"] ?? "",
                "no": talebe["no"] ?? "",
                "cikisTarihi": DateTime.now().toString(),
                "girisTarihi": "",
                "sebep": sebepCtrl.text,
                "hoca": hocaCtrl.text,
              };

              // 🔹 tabloya ekle
              //cikisGirisTablosu.add(kayit);

              // 🔹 talebe durumunu değiştir
              talebe["DURUMU"] = "Dışarıda";

              Navigator.pop(context);
            },
            child: const Text("Çıkışı Kaydet"),
          ),
        ],
      );
    },
  );
}
