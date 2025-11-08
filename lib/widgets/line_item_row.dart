import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/line_item.dart';
import '../utils/formatter.dart';

class LineItemRow extends StatelessWidget {
  final int index;
  final LineItem item;
  final void Function(int, LineItem) onChanged;
  final void Function(int) onRemove;

  const LineItemRow({
    Key? key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spacing = const SizedBox(width: 8);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                // Product / Service
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: item.name,
                    decoration: const InputDecoration(
                      labelText: 'Product / Service',
                    ),
                    onChanged: (v) => onChanged(index, item..name = v),
                  ),
                ),
                spacing,
                // Quantity
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => onChanged(
                      index,
                      item..quantity = double.tryParse(v) ?? 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Rate
                Expanded(
                  child: TextFormField(
                    initialValue: item.rate.toString(),
                    decoration: const InputDecoration(labelText: 'Rate'),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => onChanged(
                      index,
                      item..rate = double.tryParse(v) ?? 0,
                    ),
                  ),
                ),
                spacing,
                // Discount
                Expanded(
                  child: TextFormField(
                    initialValue: item.discount.toString(),
                    decoration: const InputDecoration(labelText: 'Discount'),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => onChanged(
                      index,
                      item..discount = double.tryParse(v) ?? 0,
                    ),
                  ),
                ),
                spacing,
                // Tax %
                Expanded(
                  child: TextFormField(
                    initialValue: item.taxPercent.toString(),
                    decoration: const InputDecoration(labelText: 'Tax %'),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => onChanged(
                      index,
                      item..taxPercent = double.tryParse(v) ?? 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Item total:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  fmt(item.total(taxExclusive: true)),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => onRemove(index),
                  icon: Icon(Icons.delete, color: Colors.red.shade400),
                  tooltip: 'Remove item',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
