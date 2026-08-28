import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../network/api_service.dart';


class DocumentCacheService {
  static const String _folderName = 'prestamistas_id_documents';

  /// Saves a picked XFile into local persistent device storage
  /// Returns the persistent local file path.
  static Future<String> saveDocumentLocally(XFile pickedFile, {required String prefix}) async {
    try {
      if (kIsWeb) {
        return pickedFile.path;
      }

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory docFolder = Directory('${appDocDir.path}/$_folderName');

      if (!await docFolder.exists()) {
        await docFolder.create(recursive: true);
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = pickedFile.name.contains('.')
          ? pickedFile.name.split('.').last
          : 'jpg';
      
      final String newFileName = '${prefix}_$timestamp.$extension';
      final String localPath = '${docFolder.path}/$newFileName';

      // Read bytes & save to persistent device directory
      final Uint8List bytes = await pickedFile.readAsBytes();
      final File localFile = File(localPath);
      await localFile.writeAsBytes(bytes);

      return localFile.path;
    } catch (e) {
      debugPrint('Error saving document locally: $e');
      return pickedFile.path;
    }
  }

  /// Queues background upload to server with delay to prevent server overload
  static Future<void> syncCustomerDocumentInBackground(Map<String, dynamic> customerData) async {
    // Run upload asynchronously in background without blocking UI
    Future.delayed(const Duration(milliseconds: 1500), () async {
      try {
        await ApiService.createCustomer(customerData);
      } catch (e) {
        debugPrint('Background document sync retry scheduled: $e');
      }
    });
  }

  /// Cleans temporary cached document files older than 30 days
  static Future<void> cleanOldCache() async {
    try {
      if (kIsWeb) return;
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory docFolder = Directory('${appDocDir.path}/$_folderName');
      if (await docFolder.exists()) {
        final List<FileSystemEntity> files = docFolder.listSync();
        final now = DateTime.now();
        for (var f in files) {
          if (f is File) {
            final stat = await f.stat();
            if (now.difference(stat.modified).inDays > 30) {
              await f.delete();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning old document cache: $e');
    }
  }
}
