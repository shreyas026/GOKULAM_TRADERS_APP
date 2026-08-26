import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../../providers/orders_provider.dart';
import '../../config/theme.dart';
import 'delivery_route_screen.dart';

class DeliveryHomeScreen extends ConsumerStatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  ConsumerState<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends ConsumerState<DeliveryHomeScreen> {
  StreamSubscription<Position>? _positionSub;
  int? _trackingOrderId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ordersProvider.notifier).loadOrders());
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _toggleTracking(int orderId, bool shouldStart) async {
    if (shouldStart) {
      var status = await Permission.location.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission required for live tracking')),
          );
        }
        return;
      }
      setState(() => _trackingOrderId = orderId);
      _positionSub?.cancel();
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50,
        ),
      ).listen((pos) async {
        await ref.read(ordersProvider.notifier).updateDeliveryLocation(
          orderId, pos.latitude, pos.longitude,
        );
      }, onError: (_) {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live tracking started'), backgroundColor: AppTheme.successColor),
        );
      }
    } else {
      _positionSub?.cancel();
      setState(() => _trackingOrderId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live tracking stopped')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Deliveries')),
      body: ordersAsync.when(
        data: (orders) {
          final deliveries = orders.where((o) =>
            o.deliveryType == 'home_delivery' &&
            (o.status == 'shipped' || o.status == 'out_for_delivery')
          ).toList();
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
            itemBuilder: (_, i) {
              final order = deliveries[i];
              final nextStatus = order.status == 'shipped' ? 'out_for_delivery' : 'delivered';
              final isTracking = _trackingOrderId == order.id;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.inventory_2, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                          child: Text(order.status.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.currency_rupee, size: 16, color: AppTheme.textSecondary),
                        Text('₹${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${order.itemCount} items', style: const TextStyle(color: AppTheme.textSecondary)),
                      ]),
                      const SizedBox(height: 12),
                      if (isTracking)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text('Sharing live location...', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(isTracking ? Icons.gps_fixed : Icons.gps_off, size: 16),
                              label: Text(isTracking ? 'Stop Tracking' : 'Start Live Tracking'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                foregroundColor: isTracking ? AppTheme.errorColor : AppTheme.primaryColor,
                              ),
                              onPressed: () => _toggleTracking(order.id, !isTracking),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: Text('Mark ${nextStatus.replaceAll('_', ' ')}'),
                              onPressed: () async {
                                await ref.read(ordersProvider.notifier).updateOrderStatus(order.id, nextStatus, note: nextStatus == 'delivered' ? 'Delivered successfully' : 'Out for delivery');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Order marked as ${nextStatus.replaceAll('_', ' ')}'), backgroundColor: AppTheme.successColor),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36)),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 8),
                      if (order.deliveryLat != null && order.deliveryLng != null)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text('View Delivery Route'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              foregroundColor: AppTheme.primaryColor,
                            ),
                            onPressed: () => context.go('/delivery/route/${order.id}'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
      ),
    );
  }
}
