import 'package:flutter/widgets.dart';

/// Web stub: uses Image.network since dart:io is not available on web.
Widget buildLocalFileImage(String path, {BoxFit fit = BoxFit.cover}) {
  return Image.network(path, fit: fit);
}
