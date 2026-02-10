import 'package:flutter/material.dart';

const STATEIN = "Inside";
const STATEOUT = "Outside";

// DB field constants
const String nameDB   = "Name";
const String numberDB = "Number";
const String groupDB  = "Group";
const String stateDB  = "State";
const String dormDB = "Dorm";
const String phoneDB  = "Phone";
const String supervisorDB  = "Supervisor";
const String entryIDDB  = "EntryID";
const String exitTimeDB = "ExitTime";
const String entryTimeDB = "EntryTime";
const String permissionDB = "Permission";
const String reasonDB = "Reason";

class Student {
  String name;
  int number;
  String group;
  String state;
  String supervisor;
  String? dorm;
  String? phone;
  String? entryID;

  


  
  Student({
  ///This only used to create a student think it as "new" in C#
  ///This returns a student with given values
  ///This one is a normal constructor 
    required this.name, 
    required this.number, 
    required this.group, 
    required this.state,
    required this.dorm,
    required this.phone,
    required this.entryID,
    required this.supervisor
  });
  ///This one is a factory constructor.
  ///factory gives it the ability to return any student
  ///
  factory Student.fromFireBase(Map<String, dynamic> studentValues){
    return Student(
      name: studentValues[nameDB], 
      number: int.tryParse(studentValues[numberDB]?.toString() ?? '') ?? 0, 
      group: studentValues[groupDB], 
      phone: studentValues[phoneDB],
      state: studentValues[stateDB] ?? STATEIN,
      dorm: studentValues[dormDB],
      entryID: studentValues[entryIDDB],
      supervisor: studentValues[supervisorDB] 
    );
  }

  static Map<String, dynamic> toFireBase(Student st){
    return {
      nameDB: st.name,
      numberDB: st.number,
      groupDB: st.group,
      stateDB: st.state,
      phoneDB: st.phone,
      entryIDDB: st.entryID,
      dormDB: st.dorm,
      supervisorDB: st.supervisor
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
  String entryID;
  String exitTime;
  String group;
  int number;
  String? entryTime;
  String? permission;
  String? reason;

  Entry ({
    required this.entryID,
    required this.group,
    required this.number,
    required this.exitTime,
    required this.entryTime,
    required this.permission,
    required this.reason
  });

  factory Entry.fromFireBase(Map<String, dynamic> entryValues){
    return Entry(
      entryID: entryValues[entryIDDB],
      number: int.tryParse(entryValues[numberDB]?.toString() ?? '') ?? 0, 
      group: entryValues[groupDB], 
      exitTime: entryValues[exitTimeDB], 
      entryTime: entryValues[entryTimeDB], 
      permission: entryValues[permissionDB], 
      reason: entryValues[reasonDB], 
    );
  }

  static Map<String, dynamic> toFireBase(Entry et){
    return {
      entryIDDB: et.entryID,
      exitTimeDB: et.exitTime,
      numberDB: et.number,
      groupDB: et.group,
      entryTimeDB: et.entryTime,
      permissionDB: et.permission,
      reasonDB: et.reason
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

///Has no use for now. If there is any it will be refactored
List<T> parseToDataType<T>(//This method is only used for parsing values of a whole list
  Map<String, dynamic> rawReadValue,
  T Function(Map<String, dynamic> map) creator,
) {
  final List<T> result = [];

  rawReadValue.forEach((key, value) {
    result.add(
      creator(Map<String, dynamic>.from(value)),
    );
  });

  return result;
}