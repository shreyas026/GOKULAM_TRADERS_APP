import 'product_model.dart';

class CartItemModel {
  final int id;
  final int product;
  final ProductModel? productDetail;
  final int quantity;
  final double subtotal;

  CartItemModel({
    required this.id,
    required this.product,
    this.productDetail,
    this.quantity = 1,
    this.subtotal = 0,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] ?? 0,
      product: json['product'] ?? 0,
      productDetail: json['product_detail'] != null
          ? ProductModel.fromJson(json['product_detail'])
          : null,
      quantity: json['quantity'] ?? 1,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}

class CartModel {
  final int id;
  final List<CartItemModel> items;
  final double total;

  CartModel({
    this.id = 0,
    this.items = const [],
    this.total = 0,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'] ?? 0,
      items: json['items'] != null
          ? (json['items'] as List).map((e) => CartItemModel.fromJson(e)).toList()
          : [],
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  int get itemCount => items.length;
}

class OrderModel {
  final int id;
  final String orderId;
  final String status;
  final String deliveryType;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotal;
  final double gstAmount;
  final double discountAmount;
  final double deliveryCharge;
  final double totalAmount;
  final String notes;
  final String createdAt;
  final int itemCount;
  final String firstItemImage;

  OrderModel({
    required this.id,
    required this.orderId,
    this.status = 'pending',
    this.deliveryType = 'home_delivery',
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    this.subtotal = 0,
    this.gstAmount = 0,
    this.discountAmount = 0,
    this.deliveryCharge = 0,
    this.totalAmount = 0,
    this.notes = '',
    this.createdAt = '',
    this.itemCount = 0,
    this.firstItemImage = '',
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? '',
      status: json['status'] ?? 'pending',
      deliveryType: json['delivery_type'] ?? 'home_delivery',
      paymentMethod: json['payment_method'] ?? 'cash',
      paymentStatus: json['payment_status'] ?? 'pending',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      gstAmount: (json['gst_amount'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      deliveryCharge: (json['delivery_charge'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] ?? '',
      itemCount: json['item_count'] ?? 0,
      firstItemImage: json['first_item_image'] ?? '',
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'packed': return 'Packed';
      case 'shipped': return 'Shipped';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }
}

class OrderItemModel {
  final int id;
  final String productName;
  final String productImage;
  final int quantity;
  final double price;
  final double gstPercent;
  final double gstAmount;
  final double total;

  OrderItemModel({
    required this.id,
    this.productName = '',
    this.productImage = '',
    this.quantity = 1,
    this.price = 0,
    this.gstPercent = 0,
    this.gstAmount = 0,
    this.total = 0,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? 0,
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      gstPercent: (json['gst_percent'] ?? 0).toDouble(),
      gstAmount: (json['gst_amount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class OrderDetailModel extends OrderModel {
  final List<OrderItemModel> items;
  final dynamic deliveryAddressDetail;

  OrderDetailModel({
    required super.id,
    required super.orderId,
    super.status,
    super.deliveryType,
    super.paymentMethod,
    super.paymentStatus,
    super.subtotal,
    super.gstAmount,
    super.discountAmount,
    super.deliveryCharge,
    super.totalAmount,
    super.notes,
    super.createdAt,
    super.itemCount,
    super.firstItemImage,
    this.items = const [],
    this.deliveryAddressDetail,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? '',
      status: json['status'] ?? 'pending',
      deliveryType: json['delivery_type'] ?? 'home_delivery',
      paymentMethod: json['payment_method'] ?? 'cash',
      paymentStatus: json['payment_status'] ?? 'pending',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      gstAmount: (json['gst_amount'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      deliveryCharge: (json['delivery_charge'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] ?? '',
      itemCount: json['item_count'] ?? 0,
      firstItemImage: json['first_item_image'] ?? '',
      items: json['items'] != null
          ? (json['items'] as List).map((e) => OrderItemModel.fromJson(e)).toList()
          : [],
      deliveryAddressDetail: json['delivery_address_detail'],
    );
  }
}

class CreditModel {
  final int id;
  final int customer;
  final String? customerDetail;
  final String? displayName;
  final String? supplierName;
  final String? partyType;
  final double creditLimit;
  final double outstanding;
  final double totalCreditGiven;
  final double totalRepaid;
  final bool isActive;
  final List<CreditTransactionModel> transactions;

  CreditModel({
    required this.id,
    required this.customer,
    this.customerDetail,
    this.displayName,
    this.supplierName,
    this.partyType,
    this.creditLimit = 5000,
    this.outstanding = 0,
    this.totalCreditGiven = 0,
    this.totalRepaid = 0,
    this.isActive = true,
    this.transactions = const [],
  });

  factory CreditModel.fromJson(Map<String, dynamic> json) {
    return CreditModel(
      id: json['id'] ?? 0,
      customer: json['customer'] ?? 0,
      customerDetail: json['customer_detail']?.toString(),
      displayName: json['display_name'],
      supplierName: json['supplier_name'],
      partyType: json['party_type'],
      creditLimit: (json['credit_limit'] ?? 5000).toDouble(),
      outstanding: (json['outstanding'] ?? 0).toDouble(),
      totalCreditGiven: (json['total_credit_given'] ?? 0).toDouble(),
      totalRepaid: (json['total_repaid'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      transactions: json['transactions'] != null
          ? (json['transactions'] as List).map((e) => CreditTransactionModel.fromJson(e)).toList()
          : [],
    );
  }

  double get availableCredit => creditLimit - outstanding;
}

class CreditTransactionModel {
  final int id;
  final String transactionType;
  final double amount;
  final double balanceAfter;
  final String note;
  final String createdAt;

  CreditTransactionModel({
    required this.id,
    this.transactionType = '',
    this.amount = 0,
    this.balanceAfter = 0,
    this.note = '',
    this.createdAt = '',
  });

  factory CreditTransactionModel.fromJson(Map<String, dynamic> json) {
    return CreditTransactionModel(
      id: json['id'] ?? 0,
      transactionType: json['transaction_type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      balanceAfter: (json['balance_after'] ?? 0).toDouble(),
      note: json['note'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class DashboardStats {
  final int totalOrders;
  final int pendingOrders;
  final double totalRevenue;
  final int totalProducts;
  final int lowStock;

  DashboardStats({
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.totalRevenue = 0,
    this.totalProducts = 0,
    this.lowStock = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalOrders: json['total_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalProducts: json['total_products'] ?? 0,
      lowStock: json['low_stock'] ?? 0,
    );
  }
}