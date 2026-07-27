import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/products_provider.dart';
import '../../config/theme.dart';

class AdminInventoryScreen extends ConsumerWidget {
  const AdminInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider(''));

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: productsAsync.when(
        data: (products) {
          final lowStock = products.where((p) => p.isLowStock || p.isOutOfStock).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.errorColor.withAlpha(20),
                child: Row(children: [
                  const Icon(Icons.warning_amber, color: AppTheme.errorColor),
                  const SizedBox(width: 8),
                  Text('${lowStock.length} products low in stock', style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: products.length,
                  itemBuilder: (_, i) {
                    final p = products[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      child: ListTile(
                        title: Text(p.name, style: const TextStyle(fontSize: 14)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.isOutOfStock ? Colors.red[50] : p.isLowStock ? Colors.orange[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${p.stock}', style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: p.isOutOfStock ? Colors.red : p.isLowStock ? Colors.orange : Colors.green,
                          )),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
      ),
    );
  }
}