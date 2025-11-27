import 'dart:io';

/// Utility class for file and directory operations.
/// Uses the app's directory (relative to the executable) for storage.
class FileUtils {
  static Directory? _appDirectory;

  /// Gets the app directory path. On desktop platforms, this is a 'data' 
  /// subdirectory next to the executable. Creates the directory if it doesn't exist.
  static Future<Directory> getAppDirectory() async {
    // Use cached directory if available and still exists
    if (_appDirectory != null && await _appDirectory!.exists()) {
      return _appDirectory!;
    }

    // Get directory based on executable location
    final executablePath = Platform.resolvedExecutable;
    final executableDir = File(executablePath).parent.path;
    
    // Use a 'data' subdirectory within the app directory
    final appDataPath = '$executableDir${Platform.pathSeparator}data';
    
    final dir = Directory(appDataPath);
    
    // Try to create the directory - if this fails (permissions), 
    // fall back to current working directory
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _appDirectory = dir;
      return dir;
    } catch (e) {
      // Fallback to current working directory if executable directory is not writable
      final fallbackPath = '${Directory.current.path}${Platform.pathSeparator}detention_safe_data';
      final fallbackDir = Directory(fallbackPath);
      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }
      _appDirectory = fallbackDir;
      return fallbackDir;
    }
  }

  /// Gets the exports subdirectory within the app directory.
  static Future<Directory> getExportsDirectory() async {
    final appDir = await getAppDirectory();
    final exportsDir = Directory('${appDir.path}${Platform.pathSeparator}exports');
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
