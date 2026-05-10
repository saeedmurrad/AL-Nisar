// Android options match `com.alnisar.alnisarapp` in android/app/google-services.json.
// For iOS, add GoogleService-Info.plist and run: dart run flutterfire_cli:flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with Firebase Core.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS — '
          'add GoogleService-Info.plist and run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only supported on Android for this project.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNnzny6SUIZXDGgSNXbe1h-R-oJaxL-9s',
    appId: '1:4782847785:android:ac6ec21729169ce343a938',
    messagingSenderId: '4782847785',
    projectId: 'al-nisar-app',
    storageBucket: 'al-nisar-app.firebasestorage.app',
  );
}
