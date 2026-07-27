import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/products_provider.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';
import '../../widgets/barcode_scanner_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  void _scanBarcode() {
    showDialog(
      context: context,
      builder: (_) => BarcodeScannerDialog(
        onScan: (code) {
          _searchController.text = code;
          ref.read(searchProvider.notifier).update(code);
          context.go('/products');
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gokulam Traders'),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () => context.go('/wishlist')),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            bannersAsync.when(
              data: (banners) => _buildBannerSlider(banners),
              loading: () => const SizedBox(height: 160),
              error: (_, __) => const SizedBox(height: 160),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            categoriesAsync.when(
              data: (cats) => _buildCategories(cats),
              loading: () => const SizedBox(height: 100),
              error: (_, __) => const SizedBox(height: 100),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('Featured Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            featuredAsync.when(
              data: (products) => _buildProductGrid(products),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Failed to load products')),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _scanBarcode),
        ),
        onSubmitted: (q) {
          ref.read(searchProvider.notifier).update(q);
          context.go('/products');
        },
      ),
    );
  }

  Widget _buildBannerSlider(List<BannerModel> banners) {
    if (banners.isEmpty) return const SizedBox(height: 160, child: Center(child: Text('No banners')));
    return CarouselSlider(
      items: banners.map((b) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(imageUrl: b.image, fit: BoxFit.cover, width: double.infinity,
          placeholder: (_, __) => Container(color: Colors.grey[200]),
          errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
        ),
      )).toList(),
      options: CarouselOptions(height: 160, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.92),
    ).animate().fadeIn();
  }

  Widget _buildCategories(List<CategoryModel> cats) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: cats.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () {
            ref.read(searchProvider.notifier).update('');
            context.go('/products');
          },
          child: Container(
            width: 80, margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: cats[i].image.isNotEmpty ? CachedNetworkImageProvider(cats[i].image) : null,
                  child: cats[i].image.isEmpty ? const Icon(Icons.category, color: AppTheme.primaryColor) : null,
                ),
                const SizedBox(height: 4),
                Text(cats[i].name, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<ProductModel> products) {
    if (products.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No products'));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: products.length > 6 ? 6 : products.length,
        itemBuilder: (_, i) => ProductCard(product: products[i], onTap: () => context.go('/products/${products[i].id}')),
      ),
    );
  }
}