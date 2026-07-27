import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/products_provider.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../widgets/barcode_scanner_dialog.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _searchController = TextEditingController();
  final _billItems = <Map<String, dynamic>>[];
  double _subtotal = 0;
  double _gstTotal = 0;
  double _grandTotal = 0;
  String _customerName = 'Walk-in Customer';

  void _addProduct(ProductModel product) {
    setState(() {
      final existing = _billItems.indexWhere((i) => i['product'].id == product.id);
      if (existing >= 0) {
        _billItems[existing]['quantity']++;
        _billItems[existing]['total'] = product.sellingPrice * _billItems[existing]['quantity'];
      } else {
        _billItems.add({
          'product': product,
          'quantity': 1,
          'price': product.sellingPrice,
          'gst': product.gstPercent,
          'total': product.sellingPrice,
        });
      }
      _calculateTotals();
    });
  }

  void _scanBarcode() {
    showDialog(
      context: context,
      builder: (_) => BarcodeScannerDialog(
        onScan: (code) {
          _searchController.text = code;
          setState(() {});
        },
      ),
    );
  }

  void _calculateTotals() {
    _subtotal = 0;
    _gstTotal = 0;
    for (final item in _billItems) {
      final product = item['product'] as ProductModel;
      final qty = item['quantity'] as int;
      final price = product.sellingPrice * qty;
      _subtotal += price;
      _gstTotal += price * product.gstPercent / 100;
    }
    _grandTotal = _subtotal + _gstTotal;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(_searchController.text));

    return Scaffold(
      appBar: AppBar(title: const Text('Billing')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, SKU, or barcode',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _scanBarcode),
                  ]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _customerName = v.isEmpty ? 'Walk-in Customer' : v,
              ),
            ]),
          ),
          Expanded(
            flex: 3,
            child: productsAsync.when(
              data: (products) => _searchController.text.isEmpty
                  ? const Center(child: Text('Search for products'))
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(imageUrl: products[i].primaryImage, width: 40, height: 40, fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.grey[200]),
                            errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 20)),
                          ),
                        ),
                        title: Text(products[i].name, style: const TextStyle(fontSize: 14)),
                        subtitle: Text('₹${products[i].sellingPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                          onPressed: () => _addProduct(products[i]),
                        ),
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Failed to load')),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 2,
            child: _billItems.isEmpty
                ? const Center(child: Text('No items added'))
                : ListView.builder(
                    itemCount: _billItems.length,
                    itemBuilder: (_, i) {
                      final item = _billItems[i];
                      final product = item['product'] as ProductModel;
                      return ListTile(
                        dense: true,
                        title: Text(product.name, style: const TextStyle(fontSize: 12)),
                        subtitle: Text('Qty: ${item['quantity']} x ₹${product.sellingPrice.toStringAsFixed(0)}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('₹${(item['total'] as double).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor), onPressed: () {
                            setState(() { _billItems.removeAt(i); _calculateTotals(); });
                          }),
                        ]),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10)]),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal:'), Text('₹${_subtotal.toStringAsFixed(0)}')]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('GST:'), Text('₹${_gstTotal.toStringAsFixed(0)}')]),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('₹${_grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 44,
                child: ElevatedButton.icon(
                  onPressed: _billItems.isEmpty ? null : () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice generated successfully')));
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Generate Invoice'),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}