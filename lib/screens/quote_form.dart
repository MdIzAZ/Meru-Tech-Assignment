import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/line_item.dart';
import '../models/quote.dart';
import '../widgets/line_item_row.dart';
import '../utils/formatter.dart';

class QuoteFormScreen extends StatefulWidget {
  const QuoteFormScreen({Key? key}) : super(key: key);

  @override
  State<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientName = TextEditingController();
  final _clientAddress = TextEditingController();
  final _clientRef = TextEditingController();
  final _uuid = const Uuid();

  List<LineItem> items = [];
  bool taxExclusive = true;

  @override
  void initState() {
    super.initState();
    items.add(LineItem(id: _uuid.v4(), name: 'Sample Item', quantity: 1, rate: 500));
  }

  void _addItem() => setState(() => items.add(LineItem(id: _uuid.v4())));
  void _removeItem(int index) => setState(() => items.removeAt(index));
  void _updateItem(int index, LineItem item) => setState(() => items[index] = item);

  double get subtotal => items.fold(0, (p, e) => p + e.baseAmount());
  double get totalTax => items.fold(0, (p, e) => p + e.taxAmount());
  double get grandTotal => taxExclusive ? subtotal + totalTax : subtotal;

  void _previewQuote() {
    if (!_formKey.currentState!.validate()) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }
    final q = Quote(
      id: _uuid.v4(),
      clientName: _clientName.text,
      clientAddress: _clientAddress.text,
      clientRef: _clientRef.text,
      taxExclusive: taxExclusive,
      items: items,
    );
    Navigator.pushNamed(context, '/preview', arguments: q);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            title: const Text('Create Quote'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Client Info Card ---
                    _sectionTitle('Client Information'),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _clientName,
                              decoration: const InputDecoration(
                                labelText: 'Client Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Enter client name' : null,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _clientAddress,
                              decoration: const InputDecoration(
                                labelText: 'Client Address',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _clientRef,
                              decoration: const InputDecoration(
                                labelText: 'Client Reference',
                                prefixIcon: Icon(Icons.tag_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Tax Mode ---
                    _sectionTitle('Tax Mode'),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long, color: Colors.blueAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tax mode:',
                                style: const TextStyle(fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<bool>(
                                value: taxExclusive,
                                borderRadius: BorderRadius.circular(10),
                                items: const [
                                  DropdownMenuItem(value: true, child: Text('Tax Exclusive')),
                                  DropdownMenuItem(value: false, child: Text('Tax Inclusive')),
                                ],
                                onChanged: (v) => setState(() => taxExclusive = v!),
                              ),
                            ),
                          ],
                        ),

                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Items ---
                    _sectionTitle('Line Items'),
                    ...List.generate(
                      items.length,
                          (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: LineItemRow(
                          index: i,
                          item: items[i],
                          onChanged: _updateItem,
                          onRemove: _removeItem,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Item', style: TextStyle(color: Colors.white),),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Summary ---
                    _sectionTitle('Quote Summary'),
                    Card(
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _summaryRow('Subtotal', fmt(subtotal)),
                            _summaryRow('Tax', fmt(totalTax)),
                            const Divider(),
                            _summaryRow('Grand Total', fmt(grandTotal),
                                isBold: true, color: Colors.blue.shade900),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // --- Bottom Floating Bar ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  Text(
                    'Total: ${fmt(grandTotal)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _previewQuote,
                    icon: const Icon(Icons.visibility_rounded, color: Colors.white),
                    label: const Text('Preview Quote', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 4),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  );

  Widget _summaryRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: color ?? Colors.black87)),
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
