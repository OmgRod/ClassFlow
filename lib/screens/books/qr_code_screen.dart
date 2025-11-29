import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../services/file_selector_service.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../utils/file_utils.dart';
import '../../services/database_service.dart';

class QrCodeScreen extends StatefulWidget {
  final Subject subject;
  final int bookId;

  const QrCodeScreen({super.key, required this.subject, required this.bookId});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSubtle = false;
  bool _isSaving = false;

  String get code => widget.subject.generateCode(widget.bookId);

  Color get subjectColor => widget.subject.colorValue != null
      ? Color(widget.subject.colorValue!)
      : AppColors.getDefaultSubjectColor(widget.subject.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code'),
        actions: [
          IconButton(
            icon: Icon(_isSubtle ? Icons.visibility : Icons.visibility_off),
            tooltip: _isSubtle ? 'Make Visible' : 'Make Subtle',
            onPressed: () {
              setState(() => _isSubtle = !_isSubtle);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Subject info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: subjectColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: subjectColor, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          widget.subject.name.isNotEmpty
                              ? widget.subject.name[0]
                              : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: subjectColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subject.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Book ID: ${widget.bookId}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // QR Code
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Opacity(
                      opacity: _isSubtle
                          ? AppConstants.qrCodeSubtleOpacity
                          : 1.0,
                      child: QrImageView(
                        data: code,
                        version: QrVersions.auto,
                        size: AppConstants.qrCodeSize,
                        backgroundColor: Colors.white,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: _isSubtle
                              ? Colors.grey.shade300
                              : Colors.black,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: _isSubtle
                              ? Colors.grey.shade300
                              : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      code,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isSubtle ? Colors.grey.shade300 : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isSubtle)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Subtle mode: QR code is less visible at a glance',
                        style: TextStyle(color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveQrCode,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_alt),
                    label: Text(_isSaving ? 'Saving...' : 'Save Image'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _shareQrCode,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _captureQrCode() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing QR code: $e');
      return null;
    }
  }

  Future<void> _saveQrCode() async {
    setState(() => _isSaving = true);

    try {
      final bytes = await _captureQrCode();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture QR code')),
          );
        }
        return;
      }

      // Save to configured export directory (or app's QR codes directory)
      final custom = DatabaseService.settings['exportPath'] as String?;
      Directory directory;
      if (custom != null && custom.isNotEmpty) {
        directory = Directory(custom);
        if (!await directory.exists()) await directory.create(recursive: true);
      } else {
        directory = await FileUtils.getQrCodesDirectory();
      }

      final fileName =
          'qr_${code.replaceAll('-', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      // Offer user-chosen save location via FileSelectorService; fallback to app directory
      final fs = FileSelectorService();
      final saved = await fs.saveFile(
        suggestedName: fileName,
        mimeType: 'image/png',
        bytes: bytes,
      );

      // On iOS, saveFile uses share sheet
      if (Platform.isIOS) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR code shared. Choose where to save it.'),
            ),
          );
        }
        return;
      }

      final filePath =
          saved?.path ?? '${directory.path}${Platform.pathSeparator}$fileName';
      if (saved == null) {
        final file = File(filePath);
        await file.writeAsBytes(bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR code saved to: $filePath'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => _shareFile(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareQrCode() async {
    setState(() => _isSaving = true);

    try {
      final bytes = await _captureQrCode();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture QR code')),
          );
        }
        return;
      }

      // Save temporarily for sharing in app's temp directory
      final directory = await FileUtils.getTempDirectory();
      final fileName = 'qr_$code.png';
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes);

      await _shareFile(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareFile(String path) async {
    await Share.shareXFiles(
      [XFile(path)],
      text:
          'QR Code for ${widget.subject.name} - Book ${widget.bookId}\nCode: $code',
    );
  }
}
