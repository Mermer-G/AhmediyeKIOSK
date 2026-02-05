import 'package:app1/Pages/studentInfo.dart';
import 'package:app1/utils/database_models.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/database_service.dart'; // Correct import path

class StudentListerPage extends StatefulWidget {
  const StudentListerPage({super.key});

  @override
  State<StudentListerPage> createState() => _StudentListerPageState();
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

class _StudentListerPageState extends State<StudentListerPage> {
  List<Student> students = [];
  List<Student> shownStudents = []; 

  bool _isLoading = true;
  String? _errorMessage;
  final DatabaseService _databaseService = DatabaseService();
  // Bu metod çağrılır sıralama butonuna basıldığında
  int _sortColumnIndex = 1;
  bool _sortAscending = true;
  
  late List<DataColumn> _columns;
  late List<DataRow> _rows = [];

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
    _fetchDataFromHive();
  }

  Future<void> _fetchDataFromHive() async{
    try {
      print('===== VERİ ÇEKME BAŞLADI =====');
      final rawMap = Hive.box(studentBox).toMap();
      
      rawMap.forEach((k,v){
        Map<String, dynamic> valuesMap = Map<String, dynamic>.from(v as Map);
        students.add(
          Student.fromFireBase(valuesMap)
        );
      });

      print("Yatakhane: ${students.first.dorm}");
      print("phone: ${students.first.phone}");
      print("supervisor: ${students.first.supervisor}");

      
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

  void _saveAll(){
    students.forEach((student) {
      final value = Student.toFireBase(student);
      print("Value: ${value}");
      final path = "${student.group}_${student.number}";
      _databaseService.updateHive(path: path, data: value, b: Hive.box(studentBox));
    });
  }

  void _loadAll(){
    //This one doesn't use db service because read from hive gets you only one value. Where in here it gets you everything.
    List<Student> tempStu = [];
    final box = Hive.box(studentBox);
    setState(() {
      students.clear();
      for (var e in box.values) {
        final map = Map<String, dynamic>.from(e);
        final student = Student.fromFireBase(map);
        students.add(student);
      }
    });
    
    print("Box length: ${box.length}");
    print("Box values raw: ${box.values}");
    tempStu.forEach((stu) => print("Stu value: ${stu.group}, ${stu.number}, ${stu.name}, ${stu.phone}"));
  }

  void convertValuesToListItems() {
    applyFilterAndSort(nameFilter, numberFilter, groupFilter, stateFilter);
    setState(() {
      // We need columns and rows
      //Columns:
      _columns = Student.columns(setSortingFields);
    
      //Rows:
      if (_rows.isNotEmpty){
        _rows.clear();
      }
      print("Shown student number: ${shownStudents.length}");
      //For rows we need to create dataCells
      shownStudents.forEach((student) {
        _rows.add(DataRow(
          onSelectChanged: (selected) async {
            if (selected == true) {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => StudentInfoPage(pushID: "${student.group}_${student.number}", student: student)));
              setState(() {
                
              });       
            }
          },
          cells: [
          DataCell(Text(student.group)),  
          DataCell(Text(student.number.toString())), 
          DataCell(Text(student.name)),
          DataCell(Text(student.state == STATEIN ? "İçeride" : "Dışarıda"))],

          color: WidgetStateProperty.resolveWith((states) {
            if (student.state == STATEOUT) {
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

  void applyFilterAndSort(String nameF, String numberF, String groupF, String stateF) {
    //Filter
    shownStudents = students;    
    if (nameF.isNotEmpty){
      shownStudents = shownStudents.where((student) => student.name.toString().toLowerCase().contains(nameF.toLowerCase())).toList();
    }
    if (groupF.isNotEmpty){
      shownStudents = shownStudents.where((student) => student.group.toString().toLowerCase().contains(groupF.toLowerCase())).toList();
    }
    if (numberF.isNotEmpty){
      shownStudents = shownStudents.where((student) => student.number.toString().toLowerCase() == (numberF.toLowerCase())).toList();
    }
    if (stateF.isNotEmpty){
      shownStudents = shownStudents.where((student) => student.state.toString().toLowerCase().contains(stateF.toLowerCase())).toList();
    }

    //Sort
    switch (_sortColumnIndex) {
      case 0:
        if (_sortAscending){
          shownStudents.sort((a,b) => a.group.toLowerCase().compareTo(b.group.toLowerCase()));
        }
        else{
          shownStudents.sort((a,b) => b.group.toLowerCase().compareTo(a.group.toLowerCase()));
        }
        break;
      case 1:
        if (_sortAscending){
          shownStudents.sort((a,b) => a.number.compareTo(b.number));
        }
        else{
          shownStudents.sort((a,b) => b.number.compareTo(a.number));
        }
        break;
      case 2:
        if (_sortAscending){
          shownStudents.sort((a,b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        }
        else{
          shownStudents.sort((a,b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        }
        break;
      case 3:
        if (_sortAscending){
          shownStudents.sort((a,b) => a.state.toLowerCase().compareTo(b.state.toLowerCase()));
        }
        else{
          shownStudents.sort((a,b) => b.state.toLowerCase().compareTo(a.state.toLowerCase()));
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
                            title: "İsme Göre",
                            controller: nameController,
                            onChanged: (value) {
                              setState(() {
                                nameFilter = value;
                              });
                            }
                          ),

                          FilterTextField(
                            title: "Duruma Göre",
                            controller: stateController,
                            onChanged: (value) {
                              setState(() {
                                stateFilter = value;
                              });
                            }
                          ),

                          // ElevatedButton(
                          //   onPressed: () {
                          //     _saveAll();
                          //   },
                          //   child: const Text("Hive'a yaz"),
                          // ),

                          // ElevatedButton(
                          //   onPressed: () {
                          //     _loadAll();
                          //   },
                          //   child: const Text("Hive'dan oku"),
                          // ),

                          // ElevatedButton(
                          //   onPressed: () {
                          //     Hive.box(studentBox).clear();
                          //   },
                          //   child: const Text("Hive'da öğrencileri resetle"),
                          // ),

                          // ElevatedButton(
                          //   onPressed: () {
                          //     Hive.box(entryBox).clear();
                          //   },
                          //   child: const Text("Hive'da girişleri resetle"),
                          // ),

                          // ElevatedButton(
                          //   onPressed: () async{
                          //     final DataSnapshot? snapshot = await _databaseService.readFromDB(path: 'Student');
                          //     final raw = snapshot?.value;
                          //     students.clear;
                          //     setState(() {
                          //       students = parseToStudents(raw);
                          //     });
                          //   },
                          //   child: const Text("Firebase'den oku ve göster."),
                          // ),

                          ElevatedButton(
                            onPressed: () {
                              Hive.box(studentBox).clear();
                              _saveAll();
                            },
                            child: const Text("Student verilerini hive'a işle!"),
                          ),

                          ElevatedButton(
                            onPressed: () {
                              students.forEach((st) {
                                  _databaseService.updateDB(path: "StudentUpdated/${st.group}_${st.number}", data: Student.toFireBase(st));
                                }
                              );
                            },
                            child: const Text("Student verilerini FireBase'e pushla!"),
                          ),

                          ElevatedButton(
                            onPressed: () {
                              final map = _databaseService.readBoxFromHive(b: Hive.box(entryBox));
                              map.forEach((k,v) {
                                  print("Push IDs: $k");
                                  print("Values: $v");
                                  String path = "EntryUpdated/";
                                  path += k;
                                  final map = Map<String, dynamic>.from(v);
                                  _databaseService.updateDB(path: path, data: map);
                                }
                              );
                              // final entries = Entry.fromFireBase(map);
                              // entries.forEach(())
                            },
                            child: const Text("Entry verilerini FireBase'e pushla!"),
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