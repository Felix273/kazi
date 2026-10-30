import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Android is already configured by android/app/google-services.json.
/// Run `flutterfire configure` to add generated options for web, iOS,
/// macOS, Windows, and Linux before enabling those targets.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Run flutterfire configure to enable Firebase web.',
      );
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      _ => throw UnsupportedError(
        'Run flutterfire configure for this platform before starting Kazi.',
      ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDXsMuTMQptZav2U46QKVJhuTn4xsGh46M',
    appId: '1:640570782099:android:10f33b9a09ac862ce43866',
    messagingSenderId: '640570782099',
    projectId: 'kazi-e81ea',
    storageBucket: 'kazi-e81ea.firebasestorage.app',
  );
}
