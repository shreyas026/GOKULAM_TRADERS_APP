import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/credit_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class KhataScreen extends ConsumerStatefulWidget {
  const KhataScreen({super.key});

  @override
  ConsumerState<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends ConsumerState<KhataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null && (user.role == 'admin' || user.role == 'cashier')) {
        ref.read(creditProvider.notifier).loadCredits();
      } else {
        ref.read(creditProvider.notifier).getMyCredit();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creditAsync = ref.watch(creditProvider);
    final user = ref.watch(authProvider).user;
    final isStaff = user?.role == 'admin' || user?.role == 'cashier';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khata Book'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Customers'),
            Tab(icon: Icon(Icons.store), text: 'Suppliers'),
          ],
        ),
      ),
      body: creditAsync.when(
        data: (credits) {
          final customerCredits = credits.where((c) => c.outstanding > 0 && c.partyType != 'supplier').toList();
          final supplierCredits = credits.where((c) => c.outstanding > 0 && c.partyType == 'supplier').toList();
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(customerCredits, isCustomer: true, isStaff: isStaff),
              _buildList(supplierCredits, isCustomer: false, isStaff: isStaff),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.textSecondary),
              const SizedBox(height: 12),
              const Text('Failed to load', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              TextButton(onPressed: () {
                ref.invalidate(creditProvider);
                if (isStaff) {
                  ref.read(creditProvider.notifier).loadCredits();
                } else {
                  ref.read(creditProvider.notifier).getMyCredit();
                }
              }, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List list, {required bool isCustomer, required bool isStaff}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.primaryColor.withAlpha(15),
          child: Row(children: [
            Icon(isCustomer ? Icons.people : Icons.store, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text('Total Outstanding: ₹${list.fold(0.0, (s, c) => s + c.outstanding).toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No records'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: list.length,
                  itemBuilder: (_, i) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withAlpha(30),
                        child: Text(list[i].displayName?[0]?.toUpperCase() ?? '?',
                          style: const TextStyle(color: AppTheme.primaryColor)),
                      ),
                      title: Text(list[i].displayName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Outstanding: ₹${list[i].outstanding.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppTheme.errorColor)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/khata/${list[i].id}'),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}