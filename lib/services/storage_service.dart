import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// Service for uploading and managing files in Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an image file to Firebase Storage
  /// Returns the download URL of the uploaded file
  Future<String> uploadImage({
    required String filePath,
    required String folder,
    String? customFileName,
  }) async {
    try {
      // Create file reference
      final File file = File(filePath);
      final String fileName = customFileName ?? path.basename(filePath);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fullPath = '$folder/${timestamp}_$fileName';

      // Upload file
      final Reference ref = _storage.ref().child(fullPath);
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

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
  }) async {
    final List<String> downloadUrls = [];

    for (final filePath in filePaths) {
      try {
        final url = await uploadImage(
          filePath: filePath,
          folder: folder,
        );
        downloadUrls.add(url);
      } catch (e) {
        debugPrint('[StorageService] Failed to upload image $filePath: $e');
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
  }) async {
    try {
      final File file = File(filePath);
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

      final Reference ref = _storage.ref().child(fullPath);
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
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
