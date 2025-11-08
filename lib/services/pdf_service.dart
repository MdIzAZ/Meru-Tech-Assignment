import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/quote.dart';
import '../utils/formatter.dart';

class PdfService {
  static Future<Uint8List> generateQuotePdf(Quote q) async {
    final pdf = pw.Document();

    // Load custom Roboto font from assets
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final boldTtf = pw.Font.ttf(boldFontData);

    // Status color
    PdfColor statusColor;
    switch (q.status) {
      case 'Sent':
        statusColor = PdfColors.orange;
        break;
      case 'Accepted':
        statusColor = PdfColors.green;
        break;
      default:
        statusColor = PdfColors.grey600;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('QUOTE',
                        style: pw.TextStyle(
                          font: boldTtf,
                          fontSize: 26,
                          color: PdfColors.blue900,
                          fontWeight: pw.FontWeight.bold,
                        )),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Date: ${q.createdAt.toLocal().toIso8601String().split("T").first}',
                      style: pw.TextStyle(font: ttf, fontSize: 10),
                    ),
                    pw.Text(
                      'Tax Type: ${q.taxExclusive ? "Tax-Exclusive" : "Tax-Inclusive"}',
                      style: pw.TextStyle(font: ttf, fontSize: 10),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        color: statusColor,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      child: pw.Text(
                        q.status.toUpperCase(),
                        style: pw.TextStyle(
                            font: boldTtf,
                            fontSize: 10,
                            color: PdfColors.white),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('To:',
                        style: pw.TextStyle(
                            font: boldTtf,
                            fontSize: 12,
                            color: PdfColors.grey800)),
                    pw.Text(q.clientName,
                        style:
                        pw.TextStyle(font: ttf, fontSize: 11)),
                    if (q.clientAddress.isNotEmpty)
                      pw.Text(q.clientAddress,
                          style:
                          pw.TextStyle(font: ttf, fontSize: 10)),
                    if (q.clientRef.isNotEmpty)
                      pw.Text('Ref: ${q.clientRef}',
                          style:
                          pw.TextStyle(font: ttf, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Table Header
          pw.Container(
            color: PdfColors.blue50,
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: pw.Row(
              children: [
                _headerCell('Item', 4, boldTtf),
                _headerCell('Qty', 1, boldTtf),
                _headerCell('Rate', 2, boldTtf),
                _headerCell('Discount', 2, boldTtf),
                _headerCell('Tax %', 2, boldTtf),
                _headerCell('Total', 2, boldTtf),
              ],
            ),
          ),

          // Table Rows
          ...q.items.asMap().entries.map((entry) {
            final index = entry.key;
            final it = entry.value;
            final isEven = index % 2 == 0;
            final bgColor = isEven ? PdfColors.white : PdfColors.grey100;
            return pw.Container(
              color: bgColor,
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: pw.Row(
                children: [
                  _cell(it.name, 4, ttf),
                  _cell(it.quantity.toStringAsFixed(1), 1, ttf),
                  _cell(fmt(it.rate), 2, ttf),
                  _cell(fmt(it.discount), 2, ttf),
                  _cell('${it.taxPercent.toStringAsFixed(1)}%', 2, ttf),
                  _cell(fmt(it.total(taxExclusive: q.taxExclusive)), 2, ttf),
                ],
              ),
            );
          }),

          pw.SizedBox(height: 18),

          // Totals Section
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _summaryRow('Subtotal:', fmt(q.subtotal()), ttf, boldTtf),
                _summaryRow('Tax:', fmt(q.totalTax()), ttf, boldTtf),
                pw.Divider(color: PdfColors.grey600, thickness: 0.5),
                pw.Text('Grand Total: ${fmt(q.grandTotal())}',
                    style: pw.TextStyle(
                      font: boldTtf,
                      fontSize: 14,
                      color: PdfColors.blue900,
                      fontWeight: pw.FontWeight.bold,
                    )),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Footer
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Generated by Product Quote Builder • ${DateTime.now().toLocal().toIso8601String().split("T").first}',
              style: pw.TextStyle(
                  font: ttf, fontSize: 9, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // Helper for header cells
  static pw.Widget _headerCell(String text, int flex, pw.Font boldTtf) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(text,
          style: pw.TextStyle(
            font: boldTtf,
            fontSize: 10,
            color: PdfColors.blue900,
            fontWeight: pw.FontWeight.bold,
          )),
    );
  }

  // Helper for normal cells
  static pw.Widget _cell(String text, int flex, pw.Font ttf) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(text,
          style:
          pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey800)),
    );
  }

  // Helper for summary section
  static pw.Widget _summaryRow(
      String label, String value, pw.Font ttf, pw.Font boldTtf) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value,
              style: pw.TextStyle(
                  font: boldTtf,
                  fontSize: 11,
                  color: PdfColors.grey800,
                  fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static Future<void> printQuote(Quote q) async {
    final bytes = await generateQuotePdf(q);
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  static Future<void> shareQuote(Quote q) async {
    final bytes = await generateQuotePdf(q);
    await Printing.sharePdf(bytes: bytes, filename: 'quote_${q.id}.pdf');
  }
}
