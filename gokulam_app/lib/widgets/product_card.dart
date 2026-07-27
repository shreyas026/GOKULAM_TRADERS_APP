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
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: product.primaryImage,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 40)),
                    ),
                    if (product.discountPercent > 0)
                      Positioned(
                        top: 4, left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(4)),
                          child: Text('${product.discountPercent.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (product.isOutOfStock)
                      Positioned.fill(
                        child: Container(color: Colors.black.withAlpha(100), child: const Center(child: Text('Out of Stock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  if (product.brandName.isNotEmpty) Text(product.brandName, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('₹${product.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    if (product.mrp > product.sellingPrice) ...[
                      const SizedBox(width: 4),
                      Text('₹${product.mrp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: AppTheme.textSecondary)),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}