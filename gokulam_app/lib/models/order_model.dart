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
      id: parseInt(json['id']),
      product: parseInt(json['product']),
      productDetail: json['product_detail'] != null
          ? ProductModel.fromJson(json['product_detail'])
          : null,
      quantity: parseInt(json['quantity'], 1),
      subtotal: parseDouble(json['subtotal']),
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
      id: parseInt(json['id']),
      items: json['items'] != null
          ? (json['items'] as List).map((e) => CartItemModel.fromJson(e)).toList()
          : [],
      total: parseDouble(json['total']),
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
  final double? deliveryLat;
  final double? deliveryLng;
  final String deliveryAddressText;

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
    this.deliveryLat,
    this.deliveryLng,
    this.deliveryAddressText = '',
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: parseInt(json['id']),
      orderId: json['order_id'] ?? '',
      status: json['status'] ?? 'pending',
      deliveryType: json['delivery_type'] ?? 'home_delivery',
      paymentMethod: json['payment_method'] ?? 'cash',
      paymentStatus: json['payment_status'] ?? 'pending',
      subtotal: parseDouble(json['subtotal']),
      gstAmount: parseDouble(json['gst_amount']),
      discountAmount: parseDouble(json['discount_amount']),
      deliveryCharge: parseDouble(json['delivery_charge']),
      totalAmount: parseDouble(json['total_amount']),
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] ?? '',
      itemCount: parseInt(json['item_count']),
      firstItemImage: json['first_item_image'] ?? '',
      deliveryLat: json['delivery_lat'] != null
          ? (json['delivery_lat'] is num ? (json['delivery_lat'] as num).toDouble() : double.tryParse(json['delivery_lat'].toString()))
          : null,
      deliveryLng: json['delivery_lng'] != null
          ? (json['delivery_lng'] is num ? (json['delivery_lng'] as num).toDouble() : double.tryParse(json['delivery_lng'].toString()))
          : null,
      deliveryAddressText: json['delivery_address_text'] ?? '',
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
      id: parseInt(json['id']),
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      quantity: parseInt(json['quantity'], 1),
      price: parseDouble(json['price']),
      gstPercent: parseDouble(json['gst_percent']),
      gstAmount: parseDouble(json['gst_amount']),
      total: parseDouble(json['total']),
    );
  }
}

class OrderDetailModel extends OrderModel {
  final List<OrderItemModel> items;
  final dynamic deliveryAddressDetail;
  final double? currentLat;
  final double? currentLng;
  final String? assignedTo;

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
    this.currentLat,
    this.currentLng,
    this.assignedTo,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: parseInt(json['id']),
      orderId: json['order_id'] ?? '',
      status: json['status'] ?? 'pending',
      deliveryType: json['delivery_type'] ?? 'home_delivery',
      paymentMethod: json['payment_method'] ?? 'cash',
      paymentStatus: json['payment_status'] ?? 'pending',
      subtotal: parseDouble(json['subtotal']),
      gstAmount: parseDouble(json['gst_amount']),
      discountAmount: parseDouble(json['discount_amount']),
      deliveryCharge: parseDouble(json['delivery_charge']),
      totalAmount: parseDouble(json['total_amount']),
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] ?? '',
      itemCount: parseInt(json['item_count']),
      firstItemImage: json['first_item_image'] ?? '',
      items: json['items'] != null
          ? (json['items'] as List).map((e) => OrderItemModel.fromJson(e)).toList()
          : [],
      deliveryAddressDetail: json['delivery_address_detail'],
      currentLat: json['current_lat'] != null
          ? (json['current_lat'] is num ? (json['current_lat'] as num).toDouble() : double.tryParse(json['current_lat'].toString()))
          : null,
      currentLng: json['current_lng'] != null
          ? (json['current_lng'] is num ? (json['current_lng'] as num).toDouble() : double.tryParse(json['current_lng'].toString()))
          : null,
      assignedTo: json['assigned_to']?.toString(),
    );
  }
}

class CreditModel {
  final int id;
  final int customer;
  final String? customerDetail;
  final String? displayName;
  final String? customerPhone;
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
    this.customerPhone,
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
    String? phone;
    if (json['customer_phone'] != null) {
      phone = json['customer_phone'].toString();
    } else if (json['customer_detail'] is Map) {
      phone = json['customer_detail']['phone']?.toString();
    }
    return CreditModel(
      id: parseInt(json['id']),
      customer: parseInt(json['customer']),
      customerDetail: json['customer_detail'] is Map ? null : json['customer_detail']?.toString(),
      displayName: json['display_name'],
      customerPhone: phone,
      supplierName: json['supplier_name'],
      partyType: json['party_type'],
      creditLimit: parseDouble(json['credit_limit'], 5000),
      outstanding: parseDouble(json['outstanding']),
      totalCreditGiven: parseDouble(json['total_credit_given']),
      totalRepaid: parseDouble(json['total_repaid']),
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
      id: parseInt(json['id']),
      transactionType: json['transaction_type'] ?? '',
      amount: parseDouble(json['amount']),
      balanceAfter: parseDouble(json['balance_after']),
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
      totalOrders: parseInt(json['total_orders']),
      pendingOrders: parseInt(json['pending_orders']),
      totalRevenue: parseDouble(json['total_revenue']),
      totalProducts: parseInt(json['total_products']),
      lowStock: parseInt(json['low_stock']),
    );
  }
}