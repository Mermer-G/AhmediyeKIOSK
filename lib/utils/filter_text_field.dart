import 'package:flutter/material.dart';
import '../Pages/list.dart';

class FilterExample extends StatefulWidget {
  const FilterExample({super.key});

  @override
  State<FilterExample> createState() => _FilterExampleState();
}

class _FilterExampleState extends State<FilterExample> {
  final nameController = TextEditingController();
  final cityController = TextEditingController();

  String nameFilter = "";
  String cityFilter = "";
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilterTextField(
          title: "İsim",
          controller: nameController,
          onChanged: (value) {
            setState(() => nameFilter = value);
          },
        ),
        const SizedBox(height: 12),
        FilterTextField(
          title: "Şehir",
          controller: cityController,
          onChanged: (value) {
            setState(() => cityFilter = value);
          },
        ),
      ],
    );
  }
}