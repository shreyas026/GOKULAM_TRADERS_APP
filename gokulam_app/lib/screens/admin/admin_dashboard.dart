import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/products_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../models/order_model.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard'), actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: () {
          showDialog(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Logout'), content: const Text('Are you sure?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(onPressed: () {
                Navigator.pop(ctx);
                ref.read(authProvider.notifier).logout();
                context.go('/auth/login');
              }, child: const Text('Logout', style: TextStyle(color: AppTheme.errorColor))),
            ],
          ));
        }),
      ]),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildStatGrid(stats),
              const SizedBox(height: 20),
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildQuickActions(context),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load dashboard')),
      ),
    );
  }

  Widget _buildStatGrid(DashboardStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _statCard('Total Orders', '${stats.totalOrders}', Icons.receipt_long, AppTheme.primaryColor),
        _statCard('Pending', '${stats.pendingOrders}', Icons.hourglass_empty, AppTheme.warningColor),
        _statCard('Revenue', '₹${stats.totalRevenue.toStringAsFixed(0)}', Icons.currency_rupee, AppTheme.successColor),
        _statCard('Low Stock', '${stats.lowStock}', Icons.warning_amber, AppTheme.errorColor),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(children: [
      _actionButton(context, 'Manage Products', Icons.inventory_2, () => context.go('/admin/products')),
      const SizedBox(height: 8),
      _actionButton(context, 'Manage Orders', Icons.receipt_long, () => context.go('/admin/orders')),
      const SizedBox(height: 8),
      _actionButton(context, 'Inventory', Icons.inventory, () => context.go('/admin/inventory')),
      const SizedBox(height: 8),
      _actionButton(context, 'Customers', Icons.people, () => context.go('/admin/customers')),
    ]);
  }

  Widget _actionButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

