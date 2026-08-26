import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/products_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/credit_provider.dart';
import '../../config/theme.dart';
import '../../models/order_model.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final khataSummaryAsync = ref.watch(khataSummaryProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.store, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Gokulam Traders', style: TextStyle(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () {
                        showDialog(context: context, builder: (ctx) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            TextButton(onPressed: () {
                              Navigator.pop(ctx);
                              ref.read(authProvider.notifier).logout();
                              context.go('/auth/login');
                            }, child: const Text('Logout', style: TextStyle(color: AppTheme.errorColor))),
                          ],
                        ));
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(dashboardStatsProvider);
                      ref.invalidate(khataSummaryProvider);
                    },
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildStatsGrid(statsAsync),
                          const SizedBox(height: 16),
                          _buildKhataSummary(context, khataSummaryAsync),
                          const SizedBox(height: 24),
                          const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildQuickActions(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AsyncValue<DashboardStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _statCard('Total Orders', '${stats.totalOrders}', Icons.receipt_long, AppTheme.primaryGradient),
          _statCard('Pending', '${stats.pendingOrders}', Icons.hourglass_empty, AppTheme.orangeGradient),
          _statCard('Revenue', '₹${stats.totalRevenue.toStringAsFixed(0)}', Icons.currency_rupee, AppTheme.tealGradient),
          _statCard('Low Stock', '${stats.lowStock}', Icons.warning_amber, AppTheme.redGradient),
        ],
      ),
      loading: () => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: List.generate(4, (_) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        )),
      ),
      error: (_, __) => const Text('Failed to load stats'),
    );
  }

  Widget _buildKhataSummary(BuildContext context, AsyncValue<KhataSummary> khataAsync) {
    return khataAsync.when(
      data: (summary) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.book, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  const Text('Khata Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/khata'),
                    child: const Text('View All', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                  ),
                ],
              ),
              const Divider(),
              Row(
                children: [
                  _khataStat('Outstanding', '₹${summary.totalOutstanding.toStringAsFixed(0)}', AppTheme.errorColor),
                  _khataStat('Collected', '₹${summary.totalRepaid.toStringAsFixed(0)}', AppTheme.successColor),
                  _khataStat('Today', '₹${summary.todayCollections.toStringAsFixed(0)}', AppTheme.primaryColor),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _khataStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: gradient.colors.first.withAlpha(60), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withAlpha(200), size: 24),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(200))),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(children: [
      _actionCard(context, 'Manage Products', Icons.inventory_2_outlined, AppTheme.primaryGradient, () => context.go('/admin/products')),
      const SizedBox(height: 10),
      _actionCard(context, 'Manage Categories', Icons.category_outlined, AppTheme.blueGradient, () => context.go('/admin/categories')),
      const SizedBox(height: 10),
      _actionCard(context, 'Manage Orders', Icons.receipt_long_outlined, AppTheme.orangeGradient, () => context.go('/admin/orders')),
      const SizedBox(height: 10),
      _actionCard(context, 'Inventory', Icons.warehouse_outlined, AppTheme.purpleGradient, () => context.go('/admin/inventory')),
      const SizedBox(height: 10),
      _actionCard(context, 'Customers', Icons.people_outline, AppTheme.tealGradient, () => context.go('/admin/customers')),
      const SizedBox(height: 10),
      _actionCard(context, 'Shop Location & Settings', Icons.location_on_outlined, AppTheme.primaryGradient, () => context.go('/admin/store-settings')),
    ]);
  }

  Widget _actionCard(BuildContext context, String label, IconData icon, LinearGradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
