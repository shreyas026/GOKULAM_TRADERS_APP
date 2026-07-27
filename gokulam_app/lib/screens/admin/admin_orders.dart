import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/orders_provider.dart';
import '../../config/theme.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ordersProvider.notifier).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders'), actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: (v) => setState(() => _filter = v),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'all', child: Text('All')),
            const PopupMenuItem(value: 'pending', child: Text('Pending')),
            const PopupMenuItem(value: 'confirmed', child: Text('Confirmed')),
            const PopupMenuItem(value: 'delivered', child: Text('Delivered')),
          ],
        ),
      ]),
      body: ordersAsync.when(
        data: (orders) {
          final filtered = _filter == 'all' ? orders : orders.where((o) => o.status == _filter).toList();
          if (filtered.isEmpty) return const Center(child: Text('No orders'));
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filtered.length,
            itemBuilder: (_, i) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(filtered[i].orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('₹${filtered[i].totalAmount.toStringAsFixed(0)} | ${filtered[i].itemCount} items'),
                trailing: _statusChip(filtered[i].status),
                onTap: () => context.go('/orders/${filtered[i].id}'),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
      child: Text(status.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
    );
  }
}