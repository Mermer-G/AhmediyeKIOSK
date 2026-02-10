import 'package:ahmediye_kiosk/Pages/entryInfo.dart';
import 'package:ahmediye_kiosk/Pages/studentList.dart';
import 'package:ahmediye_kiosk/utils/database_models.dart';
import 'package:ahmediye_kiosk/utils/database_service.dart';
import 'package:ahmediye_kiosk/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class entryListerPage extends StatefulWidget {
  const entryListerPage({super.key});

  @override
  State<entryListerPage> createState() => _entryListerPageState();
}

class _entryListerPageState extends State<entryListerPage> {
  List<Entry> entries = [];
  List<Entry> shownEntries = [];

  bool _isLoading = true;
  String? _errorMessage;
  int _sortColumnIndex = 2;
  bool _sortAscending = false;

  late List<DataColumn> _columns;
  List<DataRow> _rows = [];

  final groupController = TextEditingController();
  final numberController = TextEditingController();
  final exitTimeController = TextEditingController();
  String groupFilter = "";
  String numberFilter = "";
  String exitTimeFilter = "";

  @override
  void initState() {
    super.initState();
    _fetchDataFromHive();
  }

  Future<void> _fetchDataFromHive() async {
    try {
      final rawMap = Hive.box(entryBox).toMap();

      rawMap.forEach((k, v) {
        Map<String, dynamic> valuesMap = Map<String, dynamic>.from(v as Map);
        entries.add(Entry.fromFireBase(valuesMap));
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Veri yuklenemedi. Veri tabanindan resetlemeyi deneyin.';
        _isLoading = false;
      });
    }
  }

  void convertValuesToListItems() {
    applyFilterAndSort(numberFilter, groupFilter, exitTimeFilter);
    setState(() {
      _columns = Entry.columns(setSortingFields);
      _rows.clear();
      shownEntries.forEach((entry) {
        _rows.add(DataRow(
          onSelectChanged: (selected) async {
            if (selected == true) {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => EntryInfoPage(entry: entry)));
              setState(() {});
            }
          },
          cells: [
            DataCell(Text(entry.group)),
            DataCell(Text(entry.number.toString())),
            DataCell(Text(entry.exitTime)),
          ],
          color: WidgetStateProperty.resolveWith((states) {
            if (entry.entryTime == null) {
              return Colors.red.shade100;
            }
            if (states.contains(WidgetState.selected)) {
              return Colors.blue.shade50;
            }
            return Colors.grey.shade100;
          }),
        ));
      });
      _isLoading = false;
    });
  }

  void applyFilterAndSort(String numberF, String groupF, String exitTimeF) {
    shownEntries = entries;
    if (groupF.isNotEmpty) {
      shownEntries = shownEntries.where((entry) => entry.group.toString().toLowerCase().contains(groupF.toLowerCase())).toList();
    }
    if (numberF.isNotEmpty) {
      shownEntries = shownEntries.where((entry) => entry.number.toString().toLowerCase().contains(numberF.toLowerCase())).toList();
    }
    if (exitTimeF.isNotEmpty) {
      shownEntries = shownEntries.where((entry) => entry.exitTime.toString().toLowerCase().contains(exitTimeF.toLowerCase())).toList();
    }

    switch (_sortColumnIndex) {
      case 0:
        shownEntries.sort((a, b) => _sortAscending
            ? a.group.toLowerCase().compareTo(b.group.toLowerCase())
            : b.group.toLowerCase().compareTo(a.group.toLowerCase()));
        break;
      case 1:
        shownEntries.sort((a, b) => _sortAscending
            ? a.number.compareTo(b.number)
            : b.number.compareTo(a.number));
        break;
      case 2:
        shownEntries.sort((a, b) => _sortAscending
            ? DateTime.parse(a.exitTime).compareTo(DateTime.parse(b.exitTime))
            : DateTime.parse(b.exitTime).compareTo(DateTime.parse(a.exitTime)));
        break;
    }
  }

  void setSortingFields(int sortingColumnIndex, bool sortAscending) {
    setState(() {
      _sortColumnIndex = sortingColumnIndex;
      _sortAscending = sortAscending;
    });
  }

  Widget _buildFilterPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FilterTextField(
          title: "Numaraya Gore",
          controller: numberController,
          onChanged: (value) => setState(() => numberFilter = value),
        ),
        FilterTextField(
          title: "Gruba Gore",
          controller: groupController,
          onChanged: (value) => setState(() => groupFilter = value),
        ),
        FilterTextField(
          title: "Cikis Tarihine Gore",
          controller: exitTimeController,
          onChanged: (value) => setState(() => exitTimeFilter = value),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            groupController.clear();
            numberController.clear();
            exitTimeController.clear();
            setState(() {
              groupFilter = "";
              numberFilter = "";
              exitTimeFilter = "";
            });
          },
          child: const Text("Filtreleri temizle"),
        ),
      ],
    );
  }

  Widget _buildFilterSidebar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 28, 132, 184),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: _buildFilterPanel(),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: drawtable(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    final compact = isCompact(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Giris-Cikis Listesi')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 50),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: compact
              ? Column(
                  children: [
                    ExpansionTile(
                      title: const Text("Filtreler"),
                      leading: const Icon(Icons.filter_list),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _buildFilterPanel(),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    Expanded(child: _buildTable()),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 4, child: _buildTable()),
                    Expanded(flex: 2, child: _buildFilterSidebar()),
                  ],
                ),
        ),
      ),
    );
  }

  DataTable drawtable() {
    convertValuesToListItems();
    return DataTable(
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
        return Colors.grey.shade100;
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
      columns: _columns,
      rows: _rows,
    );
  }
}
