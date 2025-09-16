import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/product_providers.dart';
import '../services/sqlite_service.dart';
import '../models/product.dart';

class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  String _query = '';
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name or barcode', border: OutlineInputBorder()),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: cart.isEmpty ? null : _checkout,
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text('Checkout (${cart.length})'),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _customerNameCtrl,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person), hintText: 'Customer name (optional)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _customerPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.phone), hintText: 'Contact number (optional)', border: OutlineInputBorder()),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    final filtered = products.where((p) => _query.isEmpty || p.productName.toLowerCase().contains(_query) || p.barcode.toLowerCase().contains(_query)).toList();
                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        return ListTile(
                          title: Text(p.productName),
                          subtitle: Text('Barcode: ${p.barcode} • In stock: ${p.quantity} • Price: ${p.sellingPrice.toStringAsFixed(2)}'),
                          trailing: IconButton(icon: const Icon(Icons.add_shopping_cart), onPressed: p.quantity <= 0 ? null : () => ref.read(cartProvider.notifier).add(p)),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
              const VerticalDivider(width: 1),
              SizedBox(
                width: 360,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Align(alignment: Alignment.centerLeft, child: Text('Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: cart.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, i) {
                          final item = cart[i];
                          return ListTile(
                            title: Text(item.product.productName),
                            subtitle: Text('Price: ${item.product.sellingPrice.toStringAsFixed(2)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.remove), onPressed: () => ref.read(cartProvider.notifier).setQty(item.product.id, item.quantity - 1)),
                                SizedBox(
                                  width: 40,
                                  child: Text('${item.quantity}', textAlign: TextAlign.center),
                                ),
                                IconButton(icon: const Icon(Icons.add), onPressed: () => ref.read(cartProvider.notifier).setQty(item.product.id, item.quantity + 1)),
                                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => ref.read(cartProvider.notifier).remove(item.product.id)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text('Total: ${ref.read(cartProvider.notifier).total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: cart.isEmpty ? null : _checkout,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Pay & Save'),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Future<void> _checkout() async {
    final notifier = ref.read(productsProvider.notifier);
    final cart = ref.read(cartProvider);
    final db = ref.read(sqliteServiceProvider);
    final items = cart
        .map((e) => {
              'productId': e.product.id,
              'quantity': e.quantity,
              'price': e.product.sellingPrice,
            })
        .toList();
    await db.recordSale(
      saleId: const Uuid().v4(),
      items: items,
      customerName: _customerNameCtrl.text.trim().isEmpty ? null : _customerNameCtrl.text.trim(),
      customerPhone: _customerPhoneCtrl.text.trim().isEmpty ? null : _customerPhoneCtrl.text.trim(),
    );
    await notifier.load();
    ref.read(cartProvider.notifier).clear();
    _customerNameCtrl.clear();
    _customerPhoneCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale recorded')));
    }
  }
}


