import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
// Use PDF package's built-in barcode rendering (no external svg conversion)

/// Helper service to generate a paginated PDF containing QR codes laid out in a grid.
class QrPdfService {
  /// Generate a PDF document with the provided items and return bytes.
  ///
  /// items: list of maps with keys: 'code' (String), 'label' (String)
  /// scale: fraction of page width to use per QR (0.1..0.5 typical). For example 0.2 means each QR is 1/5 page width.
  static Future<Uint8List> generatePdfBytes(
    List<Map<String, String>> items, {
    double scale = 0.2,
  }) async {
    final pdf = pw.Document();

    final pageFormat = PdfPageFormat.a4;
    final pageWidth = pageFormat.width; // points
    final pageHeight = pageFormat.height;

    final qrWidth = (pageWidth * scale).clamp(20.0, pageWidth);
    final columns = (pageWidth / qrWidth).floor().clamp(1, 10);

    // reserve some vertical space for label under each QR
    final labelHeight = 20.0;
    final verticalSpacing = 8.0;
    final effectiveQrHeight = qrWidth + labelHeight + verticalSpacing;
    final rows = (pageHeight / effectiveQrHeight).floor().clamp(1, 50);

    final perPage = columns * rows;

    // Precreate a Barcode QR generator
    int pageIndex = 0;
    while (pageIndex * perPage < items.length) {
      final start = pageIndex * perPage;
      final end = (start + perPage).clamp(0, items.length);
      final slice = items.sublist(start, end);

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) {
            return pw.Padding(
              padding: pw.EdgeInsets.all(12),
              child: pw.GridView(
                crossAxisCount: columns,
                // keep cells roughly square but allow space for label beneath
                childAspectRatio: qrWidth / effectiveQrHeight,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: slice.map((it) {
                  final code = it['code'] ?? '';
                  final label = it['label'] ?? '';

                  return pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        width: qrWidth,
                        height: qrWidth,
                        color: PdfColors.white,
                        child: pw.Center(
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: code,
                            width: qrWidth,
                            height: qrWidth,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(label, style: pw.TextStyle(fontSize: 10)),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      );

      pageIndex++;
    }

    return pdf.save();
  }

  /// Generate and share the PDF using the platform share sheet.
  static Future<void> generateAndShare(
    List<Map<String, String>> items, {
    double scale = 0.2,
    String filename = 'qr_export.pdf',
  }) async {
    final bytes = await generatePdfBytes(items, scale: scale);
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
