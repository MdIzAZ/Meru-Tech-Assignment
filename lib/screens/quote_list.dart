import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/db_helper.dart';
import '../models/quote.dart';
import 'quote_form.dart';
import '../services/pdf_service.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({Key? key}) : super(key: key);

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  List<Quote> quotes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    final data = await DBHelper().fetchAll();
    setState(() {
      quotes = data;
      loading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Sent':
        return Colors.orangeAccent;
      case 'Accepted':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(Quote q, String newStatus) async {
    await DBHelper().updateStatus(q.id, newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quote marked as $newStatus'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blueAccent,
      ),
    );
    await _loadQuotes();
  }

  Future<void> _confirmDelete(Quote q) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Quote'),
        content: Text(
          'Are you sure you want to delete this quote for "${q.clientName.isEmpty ? 'Unnamed Client' : q.clientName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await DBHelper().deleteQuote(q.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quote deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadQuotes();
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
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
            title: const Text('Saved Quotes'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : quotes.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadQuotes,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: quotes.length,
          itemBuilder: (context, i) {
            final q = quotes[i];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _statusColor(q.status),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  q.clientName.isEmpty ? 'Unnamed Client' : q.clientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${_formatDate(q.createdAt)}  •  ₹${q.grandTotal().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
                trailing: _statusBadge(q.status),
                onTap: () {
                  Navigator.pushNamed(context, '/preview', arguments: q)
                      .then((_) => _loadQuotes());
                },
                onLongPress: () async {
                  await _showActionsMenu(context, q);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuoteFormScreen()),
        ).then((_) => _loadQuotes()),
        icon: const Icon(Icons.add),
        label: const Text('New Quote'),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 70, color: Colors.grey),
          const SizedBox(height: 10),
          const Text(
            'No Quotes Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to create your first quote!',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _showActionsMenu(BuildContext context, Quote q) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View / Preview'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/preview', arguments: q)
                      .then((_) => _loadQuotes());
                },
              ),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Print Quote'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await PdfService.printQuote(q);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share as PDF'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await PdfService.shareQuote(q);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.send, color: Colors.orange),
                title: const Text('Mark as Sent'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(q, 'Sent');
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Accepted'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(q, 'Accepted');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete Quote'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _confirmDelete(q);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
