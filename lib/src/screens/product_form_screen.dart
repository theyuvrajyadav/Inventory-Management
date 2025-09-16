// Offline app: no Firestore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';
import '../models/product.dart';
import '../providers/product_providers.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.existing});
  final Product? existing;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _data = <String, dynamic>{
    'productName': '',
    'barcode': '',
    'category': '',
    'size': '',
    'color': '',
    'purchasePrice': 0.0,
    'sellingPrice': 0.0,
    'quantity': 0,
    'supplierName': '',
    'imageUrl': '',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _data
        ..['productName'] = e.productName
        ..['barcode'] = e.barcode
        ..['category'] = e.category
        ..['size'] = e.size
        ..['color'] = e.color
        ..['purchasePrice'] = e.purchasePrice
        ..['sellingPrice'] = e.sellingPrice
        ..['quantity'] = e.quantity
        ..['supplierName'] = e.supplierName ?? ''
        ..['imageUrl'] = e.imageUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final products = ref.read(productsProvider.notifier);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Update Product' : 'Add New Product', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _field('Product Name', 'productName'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _field('Barcode', 'barcode'),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _scanAndFillBarcode(context),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan'),
                      ),
                    ],
                  ),
                  _field('Category', 'category'),
                  _field('Size', 'size'),
                  _field('Color', 'color'),
                  _numField('Purchase Price', 'purchasePrice'),
                  _numField('Selling Price', 'sellingPrice'),
                  _intField('Quantity', 'quantity'),
                  _field('Supplier (optional)', 'supplierName', requiredField: false),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _field('Image Path (optional)', 'imageUrl', requiredField: false),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickImageFromSystem,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Browse...'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(children: [
                FilledButton.icon(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    _formKey.currentState!.save();
                    final now = DateTime.now();
                    if (isEdit) {
                      final updated = widget.existing!.copyWith(
                        productName: _data['productName'],
                        barcode: _data['barcode'],
                        category: _data['category'],
                        size: _data['size'],
                        color: _data['color'],
                        purchasePrice: _data['purchasePrice'],
                        sellingPrice: _data['sellingPrice'],
                        quantity: _data['quantity'],
                        supplierName: (_data['supplierName'] as String).isEmpty ? null : _data['supplierName'],
                        imageUrl: _data['imageUrl'],
                      );
                      await products.addOrUpdate(updated);
                    } else {
                      final p = Product(
                        id: const Uuid().v4(),
                        productName: _data['productName'],
                        barcode: _data['barcode'],
                        category: _data['category'],
                        size: _data['size'],
                        color: _data['color'],
                        purchasePrice: _data['purchasePrice'],
                        sellingPrice: _data['sellingPrice'],
                        quantity: _data['quantity'],
                        supplierName: (_data['supplierName'] as String).isEmpty ? null : _data['supplierName'],
                        dateAdded: now,
                        imageUrl: _data['imageUrl'],
                      );
                      await products.addOrUpdate(p);
                    }
                    if (!mounted) return;
                    final message = isEdit ? 'Product updated' : 'Product added';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                  },
                  icon: const Icon(Icons.save),
                  label: Text(isEdit ? 'Save Changes' : 'Add Product'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanAndFillBarcode(BuildContext context) async {
    // Use a simple dialog with MobileScanner to scan and fill the barcode.
    final controller = MobileScannerController();
    String? code;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Barcode'),
        content: SizedBox(
          width: 400,
          height: 250,
          child: MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
              if (raw != null) {
                code = raw;
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ),
    );
    await controller.dispose();
    if (code != null) {
      setState(() {
        _data['barcode'] = code!;
      });
    }
  }

  Future<void> _pickImageFromSystem() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _data['imageUrl'] = result.files.single.path!;
      });
    }
  }

  Widget _field(String label, String keyName, {bool requiredField = true}) {
    return SizedBox(
      width: 300,
      child: TextFormField(
        initialValue: (_data[keyName] ?? '').toString(),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) {
          if (!requiredField) return null;
          return (v == null || v.trim().isEmpty) ? 'Required' : null;
        },
        onSaved: (v) => _data[keyName] = v!.trim(),
      ),
    );
  }

  Widget _numField(String label, String keyName) {
    return SizedBox(
      width: 300,
      child: TextFormField(
        initialValue: (_data[keyName] ?? 0.0).toString(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter number' : null,
        onSaved: (v) => _data[keyName] = double.parse(v!),
      ),
    );
  }

  Widget _intField(String label, String keyName) {
    return SizedBox(
      width: 300,
      child: TextFormField(
        initialValue: (_data[keyName] ?? 0).toString(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter integer' : null,
        onSaved: (v) => _data[keyName] = int.parse(v!),
      ),
    );
  }
}


