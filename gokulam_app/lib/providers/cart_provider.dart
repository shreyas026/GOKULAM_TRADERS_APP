import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class CartNotifier extends StateNotifier<AsyncValue<CartModel>> {
  CartNotifier() : super(const AsyncLoading());

  Future<void> loadCart() async {
    state = const AsyncLoading();
    try {
      final api = ApiService();
      final res = await api.get(ApiEndpoints.cart);
      state = AsyncData(CartModel.fromJson(res.data));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addItem(int productId, {int quantity = 1}) async {
    try {
      final api = ApiService();
      await api.post(ApiEndpoints.cart, data: {
        'product_id': productId,
        'quantity': quantity,
      });
      await loadCart();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateItem(int itemId, int quantity) async {
    try {
      final api = ApiService();
      await api.patch('${ApiEndpoints.cart}items/$itemId/', data: {'quantity': quantity});
      await loadCart();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> removeItem(int itemId) async {
    try {
      final api = ApiService();
      await api.delete('${ApiEndpoints.cart}items/$itemId/');
      await loadCart();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> clearCart() async {
    try {
      final api = ApiService();
      await api.delete(ApiEndpoints.cart);
      state = AsyncData(CartModel());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<CartModel>>((ref) => CartNotifier());

class WishlistNotifier extends StateNotifier<AsyncValue<List<CartItemModel>>> {
  WishlistNotifier() : super(const AsyncData([]));

  Future<void> loadWishlist() async {
    try {
      final api = ApiService();
      final res = await api.get(ApiEndpoints.wishlist);
      final list = (res.data as List).map((e) => CartItemModel.fromJson(e)).toList();
      state = AsyncData(list);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addToWishlist(int productId) async {
    try {
      final api = ApiService();
      await api.post(ApiEndpoints.wishlist, data: {'product': productId});
      await loadWishlist();
    } catch (_) {}
  }

  Future<void> removeFromWishlist(int productId) async {
    try {
      final api = ApiService();
      await api.delete('${ApiEndpoints.wishlist}remove/$productId/');
      await loadWishlist();
    } catch (_) {}
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, AsyncValue<List<CartItemModel>>>((ref) => WishlistNotifier());