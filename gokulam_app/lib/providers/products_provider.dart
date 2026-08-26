import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class StoreConfigModel {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double deliveryRadiusKm;
  final double deliveryChargePerHalfKm;

  StoreConfigModel({
    this.name = 'Gokulam Traders',
    this.address = '123 Main Road, Bangalore - 560001',
    this.latitude = 12.9716,
    this.longitude = 77.5946,
    this.deliveryRadiusKm = 5,
    this.deliveryChargePerHalfKm = 5,
  });

  factory StoreConfigModel.fromJson(Map<String, dynamic> json) {
    return StoreConfigModel(
      name: json['name'] ?? 'Gokulam Traders',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 12.9716,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.5946,
      deliveryRadiusKm: (json['delivery_radius_km'] as num?)?.toDouble() ?? 5,
      deliveryChargePerHalfKm: (json['delivery_charge_per_half_km'] as num?)?.toDouble() ?? 5,
    );
  }
}

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

final productsByCategoryProvider = FutureProvider.autoDispose.family<List<ProductModel>, int>((ref, categoryId) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.products, params: {'category': categoryId});
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => ProductModel.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

final featuredProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.products, params: {'is_featured': 'true'});
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => ProductModel.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

final homeProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.products, params: {'ordering': '-total_sold'});
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => ProductModel.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.categories);
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => CategoryModel.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

final brandsProvider = FutureProvider<List<BrandModel>>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.brands);
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => BrandModel.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

final bannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.banners);
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => BannerModel.fromJson(e)).toList();
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
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => ProductModel.fromJson(e)).toList();
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

final storeConfigProvider = FutureProvider<StoreConfigModel>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.storeLocation);
    return StoreConfigModel.fromJson(res.data);
  } catch (e) {
    return StoreConfigModel();
  }
});

class SearchNotifier extends StateNotifier<String> {
  SearchNotifier() : super('');

  void update(String query) => state = query;
}

final searchProvider = StateNotifierProvider<SearchNotifier, String>((ref) => SearchNotifier());