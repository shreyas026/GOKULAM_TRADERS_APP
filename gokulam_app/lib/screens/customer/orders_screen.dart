import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/orders_provider.dart';
import '../../config/theme.dart';
import '../../models/order_model.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ordersProvider.notifier).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) return const Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, size: 80, color: AppTheme.textSecondary),
              SizedBox(height: 16), Text('No orders yet', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
            ],
          ));
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (_, i) => _buildOrderCard(orders[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load orders')),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                _buildStatusChip(order.status),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Text('₹${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const Spacer(),
                Text('${order.itemCount} items', style: const TextStyle(color: AppTheme.textSecondary)),
              ]),
              const SizedBox(height: 4),
              Text(order.createdAt.isNotEmpty ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(order.createdAt)) : '',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'delivered': color = AppTheme.successColor; break;
      case 'cancelled': color = AppTheme.errorColor; break;
      case 'out_for_delivery': color = Colors.orange; break;
      default: color = AppTheme.warningColor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(12)),
      child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}