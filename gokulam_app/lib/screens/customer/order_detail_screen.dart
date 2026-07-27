import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/orders_provider.dart';
import '../../services/invoice_service.dart';
import '../../models/order_model.dart';
import '../../config/theme.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isPrinting = false;
  bool _isSharing = false;

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
            hintText: 'e.g. 9876543210',
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

  @override
  Widget build(BuildContext context) {
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
                _buildStatusTimeline(order.status),
                const SizedBox(height: 16),
                Card(child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Order #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    _infoRow('Payment', order.paymentMethod.replaceAll('_', ' ').toUpperCase()),
                    _infoRow('Status', order.statusDisplay),
                    _infoRow('Total', '₹${order.totalAmount.toStringAsFixed(0)}'),
                    if (order.deliveryAddressDetail != null) _infoRow('Address', order.deliveryAddressDetail['full_address'] ?? ''),
                  ]),
                )),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPrinting ? null : () async {
                        setState(() => _isPrinting = true);
                        await InvoiceService.printInvoice(order);
                        setState(() => _isPrinting = false);
                      },
                      icon: _isPrinting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.print),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSharing ? null : () async {
                        setState(() => _isSharing = true);
                        await InvoiceService.shareInvoice(order);
                        setState(() => _isSharing = false);
                      },
                      icon: _isSharing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showWhatsAppDialog(order),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), minimumSize: const Size(0, 44)),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ...order.items.map((item) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(imageUrl: item.productImage, width: 50, height: 50, fit: BoxFit.cover,
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

  Widget _buildStatusTimeline(String status) {
    final steps = ['pending', 'confirmed', 'packed', 'shipped', 'out_for_delivery', 'delivered'];
    final currentIndex = steps.indexOf(status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(steps.length, (i) {
            final isActive = i <= currentIndex;
            return Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isActive ? AppTheme.primaryColor : Colors.grey[300],
                  child: Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(height: 4),
                Text(steps[i].replaceAll('_', '\n'), style: TextStyle(fontSize: 9, color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary), textAlign: TextAlign.center),
              ],
            );
          }),
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