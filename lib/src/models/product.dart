// Offline model for SQLite

class Product {
  final String id;
  final String productName;
  final String barcode;
  final String category;
  final String size;
  final String color;
  final double purchasePrice;
  final double sellingPrice;
  final int quantity;
  final String? supplierName;
  final DateTime dateAdded;
  final String imageUrl;

  const Product({
    required this.id,
    required this.productName,
    required this.barcode,
    required this.category,
    required this.size,
    required this.color,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    required this.supplierName,
    required this.dateAdded,
    required this.imageUrl,
  });

  double get inventoryValue => purchasePrice * quantity;
  bool isLowStock([int threshold = 5]) => quantity < threshold;

  Product copyWith({
    String? id,
    String? productName,
    String? barcode,
    String? category,
    String? size,
    String? color,
    double? purchasePrice,
    double? sellingPrice,
    int? quantity,
    String? supplierName,
    DateTime? dateAdded,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      size: size ?? this.size,
      color: color ?? this.color,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      supplierName: supplierName ?? this.supplierName,
      dateAdded: dateAdded ?? this.dateAdded,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      id: data['id'] as String,
      productName: data['productName'] as String? ?? '',
      barcode: data['barcode'] as String? ?? '',
      category: data['category'] as String? ?? '',
      size: data['size'] as String? ?? '',
      color: data['color'] as String? ?? '',
      purchasePrice: (data['purchasePrice'] as num? ?? 0).toDouble(),
      sellingPrice: (data['sellingPrice'] as num? ?? 0).toDouble(),
      quantity: (data['quantity'] as num? ?? 0).toInt(),
      supplierName: data['supplierName'] as String?,
      dateAdded: DateTime.fromMillisecondsSinceEpoch((data['dateAdded'] as num? ?? 0).toInt(), isUtc: true).toLocal(),
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'barcode': barcode,
      'category': category,
      'size': size,
      'color': color,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'supplierName': supplierName,
      'dateAdded': dateAdded.toUtc().millisecondsSinceEpoch,
      'imageUrl': imageUrl,
    };
  }
}


