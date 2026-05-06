import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-a09dHvbg6CcddPszXGWwbAfxBJw0CxA',
    appId: '1:60867558562:android:0e58603b86e6e9319e6bfb',
    messagingSenderId: '60867558562',
    projectId: 'ff-pro-arena-pk',
    storageBucket: 'ff-pro-arena-pk.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB-a09dHvbg6CcddPszXGWwbAfxBJw0CxA',
    appId: '1:60867558562:ios:0e58603b86e6e9319e6bfb',
    messagingSenderId: '60867558562',
    projectId: 'ff-pro-arena-pk',
    storageBucket: 'ff-pro-arena-pk.firebasestorage.app',
    iosBundleId: 'com.ffproarenapk.pk',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB-a09dHvbg6CcddPszXGWwbAfxBJw0CxA',
    appId: '1:60867558562:web:0e58603b86e6e9319e6bfb',
    messagingSenderId: '60867558562',
    projectId: 'ff-pro-arena-pk',
    storageBucket: 'ff-pro-arena-pk.firebasestorage.app',
  );
}
