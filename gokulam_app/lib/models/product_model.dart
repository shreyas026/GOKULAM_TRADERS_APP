class CategoryModel {
  final int id;
  final String name;
  final String image;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    this.image = '',
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

class ProductModel {
  final int id;
  final String name;
  final int? category;
  final String categoryName;
  final int? brand;
  final String brandName;
  final String sku;
  final String barcode;
  final double mrp;
  final double sellingPrice;
  final double discountPercent;
  final double gstPercent;
  final int stock;
  final int lowStockThreshold;
  final List<String> images;
  final String primaryImage;
  final bool isAvailable;
  final bool isFeatured;
  final double rating;
  final int totalSold;
  final String description;
  final String weight;
  final String dimensions;
  final String material;

  ProductModel({
    required this.id,
    required this.name,
    this.category,
    this.categoryName = '',
    this.brand,
    this.brandName = '',
    this.sku = '',
    this.barcode = '',
    this.mrp = 0,
    this.sellingPrice = 0,
    this.discountPercent = 0,
    this.gstPercent = 18,
    this.stock = 0,
    this.lowStockThreshold = 5,
    this.images = const [],
    this.primaryImage = '',
    this.isAvailable = true,
    this.isFeatured = false,
    this.rating = 0,
    this.totalSold = 0,
    this.description = '',
    this.weight = '',
    this.dimensions = '',
    this.material = '',
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'],
      categoryName: json['category_name'] ?? '',
      brand: json['brand'],
      brandName: json['brand_name'] ?? '',
      sku: json['sku'] ?? '',
      barcode: json['barcode'] ?? '',
      mrp: (json['mrp'] ?? 0).toDouble(),
      sellingPrice: (json['selling_price'] ?? 0).toDouble(),
      discountPercent: (json['discount_percent'] ?? 0).toDouble(),
      gstPercent: (json['gst_percent'] ?? 18).toDouble(),
      stock: json['stock'] ?? 0,
      lowStockThreshold: json['low_stock_threshold'] ?? 5,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      primaryImage: json['primary_image'] ?? '',
      isAvailable: json['is_available'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      totalSold: json['total_sold'] ?? 0,
      description: json['description'] ?? '',
      weight: json['weight'] ?? '',
      dimensions: json['dimensions'] ?? '',
      material: json['material'] ?? '',
    );
  }

  double get discountedPrice => sellingPrice;
  double get savings => mrp - sellingPrice;
  double get gstAmount => sellingPrice * gstPercent / 100;
  double get finalPrice => sellingPrice + gstAmount;
  bool get isLowStock => stock > 0 && stock <= lowStockThreshold;
  bool get isOutOfStock => stock == 0;
}

class BannerModel {
  final int id;
  final String title;
  final String image;
  final String link;

  BannerModel({
    required this.id,
    required this.title,
    this.image = '',
    this.link = '',
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      link: json['link'] ?? '',
    );
  }
}

class CouponModel {
  final String code;
  final double discountPercent;
  final double discountAmount;
  final double minOrderAmount;
  final double? maxDiscount;
  final bool valid;

  CouponModel({
    required this.code,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.minOrderAmount = 0,
    this.maxDiscount,
    this.valid = false,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      code: json['code'] ?? '',
      discountPercent: (json['discount_percent'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      minOrderAmount: (json['min_order_amount'] ?? 0).toDouble(),
      maxDiscount: json['max_discount']?.toDouble(),
      valid: json['valid'] ?? false,
    );
  }
}