import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class KhataSummary {
  final int totalCustomers;
  final int totalSuppliers;
  final double totalOutstanding;
  final double totalCreditGiven;
  final double totalRepaid;
  final int overdueCount;
  final double todayCollections;
  final List<CreditTransactionModel> recentTransactions;

  KhataSummary({
    this.totalCustomers = 0,
    this.totalSuppliers = 0,
    this.totalOutstanding = 0,
    this.totalCreditGiven = 0,
    this.totalRepaid = 0,
    this.overdueCount = 0,
    this.todayCollections = 0,
    this.recentTransactions = const [],
  });

  factory KhataSummary.fromJson(Map<String, dynamic> json) {
    return KhataSummary(
      totalCustomers: json['total_customers'] ?? 0,
      totalSuppliers: json['total_suppliers'] ?? 0,
      totalOutstanding: (json['total_outstanding'] ?? 0).toDouble(),
      totalCreditGiven: (json['total_credit_given'] ?? 0).toDouble(),
      totalRepaid: (json['total_repaid'] ?? 0).toDouble(),
      overdueCount: json['overdue_count'] ?? 0,
      todayCollections: (json['today_collections'] ?? 0).toDouble(),
      recentTransactions: json['recent_transactions'] != null
          ? (json['recent_transactions'] as List)
              .map((e) => CreditTransactionModel.fromJson(e))
              .toList()
          : [],
    );
  }
}

class CreditNotifier extends StateNotifier<AsyncValue<List<CreditModel>>> {
  CreditNotifier() : super(const AsyncData([]));

  Future<void> loadCredits({String search = ''}) async {
    state = const AsyncLoading();
    try {
      final api = ApiService();
      final params = <String, dynamic>{};
      if (search.isNotEmpty) params['search'] = search;
      final res = await api.get(ApiEndpoints.credits, params: params);
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

  Future<void> addPayment(int creditId, double amount, {String note = '', String paymentMethod = 'cash'}) async {
    try {
      final api = ApiService();
      await api.post('${ApiEndpoints.credits}$creditId/add_payment/', data: {
        'amount': amount,
        'payment_method': paymentMethod,
        'note': note,
      });
      await loadCredits();
    } catch (_) {}
  }

  Future<void> addCredit(int creditId, double amount, {String note = ''}) async {
    try {
      final api = ApiService();
      await api.post('${ApiEndpoints.credits}$creditId/add_credit/', data: {
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

final khataSummaryProvider = FutureProvider.autoDispose<KhataSummary>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.creditSummary);
    return KhataSummary.fromJson(res.data);
  } catch (_) {
    return KhataSummary();
  }
});
