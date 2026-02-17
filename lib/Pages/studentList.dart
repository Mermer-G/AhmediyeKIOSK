import 'package:app1/Pages/studentInfo.dart';
import 'package:app1/utils/database_models.dart';
import 'package:flutter/material.dart';
import 'package:app1/Pages/home.dart';

class StudentListerPage extends StatefulWidget {
  final List<Student> students;
  final int sortColumnIndex;
  final bool sortAscending;
  final String groupFilter;


  const StudentListerPage({
    super.key,
    required this.students,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.groupFilter
  });

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
    _sortColumnIndex = widget.sortColumnIndex;
    _sortAscending = widget.sortAscending;
    groupFilter = widget.groupFilter;
    groupController.text = widget.groupFilter;
    _isLoading = false;
    students = widget.students;
    
  }

  

  
  void convertValuesToListItems() {
    applyFilterAndSort(nameFilter, numberFilter, groupFilter, stateFilter);
    
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
      final state = student.state ?? "Belirlenmemiş";
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
        DataCell(
          SizedBox(
            width: 150, // sabit genişlik ver
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(student.name),
            ),
          )
        ),
        DataCell(
          Text(state.toLowerCase() == STATEIN.toLowerCase()
              ? "İçeride"
              : "Dışarıda")
        )
        ],

        color: WidgetStateProperty.resolveWith((states) {
          if (state.toLowerCase() == STATEOUT.toLowerCase()) {
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
          shownStudents.sort((a,b) => a.state!.toLowerCase().compareTo(b.state!.toLowerCase()));
        }
        else{
          shownStudents.sort((a,b) => b.state!.toLowerCase().compareTo(a.state!.toLowerCase()));
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

    return LayoutBuilder(
      builder: (context, constraints) {
        
        final bool isWide = constraints.maxWidth > 700;
        
        return Scaffold(
          appBar: AppBar(title: const Text('Talebe Listesi')),
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
                          flex: 4, 
                          child: Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  child: drawtable()
                                ),
                              ),
                            ],
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
          title: "Isme Gore",
          controller: nameController,
          onChanged: (value) => setState(() => nameFilter = value),
        ),
        FilterTextField(
          title: "Duruma Gore",
          controller: stateController,
          onChanged: (value) => setState(() => stateFilter = value),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            groupController.clear();
            numberController.clear();
            nameController.clear();
            stateController.clear();
            setState(() {
              groupFilter = "";
              numberFilter = "";
              nameFilter = "";
              stateFilter = "";
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
            color: const Color.fromARGB(255, 231, 231, 231),
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
  
}