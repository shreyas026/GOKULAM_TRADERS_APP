import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/products_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';

class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider(''));

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/admin/products/add')),
      ]),
      body: productsAsync.when(
        data: (products) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productsProvider(''));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (_, i) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: products[i].primaryImage,
                    width: 50, height: 50, fit: BoxFit.cover,
                    memCacheWidth: 120,
                    maxWidthDiskCache: 120,
                    placeholder: (_, __) => Container(color: Colors.grey[200]),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                  ),
                ),
                title: Text(products[i].name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('₹${products[i].sellingPrice.toStringAsFixed(0)} | Stock: ${products[i].stock}', style: const TextStyle(fontSize: 12)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('${products[i].stock}', style: TextStyle(
                    color: products[i].isLowStock ? AppTheme.errorColor : products[i].isOutOfStock ? Colors.red : AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => context.go('/admin/products/edit/${products[i].id}')),
                ]),
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
      ),
    );
  }
}
