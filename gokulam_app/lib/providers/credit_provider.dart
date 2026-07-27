import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class CreditNotifier extends StateNotifier<AsyncValue<List<CreditModel>>> {
  CreditNotifier() : super(const AsyncData([]));

  Future<void> loadCredits() async {
    state = const AsyncLoading();
    try {
      final api = ApiService();
      final res = await api.get(ApiEndpoints.credits);
      final results = res.data['results'] as List? ?? res.data as List;
      state = AsyncData(results.map((e) => CreditModel.fromJson(e)).toList());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> getMyCredit() async {
    state = const AsyncLoading();
    try {
      final api = ApiService();
      final res = await api.get(ApiEndpoints.myCredit);
      final credit = CreditModel.fromJson(res.data);
      state = AsyncData([credit]);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addPayment(int creditId, double amount, {String note = ''}) async {
    try {
      final api = ApiService();
      await api.post('${ApiEndpoints.credits}$creditId/add_payment/', data: {
        'customer_id': creditId,
        'amount': amount,
        'note': note,
      });
      await loadCredits();
    } catch (_) {}
  }

  Future<void> getOutstandingCredits() async {
    state = const AsyncLoading();
    try {
      final api = ApiService();
      final res = await api.get('${ApiEndpoints.credits}outstanding/');
      final results = res.data['results'] as List? ?? res.data as List;
      state = AsyncData(results.map((e) => CreditModel.fromJson(e)).toList());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final creditProvider = StateNotifierProvider<CreditNotifier, AsyncValue<List<CreditModel>>>((ref) => CreditNotifier());

final myCreditProvider = FutureProvider.autoDispose<CreditModel?>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.myCredit);
    return CreditModel.fromJson(res.data);
  } catch (_) {
    return null;
  }
});