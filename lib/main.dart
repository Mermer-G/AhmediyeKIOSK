import 'package:app1/Pages/home.dart';
import 'package:flutter/material.dart';
import 'package:app1/utils/database_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/adapters.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox(studentBox);
  await Hive.openBox(entryBox);
  await Hive.openBox(studentStateBox);
  await Hive.openBox(metaBox);

  runApp(const MyApp());
}

// void main() {
//   runApp(
//     const Directionality(
//       textDirection: TextDirection.ltr,
//       child: Center(
//         child: Text(
//           'FLUTTER IOS TEST',
//           style: TextStyle(fontSize: 24),
//         ),
//       ),
//     ),
//   );
// }

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