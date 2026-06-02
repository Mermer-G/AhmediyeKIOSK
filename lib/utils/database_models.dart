import 'package:app1/Pages/settings.dart';
import 'package:app1/utils/debugger.dart';
import 'package:flutter/material.dart';

// 🔑 DB field constants
const String nameDB   = "Name";
const String numberDB = "Number";
const String groupDB  = "Group";
const String stateDB  = "State";
const String dormDB = "Dorm";
const String phoneDB  = "Phone";
const String supervisorDB  = "Supervisor";
const String operatorDB  = "Operator";
const String entryIDDB  = "EntryID";
const String exitTimeDB = "ExitTime";
const String entryTimeDB = "EntryTime";
const String permissionDB = "Permission";
const String reasonDB = "Reason";
const String otherReasonDB = "OtherReason";

class Student {
  String name;
  int number;
  String group;
  String supervisor;
  String? state;
  String? dorm;
  String? phone;
  int? entryID;
  


  
  Student({
  ///This only used to create a student think it as "new" in C#
  ///This returns a student with given values
  ///This one is a normal constructor 
    required this.name, 
    required this.number, 
    required this.group, 
    required this.dorm,
    required this.phone,
    required this.supervisor,
    required this.entryID
  });
  ///This one is a factory constructor.
  ///factory gives it the ability to return any student
  ///
  factory Student.fromMap(Map<String, dynamic> studentValues){
    return Student(
      name: studentValues[nameDB], 
      number: parseInt(studentValues[numberDB]) ?? -1, 
      group: studentValues[groupDB], 
      phone: studentValues[phoneDB],
      dorm: studentValues[dormDB],
      supervisor: studentValues[supervisorDB],
      entryID: parseInt(studentValues[entryIDDB])
    );
  }

  static Map<String, dynamic> toMap(Student st){
    return {
      nameDB: st.name,
      numberDB: parseInt(st.number),
      groupDB: st.group,
      phoneDB: st.phone,
      dormDB: st.dorm,
      supervisorDB: st.supervisor,
    };
  }

  static List<DataColumn> columns(void Function(int sortColumnIndex, bool sortAscending) onSort) {
    return [
      DataColumn(
        onSort: onSort,
        label: Text("Grup")
      ),
      DataColumn(
        onSort: onSort,
        label: Text("Numara")
      ),
      DataColumn(
        onSort: onSort,
        label: Text("Ad Soyad")
      ),
      DataColumn(
        onSort: onSort,
        label: Text("Durumu")
      )
    ];
  }
}

class Entry {
  int entryID;
  String exitTime;
  String group;
  int number;
  String name;
  String operator;
  String? entryTime;
  String? permission;
  String? reason;
  String? otherReason;

  Entry ({
    required this.entryID,
    required this.group,
    required this.number,
    required this.name,
    required this.operator,
    required this.exitTime,
    this.entryTime,
    this.permission,
    this.reason,
    this.otherReason
  });

  // factory Entry.fromMap(Map<String, dynamic> entryValues){
  //   return Entry(
  //     entryID: entryValues[entryIDDB],
  //     group: entryValues[groupDB], 
  //     number: parseInt(entryValues[numberDB]) ?? -1, 
  //     name: entryValues[nameDB] ?? "Yazılmamış", //New
  //     operator: entryValues[operatorDB] ?? "Yazılmamış", //New
  //     exitTime: entryValues[exitTimeDB], 
  //     entryTime: entryValues[entryTimeDB] ?? "Daha giriş yapılmamış", 
  //     permission: entryValues[permissionDB], 
  //     reason: entryValues[reasonDB], 
  //     otherReason: entryValues[otherReasonDB] ?? "Yok", //New
  //   );
  // }

  factory Entry.fromMap(Map<dynamic, dynamic> rawMap) {
    final entryValues = Map<String, dynamic>.from(rawMap); // ❗ zorunlu cast

    return Entry(
      entryID: entryValues[entryIDDB] is int ? entryValues[entryIDDB] : int.tryParse(entryValues[entryIDDB].toString()) ?? -1,
      group: entryValues[groupDB]?.toString() ?? "Bilinmiyor",
      number: entryValues[numberDB] is int ? entryValues[numberDB] : int.tryParse(entryValues[numberDB].toString()) ?? -1,
      name: entryValues[nameDB]?.toString() ?? "Yazılmamış",
      operator: entryValues[operatorDB]?.toString() ?? "Yazılmamış",
      exitTime: entryValues[exitTimeDB]?.toString() ?? "Bilinmiyor",
      entryTime: entryValues[entryTimeDB]?.toString() ?? "Daha giriş yapılmamış",
      permission: entryValues[permissionDB]?.toString() ?? "Bilinmiyor",
      reason: entryValues[reasonDB]?.toString() ?? "Bilinmiyor",
      otherReason: entryValues[otherReasonDB]?.toString().isEmpty == true ? "Yok" : entryValues[otherReasonDB]?.toString() ?? "Yok",
    );
  }

  static Map<String, dynamic> toMap(Entry et){
    return {
      entryIDDB: et.entryID,
      exitTimeDB: et.exitTime,
      numberDB: parseInt(et.number),
      groupDB: et.group,
      nameDB: et.name,
      operatorDB: et.operator,
      entryTimeDB: et.entryTime,
      permissionDB: et.permission,
      reasonDB: et.reason,
      otherReasonDB: et.otherReason,
    };
  }

  static List<DataColumn> columns(void Function(int sortColumnIndex, bool sortAscending) onSort) {
    return [
      DataColumn(
        onSort: onSort,
        label: Text("Grup")
      ),
      DataColumn(
        onSort: onSort,
        label: Text("Numara")
      ),
      DataColumn(
        onSort: onSort,
        label: Text("Çıkış Vakti")
      )
    ];
  }

}

enum StudentStateEnum {
  inside,
  outside,
}

class StudentState {
  String group;
  int number;
  StudentStateEnum state;
  int? lastEntryID;

  StudentState({
    required this.group,
    required this.number,
    required this.state,
    required this.lastEntryID
  });

  factory StudentState.fromMap(Map<String, dynamic> stateValues){
    return StudentState(
      group: stateValues[groupDB], 
      number: parseInt(stateValues[numberDB]) ?? -1,
      state: () {
        try {
          return StudentStateEnum.values.byName(
            stateValues[stateDB].toString(),
          );
        } catch (_) {
          return StudentStateEnum.inside;
        }
      }(),
      lastEntryID: stateValues[entryIDDB]
    );
  }

  static Map<String, dynamic> toMap(StudentState state){
    return {
      groupDB: state.group,
      numberDB: parseInt(state.number),
      stateDB: state.state.name,
      entryIDDB: state.lastEntryID
    };
  }
}

///Has no use for now. If there is any it will be refactored
List<T> parseToDataType<T>(//This method is only used for parsing values of a whole list
  Map<String, dynamic> rawReadValue,
  T Function(Map<String, dynamic> map) creator,
) {
  final List<T> result = [];

  rawReadValue.forEach((key, value) {
    AppLogger.instance.log("Types while parsing: Key:($key)${key.runtimeType}, Value:($value)${value.runtimeType}");
    result.add(
      creator(                            
        Map<String, dynamic>.from(value) // 👉 {Name: Ali}
      ),
    );
  });

  return result;
}