class InventoryProduct {
  final int id;
  final String name;
  final String? sku;
  final String unit;

  InventoryProduct({required this.id, required this.name, this.sku, required this.unit});

  factory InventoryProduct.fromJson(Map<String, dynamic> json) {
    return InventoryProduct(
      id: json['id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      unit: json['unit'] as String? ?? 'unite',
    );
  }
}

class InventoryLine {
  final int id;
  final InventoryProduct product;
  final int quantity;
  final int alertThreshold;
  final bool isLow;

  InventoryLine({
    required this.id,
    required this.product,
    required this.quantity,
    required this.alertThreshold,
    required this.isLow,
  });

  factory InventoryLine.fromJson(Map<String, dynamic> json) {
    return InventoryLine(
      id: json['id'] as int,
      product: InventoryProduct.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      alertThreshold: json['alert_threshold'] as int,
      isLow: json['is_low'] as bool? ?? false,
    );
  }
}
