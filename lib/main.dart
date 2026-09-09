import 'package:app1/Pages/new_home.dart';
import 'package:app1/Theme/dashboard_theme.dart';
import 'package:app1/utils/debugger.dart';
import 'package:flutter/material.dart';
import 'package:app1/utils/database_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/adapters.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_release.dart' as prod;

const bool DEVBUILD = true; 

FirebaseOptions get firebaseOptions {
  return DEVBUILD
      ? dev.DefaultFirebaseOptions.currentPlatform
      : prod.DefaultFirebaseOptions.currentPlatform;
}

String get fireBaseAppName => DEVBUILD ? 'dev' : 'prod';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.instance.warn("Build Time: ${DateTime.now()}");
  
  

  AppLogger.navigatorKey = appNavigatorKey;

  await initFirebaseSafe();

  await Hive.initFlutter();
  await Hive.openBox(memberBox);
  await Hive.openBox(entryBox);
  await Hive.openBox(memberStateBox);
  await Hive.openBox(metaBox);
  await Hive.openBox(queueBox);
  await Hive.openBox(reasonBox);
  await Hive.openBox(permissionBox);
  await Hive.openBox(userBox);

  AppLogger.instance.warn("Forced DB URL: ${Firebase.app(fireBaseAppName).options.databaseURL}");
  // AppLogger.instance.warn("Normal DB URL: ${Firebase.app().options.databaseURL}");
  AppLogger.instance.warn("DB App name: $fireBaseAppName");
  runApp(const MyApp());
}

Future<void> initFirebaseSafe() async {
  final String name = fireBaseAppName;

  try {
    // 1. deneme
    try {
      await Firebase.initializeApp(
        name: name,
        options: firebaseOptions,
      );

      await Firebase.initializeApp(
        options: firebaseOptions, // DEFAULT app
      );

      AppLogger.instance.log("First init success: $name");
    } catch (e) {
      AppLogger.instance.log("First init failed: $e");

      // Eğer zaten varsa, al
      try {
        Firebase.app(name);
        AppLogger.instance.log("ℹApp already exists, using existing: $name");
      } catch (_) {
        rethrow;
      }
    }
  } catch (e, stack) {
    AppLogger.instance.log("Outer init problem: $e");
    AppLogger.instance.log("Stack: $stack");

    // 2. deneme (force retry)
    try {
      await Future.delayed(const Duration(milliseconds: 200));

      await Firebase.initializeApp(
        name: name,
        options: firebaseOptions,
      );

      await Firebase.initializeApp(
        options: firebaseOptions, // DEFAULT app
      );

      AppLogger.instance.log("Second init success: $name");
    } catch (e2) {
      AppLogger.instance.log("Firebase init totally failed: $e2");
    }
  }
}

final routeObserver = AppRouteObserver();

class AppRouteObserver extends NavigatorObserver {
  String? currentRoute;

  @override
  void didPush(Route route, Route? previousRoute) {
    currentRoute = route.settings.name;
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    currentRoute = previousRoute?.settings.name;
    super.didPop(route, previousRoute);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: NoStretchScrollBehavior(),
      navigatorKey: appNavigatorKey,
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const NewHomePage(),
        '/debug': (context) => const DebugPage(),
      },
    );
  }
}
