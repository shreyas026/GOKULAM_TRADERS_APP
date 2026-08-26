import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/credit_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';

class KhataScreen extends ConsumerStatefulWidget {
  const KhataScreen({super.key});

  @override
  ConsumerState<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends ConsumerState<KhataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null && (user.role == 'admin' || user.role == 'cashier')) {
        ref.read(creditProvider.notifier).loadCredits();
        ref.read(khataSummaryProvider.future);
      } else {
        ref.read(creditProvider.notifier).getMyCredit();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    setState(() => _searchQuery = _searchController.text.trim());
    ref.read(creditProvider.notifier).loadCredits(search: _searchQuery);
  }

  void _addSupplier() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '5000');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Supplier Name *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credit Limit', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => nameCtrl.text.trim().isEmpty ? null : Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService().post('${ApiEndpoints.credits}add_supplier/', data: {
          'supplier_name': nameCtrl.text.trim(),
          'supplier_phone': phoneCtrl.text.trim(),
          'credit_limit': double.tryParse(limitCtrl.text) ?? 5000,
        });
        if (mounted) {
          ref.read(creditProvider.notifier).loadCredits();
          ref.invalidate(khataSummaryProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supplier added'), backgroundColor: AppTheme.successColor),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
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
        actions: isStaff
            ? [
                IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Add Supplier',
                  onPressed: _addSupplier,
                ),
              ]
            : null,
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
      body: Column(
        children: [
          if (isStaff) _buildSummarySection(),
          _buildSearchBar(),
          Expanded(
            child: creditAsync.when(
              data: (credits) {
                final customerCredits = credits.where((c) => c.partyType != 'supplier').toList();
                final supplierCredits = credits.where((c) => c.partyType == 'supplier').toList();
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
          ),
        ],
      ),
      floatingActionButton: isStaff
          ? FloatingActionButton(
              onPressed: _addSupplier,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildSummarySection() {
    final summaryAsync = ref.watch(khataSummaryProvider);
    return summaryAsync.when(
      data: (summary) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: AppTheme.primaryColor.withAlpha(15),
        child: Row(
          children: [
            _summaryItem('Outstanding', '₹${summary.totalOutstanding.toStringAsFixed(0)}', AppTheme.errorColor),
            Container(width: 1, height: 30, color: Colors.grey[300]),
            _summaryItem('Collected', '₹${summary.totalRepaid.toStringAsFixed(0)}', AppTheme.successColor),
            Container(width: 1, height: 30, color: Colors.grey[300]),
            _summaryItem('Today', '₹${summary.todayCollections.toStringAsFixed(0)}', AppTheme.primaryColor),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or phone...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    ref.read(creditProvider.notifier).loadCredits();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onSubmitted: (_) => _onSearch(),
        onChanged: (v) {
          if (v.isEmpty) {
            setState(() => _searchQuery = '');
            ref.read(creditProvider.notifier).loadCredits();
          }
        },
      ),
    );
  }

  Widget _buildList(List list, {required bool isCustomer, required bool isStaff}) {
    final outstandingTotal = list.fold(0.0, (s, c) => s + (c.outstanding > 0 ? c.outstanding : 0.0));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: AppTheme.primaryColor.withAlpha(8),
          child: Row(children: [
            Icon(isCustomer ? Icons.people : Icons.store, color: AppTheme.primaryColor, size: 16),
            const SizedBox(width: 6),
            Text('${list.length} ${isCustomer ? "Customers" : "Suppliers"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('Total: ₹${outstandingTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.errorColor)),
          ]),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isCustomer ? Icons.people_outline : Icons.store_outlined, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(_searchQuery.isNotEmpty ? 'No results found' : 'No records', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.read(creditProvider.notifier).loadCredits(search: _searchQuery);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final credit = list[i];
                      final hasOutstanding = credit.outstanding > 0;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        color: hasOutstanding ? null : Colors.grey[50],
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: hasOutstanding
                                ? AppTheme.primaryColor.withAlpha(30)
                                : AppTheme.successColor.withAlpha(30),
                            child: Text(
                              (credit.displayName ?? '?')[0].toUpperCase(),
                              style: TextStyle(
                                color: hasOutstanding ? AppTheme.primaryColor : AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  credit.displayName ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              if (credit.customerPhone != null && credit.customerPhone!.isNotEmpty)
                                Text(credit.customerPhone!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              if (hasOutstanding)
                                Text('Due: ₹${credit.outstanding.toStringAsFixed(0)}',
                                  style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600, fontSize: 12))
                              else
                                Text('Settled', style: TextStyle(color: AppTheme.successColor, fontSize: 12)),
                              const SizedBox(width: 8),
                              if (credit.totalCreditGiven > 0)
                                Text('Total: ₹${credit.totalCreditGiven.toStringAsFixed(0)}',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => context.go('/khata/${credit.id}'),
                        ),
                      ).animate().fadeIn(duration: 200.ms, delay: Duration(milliseconds: 50 * i));
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
