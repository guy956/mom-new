import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

// Conditional import for dart:io (only available on mobile)
import 'storage_service_io.dart' if (dart.library.js_interop) 'storage_service_web.dart' as platform;

/// Service for uploading and managing files in Firebase Storage
/// Supports both mobile (File-based) and web (bytes-based) uploads
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const _allowedImageExtensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'};
  static const _mimeTypes = {
    '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png',
    '.gif': 'image/gif', '.webp': 'image/webp', '.heic': 'image/heic',
  };
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  /// Upload an image file to Firebase Storage
  /// On web, pass [fileBytes] instead of relying on file path
  /// Returns the download URL of the uploaded file
  Future<String> uploadImage({
    required String filePath,
    required String folder,
    String? customFileName,
    Uint8List? fileBytes,
  }) async {
    try {
      final String fileName = customFileName ?? path.basename(filePath);
      final String ext = path.extension(fileName).toLowerCase();

      // Validate file extension
      if (!_allowedImageExtensions.contains(ext)) {
        throw Exception('File type $ext is not allowed. Allowed: ${_allowedImageExtensions.join(', ')}');
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fullPath = '$folder/${timestamp}_$fileName';
      final String contentType = _mimeTypes[ext] ?? 'image/jpeg';
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final Reference ref = _storage.ref().child(fullPath);
      TaskSnapshot snapshot;

      if (kIsWeb) {
        // Web: use putData with bytes
        final bytes = fileBytes ?? await platform.readFileBytes(filePath);
        if (bytes.length > _maxFileSizeBytes) {
          throw Exception('File too large (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB). Maximum: ${_maxFileSizeBytes ~/ 1024 ~/ 1024} MB');
        }
        snapshot = await ref.putData(bytes, metadata);
      } else {
        // Mobile: use putFile with dart:io File
        final file = platform.createFile(filePath);
        final fileSize = await platform.getFileLength(file);
        if (fileSize > _maxFileSizeBytes) {
          throw Exception('File too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB). Maximum: ${_maxFileSizeBytes ~/ 1024 ~/ 1024} MB');
        }
        snapshot = await ref.putFile(file, metadata);
      }

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('[StorageService] Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('[StorageService] Error uploading image: $e');
      rethrow;
    }
  }

  /// Upload multiple images at once
  /// Returns a list of download URLs
  Future<List<String>> uploadMultipleImages({
    required List<String> filePaths,
    required String folder,
    List<Uint8List>? fileBytesList,
  }) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < filePaths.length; i++) {
      try {
        final url = await uploadImage(
          filePath: filePaths[i],
          folder: folder,
          fileBytes: fileBytesList != null && i < fileBytesList.length ? fileBytesList[i] : null,
        );
        downloadUrls.add(url);
      } catch (e) {
        debugPrint('[StorageService] Failed to upload image ${filePaths[i]}: $e');
        // Continue uploading other images even if one fails
      }
    }

    return downloadUrls;
  }

  /// Delete a file from Firebase Storage by its download URL
  Future<void> deleteFileByUrl(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      debugPrint('[StorageService] File deleted successfully: $downloadUrl');
    } catch (e) {
      debugPrint('[StorageService] Error deleting file: $e');
      rethrow;
    }
  }

  /// Delete multiple files at once
  Future<void> deleteMultipleFiles(List<String> downloadUrls) async {
    for (final url in downloadUrls) {
      try {
        await deleteFileByUrl(url);
      } catch (e) {
        debugPrint('[StorageService] Failed to delete file $url: $e');
        // Continue deleting other files even if one fails
      }
    }
  }

  /// Upload a document file (PDF, DOC, etc.)
  Future<String> uploadDocument({
    required String filePath,
    required String folder,
    String? customFileName,
    Uint8List? fileBytes,
  }) async {
    try {
      final String fileName = customFileName ?? path.basename(filePath);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fullPath = '$folder/${timestamp}_$fileName';

      // Determine content type based on file extension
      final String extension = path.extension(filePath).toLowerCase();
      String contentType = 'application/octet-stream';
      if (extension == '.pdf') {
        contentType = 'application/pdf';
      } else if (extension == '.doc' || extension == '.docx') {
        contentType = 'application/msword';
      }

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final Reference ref = _storage.ref().child(fullPath);
      TaskSnapshot snapshot;

      if (kIsWeb) {
        final bytes = fileBytes ?? await platform.readFileBytes(filePath);
        snapshot = await ref.putData(bytes, metadata);
      } else {
        final file = platform.createFile(filePath);
        snapshot = await ref.putFile(file, metadata);
      }

      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('[StorageService] Document uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('[StorageService] Error uploading document: $e');
      rethrow;
    }
  }

  /// Get metadata for a file
  Future<FullMetadata?> getFileMetadata(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      debugPrint('[StorageService] Error getting file metadata: $e');
      return null;
    }
  }

  /// List all files in a folder
  Future<List<String>> listFilesInFolder(String folderPath) async {
    try {
      final Reference ref = _storage.ref().child(folderPath);
      final ListResult result = await ref.listAll();

      final List<String> downloadUrls = [];
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        downloadUrls.add(url);
      }

      return downloadUrls;
    } catch (e) {
      debugPrint('[StorageService] Error listing files: $e');
      return [];
    }
  }
}
