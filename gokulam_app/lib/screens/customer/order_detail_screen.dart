import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/orders_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/invoice_service.dart';
import '../../models/order_model.dart';
import '../../config/theme.dart';
import '../../widgets/delivery_map_view.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isPrinting = false;
  bool _isSharing = false;
  Map<String, dynamic>? _tracking;
  Timer? _trackTimer;

  void _showWhatsAppDialog(OrderDetailModel order) {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send via WhatsApp'),
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
            onPressed: () {
              Navigator.pop(ctx);
              final phone = phoneController.text.trim();
              if (phone.isNotEmpty) {
                InvoiceService.sendViaWhatsApp(order, phone);
              }
            },
          ),
        ],
      ),
    );
  }

  void _startTracking(OrderDetailModel order) {
    _trackTimer?.cancel();
    _pollTracking(order);
    _trackTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pollTracking(order));
  }

  Future<void> _pollTracking(OrderDetailModel order) async {
    final data = await ref.read(ordersProvider.notifier).getTracking(order.id);
    if (!mounted) return;
    setState(() {
      if (data != null) _tracking = data;
    });
  }

  @override
  void dispose() {
    _trackTimer?.cancel();
    super.dispose();
  }

  List<String> _getFlowSteps(String deliveryType) {
    if (deliveryType == 'takeaway') {
      return ['pending', 'confirmed', 'packed', 'delivered'];
    }
    return ['pending', 'confirmed', 'packed', 'shipped', 'out_for_delivery', 'delivered'];
  }

  String? _getNextStatus(String currentStatus, String deliveryType) {
    final steps = _getFlowSteps(deliveryType);
    final idx = steps.indexOf(currentStatus);
    if (idx >= 0 && idx < steps.length - 1) return steps[idx + 1];
    return null;
  }

  void _updateStatus(OrderDetailModel order, String newStatus) async {
    String note = '';
    if (newStatus == 'delivered') note = 'Delivered successfully';
    if (newStatus == 'cancelled') note = 'Order cancelled';
    await ref.read(ordersProvider.notifier).updateOrderStatus(order.id, newStatus, note: note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated to ${newStatus.replaceAll('_', ' ').toUpperCase()}'), backgroundColor: AppTheme.successColor),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).user?.role ?? 'customer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: FutureBuilder(
        future: ref.read(ordersProvider.notifier).getOrderDetail(widget.orderId),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final order = snap.data;
          if (order == null) return const Center(child: Text('Order not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusTimeline(order.status, order.deliveryType),
                const SizedBox(height: 16),
                _buildMapCard(order),
                const SizedBox(height: 16),
                Card(child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('Order #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: order.deliveryType == 'takeaway' ? Colors.blue.withAlpha(30) : Colors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(order.deliveryType == 'takeaway' ? 'Takeaway' : 'Home Delivery',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                            color: order.deliveryType == 'takeaway' ? Colors.blue : Colors.green)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _infoRow('Payment', order.paymentMethod.replaceAll('_', ' ').toUpperCase()),
                    _infoRow('Status', order.statusDisplay),
                    _infoRow('Total', '₹${order.totalAmount.toStringAsFixed(0)}'),
                    if (order.deliveryAddressDetail != null) _infoRow('Address', order.deliveryAddressDetail['full_address'] ?? ''),
                  ]),
                )),
                const SizedBox(height: 12),
                _buildActionButtons(order, role),
                const SizedBox(height: 16),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ...order.items.map((item) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(imageUrl: item.productImage, width: 50, height: 50, fit: BoxFit.cover, memCacheWidth: 120, maxWidthDiskCache: 120,
                        placeholder: (_, __) => Container(color: Colors.grey[200]),
                        errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                      ),
                    ),
                    title: Text(item.productName),
                    subtitle: Text('Qty: ${item.quantity} x ₹${item.price.toStringAsFixed(0)}'),
                    trailing: Text('₹${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapCard(OrderDetailModel order) {
    final addr = order.deliveryAddressDetail;
    final destLat = addr != null && addr['latitude'] != null
        ? double.tryParse(addr['latitude'].toString())
        : null;
    final destLng = addr != null && addr['longitude'] != null
        ? double.tryParse(addr['longitude'].toString())
        : null;

    if (order.deliveryType != 'home_delivery' || destLat == null || destLng == null) {
      return const SizedBox.shrink();
    }

    final dest = LatLng(destLat, destLng);
    final isDelivering = order.status == 'out_for_delivery' || order.status == 'delivered';

    if (isDelivering) {
      _startTracking(order);
    } else {
      _trackTimer?.cancel();
    }

    final trackingLat = _tracking?['lat'] != null ? double.tryParse(_tracking!['lat'].toString()) : order.currentLat;
    final trackingLng = _tracking?['lng'] != null ? double.tryParse(_tracking!['lng'].toString()) : order.currentLng;
    final hasAgent = isDelivering && trackingLat != null && trackingLng != null;
    final agent = hasAgent ? LatLng(trackingLat!, trackingLng!) : null;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                const Icon(Icons.map, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text('Delivery Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                if (hasAgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.green.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 6),
                      Text('Live', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    ]),
                  )
                else
                  Text(order.statusDisplay, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: DeliveryRadiusMap(
              center: agent ?? dest,
              marker: hasAgent ? agent : null,
              initialZoom: hasAgent ? 14 : 13,
            ),
          ),
          if (hasAgent)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.delivery_dining, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delivery agent${order.assignedTo != null ? ' (${order.assignedTo})' : ''} is on the way',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _canAdvance(String role, String status, String newStatus, String deliveryType) {
    if (newStatus == 'cancelled') return true;
    final allowed = {
      'admin': {'confirmed', 'packed', 'shipped', 'out_for_delivery', 'delivered', 'cancelled'},
      'cashier': {'confirmed', 'packed', 'cancelled'},
      'delivery': {'out_for_delivery', 'delivered'},
    }[role];
    if (allowed == null || !allowed.contains(newStatus)) return false;
    return _getNextStatus(status, deliveryType) == newStatus;
  }

  Widget _buildActionButtons(OrderDetailModel order, String role) {
    final nextStatus = _getNextStatus(order.status, order.deliveryType);
    final canCancel = role == 'admin' || role == 'cashier' || (role == 'customer' && order.status == 'pending');
    final canAdvance = nextStatus != null && _canAdvance(role, order.status, nextStatus, order.deliveryType);

    if (canAdvance || canCancel) {
      return Row(children: [
        if (canAdvance)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(order, nextStatus!),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text('Mark ${nextStatus!.replaceAll('_', ' ')}'),
            ),
          ),
        if (canAdvance && canCancel) const SizedBox(width: 8),
        if (canCancel)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _updateStatus(order, 'cancelled'),
              icon: const Icon(Icons.cancel, size: 18, color: AppTheme.errorColor),
              label: const Text('Cancel', style: TextStyle(color: AppTheme.errorColor)),
            ),
          ),
      ]);
    }

    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _showWhatsAppDialog(order),
          icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
          label: const Text('WhatsApp', style: TextStyle(color: Color(0xFF25D366))),
        ),
      ),
    ]);
  }

  Widget _buildStatusTimeline(String status, String deliveryType) {
    final steps = _getFlowSteps(deliveryType);
    final currentIndex = steps.indexOf(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(deliveryType == 'takeaway' ? 'Takeaway Order Flow' : 'Home Delivery Flow',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(steps.length, (i) {
                final isActive = i <= currentIndex;
                final isCurrent = i == currentIndex;
                return Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: isCurrent ? 18 : 14,
                        backgroundColor: isActive ? AppTheme.primaryColor : Colors.grey[300],
                        child: isCurrent
                            ? const Icon(Icons.radio_button_checked, color: Colors.white, size: 16)
                            : Icon(Icons.check, color: Colors.white, size: isCurrent ? 18 : 12),
                      ),
                      const SizedBox(height: 4),
                      Text(steps[i].replaceAll('_', '\n'),
                        style: TextStyle(fontSize: 9, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary),
                        textAlign: TextAlign.center),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
