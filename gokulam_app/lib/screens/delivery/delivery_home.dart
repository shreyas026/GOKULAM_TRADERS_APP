import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/orders_provider.dart';
import '../../config/theme.dart';

class DeliveryHomeScreen extends ConsumerStatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  ConsumerState<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends ConsumerState<DeliveryHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ordersProvider.notifier).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Deliveries')),
      body: ordersAsync.when(
        data: (orders) {
          final deliveries = orders.where((o) => o.status == 'out_for_delivery' || o.status == 'shipped').toList();
          if (deliveries.isEmpty) return const Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: AppTheme.successColor),
              SizedBox(height: 16), Text('All deliveries completed', style: TextStyle(fontSize: 18)),
            ],
          ));
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: deliveries.length,
            itemBuilder: (_, i) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.inventory_2, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(deliveries[i].orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                        child: const Text('Out for Delivery', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.currency_rupee, size: 16, color: AppTheme.textSecondary),
                      Text('₹${deliveries[i].totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${deliveries[i].itemCount} items', style: const TextStyle(color: AppTheme.textSecondary)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text('Navigate'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigation - coming soon')));
                        },
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Mark Delivered'),
                        onPressed: () {
                          ref.read(ordersProvider.notifier).updateOrderStatus(deliveries[i].id, 'delivered', note: 'Delivered successfully');
                        },
                        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36)),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
      ),
    );
  }
}