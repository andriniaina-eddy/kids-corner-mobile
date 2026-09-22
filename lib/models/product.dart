class Product {
  final int id;
  final String name;
  final String? sku;
  final String unit;
  final double purchasePrice;
  final double salePrice;
  final int totalStock;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    this.sku,
    required this.unit,
    required this.purchasePrice,
    required this.salePrice,
    required this.totalStock,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      unit: json['unit'] as String? ?? 'unite',
      purchasePrice: double.tryParse('${json['purchase_price']}') ?? 0,
      salePrice: double.tryParse('${json['sale_price']}') ?? 0,
      totalStock: json['total_stock'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
