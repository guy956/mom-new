import 'dart:io';
import 'package:flutter/widgets.dart';

/// Native (iOS/Android/desktop): uses Image.file with dart:io File.
Widget buildLocalFileImage(String path, {BoxFit fit = BoxFit.cover}) {
  return Image.file(File(path), fit: fit);
}
