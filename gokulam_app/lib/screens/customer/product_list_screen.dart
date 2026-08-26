import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/products_provider.dart';
import '../../config/theme.dart';
import '../../widgets/product_card.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchProvider);
    final productsAsync = ref.watch(productsProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: Text(query.isEmpty ? 'All Products' : 'Results for "$query"'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: productsAsync.when(
        data: (products) => products.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No products found', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                    const SizedBox(height: 8),
                    Text('Try a different search term', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(10),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 10, mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) => ProductCard(
                    product: products[i],
                    onTap: () => context.go('/products/${products[i].id}'),
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load products')),
      ),
    );
  }
}
