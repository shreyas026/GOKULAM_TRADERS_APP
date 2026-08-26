class AppConfig {
  static const String appName = 'Gokulam Traders';
  static const String apiBaseUrl = 'https://web-production-1b48f1.up.railway.app/api';
  static const int deliveryRadiusKm = 5;
  static const double deliveryChargePerHalfKm = 5.0;

  static double deliveryChargeForDistance(double distanceKm) {
    return deliveryChargeForDistanceBooking(distanceKm, deliveryChargePerHalfKm);
  }

  static double deliveryChargeForDistanceBooking(double distanceKm, double chargePerHalfKm) {
    if (distanceKm <= 0) return 0;
    final slabs = (distanceKm / 0.5).ceil();
    return slabs * chargePerHalfKm;
  }

  static const double storeLat = 12.9716;
  static const double storeLng = 77.5946;
}

class ApiEndpoints {
  static const String login = '/auth/login/';
  static const String register = '/auth/register/';
  static const String profile = '/auth/profile/';
  static const String changePassword = '/auth/change-password/';
  static const String addresses = '/auth/addresses/';
  static const String customers = '/auth/customers/';
  static const String users = '/auth/users/';
  static const String updateFcm = '/auth/update-fcm/';

  static const String products = '/products/';
  static const String productSearch = '/products/search/';
  static const String productByBarcode = '/products/by_barcode/';
  static const String productLowStock = '/products/low_stock/';
  static const String categories = '/categories/';
  static const String brands = '/brands/';
  static const String banners = '/banners/';
  static const String couponValidate = '/coupon/validate/';
  static const String dashboardStats = '/dashboard/stats/';

  static const String cart = '/cart/';
  static const String orders = '/orders/';
  static const String orderCreate = '/orders/create_order/';
  static const String wishlist = '/wishlist/';
  static const String storeLocation = '/store/location/';

  static const String credits = '/khata/credits/';
  static const String myCredit = '/khata/credits/my_credit/';
  static const String creditSummary = '/khata/credits/summary/';
  static const String creditCustomers = '/khata/credits/customers/';
  static const String creditSuppliers = '/khata/credits/suppliers/';
  static const String allTransactions = '/khata/credits/all_transactions/';
  static const String payments = '/khata/payments/';
  static const String paymentInitiate = '/khata/payment/initiate/';
}