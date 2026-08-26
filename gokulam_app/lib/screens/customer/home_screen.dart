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
import 'store_locator_screen.dart';

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

  void _showStoreMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StoreLocatorScreen()),
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
    final productsAsync = ref.watch(homeProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildSearchBar(),
                        bannersAsync.when(
                          data: (banners) => _buildBannerSlider(banners),
                          loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
                          error: (e, __) => SizedBox(height: 160, child: Center(child: Text('Banners: $e'))),
                        ),
                        _buildSectionHeader('Categories', () {}),
                        categoriesAsync.when(
                          data: (cats) => _buildCategories(cats),
                          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                          error: (e, __) => SizedBox(height: 100, child: Center(child: Text('Categories: $e'))),
                        ),
                        _buildSectionHeader('All Products', () {
                          ref.read(searchProvider.notifier).update('');
                          context.go('/products');
                        }),
                        productsAsync.when(
                          data: (products) => _buildProductGrid(products),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, __) => Center(child: Text('Products error: $e')),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gokulam Traders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Hardware · Electrical · Plumbing', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () => context.go('/wishlist'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.storefront, color: Colors.white),
            onPressed: () => _showStoreMap(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search products, brands...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor), onPressed: _scanBarcode),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onSubmitted: (q) {
            ref.read(searchProvider.notifier).update(q);
            context.go('/products');
          },
        ),
      ),
    );
  }

  Widget _buildBannerSlider(List<BannerModel> banners) {
    if (banners.isEmpty) return const SizedBox(height: 160, child: Center(child: Text('No banners')));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CarouselSlider(
        items: banners.map((b) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: b.image,
                  fit: BoxFit.cover,
                  memCacheWidth: 720,
                  maxWidthDiskCache: 720,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withAlpha(100), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12, left: 16,
                  child: Text(b.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
                ),
              ],
            ),
          ),
        )).toList(),
        options: CarouselOptions(
          height: 160,
          autoPlay: true,
          enlargeCenterPage: false,
          viewportFraction: 0.88,
          autoPlayInterval: const Duration(seconds: 4),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(List<CategoryModel> cats) {
    final colors = [
      AppTheme.primaryGradient,
      AppTheme.orangeGradient,
      AppTheme.blueGradient,
      AppTheme.purpleGradient,
      AppTheme.redGradient,
      AppTheme.tealGradient,
    ];
    final icons = [
      Icons.build, Icons.electrical_services, Icons.plumbing,
      Icons.handyman, Icons.format_paint, Icons.health_and_safety,
      Icons.bolt, Icons.water_drop, Icons.lightbulb,
      Icons.toggle_on, Icons.science, Icons.bathtub,
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: cats.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => context.go('/products/category/${cats[i].id}/${Uri.encodeComponent(cats[i].name)}'),
          child: Container(
            width: 76,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: colors[i % colors.length],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: colors[i % colors.length].colors.first.withAlpha(60), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  child: cats[i].image.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(imageUrl: cats[i].image, fit: BoxFit.cover, memCacheWidth: 150, maxWidthDiskCache: 150),
                        )
                      : Icon(icons[i % icons.length], color: Colors.white, size: 28),
                ),
                const SizedBox(height: 6),
                Text(cats[i].name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<ProductModel> products) {
    if (products.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No products available'));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 10, mainAxisSpacing: 10,
        ),
        itemCount: products.length > 10 ? 10 : products.length,
        itemBuilder: (_, i) => ProductCard(
          product: products[i],
          onTap: () => context.go('/products/${products[i].id}'),
        ),
      ),
    );
  }
}
