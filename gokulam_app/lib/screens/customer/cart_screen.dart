import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../config/theme.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).loadCart());
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: cartAsync.when(
        data: (cart) {
          if (cart.items.isEmpty) {
            return const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 80, color: AppTheme.textSecondary),
                SizedBox(height: 16),
                Text('Your cart is empty', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
              ],
            ));
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(cartProvider.notifier).loadCart(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      final product = item.productDetail;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: product?.primaryImage ?? '',
                                width: 80, height: 80, fit: BoxFit.cover,
                                memCacheWidth: 160,
                                maxWidthDiskCache: 160,
                                placeholder: (_, __) => Container(width: 80, height: 80, color: Colors.grey[200]),
                                errorWidget: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.image)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product?.name ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('₹${(item.subtotal / item.quantity).toStringAsFixed(0)} x ${item.quantity}', style: const TextStyle(color: AppTheme.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text('Total: ₹${item.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                ],
                              ),
                            ),
                            Column(children: [
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () => ref.read(cartProvider.notifier).updateItem(item.id, item.quantity + 1),
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () {
                                  if (item.quantity <= 1) {
                                    ref.read(cartProvider.notifier).removeItem(item.id);
                                  } else {
                                    ref.read(cartProvider.notifier).updateItem(item.id, item.quantity - 1);
                                  }
                                },
                              ),
                            ]),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                              onPressed: () => ref.read(cartProvider.notifier).removeItem(item.id),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, -2))]),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('₹${cart.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(onPressed: () => context.go('/checkout'), child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16))),
                  ),
                ]),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load cart')),
      ),
    );
  }
}