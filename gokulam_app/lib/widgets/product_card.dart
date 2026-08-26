import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 3)),
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: product.primaryImage,
                      fit: BoxFit.cover,
                      memCacheWidth: 360,
                      maxWidthDiskCache: 360,
                      placeholder: (_, __) => Container(
                        decoration: const BoxDecoration(gradient: AppTheme.cardGradient),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        decoration: const BoxDecoration(gradient: AppTheme.cardGradient),
                        child: const Icon(Icons.inventory_2_outlined, size: 40, color: AppTheme.textSecondary),
                      ),
                    ),
                    if (product.discountPercent > 0)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppTheme.secondaryGradient,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: AppTheme.secondaryColor.withAlpha(80), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Text('${product.discountPercent.toStringAsFixed(0)}% OFF', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (product.isOutOfStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(color: Colors.black.withAlpha(120), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                          child: const Center(
                            child: Text('Out of Stock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withAlpha(60)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (product.brandName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(product.brandName, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('₹${product.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      if (product.mrp > product.sellingPrice) ...[
                        const SizedBox(width: 4),
                        Text('₹${product.mrp.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: Colors.grey[400])),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
