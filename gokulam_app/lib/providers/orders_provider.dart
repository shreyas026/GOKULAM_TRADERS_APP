import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  OrdersNotifier() : super(const AsyncData([]));

  Future<void> loadOrders() async {
    state = const AsyncLoading();
    try {
      final api = ApiService();
      final res = await api.get(ApiEndpoints.orders);
      final results = res.data['results'] as List? ?? res.data as List;
      state = AsyncData(results.map((e) => OrderModel.fromJson(e)).toList());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<OrderDetailModel?> getOrderDetail(int orderId) async {
    try {
      final api = ApiService();
      final res = await api.get('${ApiEndpoints.orders}$orderId/');
      return OrderDetailModel.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    try {
      final api = ApiService();
      final res = await api.post(ApiEndpoints.orderCreate, data: data);
      await loadOrders();
      return {'success': true, 'order': OrderDetailModel.fromJson(res.data)};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> updateOrderStatus(int orderId, String status, {String note = ''}) async {
    try {
      final api = ApiService();
      await api.post('${ApiEndpoints.orders}$orderId/update_status/', data: {
        'status': status,
        'note': note,
      });
      await loadOrders();
    } catch (_) {}
  }

  Future<void> assignDelivery(int orderId, int staffId) async {
    try {
      final api = ApiService();
      await api.post('${ApiEndpoints.orders}$orderId/assign_delivery/', data: {
        'staff_id': staffId,
      });
      await loadOrders();
    } catch (_) {}
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderModel>>>((ref) => OrdersNotifier());

final pendingOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get('${ApiEndpoints.orders}pending/');
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => OrderModel.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});