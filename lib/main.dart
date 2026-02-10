import 'package:ahmediye_kiosk/Pages/home.dart';
import 'package:ahmediye_kiosk/utils/database_service.dart';
import 'package:ahmediye_kiosk/utils/synchronizer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/adapters.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  if (!Hive.isBoxOpen(studentBox)) {
    await Hive.openBox(studentBox);
  }

  if (!Hive.isBoxOpen(entryBox)) {
    await Hive.openBox(entryBox);
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  Synchronizer().start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage()
    );
  }
}