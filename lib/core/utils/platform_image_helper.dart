/// Platform-aware image widget that displays a local file image on native
/// platforms and a network image on web, without importing dart:io directly.
///
/// This avoids the dart:io compile-time error when building for web.
export 'platform_image_helper_stub.dart'
    if (dart.library.io) 'platform_image_helper_io.dart';
