import 'package:app1/Pages/entryInfo.dart';
import 'package:app1/Pages/studentList.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:firebase_database/firebase_database.dart';
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
  final DatabaseService _databaseService = DatabaseService();
  // Bu metod çağrılır sıralama butonuna basıldığında
  int _sortColumnIndex = 2;
  bool _sortAscending = false;
  
  late List<DataColumn> _columns;
 List<DataRow> _rows = [];

  //filter text fields
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

  Future<void> _fetchDataFromHive() async{
    try {
      print('===== VERİ ÇEKME BAŞLADI =====');
      final rawMap = Hive.box(entryBox).toMap();
      print("Keys[${rawMap.keys.first.runtimeType}]: ${rawMap.keys.first}, Values[${rawMap.values.first.runtimeType}]: ${rawMap.values.first}");
      
      rawMap.forEach((k,v){
        Map<String, dynamic> valuesMap = Map<String, dynamic>.from(v as Map);
        entries.add(
          Entry.fromFireBase(valuesMap)
        );
      });

      print("Student count: ${entries.length} ");
      
      //This is just for testing shown data will be set in somewhere different.
      // convertValuesToListItems();
      setState(() {
        _isLoading = false;
      });
    } 
      
    catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDataFromFirebase() async {
    try {
      print('===== VERİ ÇEKME BAŞLADI =====');
      final DataSnapshot? snapshot = await _databaseService.readFromDB(path: 'Entry');
      final raw = snapshot?.value;
      entries = parseToEntries(raw);
      print("Student count: ${entries.length} ");
      
      //This is just for testing shown data will be set in somewhere different.
      // convertValuesToListItems();
      setState(() {
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

  List<Entry> parseToEntries(Object? raw){
    List<Entry> returnList = [];

    if(raw is Map){
      //Here keys are nodeKeys(IDs) of students and the values are value blocks A1 : {Dorm:..., Name:...}
      Map<String, dynamic> stringMap = raw.map((key,value) => MapEntry(key.toString(), value));
      print("A");
      returnList = parseToDataType(stringMap, Entry.fromFireBase);
    }

    else{
      //TODO: Throw error
    }

    return returnList;
  }

  void convertValuesToListItems() {
    applyFilterAndSort(numberFilter, groupFilter, exitTimeFilter);
    setState(() {
      // We need columns and rows
      //Columns:
      _columns = Entry.columns(setSortingFields);
    
      //Rows:
      _rows.clear();
      //For rows we need to create dataCells
      int numberOfstudents = 0;
      shownEntries.forEach((entry) {
        numberOfstudents++;
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
          DataCell(Text(entry.exitTime)),],

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
      print("Number of students in the table: $numberOfstudents");
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
    print("Tapped! index: ${sortingColumnIndex}, ascending: ${sortAscending} ");
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
                      child: drawtable(),
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
                              setState(() {
                                numberFilter = value;
                              });
                            }
                          ),

                          FilterTextField(
                            title: "Gruba Göre",
                            controller: groupController,
                            onChanged: (value) {
                              setState(() {
                                groupFilter = value;
                              });
                            }
                          ),

                          FilterTextField(
                            title: "Çıkış Tarihine Göre",
                            controller: exitTimeController,
                            onChanged: (value) {
                              setState(() {
                                exitTimeFilter = value;
                              });
                            }
                          ),

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
                            child: const Text("Filtreleri temizle."),
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