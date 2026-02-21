import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration options for each platform.
/// Values extracted from:
///   - Web: Firebase Console web app config
///   - Android: google-services.json
///   - iOS: GoogleService-Info.plist (downloaded from Firebase Console)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web configuration - from Firebase Console
  // IMPORTANT: authDomain must match Firebase Console > Authentication > Settings > Authorized domains
  // Also add momit.pages.dev to authorized domains in Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCjI-LFvVTF2WPHRMiVVS4ClbnSixG1bR4',
    appId: '1:459220254220:web:1b2ae6f7c99fff14fff829',
    messagingSenderId: '459220254220',
    projectId: 'momit-1',
    authDomain: 'momit-1.firebaseapp.com',
    storageBucket: 'momit-1.firebasestorage.app',
    // measurementId omitted - not needed for core Firebase functionality
  );

  /// Web OAuth Client ID for Google Sign-In on Web
  /// HOW TO GET THIS:
  /// 1. Go to Google Cloud Console > project "momit-1"
  /// 2. APIs & Credentials > OAuth 2.0 Client IDs
  /// 3. Create new credentials > OAuth client ID > Type: "Web application"
  /// 4. Authorized JavaScript origins:
  ///    - https://momit.pages.dev
  ///    - https://momit-1.firebaseapp.com
  ///    - http://localhost
  /// 5. Authorized redirect URIs:
  ///    - https://momit-1.firebaseapp.com/__/auth/handler
  /// 6. Copy the Client ID and paste it below
  /// 7. Also add momit.pages.dev to Firebase Console > Authentication > Settings > Authorized domains
  static const String webGoogleClientId = '';

  // Android configuration - from google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCjI-LFvVTF2WPHRMiVVS4ClbnSixG1bR4',
    appId: '1:459220254220:android:1b2ae6f7c99fff14fff829',
    messagingSenderId: '459220254220',
    projectId: 'momit-1',
    storageBucket: 'momit-1.firebasestorage.app',
  );

  // iOS configuration - from GoogleService-Info.plist (REAL values)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAWumTmBmRzyqw1mBg3q63kzrsaED1S1ds',
    appId: '1:459220254220:ios:70f057902858a848fff829',
    messagingSenderId: '459220254220',
    projectId: 'momit-1',
    storageBucket: 'momit-1.firebasestorage.app',
    iosClientId: '459220254220-gaaf7nh618bgjc2tbd0ds6r0urgru8ea.apps.googleusercontent.com',
    iosBundleId: 'com.momconnect.social',
  );
}
