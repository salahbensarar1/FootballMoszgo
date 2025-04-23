import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

class FirebaseConfig {
  static Future<FirebaseApp> initializeFirebase() async {
    if (Firebase.apps.isEmpty) {
      final firebaseOptions = FirebaseOptions(
        apiKey: 'AIzaSyBPwPSHkw1rupR_PCwaaKeFknpSqoBeUfM',
        appId: Platform.isIOS
            ? '1:388672883836:ios:5d90d92b8467e1407e0df9'
            : '1:388672883836:android:924ffce1dc97af7d7e0df9',
        messagingSenderId: '388672883836',
        projectId: 'foottraining-4051b',
        storageBucket: 'foottraining-4051b.appspot.com',
      );

      // ✅ Conditionally use the name only on iOS
      if (Platform.isIOS) {
        return await Firebase.initializeApp(
          name: 'foottraining-4051b',
          options: firebaseOptions,
        );
      } else {
        return await Firebase.initializeApp(
          options: firebaseOptions,
        );
      }
    } else {
      print("✅ Firebase already initialized, using existing app.");
      return Platform.isIOS
          ? Firebase.app('foottraining-4051b')
          : Firebase.app();
    }
  }
}
//return await Firebase.initializeApp(
// options: yourOptionsHere
//);
