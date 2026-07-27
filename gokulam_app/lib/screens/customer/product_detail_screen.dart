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
      appBar: AppBar(
        title: const Text('Product Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) return const Center(child: Text('Product not found'));
          return _buildContent(product);
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

  Widget _buildContent(ProductModel product) {
    final images = product.images.isNotEmpty ? product.images : (product.primaryImage.isNotEmpty ? [product.primaryImage] : []);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty) ...[
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: images[_selectedImageIndex],
                height: 280, width: double.infinity, fit: BoxFit.cover,
                placeholder: (_, __) => Container(height: 280, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                errorWidget: (_, __, ___) => Container(height: 280, color: Colors.grey[200], child: const Icon(Icons.image, size: 64)),
              ),
            ).animate().fadeIn(),
            if (images.length > 1)
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  itemCount: images.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => _selectedImageIndex = i),
                    child: Container(
                      width: 52, height: 52, margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _selectedImageIndex == i ? AppTheme.primaryColor : Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: CachedNetworkImage(imageUrl: images[i], fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (product.brandName.isNotEmpty) Text(product.brandName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (product.mrp > product.sellingPrice) ...[
                      Text('₹${product.mrp.toStringAsFixed(0)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppTheme.textSecondary, fontSize: 16)),
                      const SizedBox(width: 8),
                    ],
                    Text('₹${product.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    if (product.discountPercent > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(4)),
                        child: Text('${product.discountPercent.toStringAsFixed(0)}% OFF', style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('GST: ${product.gstPercent.toStringAsFixed(0)}% | Inclusive of all taxes', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    RatingBarIndicator(rating: product.rating, itemSize: 18, itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber)),
                    const SizedBox(width: 8),
                    Text('(${product.totalSold} sold)', style: const TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (product.stock > 10)
                      const Chip(label: Text('In Stock', style: TextStyle(color: Colors.green, fontSize: 12)), backgroundColor: Color(0xFFE8F5E9))
                    else if (product.stock > 0)
                      Chip(label: Text('Only ${product.stock} left', style: const TextStyle(color: Colors.orange, fontSize: 12)), backgroundColor: Colors.orange[50])
                    else
                      const Chip(label: Text('Out of Stock', style: TextStyle(color: Colors.red, fontSize: 12)), backgroundColor: Color(0xFFFFEBEE)),
                    const Spacer(),
                    Row(
                      children: [
                        IconButton(onPressed: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1), icon: const Icon(Icons.remove_circle_outline)),
                        Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => setState(() => _quantity = _quantity < product.stock ? _quantity + 1 : product.stock), icon: const Icon(Icons.add_circle_outline)),
                      ],
                    ),
                  ],
                ),
                if (product.description.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(product.description, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                ],
                const Divider(height: 24),
                const Text('Specifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (product.material.isNotEmpty) _specRow('Material', product.material),
                if (product.weight.isNotEmpty) _specRow('Weight', product.weight),
                if (product.dimensions.isNotEmpty) _specRow('Dimensions', product.dimensions),
                _specRow('SKU', product.sku),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildBottomBar(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: product.isOutOfStock ? null : () {
              ref.read(cartProvider.notifier).addItem(product.id, quantity: _quantity);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Add to Cart'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: product.isOutOfStock ? null : () {
              ref.read(cartProvider.notifier).addItem(product.id, quantity: _quantity);
              context.go('/checkout');
            },
            icon: const Icon(Icons.flash_on),
            label: const Text('Buy Now'),
          ),
        ),
      ]),
    );
  }
}