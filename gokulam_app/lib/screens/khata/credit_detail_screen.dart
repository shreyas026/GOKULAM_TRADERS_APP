import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';

final creditDetailProvider = FutureProvider.autoDispose.family<CreditModel?, int>((ref, id) async {
  final api = ApiService();
  try {
    final res = await api.get('${ApiEndpoints.credits}$id/');
    return CreditModel.fromJson(res.data);
  } catch (_) {
    return null;
  }
});

class CreditDetailScreen extends ConsumerWidget {
  final int creditId;
  const CreditDetailScreen({super.key, required this.creditId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(creditDetailProvider(creditId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: detailAsync.when(
        data: (credit) {
          if (credit == null) return const Center(child: Text('Not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    const Text('Outstanding Balance', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text('₹${credit.outstanding.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: credit.creditLimit > 0 ? credit.outstanding / credit.creditLimit : 0,
                      backgroundColor: Colors.grey[200],
                      color: credit.outstanding > credit.creditLimit * 0.8 ? Colors.red : Colors.green,
                    ),
                    const SizedBox(height: 8),
                    Text('Credit Limit: ₹${credit.creditLimit.toStringAsFixed(0)} | Available: ₹${credit.availableCredit.toStringAsFixed(0)}'),
                  ]),
                )),
                const SizedBox(height: 12),
                const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...credit.transactions.take(20).map((t) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  child: ListTile(
                    title: Text(t.transactionType.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(t.createdAt.isNotEmpty ? t.createdAt.substring(0, 10) : '', style: const TextStyle(fontSize: 11)),
                    trailing: Text('₹${t.amount.toStringAsFixed(0)}', style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: t.transactionType == 'repayment' ? Colors.green : Colors.red,
                    )),
                  ),
                )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
      ),
    );
  }
}