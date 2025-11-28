import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';

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
  // Manual fallback selection
  bool _manualMode = false;
  int? _manualSelectedBookId;

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
                // Scan status indicator
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _isScanning ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isScanning ? Icons.qr_code_scanner : Icons.pause,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isScanning ? 'Scanning...' : 'Paused',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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
              padding: const EdgeInsets.all(16),
              child: _buildResultPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraError(String message) {
    return Container(
      color: Colors.black,
      child: Center(
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _requestCameraPermission(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
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

  Widget _buildResultPanel() {
    Widget main;
    if (_lastScannedCode == null) {
      main = _buildEmptyState();
    } else if (_hasError) {
      main = _buildErrorState();
    } else if (_scannedSubject != null) {
      main = _buildSuccessState();
    } else {
      main = _buildEmptyState();
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [main, const SizedBox(height: 12), _buildManualFallback()],
      ),
    );
  }

  Widget _buildManualFallback() {
    final bookService = context.watch<BookService>();
    final subjectService = context.watch<SubjectService>();
    // Ensure book & subject lists are fresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bookService.refresh();
      subjectService.refresh();
    });
    final books = bookService.books;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.handshake, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(child: Text('Manual fallback & reports')),
                TextButton(
                  onPressed: () => setState(() => _manualMode = !_manualMode),
                  child: Text(_manualMode ? 'Hide' : 'Manual Select'),
                ),
              ],
            ),
            if (_manualMode) ...[
              const SizedBox(height: 8),
              DropdownButton<int>(
                isExpanded: true,
                hint: const Text('Select book'),
                value: _manualSelectedBookId,
                items: books.map((b) {
                  final subj = subjectService.getSubjectById(b.subjectId);
                  final label = subj != null
                      ? '${subj.name} - ${b.id}'
                      : 'Book ${b.id}';
                  return DropdownMenuItem<int>(value: b.id, child: Text(label));
                }).toList(),
                onChanged: (v) => setState(() => _manualSelectedBookId = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _manualSelectedBookId == null
                          ? null
                          : _confirmManualSelection,
                      child: const Text('Use Selected Book'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        ((_manualSelectedBookId ?? _scannedBookId) == null)
                        ? null
                        : () => _reportBookStatus(
                            'teacher',
                            bookId: _manualSelectedBookId,
                          ),
                    child: const Text('My teacher has my book'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        ((_manualSelectedBookId ?? _scannedBookId) == null)
                        ? null
                        : () => _reportBookStatus(
                            'missing',
                            bookId: _manualSelectedBookId,
                          ),
                    child: const Text("I can't find my book"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmManualSelection() {
    final bookService = context.read<BookService>();
    final subjectService = context.read<SubjectService>();
    final book = bookService.getBookById(_manualSelectedBookId!);
    if (book == null) return;
    final subj = subjectService.getSubjectById(book.subjectId);
    setState(() {
      _scannedBookId = book.id;
      _scannedSubject = subj;
      _lastScannedCode = book.generateQrCode(subj?.name ?? '');
      _hasError = false;
      _errorMessage = null;
    });
  }

  Future<void> _reportBookStatus(String type, {int? bookId}) async {
    // Instead of creating a report, simply mark the book status so it appears
    // in the Books menu as missing or handed in.
    final bookService = context.read<BookService>();
    final idToUse = bookId ?? _scannedBookId;
    if (idToUse == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No book selected')));
      return;
    }

    if (type == 'teacher') {
      await bookService.markBookHandedIn(idToUse);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Marked as handed in')));
    } else {
      await bookService.markBookMissing(idToUse);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Marked as missing')));
    }

    // Refresh local state and services
    setState(() {
      _scannedBookId = idToUse;
    });
    bookService.refresh();
  }

  Widget _buildEmptyState() {
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
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Card(
      color: Colors.red.shade50,
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

  Widget _buildSuccessState() {
    final color = _scannedSubject!.colorValue != null
        ? Color(_scannedSubject!.colorValue!)
        : AppColors.getDefaultSubjectColor(_scannedSubject!.id);

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _scannedSubject!.name.isNotEmpty
                          ? _scannedSubject!.name[0]
                          : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Code: $_lastScannedCode',
                style: const TextStyle(fontFamily: 'monospace'),
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

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue == null) continue;

      final code = barcode.rawValue!;
      if (code == _lastScannedCode) continue;

      setState(() {
        _isScanning = false;
        _lastScannedCode = code;
        _hasError = false;
        _errorMessage = null;
        _scannedSubject = null;
        _scannedBookId = null;
      });

      _parseCode(code);
      break;
    }
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
      ..color = Colors.black.withOpacity(0.5)
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
