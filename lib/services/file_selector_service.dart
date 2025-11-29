import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class FileSelectorService {
  Future<XFile?> pickSingleFile({List<XTypeGroup>? typeGroups}) async {
    final result = await openFile(
      acceptedTypeGroups: typeGroups ?? [anyTypeGroup()],
    );
    return result;
  }

  Future<List<XFile>> pickMultipleFiles({List<XTypeGroup>? typeGroups}) async {
    final results = await openFiles(
      acceptedTypeGroups: typeGroups ?? [anyTypeGroup()],
    );
    return results;
  }

  Future<XFile?> saveFile({
    required String suggestedName,
    required String mimeType,
    Uint8List? bytes,
  }) async {
    // iOS doesn't support getSaveLocation, use share sheet instead
    if (Platform.isIOS) {
      final data = bytes ?? Uint8List(0);
      // Save to temp directory first
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$suggestedName');
      await tempFile.writeAsBytes(data);
      // Share the file using share sheet
      await Share.shareXFiles([
        XFile(tempFile.path),
      ], text: 'Export from ClassFlow');
      // Return the temp file path
      return XFile(tempFile.path);
    }

    // For other platforms, use the standard file picker
    final file = await getSaveLocation(suggestedName: suggestedName);
    if (file == null) return null;
    final data = bytes ?? Uint8List(0);
    final xFile = XFile.fromData(data, name: suggestedName, mimeType: mimeType);
    await xFile.saveTo(file.path);
    return XFile(file.path);
  }

  XTypeGroup imagesTypeGroup() => const XTypeGroup(
    label: 'images',
    extensions: <String>['jpg', 'jpeg', 'png'],
  );

  XTypeGroup pdfTypeGroup() =>
      const XTypeGroup(label: 'pdf', extensions: <String>['pdf']);

  XTypeGroup anyTypeGroup() => const XTypeGroup(label: 'any');
}
