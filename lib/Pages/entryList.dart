import 'package:app1/Pages/entryInfo.dart';
import 'package:app1/Pages/settings.dart';
import 'package:app1/Pages/memberList.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:app1/utils/debugger.dart';
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
  // Bu metod çağrılır sıralama butonuna basıldığında
  int _sortColumnIndex = 2;
  bool _sortAscending = false;
  
  late List<DataColumn> _columns;
 List<DataRow> _rows = [];

  //filter text fields
  final groupController = TextEditingController();
  final numberController = TextEditingController();
  final exitTimeController = TextEditingController();
  final loadAmountController = TextEditingController();
  String groupFilter = "";
  String numberFilter = "";
  String exitTimeFilter = "";
  int loadAmount = 50;
  int loadedDataAmount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDataFromHive();
    loadAmountController.text = loadAmount.toString();
  }

  Future<void> _fetchDataFromHive() async{
    try {
      setState(() {
        _isLoading = true;
      });
      AppLogger.instance.log('===== VERİ ÇEKME BAŞLADI: Entry =====');
      final box = Hive.box(entryBox);

      AppLogger.instance.log("Box entry count: ${box.length}");
      final latest = box.keys.toList()
        ..sort((a, b) => int.parse(b).compareTo(int.parse(a)));

      // entries.clear();
      // entries = latest.take(loadAmount)
      //   .map((k) => Entry.fromMap(box.get(k)))
      //   .toList();

      entries = latest.take(loadAmount)
        .map((k) {
          final value = box.get(k);
          AppLogger.instance.log("KEY: $k VALUE: $value");
          return Entry.fromMap(value);
        })
        .toList();
      
      loadedDataAmount = entries.length;
      AppLogger.instance.log("Entry count: $loadedDataAmount ");
      
      //This is just for testing shown data will be set in somewhere different.
      // convertValuesToListItems();
      setState(() {
        _isLoading = false;
      });
    } 
      
    catch (e) {
      setState(() {
        _errorMessage = 'Veri yüklenemedi. Veri tabanından resetlemeyi deneyin.';
        _isLoading = false;
      });
    }
  }

  List<Entry> parseToEntries(Object? raw){
    List<Entry> returnList = [];

    if(raw is Map){
      //Here keys are nodeKeys(IDs) of members and the values are value blocks A1 : {Dorm:..., Name:...}
      Map<String, dynamic> stringMap = raw.map((key,value) => MapEntry(key.toString(), value));
      returnList = parseToDataType(stringMap, Entry.fromMap);
    }

    else{
      //TODO: Throw error
    }

    return returnList;
  }

  void convertValuesToListItems() {
    applyFilterAndSort(numberFilter, groupFilter, exitTimeFilter);
  
    // We need columns and rows
    //Columns:
    _columns = Entry.columns(setSortingFields);
  
    //Rows:
    _rows.clear();
    //For rows we need to create dataCells
    int numberOfmembers = 0;
    shownEntries.forEach((entry) {
      numberOfmembers++;
      _rows.add(DataRow(
        onSelectChanged: (selected) async {
          if (selected == true) {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => EntryInfoPage(entry: entry))); // yeni info page gelecek buraya.
            setState(() {});       
          }
        },
        cells: [
        DataCell(Text(entry.group)),  
        DataCell(Text(entry.number.toString())), 
        if (DateTime.tryParse(entry.exitTime) != null)
          DataCell(Text(formatDateTime(DateTime.tryParse(entry.exitTime)!)))],

        color: WidgetStateProperty.resolveWith((states) {
        // entryTime default value mu?
        if (entry.entryTime == "Daha giriş yapılmamış") {
          return Colors.red.shade100;
        }

        // widget selected mi?
        if (states.contains(WidgetState.selected)) {
          return Colors.blue.shade50;
        }

        // default
        return Colors.grey.shade100;
      }),
      ));
    });
    _isLoading = false;
    AppLogger.instance.log("Number of members in the table: $numberOfmembers");
  
  }

  void setAmountAndReload() async{
    setState(() {
      var value = int.tryParse(loadAmountController.text);
      if (value != null ){
        loadAmount = value;
        _fetchDataFromHive();
      }
    });
  }

  void applyFilterAndSort(String numberF, String groupF, String exitTimeF) {
    //Filter
    shownEntries = entries;    
    if (groupF.isNotEmpty){
      shownEntries = shownEntries.where((entry) => entry.group.toString().toLowerCase().contains(groupF.toLowerCase())).toList();
    }
    if (numberF.isNotEmpty){
      shownEntries = shownEntries.where((entry) => entry.number.toString().toLowerCase().contains(numberF.toLowerCase())).toList();
    }
    if (exitTimeF.isNotEmpty){
      shownEntries = shownEntries.where((entry) => entry.exitTime.toString().toLowerCase().contains(exitTimeF.toLowerCase())).toList();
    }
    

    //Sort
    switch (_sortColumnIndex) {
      case 0:
        if (_sortAscending){
          shownEntries.sort((a,b) => a.group.toLowerCase().compareTo(b.group.toLowerCase()));
        }
        else{
          shownEntries.sort((a,b) => b.group.toLowerCase().compareTo(a.group.toLowerCase()));
        }
        break;
      case 1:
        if (_sortAscending){
          shownEntries.sort((a,b) => a.number.compareTo(b.number));
        }
        else{
          shownEntries.sort((a,b) => b.number.compareTo(a.number));
        }
        break;
      case 2:
        if (_sortAscending){
          shownEntries.sort((a, b) => DateTime.parse(a.exitTime).compareTo(DateTime.parse(b.exitTime)));
        }
        else{
          shownEntries.sort((a, b) => DateTime.parse(b.exitTime).compareTo(DateTime.parse(a.exitTime)));
        }
        break;
    }

  }

  void setSortingFields(int sortingColumnIndex, bool sortAscending){
    setState(() {
      _sortColumnIndex = sortingColumnIndex;
      _sortAscending = sortAscending;
    });
    AppLogger.instance.log("Tapped! index: ${sortingColumnIndex}, ascending: ${sortAscending} ");
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
        const SizedBox(height: 8),
        Center(child: Text("Listede gösterilen veri miktarı:")),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: loadAmountController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(width: 12),

            ElevatedButton(
              onPressed: setAmountAndReload,
              child: const Text("Kaydet"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(child: Text("Yüklenen veri adedi: $loadedDataAmount")),
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
            color: const Color.fromARGB(255, 228, 228, 228),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        
        final bool isWide = constraints.maxWidth > 700;

        return Scaffold(
          appBar: AppBar(title: const Text('Giris-Cikis Listesi')),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 50),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: !isWide
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
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: drawtable(),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: drawtable(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(flex: 2, child: _buildFilterSidebar()),
                  ],
                ),
              ),
            ),
      );
      }
    );


  }

}

