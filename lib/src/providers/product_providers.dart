import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/sqlite_service.dart';

final sqliteServiceProvider = Provider<SqliteService>((ref) {
  return SqliteService();
});

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  ProductsNotifier(this._db) : super(const AsyncValue.loading());
  final SqliteService _db;

  Future<void> load() async {
    try {
      final list = await _db.getAllProducts();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addOrUpdate(Product p) async {
    await _db.upsertProduct(p);
    await load();
  }

  Future<void> remove(String id) async {
    await _db.deleteProduct(id);
    await load();
  }

  Future<void> adjust(String id, int delta) async {
    await _db.adjustStock(id, delta);
    await load();
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  final db = ref.watch(sqliteServiceProvider);
  final notifier = ProductsNotifier(db);
  // Kick initial load after init occurs externally in main.
  return notifier;
});

final lowStockThresholdProvider = StateProvider<int>((ref) => 5);

class CartItem {
  CartItem({required this.product, required this.quantity});
  final Product product;
  int quantity;
  double get lineTotal => product.sellingPrice * quantity;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []);

  void add(Product product, {int qty = 1}) {
    final existingIndex = state.indexWhere((e) => e.product.id == product.id);
    if (existingIndex >= 0) {
      final updated = [...state];
      updated[existingIndex].quantity += qty;
      state = updated;
    } else {
      state = [...state, CartItem(product: product, quantity: qty)];
    }
  }

  void setQty(String productId, int qty) {
    final idx = state.indexWhere((e) => e.product.id == productId);
    if (idx < 0) return;
    final updated = [...state];
    updated[idx].quantity = qty.clamp(1, 999999);
    state = updated;
  }

  void remove(String productId) {
    state = state.where((e) => e.product.id != productId).toList();
  }

  void clear() => state = const [];

  double get total => state.fold(0, (a, b) => a + b.lineTotal);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());


