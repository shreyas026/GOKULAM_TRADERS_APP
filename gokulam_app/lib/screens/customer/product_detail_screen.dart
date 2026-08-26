import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/products_provider.dart';
import '../../providers/cart_provider.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int id;
  const ProductDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: productAsync.when(
        data: (product) {
          if (product == null) return const Center(child: Text('Product not found'));
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(product),
              SliverToBoxAdapter(child: _buildContent(product)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
      ),
      bottomNavigationBar: productAsync.whenOrNull(data: (product) {
        if (product == null) return null;
        return _buildBottomBar(product);
      }),
    );
  }

  Widget _buildAppBar(ProductModel product) {
    final images = product.images.isNotEmpty ? product.images : (product.primaryImage.isNotEmpty ? [product.primaryImage] : []);
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(10)),
        child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: images.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: images[_selectedImageIndex],
                    fit: BoxFit.cover,
                    memCacheWidth: 900,
                    maxWidthDiskCache: 900,
                    placeholder: (_, __) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 64)),
                  ),
                  Container(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withAlpha(80), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter, stops: const [0, 0.5])),
                  ),
                  if (product.discountPercent > 0)
                    Positioned(
                      top: 50, right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(gradient: AppTheme.secondaryGradient, borderRadius: BorderRadius.circular(8)),
                        child: Text('${product.discountPercent.toStringAsFixed(0)}% OFF', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              )
            : Container(
                decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                child: const Center(child: Icon(Icons.inventory_2, size: 80, color: Colors.white)),
              ),
      ),
    );
  }

  Widget _buildContent(ProductModel product) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3)),
                    if (product.brandName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(product.brandName, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('₹${product.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              if (product.mrp > product.sellingPrice) ...[
                const SizedBox(width: 8),
                Text('₹${product.mrp.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, decoration: TextDecoration.lineThrough, color: Colors.grey[400])),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                child: Text('GST ${product.gstPercent.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              RatingBarIndicator(rating: product.rating > 0 ? product.rating : 4.0, itemSize: 20, itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber)),
              const SizedBox(width: 8),
              Text('(${product.totalSold} sold)', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              const Spacer(),
              _stockChip(product),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    IconButton(onPressed: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1), icon: const Icon(Icons.remove_circle_outline)),
                    Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => setState(() => _quantity = _quantity < product.stock ? _quantity + 1 : product.stock), icon: const Icon(Icons.add_circle_outline)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('Total: ₹${(product.sellingPrice * _quantity).toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ],
          ),
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(product.description, style: TextStyle(color: Colors.grey[600], height: 1.6, fontSize: 14)),
          ],
          const SizedBox(height: 20),
          const Text('Specifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (product.material.isNotEmpty) _specRow('Material', product.material),
          if (product.weight.isNotEmpty) _specRow('Weight', product.weight),
          if (product.dimensions.isNotEmpty) _specRow('Dimensions', product.dimensions),
          _specRow('SKU', product.sku),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _stockChip(ProductModel product) {
    if (product.stock > 10) return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
      child: const Text('In Stock', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
    );
    if (product.stock > 0) return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
      child: Text('Only ${product.stock} left', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
      child: const Text('Out of Stock', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[500]))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildBottomBar(ProductModel product) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryColor, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: OutlinedButton.icon(
              onPressed: product.isOutOfStock ? null : () {
                ref.read(cartProvider.notifier).addItem(product.id, quantity: _quantity);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Added to cart'),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              },
              icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryColor),
              label: const Text('Add to Cart', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppTheme.primaryColor.withAlpha(60), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: ElevatedButton.icon(
              onPressed: product.isOutOfStock ? null : () {
                ref.read(cartProvider.notifier).addItem(product.id, quantity: _quantity);
                context.go('/checkout');
              },
              icon: const Icon(Icons.flash_on, color: Colors.white),
              label: const Text('Buy Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ),
      ]),
    );
  }
}
