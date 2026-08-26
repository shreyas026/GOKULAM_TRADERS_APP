import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/products_provider.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import 'map_location_picker.dart';

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

  MapLocationPickerResult? _pickedLocation;

  StoreConfigModel? _store;

  double get _deliveryCharge {
    if (_deliveryType != 'home_delivery') return 0;
    if (_pickedLocation == null) return _store?.deliveryChargePerHalfKm ?? AppConfig.deliveryChargePerHalfKm;
    return AppConfig.deliveryChargeForDistanceBooking(
        _pickedLocation!.distanceKm, _store?.deliveryChargePerHalfKm ?? AppConfig.deliveryChargePerHalfKm);
  }

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  void _loadStore() async {
    final store = await ref.read(storeConfigProvider.future);
    if (mounted) setState(() => _store = store);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final store = await ref.read(storeConfigProvider.future);
    if (!mounted) return;
    final result = await Navigator.push<MapLocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          storePoint: LatLng(store.latitude, store.longitude),
          radiusKm: store.deliveryRadiusKm,
          chargePerHalfKm: store.deliveryChargePerHalfKm,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _pickedLocation = result;
        _selectedAddressId = result.address?.id;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_deliveryType == 'home_delivery' && _selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery location on the map'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isPlacing = true);
    final notifier = ref.read(ordersProvider.notifier);
    final data = <String, dynamic>{
      'delivery_type': _deliveryType,
      'payment_method': _paymentMethod,
      'notes': _notesController.text,
    };
    if (_deliveryType == 'home_delivery') {
      data['address_id'] = _selectedAddressId;
    }
    final result = await notifier.createOrder(data);
    setState(() => _isPlacing = false);
    if (result['success'] == true) {
      ref.read(cartProvider.notifier).clearCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully!')));
        context.go('/orders');
      }
    } else {
      String errorMsg = _friendlyError(result['error'].toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
      }
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('5 km')) return raw;
    if (raw.contains('stock')) return raw;
    if (raw.contains('Credit limit')) return raw;
    if (raw.contains('Delivery address required')) return 'Please select a valid delivery location.';
    return 'Failed to place order. Please check your details and try again.';
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
                  onSelectionChanged: (v) => setState(() {
                    _deliveryType = v.first;
                    if (_deliveryType == 'takeaway') {
                      _selectedAddressId = null;
                      _pickedLocation = null;
                    }
                  }),
                ),
                const SizedBox(height: 20),

                if (_deliveryType == 'home_delivery') ...[
                  const Text('Delivery Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_pickedLocation != null) ...[
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _pickedLocation!.distanceKm <= (_store?.deliveryRadiusKm ?? 5)
                              ? AppTheme.primaryColor
                              : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _pickedLocation!.distanceKm <= (_store?.deliveryRadiusKm ?? 5)
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _pickedLocation!.distanceKm <= (_store?.deliveryRadiusKm ?? 5)
                                      ? AppTheme.successColor
                                      : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_pickedLocation!.distanceKm.toStringAsFixed(1)} km from store',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _pickedLocation!.distanceKm <= (_store?.deliveryRadiusKm ?? 5)
                                        ? AppTheme.successColor
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            if (_pickedLocation!.address != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _pickedLocation!.address!.fullAddress.isNotEmpty
                                    ? _pickedLocation!.address!.fullAddress
                                    : 'Location selected on map',
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openMapPicker,
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text('Change Location'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openMapPicker,
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text('Select Delivery Location on Map'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppTheme.primaryColor),
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to open map and mark your delivery location within 5 km of the store',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],

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
                    Text('₹${_deliveryCharge.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16)),
                  ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('₹${(_deliveryType == 'home_delivery' ? cart.total + _deliveryCharge : cart.total).toStringAsFixed(0)}',
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
