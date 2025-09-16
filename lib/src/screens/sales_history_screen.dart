import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/sqlite_service.dart';
import '../models/sale.dart';
import '../providers/product_providers.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  late Future<List<Sale>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Sale>> _load() async {
    final db = ref.read(sqliteServiceProvider);
    final rows = await db.fetchSales();
    return rows.map((e) => Sale.fromMap(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = NumberFormat.currency(symbol: '₹');
    final d = DateFormat.yMMMd().add_jm();
    return FutureBuilder<List<Sale>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final sales = snapshot.data ?? const [];
        if (sales.isEmpty) return const Center(child: Text('No sales yet'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: sales.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, i) {
            final s = sales[i];
            final subtitle = [
              if (s.customerName != null && s.customerName!.isNotEmpty) s.customerName!,
              if (s.customerPhone != null && s.customerPhone!.isNotEmpty) s.customerPhone!,
            ].join(' • ');
            return ExpansionTile(
              title: Text('${d.format(s.date)} • ${c.format(s.total)}'),
              subtitle: subtitle.isEmpty ? null : Text(subtitle),
              children: [
                FutureBuilder<List<SaleItemRow>>(
                  future: _loadItems(s.id),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      );
                    }
                    final items = snap.data ?? const [];
                    return Column(
                      children: items
                          .map((it) => ListTile(
                                dense: true,
                                title: Text(it.productName),
                                subtitle: Text('Qty: ${it.quantity} × ${c.format(it.price)}'),
                                trailing: Text(c.format(it.quantity * it.price)),
                              ))
                          .toList(),
                    );
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<List<SaleItemRow>> _loadItems(String saleId) async {
    final db = ref.read(sqliteServiceProvider);
    final rows = await db.fetchSaleItems(saleId);
    return rows.map((e) => SaleItemRow.fromMap(e)).toList();
  }
}


