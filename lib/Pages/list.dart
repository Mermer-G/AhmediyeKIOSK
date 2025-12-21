import 'package:app1/Pages/info.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../utils/database_service.dart'; // Correct import path

class ListerPage extends StatefulWidget {
  const ListerPage({super.key});

  @override
  State<ListerPage> createState() => _ListerPageState();
}

class FilterTextField extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const FilterTextField({
    super.key,
    required this.title,
    required this.controller,
    required this.onChanged,
    this.hint = "Filtrele...",
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _ListerPageState extends State<ListerPage> {
  List<Map<String, String>> _allItems = []; // ORİJİNAL veri
  List<Map<String, String>> _items = [];    // EKRANDA GÖSTERİLEN
  // int? _selectedIndex;
  bool _isLoading = true;
  String? _errorMessage;
  final DatabaseService _databaseService = DatabaseService();
  // Bu metod çağrılır sıralama butonuna basıldığında
  int _sortColumnIndex = 0;
  bool _sortAscending = false;
  
  late final List<String> _columns;

  //filter text fields
  final nameController = TextEditingController();
  final groupController = TextEditingController();
  final stateController = TextEditingController();
  final numberController = TextEditingController();
  String nameFilter = "";
  String groupFilter = "";
  String stateFilter = "";
  String numberFilter = "";

  @override
  void initState() {
    super.initState();
    _fetchDataFromFirebase();
    _columns = _allItems.isNotEmpty
      ? _allItems.first.keys.toList()
      : [];
  }
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchDataFromFirebase() async {
    try {
      print('===== VERİ ÇEKME BAŞLADI =====');
      final DataSnapshot? snapshot = await _databaseService.read(path: 'STUDENT');
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
        _allItems = normalized.map((map) {
          return map.map((key, value) =>
              MapEntry(key.toString(), value.toString()));
        }).toList();

        _items = List.from(_allItems); // 🔥 çok önemli
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

    void applyFilterAndSort() {
      List<Map<String, String>> filtered = _allItems.where((item) {
        final nameMatch = item['ADI SOYADI']
            .toString()
            .toLowerCase()
            .contains(nameFilter.toLowerCase());

        final groupMatch = item['GRUBU']
            .toString()
            .toLowerCase()
            .contains(groupFilter.toLowerCase());

        final numberMatch = item['NUMARASI']
          .toString()
          .toLowerCase()
          .contains(numberFilter.toLowerCase());

        return numberMatch && groupMatch && nameMatch;
      }).toList();

      if (filtered.isNotEmpty) {
        final key = filtered.first.keys.elementAt(_sortColumnIndex!);

        filtered.sort((a, b) {
          final aValue = a[key] ?? "";
          final bValue = b[key] ?? "";

          final aNum = num.tryParse(aValue.toString());
          final bNum = num.tryParse(bValue.toString());

          int compareResult;

          if (aNum != null && bNum != null) {
            compareResult = aNum.compareTo(bNum);
          } else {
            compareResult = aValue
                .toString()
                .toLowerCase()
                .compareTo(bValue.toString().toLowerCase());
          }

          return _sortAscending ? compareResult : -compareResult;
        });
      }

      setState(() {
        _items = filtered;
      });
    }

    void sort(int columnIndex) {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortAscending = true;
      }

      _sortColumnIndex = columnIndex;

      applyFilterAndSort();
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
                flex: 4,
                child: Align(
                  alignment: Alignment.topLeft,
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
                        columns: _allItems.first.keys.map((key) {
                          return DataColumn(
                            label: Text(key.toUpperCase()),
                            onSort: (columnIndex, _) {
                              sort(columnIndex);
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
                                  builder: (context) => InfoPage(
                                    data: [item], // 🔥 sadece seçilen satır
                                  ),
                                ),
                              );
                            },
                            color: WidgetStateColor.resolveWith((states) {
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

              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity, // 🔥 BU ÖNEMLİ
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 28, 132, 184),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FilterTextField(
                            title: "Numaraya Göre",
                            controller: numberController,
                            onChanged: (value) {
                              numberFilter = value;
                              applyFilterAndSort();
                            }
                          ),

                          FilterTextField(
                            title: "Gruba Göre",
                            controller: groupController,
                            onChanged: (value) {
                              groupFilter = value;
                              applyFilterAndSort();
                            }
                          ),

                          FilterTextField(
                            title: "İsme Göre",
                            controller: nameController,
                            onChanged: (value) {
                              nameFilter = value;
                              applyFilterAndSort();
                            }
                          ),


                          ElevatedButton(
                            onPressed: () {},
                            child: const Text("Buton"),
                          ),
                        ],
                      )
                    ),
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