import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../config/theme.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(wishlistProvider.notifier).loadWishlist());
  }

  @override
  Widget build(BuildContext context) {
    final wishlistAsync = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(wishlistProvider.notifier).loadWishlist(),
        child: wishlistAsync.when(
          data: (items) {
            if (items.isEmpty) return ListView(children: const [
              Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 80),
                  Icon(Icons.favorite_border, size: 80, color: AppTheme.textSecondary),
                  SizedBox(height: 16), Text('Wishlist is empty', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                ],
              )),
            ]);
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final product = items[i].productDetail;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: product?.primaryImage ?? '',
                        width: 50, height: 50, fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey[200]),
                        errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                      ),
                    ),
                    title: Text(product?.name ?? 'Product', maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(product != null ? '₹${product.sellingPrice.toStringAsFixed(0)}' : ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                      onPressed: () => ref.read(wishlistProvider.notifier).removeFromWishlist(items[i].product),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Failed to load')),
        ),
      ),
    );
  }
}