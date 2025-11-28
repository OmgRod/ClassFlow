import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Utility class for file and directory operations.
/// Uses a writable app-specific directory for storage.
class FileUtils {
  static Directory? _appDirectory;

  /// Gets the app directory path.
  ///
  /// On mobile/desktop, this is based on the OS-provided
  /// application documents directory. On web, this should
  /// not be called.
  static Future<Directory> getAppDirectory() async {
    // Use cached directory if available and still exists
    if (_appDirectory != null && await _appDirectory!.exists()) {
      return _appDirectory!;
    }

    Directory baseDir;
    try {
      // Use path_provider so we always get a writable location
      baseDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      // Fallback to current working directory if anything goes wrong
      baseDir = Directory.current;
    }

    final dir = Directory(
      '${baseDir.path}${Platform.pathSeparator}detention_safe_data',
    );

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _appDirectory = dir;
    return dir;
  }

  /// Gets the exports subdirectory within the app directory.
  static Future<Directory> getExportsDirectory() async {
    final appDir = await getAppDirectory();
    final exportsDir = Directory(
      '${appDir.path}${Platform.pathSeparator}exports',
    );
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    return exportsDir;
  }

  /// Gets the QR codes subdirectory within the app directory.
  static Future<Directory> getQrCodesDirectory() async {
    final appDir = await getAppDirectory();
    final qrDir = Directory('${appDir.path}${Platform.pathSeparator}qr_codes');
    if (!await qrDir.exists()) {
      await qrDir.create(recursive: true);
    }
    return qrDir;
  }

  /// Gets a temporary directory within the app directory.
  static Future<Directory> getTempDirectory() async {
    final appDir = await getAppDirectory();
    final tempDir = Directory('${appDir.path}${Platform.pathSeparator}temp');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }
}
