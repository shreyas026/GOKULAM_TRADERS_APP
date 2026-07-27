import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

final productsProvider = FutureProvider.autoDispose.family<List<ProductModel>, String>((ref, query) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.products, params: query.isNotEmpty ? {'search': query} : {});
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => ProductModel.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

final featuredProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.products, params: {'is_featured': 'true'});
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => ProductModel.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.categories);
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => CategoryModel.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

final bannersProvider = FutureProvider.autoDispose<List<BannerModel>>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.banners);
    return (res.data as List).map((e) => BannerModel.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

final productDetailProvider = FutureProvider.autoDispose.family<ProductModel?, int>((ref, id) async {
  final api = ApiService();
  try {
    final res = await api.get('${ApiEndpoints.products}$id/');
    return ProductModel.fromJson(res.data);
  } catch (e) {
    return null;
  }
});

final lowStockProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.productLowStock);
    return (res.data as List).map((e) => ProductModel.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.dashboardStats);
    return DashboardStats.fromJson(res.data);
  } catch (e) {
    return DashboardStats();
  }
});

class SearchNotifier extends StateNotifier<String> {
  SearchNotifier() : super('');

  void update(String query) => state = query;
}

final searchProvider = StateNotifierProvider<SearchNotifier, String>((ref) => SearchNotifier());