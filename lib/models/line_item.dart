class LineItem {
  String id;
  String name;
  double quantity;
  double rate;
  double discount; // absolute per unit
  double taxPercent;

  LineItem({
    required this.id,
    this.name = '',
    this.quantity = 1,
    this.rate = 0,
    this.discount = 0,
    this.taxPercent = 0,
  });

  double get netRate => (rate - discount);

  double baseAmount() => netRate * quantity;

  double taxAmount() => baseAmount() * taxPercent / 100;

  double total({required bool taxExclusive}) {
    final base = baseAmount();
    return taxExclusive ? base + taxAmount() : base;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'rate': rate,
    'discount': discount,
    'taxPercent': taxPercent,
  };

  static LineItem fromJson(Map<String, dynamic> m) => LineItem(
    id: m['id'] as String,
    name: m['name'] as String? ?? '',
    quantity: (m['quantity'] as num?)?.toDouble() ?? 0.0,
    rate: (m['rate'] as num?)?.toDouble() ?? 0.0,
    discount: (m['discount'] as num?)?.toDouble() ?? 0.0,
    taxPercent: (m['taxPercent'] as num?)?.toDouble() ?? 0.0,
  );
}