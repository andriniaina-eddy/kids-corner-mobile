class ProductVariant {
  final int id;
  final String name;
  final String? sku;
  final double? salePrice;
  final double? purchasePrice;
  final int? totalStock;

  ProductVariant({
    required this.id,
    required this.name,
    this.sku,
    this.salePrice,
    this.purchasePrice,
    this.totalStock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      salePrice: json['sale_price'] != null ? double.tryParse('${json['sale_price']}') : null,
      purchasePrice: json['purchase_price'] != null ? double.tryParse('${json['purchase_price']}') : null,
      totalStock: json['total_stock'] as int?,
    );
  }
}
