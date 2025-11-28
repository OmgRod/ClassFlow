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

    final tileWidth = (pageWidth * scale).clamp(60.0, pageWidth);

    // Simple, reliable capacity: fixed columns x rows based on geometry.
    // This avoids the probe doc double-counting across layout passes.
    final columns = (pageWidth / (tileWidth + 16)).floor().clamp(1, 6);

    // Reserve margins and spacing; keep rows small so we never overfill.
    const pagePadding = 24.0;
    const verticalSpacing = 16.0; // Wrap runSpacing
    const tileVertical =
        16.0 * 2 + // container padding
        (0.7) + // QR aspect ratio factor (relative)
        10.0 + // gap
        14.0; // text line

    final usableHeight = pageFormat.height - pagePadding * 2;
    final approxTileHeight = (pageWidth * scale * tileVertical).clamp(
      80.0,
      240.0,
    );
    int rows =
        ((usableHeight + verticalSpacing) /
                (approxTileHeight + verticalSpacing))
            .floor();
    if (rows < 1) rows = 1;
    if (rows > 6) rows = 6;

    final perPage = (columns * rows).clamp(1, 48);

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
              padding: const pw.EdgeInsets.all(24),
              child: pw.Wrap(
                spacing: 16,
                runSpacing: 16,
                children: slice.map((it) {
                  final code = it['code'] ?? '';
                  return pw.SizedBox(
                    width: tileWidth,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(16),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(
                              color: PdfColors.black,
                              width: 1,
                            ),
                          ),
                          child: pw.Column(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: code,
                                width: tileWidth * 0.7,
                                height: tileWidth * 0.7,
                              ),
                              pw.SizedBox(height: 10),
                              pw.FittedBox(
                                fit: pw.BoxFit.scaleDown,
                                child: pw.Text(
                                  code,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                    font: pw.Font.courier(),
                                  ),
                                  textAlign: pw.TextAlign.center,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

  // No extra helpers needed; FittedBox keeps code text on one line.

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
