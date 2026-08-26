class UserModel {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String role;
  final String address;
  final String profilePic;
  final String dateJoined;

  UserModel({
    required this.id,
    required this.username,
    this.email = '',
    this.phone = '',
    this.role = 'customer',
    this.address = '',
    this.profilePic = '',
    this.dateJoined = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      address: json['address'] ?? '',
      profilePic: json['profile_pic'] ?? '',
      dateJoined: json['date_joined'] ?? '',
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isCashier => role == 'cashier';
  bool get isDelivery => role == 'delivery';
  bool get isCustomer => role == 'customer';

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'phone': phone,
      'role': role,
      'address': address,
      'profile_pic': profilePic,
    };
  }
}

class AddressModel {
  final int id;
  final String label;
  final String fullAddress;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  AddressModel({
    this.id = 0,
    this.label = 'Home',
    this.fullAddress = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? 0,
      label: json['label'] ?? 'Home',
      fullAddress: json['full_address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] is num ? json['latitude'].toDouble() : double.tryParse(json['latitude'].toString())) : null,
      longitude: json['longitude'] != null ? (json['longitude'] is num ? json['longitude'].toDouble() : double.tryParse(json['longitude'].toString())) : null,
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'full_address': fullAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
    };
  }
}