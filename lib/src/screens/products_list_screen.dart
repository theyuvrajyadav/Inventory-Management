import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_providers.dart';
import '../models/product.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  String _query = '';
  String _filterCategory = '';
  String _filterSize = '';
  String _filterColor = '';
  // Threshold managed via provider; no local state needed.

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(productsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by name or barcode',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _openFilters(context),
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filters',
            )
          ]),
        ),
        Expanded(
          child: asyncProducts.when(
            data: (products) {
              var filtered = products.where((p) {
                final matchesQuery = _query.isEmpty ||
                    p.productName.toLowerCase().contains(_query) ||
                    p.barcode.toLowerCase().contains(_query);
                final matchesCategory = _filterCategory.isEmpty || p.category == _filterCategory;
                final matchesSize = _filterSize.isEmpty || p.size == _filterSize;
                final matchesColor = _filterColor.isEmpty || p.color == _filterColor;
                return matchesQuery && matchesCategory && matchesSize && matchesColor;
              }).toList();
              filtered.sort((a, b) => a.productName.compareTo(b.productName));
              final threshold = ref.watch(lowStockThresholdProvider);
              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, i) => _ProductTile(product: filtered[i], threshold: threshold),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        final asyncProducts = ref.read(productsProvider);
        final categories = <String>{};
        final sizes = <String>{};
        final colors = <String>{};
        asyncProducts.whenData((list) {
          for (final p in list) {
            if (p.category.isNotEmpty) categories.add(p.category);
            if (p.size.isNotEmpty) sizes.add(p.size);
            if (p.color.isNotEmpty) colors.add(p.color);
          }
        });
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filterDropdown('Category', categories.toList(), _filterCategory, (v) => setState(() => _filterCategory = v)),
              const SizedBox(height: 8),
              _filterDropdown('Size', sizes.toList(), _filterSize, (v) => setState(() => _filterSize = v)),
              const SizedBox(height: 8),
              _filterDropdown('Color', colors.toList(), _filterColor, (v) => setState(() => _filterColor = v)),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _filterCategory = '';
                        _filterSize = '';
                        _filterColor = '';
                      });
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Apply'),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _filterDropdown(String label, List<String> items, String value, ValueChanged<String> onChanged) {
    items.sort();
    return Row(children: [
      SizedBox(width: 100, child: Text(label)),
      const SizedBox(width: 12),
      Expanded(
        child: DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          items: [
            const DropdownMenuItem(value: '', child: Text('Any')),
            ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
          ],
          onChanged: (v) => onChanged(v ?? ''),
        ),
      ),
    ]);
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product, required this.threshold});
  final Product product;
  final int threshold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(productsProvider.notifier);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: product.isLowStock(threshold) ? Colors.red.shade100 : Colors.green.shade100,
        child: Icon(product.isLowStock(threshold) ? Icons.warning_amber : Icons.check, color: product.isLowStock(threshold) ? Colors.red : Colors.green),
      ),
      title: Text(product.productName),
      subtitle: Text('Barcode: ${product.barcode} • Qty: ${product.quantity} • Price: ${product.sellingPrice.toStringAsFixed(2)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => notifier.adjust(product.id, -1),
            tooltip: 'Decrement',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => notifier.adjust(product.id, 1),
            tooltip: 'Increment',
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete product?'),
                    content: Text('Remove ${product.productName}?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await notifier.remove(product.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
                  }
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}


