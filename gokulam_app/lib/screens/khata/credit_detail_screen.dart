import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/order_model.dart';
import '../../providers/credit_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';

final creditDetailProvider = FutureProvider.autoDispose.family<CreditModel?, int>((ref, id) async {
  final api = ApiService();
  try {
    final res = await api.get('${ApiEndpoints.credits}$id/');
    return CreditModel.fromJson(res.data);
  } catch (_) {
    return null;
  }
});

class CreditDetailScreen extends ConsumerStatefulWidget {
  final int creditId;
  const CreditDetailScreen({super.key, required this.creditId});

  @override
  ConsumerState<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends ConsumerState<CreditDetailScreen> {
  String _txnFilter = 'all';

  void _showAddPayment() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String paymentMethod = 'cash';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setDialogState(() => paymentMethod = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(amountCtrl.text);
                if (v != null && v > 0) {
                  Navigator.pop(ctx, {'amount': v, 'method': paymentMethod, 'note': noteCtrl.text.trim()});
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await ref.read(creditProvider.notifier).addPayment(
        widget.creditId,
        result['amount'],
        note: result['note'],
        paymentMethod: result['method'],
      );
      ref.invalidate(creditDetailProvider(widget.creditId));
      ref.invalidate(khataSummaryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded'), backgroundColor: AppTheme.successColor),
        );
      }
    }
  }

  void _showAddCredit() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Credit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(amountCtrl.text);
              if (v != null && v > 0) {
                Navigator.pop(ctx, {'amount': v, 'note': noteCtrl.text.trim()});
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await ref.read(creditProvider.notifier).addCredit(
        widget.creditId,
        result['amount'],
        note: result['note'],
      );
      ref.invalidate(creditDetailProvider(widget.creditId));
      ref.invalidate(khataSummaryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credit added'), backgroundColor: AppTheme.successColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(creditDetailProvider(widget.creditId));
    final user = ref.watch(authProvider).user;
    final isStaff = user?.role == 'admin' || user?.role == 'cashier';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: isStaff
            ? [
                IconButton(
                  icon: const Icon(Icons.add_card),
                  tooltip: 'Record Payment',
                  onPressed: _showAddPayment,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add Credit',
                  onPressed: _showAddCredit,
                ),
              ]
            : null,
      ),
      body: detailAsync.when(
        data: (credit) {
          if (credit == null) return const Center(child: Text('Not found'));
          final transactions = _filterTransactions(credit.transactions);
          final utilizationPct = credit.creditLimit > 0
              ? (credit.outstanding / credit.creditLimit).clamp(0.0, 1.0)
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: credit.outstanding > 0
                            ? AppTheme.errorColor.withAlpha(20)
                            : AppTheme.successColor.withAlpha(20),
                        child: Text(
                          (credit.displayName ?? '?')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: credit.outstanding > 0 ? AppTheme.errorColor : AppTheme.successColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(credit.displayName ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (credit.customerPhone != null && credit.customerPhone!.isNotEmpty)
                        Text(credit.customerPhone!, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      const SizedBox(height: 16),
                      Text('Outstanding Balance', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '₹${credit.outstanding.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: credit.outstanding > 0 ? AppTheme.errorColor : AppTheme.successColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: utilizationPct,
                        backgroundColor: Colors.grey[200],
                        color: utilizationPct > 0.8 ? Colors.red : utilizationPct > 0.5 ? Colors.orange : Colors.green,
                        minHeight: 6,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoChip('Limit', '₹${credit.creditLimit.toStringAsFixed(0)}'),
                          _infoChip('Used', '${(utilizationPct * 100).toStringAsFixed(0)}%'),
                          _infoChip('Available', '₹${credit.availableCredit.toStringAsFixed(0)}'),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(child: _statColumn('Credit Given', '₹${credit.totalCreditGiven.toStringAsFixed(0)}')),
                          Expanded(child: _statColumn('Repaid', '₹${credit.totalRepaid.toStringAsFixed(0)}')),
                          Expanded(child: _statColumn('Balance', '₹${credit.outstanding.toStringAsFixed(0)}')),
                        ],
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    _buildFilterChip(),
                  ],
                ),
                const SizedBox(height: 8),
                if (transactions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('No transactions', style: TextStyle(color: Colors.grey[500]))),
                    ),
                  )
                else
                  ...transactions.map((t) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: t.transactionType == 'repayment'
                            ? AppTheme.successColor.withAlpha(20)
                            : AppTheme.errorColor.withAlpha(20),
                        child: Icon(
                          t.transactionType == 'repayment' ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 14,
                          color: t.transactionType == 'repayment' ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                      ),
                      title: Text(
                        _txnTypeLabel(t.transactionType),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${_formatDate(t.createdAt)}${t.note.isNotEmpty ? ' · ${t.note}' : ''}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${t.transactionType == 'repayment' ? '-' : '+'}₹${t.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: t.transactionType == 'repayment' ? AppTheme.successColor : AppTheme.errorColor,
                            ),
                          ),
                          Text(
                            'Bal: ₹${t.balanceAfter.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  )),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
      ),
    );
  }

  Widget _buildFilterChip() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'all', label: Text('All', style: TextStyle(fontSize: 11))),
        ButtonSegment(value: 'purchase', label: Text('Credit', style: TextStyle(fontSize: 11))),
        ButtonSegment(value: 'repayment', label: Text('Payment', style: TextStyle(fontSize: 11))),
      ],
      selected: {_txnFilter},
      onSelectionChanged: (v) => setState(() => _txnFilter = v.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  List<CreditTransactionModel> _filterTransactions(List<CreditTransactionModel> txns) {
    if (_txnFilter == 'all') return txns.take(50).toList();
    return txns.where((t) => t.transactionType == _txnFilter).take(50).toList();
  }

  String _txnTypeLabel(String type) {
    switch (type) {
      case 'purchase': return 'Credit Given';
      case 'repayment': return 'Payment Received';
      case 'adjustment': return 'Adjustment';
      default: return type;
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      return dateStr.substring(0, 10);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _infoChip(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }
}
