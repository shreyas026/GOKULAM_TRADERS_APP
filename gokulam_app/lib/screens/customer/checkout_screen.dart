import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../config/theme.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _deliveryType = 'home_delivery';
  int? _selectedAddressId;
  String _paymentMethod = 'cash';
  final _notesController = TextEditingController();
  bool _isPlacing = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    final notifier = ref.read(ordersProvider.notifier);
    final result = await notifier.createOrder({
      'delivery_type': _deliveryType,
      'address_id': _selectedAddressId,
      'payment_method': _paymentMethod,
      'notes': _notesController.text,
    });
    setState(() => _isPlacing = false);
    if (result['success'] == true) {
      ref.read(cartProvider.notifier).clearCart();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully!')));
      context.go('/orders');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: cartAsync.when(
        data: (cart) {
          if (cart.items.isEmpty) return const Center(child: Text('Cart is empty'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'home_delivery', label: Text('Home Delivery'), icon: Icon(Icons.local_shipping)),
                    ButtonSegment(value: 'takeaway', label: Text('Takeaway'), icon: Icon(Icons.store)),
                  ],
                  selected: {_deliveryType},
                  onSelectionChanged: (v) => setState(() => _deliveryType = v.first),
                ),
                const SizedBox(height: 20),
                const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                    DropdownMenuItem(value: 'debit_card', child: Text('Debit Card')),
                    DropdownMenuItem(value: 'net_banking', child: Text('Net Banking')),
                    DropdownMenuItem(value: 'credit', child: Text('Credit Account')),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Order Notes (optional)', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                  Text('₹${cart.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16)),
                ]),
                const SizedBox(height: 8),
                if (_deliveryType == 'home_delivery')
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Delivery Charge:', style: TextStyle(fontSize: 16)),
                    Text('₹20', style: const TextStyle(fontSize: 16)),
                  ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('₹${(_deliveryType == 'home_delivery' ? cart.total + 20 : cart.total).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: _isPlacing ? null : _placeOrder,
                    child: _isPlacing
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Place Order', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
      ),
    );
  }
}