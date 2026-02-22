import 'dart:io';
import 'dart:typed_data';

/// Create a dart:io File (mobile only)
File createFile(String filePath) => File(filePath);

/// Get file length in bytes (mobile only)
Future<int> getFileLength(dynamic file) async => await (file as File).length();

/// Read file bytes from path (mobile only)
Future<Uint8List> readFileBytes(String filePath) async => await File(filePath).readAsBytes();
