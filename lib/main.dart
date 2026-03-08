import 'package:app1/Pages/home.dart';
import 'package:app1/utils/debugger.dart';
import 'package:flutter/material.dart';
import 'package:app1/utils/database_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/adapters.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_release.dart' as release;

// const env = String.fromEnvironment('ENV');
const bool DEVBUILD = false; 

FirebaseOptions get firebaseOptions {
  if (DEVBUILD) {
    return dev.DefaultFirebaseOptions.currentPlatform;
  } else {
    return release.DefaultFirebaseOptions.currentPlatform;
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.instance.warn("Build Time: ${DateTime.now()}");

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: firebaseOptions);
      AppLogger.instance.log("First init succes!");
    }
  } catch (e, stack) {
    // Firebase.apps erişimi bile iOS Safari'de patlıyor
    // Direkt initializeApp dene
    AppLogger.instance.log("⚠️ First init problem was: $e");
    AppLogger.instance.log("⚠️ First init trace was: $stack");
    try {
      
      await Firebase.initializeApp(options: firebaseOptions);
      AppLogger.instance.log("Second init succes!");
    } catch (e2) {
      AppLogger.instance.log("⚠️ Firebase init: $e2");
    }
  }

  await Hive.initFlutter();
  await Hive.openBox(studentBox);
  await Hive.openBox(entryBox);
  await Hive.openBox(studentStateBox);
  await Hive.openBox(metaBox);

  runApp(const MyApp());
}

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   runApp(const MyApp());
// }


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/debug': (context) => const DebugPage(),
      },
    );
  }
}


// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   runApp(const DebugApp());
// }

// class DebugApp extends StatefulWidget {
//   const DebugApp({super.key});

//   @override
//   State<DebugApp> createState() => _DebugAppState();
// }

// class _DebugAppState extends State<DebugApp> {
//   final List<String> logs = [];

//   @override
//   void initState() {
//     super.initState();
//     _initializeEverything();
//   }

//   Future<void> _initializeEverything() async {
//     void log(String message) {
//       setState(() {
//         logs.add(message);
//       });
//     }

//     log("WidgetsFlutterBinding initialized");

//     log("KisWeb: $kIsWeb, platform: $defaultTargetPlatform");
//     log("Deneme 1");

//     // try {
//     //   log("Checking Firebase...");
//     //   if (Firebase.apps.isEmpty) {
//     //     log("Initializing Firebase...");
//     //     await Firebase.initializeApp(
//     //       options: firebaseOptions,
//     //     );
//     //     log("Firebase initialized ✅");
//     //   } else {
//     //     log("Firebase already initialized");
//     //   }
//     // } catch (e, stack) {
//     //   log("Firebase init error: $e");
//     //   log(stack.toString());
//     // }

//     log("Deneme 2");

//     try {
//       log("Init başlıyor...");

//       final options = release.DefaultFirebaseOptions.currentPlatform;
//       log("Options alındı: ${options.appId}");

//       // 10 saniye timeout ekliyoruz
//       await Firebase.initializeApp(options: options)
//           .timeout(
//             const Duration(seconds: 10),
//             onTimeout: () {
//               log("⏰ Firebase init timeout!");
//               // Alternatif fallback
//               return Firebase.app(); // veya null döndür
//             },
//           );

//       log("Init bitti!");
//     } catch (e) {
//       log("Hata: $e");
//     }
      
    

//     try {
//       log("Initializing Hive...");
//       await Hive.initFlutter();
//       await Hive.openBox(studentBox);
//       await Hive.openBox(entryBox);
//       await Hive.openBox(studentStateBox);
//       await Hive.openBox(metaBox);
//       log("Hive initialized ✅");
//     } catch (e, stack) {
//       log("Hive init error: $e");
//       log(stack.toString());
//     }

//     log("Initialization complete!");
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         appBar: AppBar(title: const Text("Debug Test")),
//         body: Container(
//           padding: const EdgeInsets.all(16),
//           color: Colors.white,
//           child: ListView.builder(
//             itemCount: logs.length,
//             itemBuilder: (context, index) {
//               return SelectableText(
//                 logs[index],
//                 style: const TextStyle(fontSize: 14, color: Colors.black),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }