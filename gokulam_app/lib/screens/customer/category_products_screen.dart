import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/products_provider.dart';
import '../../config/theme.dart';
import '../../widgets/product_card.dart';

class CategoryProductsScreen extends ConsumerWidget {
  final String categoryName;
  final int categoryId;
  const CategoryProductsScreen({super.key, required this.categoryName, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByCategoryProvider(categoryId));

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: productsAsync.when(
        data: (products) => products.isEmpty
            ? const Center(child: Text('No products in this category'))
            : GridView.builder(
                padding: const EdgeInsets.all(10),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load products')),
      ),
    );
  }
}