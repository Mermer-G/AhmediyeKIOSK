import 'package:app1/Pages/info.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../utils/database_service.dart'; // Correct import path

class ListerPage extends StatefulWidget {
  const ListerPage({super.key});

  @override
  State<ListerPage> createState() => _ListerPageState();
}

class _ListerPageState extends State<ListerPage> {
  List<Map<String, String>> _items = [];
  // int? _selectedIndex;
  bool _isLoading = true;
  String? _errorMessage;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _fetchDataFromFirebase();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchDataFromFirebase() async {
  try {
    print('===== VERİ ÇEKME BAŞLADI =====');
    final DataSnapshot? snapshot = await _databaseService.read(path: 'TALEBE');
    final raw = snapshot?.value;

    print("Gelen veri tipi: ${raw.runtimeType}");
    print("Gelen veri: $raw");

    List<Map<String, dynamic>> temp = [];

    // Veri List tipindeyse
    if (raw is List) {
      for (var item in raw) {
        if (item != null && item is Map && item.isNotEmpty) {
          temp.add(Map<String, dynamic>.from(item));
        }
      }
    }

    // Veri Map tipindeyse
    else if (raw is Map) {
      raw.forEach((key, val) {
        if (val != null && val is Map && val.isNotEmpty) {
          temp.add(Map<String, dynamic>.from(val));
        }
      });
    }

    // Hiç veri yoksa
    if (temp.isEmpty) {
      setState(() {
        _items = [];
        _isLoading = false;
        _errorMessage = "No valid data found.";
      });
      return;
    }

    // 🔥 bulunan tüm key’leri topla → otomatik kolon oluştur
    final allKeys = temp.map((m) => m.keys).expand((e) => e).toSet();

    // 🔥 tüm satırları String’e dönüştür
    final normalized = temp.map((map) {
      return {
        for (var key in allKeys) key.toString(): map[key]?.toString() ?? ""
      };
    }).toList();

    setState(() {
      _items = normalized.cast<Map<String, String>>();
      _isLoading = false;
    });

  } catch (e) {
    print('HATA: $e');
    setState(() {
      _errorMessage = 'Error fetching data: $e';
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Data Table'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 50), // 🔥 alt padding 32 px
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center( // 🔥 tabloyu ortaya alır
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 300,
                maxWidth: 900, // 🔥 tablo genişliği kontrol
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    showCheckboxColumn: false,


                    headingRowColor: MaterialStateColor.resolveWith(
                      (states) => Colors.blueGrey.shade100,
                    ),
                    dataRowColor: MaterialStateColor.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.blue.shade50;
                      }
                      return Colors.grey.shade50;
                    }),
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),

                    dataTextStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),

                    columnSpacing: 30,
                    horizontalMargin: 16,
                    dividerThickness: 1.2,

                    columns: _items.isNotEmpty
                        ? _items.first.keys
                            .map((k) => DataColumn(label: Text(k.toUpperCase())))
                            .toList()
                        : [],

                    rows: _items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      final isHeaderRow = false; // 🔥 DataTable zaten header'ı otomatik oluşturuyor

                      return DataRow(
                        onSelectChanged: (_) {
                          print("🔵 Satıra tıklandı! Index: $index");
                          print("🟢 Satır verisi: $item");

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InfoPage(data: item),
                            ),
                          );
                        },
                        color: MaterialStateColor.resolveWith((states) {
                          return index % 2 == 0 ? Colors.white : Colors.grey.shade200;
                        }),
                        cells: item.values.map((v) {
                          return DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 4.0,
                              ),
                              child: Text(v),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      )


    );
  }
}