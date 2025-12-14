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
  // Bu metod çağrılır sıralama butonuna basıldığında
    int _sortColumnIndex = 0;
    bool _sortAscending = false;


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

      // print("Gelen veri tipi: ${raw.runtimeType}");
      // print("Gelen veri: $raw");

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
    } 
    catch (e) {
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

    

    void _sort(int columnIndex) {
      

      setState(() {
        if (_sortColumnIndex == columnIndex) {
          // Aynı sütuna tekrar basıldı, sıralama yönünü değiştir
          _sortAscending = !_sortAscending;
          print("YESSS");
        } else {
          // Yeni sütuna basıldı, sıralama artan olsun
          _sortAscending = true;
          print("NOoo");
        }
        _sortColumnIndex = columnIndex;
        final key = _items.first.keys.elementAt(columnIndex);

        _items.sort((a, b) {
          final aValue = a[key] ?? "";
          final bValue = b[key] ?? "";

          final aNum = num.tryParse(aValue);
          final bNum = num.tryParse(bValue);

          int compareResult;

          if (aNum != null && bNum != null) {
            compareResult = aNum.compareTo(bNum);
          } else {
            compareResult = aValue.toString().toLowerCase().compareTo(bValue.toString().toLowerCase());
          }

          return _sortAscending ? compareResult : -compareResult;
        });
      });
    }

    Widget sectionTitle(String text, Color color) {
      return Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    Widget sortButton(
      String text,
      int index, 
      bool asc,
    ) {
      return SizedBox(
        width: 130,
        child: ElevatedButton(
          onPressed: () {
            
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
      );
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
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      showCheckboxColumn: false,
                      headingRowColor: WidgetStateColor.resolveWith(
                        (states) => Colors.blueGrey.shade100,
                      ),
                      dataRowColor: WidgetStateColor.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
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
                      columns: _items.first.keys.map((key) {
                        return DataColumn(
                          label: Text(key.toUpperCase()),
                          onSort: (columnIndex, _) {
                            _sort(columnIndex);
                          } 
                        );
                      }).toList(),
                                
                      rows: _items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                                
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

              Expanded(
                flex: 2,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity, // 🔥 BU ÖNEMLİ
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        sectionTitle("Artan Sıralama", const Color(0xFF006110)),
                          const SizedBox(height: 12),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Wrap(
                              spacing: 10,
                              children: [
                                sortButton("Duruma Göre", 0, false),
                                sortButton("Gruba Göre", 1, false),
                                sortButton("Yatakhaneye Göre", 2, false),
                                sortButton("İsme Göre", 3, false),
                                sortButton("Numaraya Göre", 4, false),
                              ],
                            ),
                          ),

                        const SizedBox(height: 30),

                        sectionTitle("Azalan Sıralama", const Color(0xFF004E61)),
                          const SizedBox(height: 12),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Wrap(
                              spacing: 10,
                              children: [
                                sortButton("Duruma Göre", 0, true),
                                sortButton("Gruba Göre", 1, true),
                                sortButton("Yatakhaneye Göre", 2, true),
                                sortButton("İsme Göre", 3, true),
                                sortButton("Numaraya Göre", 4, true),
                              ],
                            ),
                          ),


                        const SizedBox(height: 40),

                        ElevatedButton(
                          onPressed: () {},
                          child: const Text("Buton"),
                        ),
                      ],
                    )
                  ),
                ),
              )
            ],
          ),
        ),
      )


    );
  }
}