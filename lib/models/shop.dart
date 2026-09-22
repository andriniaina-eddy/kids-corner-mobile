class Shop {
  final int id;
  final String name;
  final String code;
  final String? city;
  final String? address;
  final String? phone;
  final bool isActive;
  final int? productsCount;
  final int? totalQuantity;
  final int? lowStockCount;
  final int? employeesCount;
  final int? inventoriesCount;

  Shop({
    required this.id,
    required this.name,
    required this.code,
    this.city,
    this.address,
    this.phone,
    this.isActive = true,
    this.productsCount,
    this.totalQuantity,
    this.lowStockCount,
    this.employeesCount,
    this.inventoriesCount,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      city: json['city'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      productsCount: json['products_count'] as int?,
      totalQuantity: json['total_quantity'] as int?,
      lowStockCount: json['low_stock_count'] as int?,
      employeesCount: json['employees_count'] as int?,
      inventoriesCount: json['inventories_count'] as int?,
    );
  }
}
