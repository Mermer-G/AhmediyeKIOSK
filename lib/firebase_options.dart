import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBpYmgNNBszyvN8j8s7wuMcF88jxb2cqRE',
    appId: '1:566523224278:android:df2b688d40ca26ffef2977',
    messagingSenderId: '566523224278',
    projectId: 'ahmediye-kiosk',
    databaseURL: 'https://ahmediye-kiosk-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'ahmediye-kiosk.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCkcVWCCax8HA93VaHK_AYT4KD9cGQYZLA',
    appId: '1:566523224278:ios:4d46a7096f82d927ef2977',
    messagingSenderId: '566523224278',
    projectId: 'ahmediye-kiosk',
    databaseURL: 'https://ahmediye-kiosk-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'ahmediye-kiosk.firebasestorage.app',
    iosBundleId: 'com.example.app1',
  );

}