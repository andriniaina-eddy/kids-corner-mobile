import 'product_variant.dart';

class Product {
  final int id;
  final String name;
  final String? sku;
  final String unit;
  final double purchasePrice;
  final double salePrice;
  final int totalStock;
  final bool isActive;
  final bool tracksBatches;
  final String? imageUrl;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    this.sku,
    required this.unit,
    required this.purchasePrice,
    required this.salePrice,
    required this.totalStock,
    this.isActive = true,
    this.tracksBatches = false,
    this.imageUrl,
    this.variants = const [],
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
      tracksBatches: json['tracks_batches'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
      variants: (json['variants'] as List<dynamic>? ?? [])
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}
