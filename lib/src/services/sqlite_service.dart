import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/product.dart';

class SqliteService {
  Database? _db;

  Future<void> init() async {
    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'inventory.db');
    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE products (
          id TEXT PRIMARY KEY,
          productName TEXT,
          barcode TEXT,
          category TEXT,
          size TEXT,
          color TEXT,
          purchasePrice REAL,
          sellingPrice REAL,
          quantity INTEGER,
          supplierName TEXT,
          dateAdded INTEGER,
          imageUrl TEXT
        )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);');

        await db.execute('''
        CREATE TABLE sales (
          id TEXT PRIMARY KEY,
          date INTEGER,
          total REAL,
          customer_name TEXT,
          customer_phone TEXT
        )
        ''');
        await db.execute('''
        CREATE TABLE sale_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id TEXT,
          product_id TEXT,
          quantity INTEGER,
          price REAL
        )
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute('''
          CREATE TABLE IF NOT EXISTS sales (
            id TEXT PRIMARY KEY,
            date INTEGER,
            total REAL,
            customer_name TEXT,
            customer_phone TEXT
          )
          ''');
          await db.execute('''
          CREATE TABLE IF NOT EXISTS sale_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id TEXT,
            product_id TEXT,
            quantity INTEGER,
            price REAL
          )
          ''');
        }
        if (oldV < 3) {
          // Add customer columns if not present
          await db.execute('ALTER TABLE sales ADD COLUMN customer_name TEXT');
          await db.execute('ALTER TABLE sales ADD COLUMN customer_phone TEXT');
        }
      },
    );
  }

  Future<List<Product>> getAllProducts() async {
    final rows = await _db!.query('products', orderBy: 'dateAdded DESC');
    return rows.map((e) => Product.fromMap(e)).toList();
    }

  Future<void> upsertProduct(Product product) async {
    await _db!.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteProduct(String id) async {
    await _db!.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<Product?> findByBarcode(String barcode) async {
    final rows = await _db!.query('products', where: 'barcode = ?', whereArgs: [barcode], limit: 1);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<void> adjustStock(String id, int delta) async {
    await _db!.rawUpdate('UPDATE products SET quantity = quantity + ? WHERE id = ?', [delta, id]);
  }

  Future<void> recordSale({
    required String saleId,
    required List<Map<String, dynamic>> items, // {productId, quantity, price}
    String? customerName,
    String? customerPhone,
  }) async {
    final total = items.fold<double>(0, (a, b) => a + (b['price'] as num) * (b['quantity'] as num));
    await _db!.transaction((txn) async {
      await txn.insert('sales', {
        'id': saleId,
        'date': DateTime.now().toUtc().millisecondsSinceEpoch,
        'total': total,
        'customer_name': customerName,
        'customer_phone': customerPhone,
      });
      for (final it in items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': it['productId'],
          'quantity': it['quantity'],
          'price': it['price'],
        });
        await txn.rawUpdate('UPDATE products SET quantity = quantity - ? WHERE id = ?', [it['quantity'], it['productId']]);
      }
    });
  }

  Future<List<Map<String, dynamic>>> fetchSales() async {
    return await _db!.query('sales', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> fetchSaleItems(String saleId) async {
    // Join with products to get productName for display
    return await _db!.rawQuery('''
      SELECT si.product_id, si.quantity, si.price, p.productName
      FROM sale_items si
      LEFT JOIN products p ON p.id = si.product_id
      WHERE si.sale_id = ?
    ''', [saleId]);
  }
}


