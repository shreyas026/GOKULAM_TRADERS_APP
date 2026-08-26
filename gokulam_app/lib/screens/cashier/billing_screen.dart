import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/products_provider.dart';
import '../../providers/orders_provider.dart';
import '../../services/invoice_service.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
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
  String _deliveryType = 'takeaway';
  String _paymentMethod = 'cash';
  final _addressController = TextEditingController();
  bool _creating = false;
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _addProduct(ProductModel product) {
    setState(() {
      final existing = _billItems.indexWhere((i) => (i['product'] as ProductModel).id == product.id);
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
    _grandTotal = _subtotal + _gstTotal + (_deliveryType == 'home_delivery' ? 20 : 0);
  }

  Future<void> _createOrder() async {
    if (_billItems.isEmpty) return;
    setState(() => _creating = true);

    final api = ApiService();
    final items = _billItems.map((i) {
      final p = i['product'] as ProductModel;
      return {'product_id': p.id, 'quantity': i['quantity']};
    }).toList();

    try {
      final cartRes = await api.get(ApiEndpoints.cart);
      await api.delete(ApiEndpoints.cart);

      for (final item in items) {
        await api.post(ApiEndpoints.cart, data: item);
      }

      final orderRes = await api.post(ApiEndpoints.orderCreate, data: {
        'delivery_type': _deliveryType,
        'payment_method': _paymentMethod,
        'delivery_address_text': _addressController.text.trim(),
        'notes': 'Created by cashier for $_customerName${_addressController.text.trim().isNotEmpty ? ' | Delivery: ${_addressController.text.trim()}' : ''}',
      });

      final order = OrderDetailModel.fromJson(orderRes.data);
      ref.read(ordersProvider.notifier).loadOrders();

      if (mounted) {
        _showOrderCreatedDialog(order);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating order: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
    setState(() => _creating = false);
  }

  void _showOrderCreatedDialog(OrderDetailModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text('Invoice #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.successColor, borderRadius: BorderRadius.circular(12)),
                    child: Text('₹${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: PdfPreview(
                build: (format) => InvoiceService.generateInvoicePdf(order).then((doc) => doc.save()),
                canChangePageFormat: false,
                canDebug: false,
                actions: [],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await InvoiceService.printInvoice(order);
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showWhatsAppDialog(order);
                      },
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetBilling();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWhatsAppDialog(OrderDetailModel order) {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Invoice via WhatsApp'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Customer Phone Number',
            hintText: 'e.g. 919876543210',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
            onPressed: () {
              final phone = phoneController.text.trim();
              Navigator.pop(ctx);
              if (phone.isNotEmpty) {
                InvoiceService.sendViaWhatsApp(order, phone);
              }
              _resetBilling();
            },
          ),
        ],
      ),
    );
  }

  void _resetBilling() {
    setState(() {
      _billItems.clear();
      _subtotal = 0;
      _gstTotal = 0;
      _grandTotal = 0;
      _customerName = 'Walk-in Customer';
      _searchController.clear();
      _addressController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(_searchQuery));

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
                  suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () {
                    showDialog(context: context, builder: (_) => BarcodeScannerDialog(onScan: (code) {
                      _searchController.text = code;
                      setState(() {});
                    }));
                  }),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 350), () {
                    setState(() => _searchQuery = value.trim());
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Customer Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder(), isDense: true),
                    onChanged: (v) => _customerName = v.isEmpty ? 'Walk-in Customer' : v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _deliveryType,
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'takeaway', child: Text('Takeaway')),
                      DropdownMenuItem(value: 'home_delivery', child: Text('Home Delivery')),
                    ],
                    onChanged: (v) => setState(() { _deliveryType = v!; _calculateTotals(); }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(labelText: 'Payment', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'upi', child: Text('UPI')),
                      DropdownMenuItem(value: 'credit_card', child: Text('Card')),
                    ],
                    onChanged: (v) => setState(() => _paymentMethod = v!),
                  ),
                ),
              ]),
              if (_deliveryType == 'home_delivery') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Delivery Address', prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder(), isDense: true),
                  maxLines: 2,
                ),
              ],
            ]),
          ),
          Expanded(
            flex: 3,
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty && _searchQuery.isNotEmpty) {
                  return const Center(child: Text('No products found'));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_searchQuery.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text('${products.length} products available', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (_, i) => ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(imageUrl: products[i].primaryImage, width: 40, height: 40, fit: BoxFit.cover, memCacheWidth: 100, maxWidthDiskCache: 100,
                              placeholder: (_, __) => Container(color: Colors.grey[200]),
                              errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 20)),
                            ),
                          ),
                          title: Text(products[i].name, style: const TextStyle(fontSize: 14)),
                          subtitle: Text('₹${products[i].sellingPrice.toStringAsFixed(0)} | Stock: ${products[i].stock}', style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                            onPressed: () => _addProduct(products[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
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
              if (_deliveryType == 'home_delivery')
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Delivery:'), Text('₹20')]),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('₹${_grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 44,
                child: ElevatedButton.icon(
                  onPressed: _billItems.isEmpty || _creating ? null : _createOrder,
                  icon: _creating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.receipt_long),
                  label: Text(_creating ? 'Creating...' : 'Create Order & Send Invoice'),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
