class Sale {
  final String id;
  final DateTime date;
  final double total;
  final String? customerName;
  final String? customerPhone;

  const Sale({required this.id, required this.date, required this.total, this.customerName, this.customerPhone});

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch((map['date'] as num).toInt(), isUtc: true).toLocal(),
      total: (map['total'] as num).toDouble(),
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
    );
  }
}

class SaleItemRow {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  const SaleItemRow({required this.productId, required this.productName, required this.quantity, required this.price});

  factory SaleItemRow.fromMap(Map<String, dynamic> map) {
    return SaleItemRow(
      productId: map['product_id'] as String,
      productName: map['productName'] as String? ?? '',
      quantity: (map['quantity'] as num).toInt(),
      price: (map['price'] as num).toDouble(),
    );
  }
}


