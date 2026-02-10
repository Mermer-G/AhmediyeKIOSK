import 'package:ahmediye_kiosk/Pages/studentInfo.dart';
import 'package:ahmediye_kiosk/utils/database_models.dart';
import 'package:ahmediye_kiosk/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/database_service.dart';

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
  int _sortColumnIndex = 1;
  bool _sortAscending = true;

  late List<DataColumn> _columns;
  late List<DataRow> _rows = [];

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

  Future<void> _fetchDataFromHive() async {
    try {
      final rawMap = Hive.box(studentBox).toMap();

      rawMap.forEach((k, v) {
        Map<String, dynamic> valuesMap = Map<String, dynamic>.from(v as Map);
        students.add(Student.fromFireBase(valuesMap));
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
    applyFilterAndSort(nameFilter, numberFilter, groupFilter, stateFilter);
    setState(() {
      _columns = Student.columns(setSortingFields);

      if (_rows.isNotEmpty) {
        _rows.clear();
      }
      shownStudents.forEach((student) {
        _rows.add(DataRow(
          onSelectChanged: (selected) async {
            if (selected == true) {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => StudentInfoPage(pushID: "${student.group}_${student.number}", student: student)));
              setState(() {});
            }
          },
          cells: [
            DataCell(Text(student.group)),
            DataCell(Text(student.number.toString())),
            DataCell(Text(student.name)),
            DataCell(Text(student.state == STATEIN ? "Iceride" : "Disarida")),
          ],
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
    shownStudents = students;
    if (nameF.isNotEmpty) {
      shownStudents = shownStudents.where((student) => student.name.toString().toLowerCase().contains(nameF.toLowerCase())).toList();
    }
    if (groupF.isNotEmpty) {
      shownStudents = shownStudents.where((student) => student.group.toString().toLowerCase().contains(groupF.toLowerCase())).toList();
    }
    if (numberF.isNotEmpty) {
      shownStudents = shownStudents.where((student) => student.number.toString().toLowerCase() == (numberF.toLowerCase())).toList();
    }
    if (stateF.isNotEmpty) {
      shownStudents = shownStudents.where((student) => student.state.toString().toLowerCase().contains(stateF.toLowerCase())).toList();
    }

    switch (_sortColumnIndex) {
      case 0:
        shownStudents.sort((a, b) => _sortAscending
            ? a.group.toLowerCase().compareTo(b.group.toLowerCase())
            : b.group.toLowerCase().compareTo(a.group.toLowerCase()));
        break;
      case 1:
        shownStudents.sort((a, b) => _sortAscending
            ? a.number.compareTo(b.number)
            : b.number.compareTo(a.number));
        break;
      case 2:
        shownStudents.sort((a, b) => _sortAscending
            ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
            : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 3:
        shownStudents.sort((a, b) => _sortAscending
            ? a.state.toLowerCase().compareTo(b.state.toLowerCase())
            : b.state.toLowerCase().compareTo(a.state.toLowerCase()));
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
          title: "Isme Gore",
          controller: nameController,
          onChanged: (value) => setState(() => nameFilter = value),
        ),
        FilterTextField(
          title: "Duruma Gore",
          controller: stateController,
          onChanged: (value) => setState(() => stateFilter = value),
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
      appBar: AppBar(title: const Text('Talebe Listesi')),
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
