import 'line_item.dart';

class Quote {
  String id;
  String clientName;
  String clientAddress;
  String clientRef;
  String status; // 'Draft', 'Sent', 'Accepted'
  DateTime createdAt;
  bool taxExclusive;
  List<LineItem> items;

  Quote({
    required this.id,
    this.clientName = '',
    this.clientAddress = '',
    this.clientRef = '',
    this.status = 'Draft', // Default
    DateTime? createdAt,
    this.taxExclusive = true,
    List<LineItem>? items,
  })  : createdAt = createdAt ?? DateTime.now(),
        items = items ?? [];

  double subtotal() => items.fold(0, (p, e) => p + e.baseAmount());
  double totalTax() => items.fold(0, (p, e) => p + e.taxAmount());
  double grandTotal() => taxExclusive ? subtotal() + totalTax() : subtotal();

  Map<String, dynamic> toDbMap() => {
    'id': id,
    'clientName': clientName,
    'clientAddress': clientAddress,
    'clientRef': clientRef,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'taxExclusive': taxExclusive ? 1 : 0,
    'items': items.map((e) => e.toJson()).toList(),
  };

  static Quote fromDbMap(Map<String, dynamic> m) {
    final items = (m['items'] as List)
        .map((e) => LineItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return Quote(
      id: m['id'],
      clientName: m['clientName'] ?? '',
      clientAddress: m['clientAddress'] ?? '',
      clientRef: m['clientRef'] ?? '',
      status: m['status'] ?? 'Draft',
      createdAt: DateTime.parse(m['createdAt']),
      taxExclusive: (m['taxExclusive'] as int) == 1,
      items: items,
    );
  }
}
