import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Stub for dart:io File on web - never used directly
dynamic createFile(String filePath) =>
    throw UnsupportedError('File operations not supported on web');

/// Stub for file length on web - never used directly
Future<int> getFileLength(dynamic file) =>
    throw UnsupportedError('File operations not supported on web');

/// Read file bytes from URL/path on web
/// On web, image picker returns blob URLs that can be fetched
Future<Uint8List> readFileBytes(String filePath) async {
  final response = await http.get(Uri.parse(filePath));
  if (response.statusCode != 200) {
    throw Exception('Failed to read file: HTTP ${response.statusCode}');
  }
  return response.bodyBytes;
}
