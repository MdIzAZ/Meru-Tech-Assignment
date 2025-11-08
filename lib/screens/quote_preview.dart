import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../data/db_helper.dart';
import '../services/pdf_service.dart';
import '../utils/formatter.dart';

class QuotePreviewScreen extends StatelessWidget {
  const QuotePreviewScreen({Key? key}) : super(key: key);

  Color _statusColor(String status) {
    switch (status) {
      case 'Sent':
        return Colors.orange;
      case 'Accepted':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Quote q = ModalRoute.of(context)!.settings.arguments as Quote;

    Future<void> _saveAndReturn() async {
      await DBHelper().insertQuote(q);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote saved successfully')),
      );
      await Future.delayed(const Duration(milliseconds: 400));
      Navigator.popUntil(context, (route) => route.isFirst);
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: const Text('Quote Preview'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ---- Quote Header ----
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.clientName.isEmpty ? 'Unnamed Client' : q.clientName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (q.clientAddress.isNotEmpty)
                      Text(q.clientAddress, style: const TextStyle(color: Colors.black54)),
                    if (q.clientRef.isNotEmpty)
                      Text('Ref: ${q.clientRef}',
                          style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 10),

                    // ✅ Fixed Overflow with Wrap
                    Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text(
                            q.status,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _statusColor(q.status),
                        ),
                        Text(
                          'Tax: ${q.taxExclusive ? 'Exclusive' : 'Inclusive'}',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        Text(
                          'Date: ${q.createdAt.toLocal().toIso8601String().split('T').first}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ---- Line Items Table ----
            _buildItemsTable(q),

            const SizedBox(height: 20),

            // ---- Totals Summary ----
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summaryRow('Subtotal', fmt(q.subtotal())),
                    _summaryRow('Tax', fmt(q.totalTax())),
                    const Divider(),
                    _summaryRow('Grand Total', fmt(q.grandTotal()),
                        isBold: true, color: Colors.blue.shade900),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // ---- Bottom Action Bar ----
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _bottomButton(
              color: Colors.green,
              icon: Icons.save,
              label: 'Save',
              onPressed: _saveAndReturn,
            ),
            _bottomButton(
              color: Colors.blueAccent,
              icon: Icons.print,
              label: 'Print',
              onPressed: () async => await PdfService.printQuote(q),
            ),
            _bottomButton(
              color: Colors.deepPurple,
              icon: Icons.share,
              label: 'Share',
              onPressed: () async => await PdfService.shareQuote(q),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Bottom Button Builder ----
  Widget _bottomButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            elevation: 3,
          ),
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  // ---- Items Table ----
  Widget _buildItemsTable(Quote q) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ...q.items.asMap().entries.map((entry) {
            final i = entry.key;
            final it = entry.value;
            final bgColor = i.isEven ? Colors.white : Colors.blue.shade50;
            return Container(
              color: bgColor,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(it.name)),
                  Expanded(flex: 1, child: Text(it.quantity.toStringAsFixed(1))),
                  Expanded(flex: 2, child: Text(fmt(it.rate))),
                  Expanded(flex: 2, child: Text(fmt(it.total(taxExclusive: q.taxExclusive)))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---- Summary Row ----
  Widget _summaryRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: color ?? Colors.black87)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
