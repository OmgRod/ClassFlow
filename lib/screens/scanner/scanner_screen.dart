import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;
  bool _isScanning = true;
  String? _lastScannedCode;
  Subject? _scannedSubject;
  int? _scannedBookId;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Check if platform is supported
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scanner'),
          leading: BackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.qr_code_scanner,
            title: 'Scanner Not Available',
            subtitle: 'The QR code scanner is currently only available on mobile devices (Android & iOS).\n\nOn desktop, you can manually find books in the Books tab by browsing through subjects.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: Column(
        children: [
          // Scanner view
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Camera view
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) {
                      return _buildCameraError(
                        error.errorDetails?.message ?? 'Camera error',
                      );
                    },
                  ),
                ),
                // Scanning overlay
                _buildScannerOverlay(),
                // Controls
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      // Torch toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: ValueListenableBuilder(
                            valueListenable:
                                _controller?.torchState ??
                                ValueNotifier(TorchState.off),
                            builder: (context, state, child) {
                              return Icon(
                                state == TorchState.on
                                    ? Icons.flash_on
                                    : Icons.flash_off,
                                color: Colors.white,
                              );
                            },
                          ),
                          onPressed: () => _controller?.toggleTorch(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Camera switch
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                          ),
                          onPressed: () => _controller?.switchCamera(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Result panel
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: isDark ? theme.colorScheme.surface : null,
              padding: const EdgeInsets.all(16),
              child: _buildResultPanel(theme, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraError(String message) {
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              const Text(
                'Camera Access Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              if (isDesktop) ...[
                const SizedBox(height: 12),
                const Text(
                  'Make sure your camera is connected and not being used by another application.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _requestCameraPermission(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.7;
        return Stack(
          children: [
            // Darkened areas around scan area
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScannerOverlayPainter(
                scanAreaSize: scanAreaSize,
                borderColor: _scannedSubject != null
                    ? Colors.green
                    : (_hasError ? Colors.red : Colors.white),
              ),
            ),
            // Corner markers
            Center(
              child: SizedBox(
                width: scanAreaSize,
                height: scanAreaSize,
                child: Stack(
                  children: [
                    _buildCorner(Alignment.topLeft),
                    _buildCorner(Alignment.topRight),
                    _buildCorner(Alignment.bottomLeft),
                    _buildCorner(Alignment.bottomRight),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorner(Alignment alignment) {
    final cornerColor = _scannedSubject != null
        ? Colors.green
        : (_hasError ? Colors.red : Colors.white);

    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight
                ? BorderSide(color: cornerColor, width: 4)
                : BorderSide.none,
            bottom:
                alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight
                ? BorderSide(color: cornerColor, width: 4)
                : BorderSide.none,
            left:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? BorderSide(color: cornerColor, width: 4)
                : BorderSide.none,
            right:
                alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? BorderSide(color: cornerColor, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildResultPanel(ThemeData theme, bool isDark) {
    Widget main;
    if (_lastScannedCode == null) {
      main = _buildEmptyState(theme, isDark);
    } else if (_hasError) {
      main = _buildErrorState(theme, isDark);
    } else if (_scannedSubject != null) {
      main = _buildSuccessState(theme, isDark);
    } else {
      main = _buildEmptyState(theme, isDark);
    }

    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [main]),
    );
  }

  // Note: status reporting is now handled from the Books screen only.

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Point camera at a QR code',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'QR codes are in format: SubjectID-BookID-SubjectName',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, bool isDark) {
    return Card(
      color: isDark
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.2)
          : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              'Invalid QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Code format not recognized',
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Scanned: $_lastScannedCode',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _resetScanner,
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme, bool isDark) {
    final color = _scannedSubject!.colorValue != null
        ? Color(_scannedSubject!.colorValue!)
        : AppColors.getDefaultSubjectColor(_scannedSubject!.id);

    return Card(
      color: isDark
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                ColorAvatar(
                  color: color,
                  text: _scannedSubject!.name.isNotEmpty
                      ? _scannedSubject!.name[0]
                      : '?',
                  size: 60,
                  fontSize: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Found!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _scannedSubject!.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Book ID: $_scannedBookId',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Code: $_lastScannedCode',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: isDark ? theme.colorScheme.onSurface : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _resetScanner,
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Another'),
            ),
          ],
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    if (capture.barcodes.isEmpty) return;

    // Prefer the barcode whose bounding box is closest to the center
    // of the camera preview. Fall back to the first valid one.
    final Size size = capture.size;
    Barcode? candidate;

    {
      final center = Offset(size.width / 2, size.height / 2);
      double bestDistance = double.infinity;

      for (final b in capture.barcodes) {
        if (b.rawValue == null) continue;

        // mobile_scanner exposes corner points instead of a direct bounding box.
        // Approximate the center by averaging the corner coordinates when available.
        Offset candidateCenter;
        final corners = b.corners;
        if (corners.isNotEmpty) {
          double sumX = 0;
          double sumY = 0;
          for (final p in corners) {
            sumX += p.dx;
            sumY += p.dy;
          }
          candidateCenter = Offset(
            sumX / corners.length,
            sumY / corners.length,
          );
        } else {
          // If we don't have geometry, fall back to camera center so the
          // first valid code will be chosen.
          candidateCenter = center;
        }
        final distance = (candidateCenter - center).distance;

        if (distance < bestDistance) {
          bestDistance = distance;
          candidate = b;
        }
      }
    }

    // If we didn't find a centered candidate with bounds, just use the first
    // barcode that has a value.
    final Barcode chosen =
        (candidate ??
        capture.barcodes.firstWhere(
          (b) => b.rawValue != null,
          orElse: () => capture.barcodes.first,
        ));

    if (chosen.rawValue == null) return;

    final code = chosen.rawValue!;
    if (code == _lastScannedCode) return;

    setState(() {
      _isScanning = false;
      _lastScannedCode = code;
      _hasError = false;
      _errorMessage = null;
      _scannedSubject = null;
      _scannedBookId = null;
    });

    _parseCode(code);
  }

  void _parseCode(String code) {
    // Expected format: SubjectID-BookID-SubjectName
    final parts = code.split('-');

    if (parts.length < 3) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Code must be in format: SubjectID-BookID-SubjectName';
      });
      return;
    }

    final subjectId = int.tryParse(parts[0]);
    final bookId = int.tryParse(parts[1]);
    final subjectName = parts.sublist(2).join('-'); // Handle names with dashes

    if (subjectId == null || bookId == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Subject ID and Book ID must be numbers';
      });
      return;
    }

    // Look up the subject
    final subjectService = context.read<SubjectService>();
    final subject = subjectService.getSubjectById(subjectId);

    if (subject == null) {
      setState(() {
        _hasError = true;
        _errorMessage =
            'Subject with ID $subjectId not found.\nName from code: $subjectName';
      });
      return;
    }

    // Verify the code matches
    if (subject.name != subjectName) {
      setState(() {
        _hasError = true;
        _errorMessage =
            'Subject name mismatch.\nExpected: ${subject.name}\nGot: $subjectName';
      });
      return;
    }

    // Success!
    setState(() {
      _scannedSubject = subject;
      _scannedBookId = bookId;
    });
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _lastScannedCode = null;
      _scannedSubject = null;
      _scannedBookId = null;
      _hasError = false;
      _errorMessage = null;
    });
  }

  Future<void> _requestCameraPermission() async {
    // On Windows/Desktop, permission_handler doesn't work properly
    // Just restart the controller and let the system handle permissions
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _controller?.dispose();
      _initController();
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
      return;
    }

    // Mobile platforms (Android/iOS)
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _controller?.dispose();
      _initController();
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
    } else if (status.isPermanentlyDenied) {
      // Guide user to settings
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Camera Permission'),
          content: const Text(
            'Camera permission is permanently denied. Please enable it in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    } else {
      // Show a simple message
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Camera Permission'),
          content: const Text(
            'Camera permission was denied. The scanner cannot run without access.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final Color borderColor;

  _ScannerOverlayPainter({
    required this.scanAreaSize,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw semi-transparent overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(
          RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
        ),
      ),
      paint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor;
  }
}
