import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';

class FileSelectorService {
  Future<XFile?> pickSingleFile({List<XTypeGroup>? typeGroups}) async {
    final result = await openFile(acceptedTypeGroups: typeGroups ?? [anyTypeGroup()]);
    return result;
  }

  Future<List<XFile>> pickMultipleFiles({List<XTypeGroup>? typeGroups}) async {
    final results = await openFiles(acceptedTypeGroups: typeGroups ?? [anyTypeGroup()]);
    return results;
  }

  Future<XFile?> saveFile({
    required String suggestedName,
    required String mimeType,
    Uint8List? bytes,
  }) async {
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

  XTypeGroup pdfTypeGroup() => const XTypeGroup(
        label: 'pdf',
        extensions: <String>['pdf'],
      );

  XTypeGroup anyTypeGroup() => const XTypeGroup(label: 'any');
}
