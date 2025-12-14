import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../utils/database_service.dart';
import '../utils/cache_helper.dart';
import 'info.dart';

class ListerPage extends StatefulWidget {
  const ListerPage({super.key});

  @override
  State<ListerPage> createState() => _ListerPageState();
}

class _ListerPageState extends State<ListerPage> {
  final DatabaseService _databaseService = DatabaseService();

  List<Map<String, String>> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFromCache();
      _fetchFromFirebaseIfNeeded();
    });
  }

  // ⚡ CACHE → ANINDA GÖSTER
  Future<void> _loadFromCache() async {
    final cached = await CacheHelper.load();
    if (cached.isNotEmpty) {
      setState(() {
        _items = cached;
        _isLoading = false;
      });
    }
  }

  // ⏱ CACHE SÜRESİ DOLDUYSA GÜNCELLE
  Future<void> _fetchFromFirebaseIfNeeded() async {
    final expired = await CacheHelper.isExpired();
    if (!expired){
      print("not expired");
      return;
      
    } 

    await _fetchDataFromFirebase();
  }

  // 🔥 FIREBASE OKUMA
  Future<void> _fetchDataFromFirebase() async {
    try {
      final DataSnapshot? snapshot =
          await _databaseService.read(path: 'TALEBE');
      final raw = snapshot?.value;
      if (raw == null) return;

      List<Map<String, dynamic>> temp = [];

      if (raw is List) {
        for (var item in raw) {
          if (item is Map && item.isNotEmpty) {
            temp.add(Map<String, dynamic>.from(item));
          }
        }
      } else if (raw is Map) {
        raw.forEach((_, val) {
          if (val is Map && val.isNotEmpty) {
            temp.add(Map<String, dynamic>.from(val));
          }
        });
      }

      if (temp.isEmpty) return;

      final allKeys =
          temp.map((m) => m.keys).expand((e) => e).toSet();

      final normalized = temp.map((map) {
        return {
          for (var key in allKeys)
            key.toString(): map[key]?.toString() ?? ""
        };
      }).toList();

      final newData =
          normalized.cast<Map<String, String>>();

      // 🔍 SADECE DEĞİŞTİYSE
      if (_items.toString() != newData.toString()) {
        setState(() {
          _items = newData;
          _isLoading = false;
        });

        await CacheHelper.save(newData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("📥 Veri güncellendi"),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Talebe Listesi")),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 50),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 300,
                maxWidth: 900,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowColor: MaterialStateProperty.all(
                      Colors.blueGrey.shade100,
                    ),
                    columnSpacing: 30,
                    horizontalMargin: 16,
                    dividerThickness: 1.2,

                    columns: _items.isNotEmpty
                        ? _items.first.keys
                            .map((k) => DataColumn(
                                  label: Text(k.toUpperCase()),
                                ))
                            .toList()
                        : [],

                    rows: _items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return DataRow(
                        onSelectChanged: (_) {
                          debugPrint("Satır tıklandı: $item");

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InfoPage(data: item),
                            ),
                          );
                        },
                        color: MaterialStateProperty.all(
                          index.isEven
                              ? Colors.white
                              : Colors.grey.shade200,
                        ),
                        cells: item.values
                            .map(
                              (v) => DataCell(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  child: Text(v),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
