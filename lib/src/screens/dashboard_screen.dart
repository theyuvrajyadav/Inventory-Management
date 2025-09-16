import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_providers.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(productsProvider);
    final threshold = ref.watch(lowStockThresholdProvider);
    return asyncProducts.when(
      data: (products) => _DashboardContent(products: products, threshold: threshold),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.products, required this.threshold});
  final List<Product> products;
  final int threshold;

  @override
  Widget build(BuildContext context) {
    final numProducts = products.length;
    final totalQty = products.fold<int>(0, (a, b) => a + b.quantity);
    final lowStockCount = products.where((p) => p.isLowStock(threshold)).length;
    final inventoryValue = products.fold<double>(0, (a, b) => a + b.inventoryValue);
    final c = NumberFormat.currency(symbol: '₹');

    Widget card(String title, String value, {Color? color, IconData? icon}) {
      final theme = Theme.of(context);
      return Card(
        color: color?.withValues(alpha: 0.07),
        child: SizedBox.expand(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 8),
                ],
                Text(title, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8))),
                const SizedBox(height: 8),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final gridCount = isWide ? 4 : 2;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: gridCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          card('Products', '$numProducts', icon: Icons.style, color: Colors.purple),
          card('Total Quantity', '$totalQty', icon: Icons.numbers, color: Colors.blue),
          card('Low Stock (<5)', '$lowStockCount', icon: Icons.warning_amber_outlined, color: Colors.red),
          card('Inventory Value', c.format(inventoryValue), icon: Icons.currency_rupee, color: Colors.teal),
        ],
      ),
    );
  }
}


