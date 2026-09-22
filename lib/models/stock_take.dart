class StockTake {
  final int id;
  final String shop;
  final int shopId;
  final String period;
  final String periodLabel;
  final String status;
  final String createdAt;
  final String? completedAt;

  StockTake({
    required this.id,
    required this.shop,
    required this.shopId,
    required this.period,
    required this.periodLabel,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  bool get isDraft => status == 'draft';

  factory StockTake.fromJson(Map<String, dynamic> json) {
    return StockTake(
      id: json['id'] as int,
      shop: json['shop'] as String,
      shopId: json['shop_id'] as int,
      period: json['period'] as String,
      periodLabel: json['period_label'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      completedAt: json['completed_at'] as String?,
    );
  }
}

class StockTakeItem {
  final int id;
  final String productName;
  final String? productSku;
  final String unit;
  final int systemQuantity;
  final int? countedQuantity;

  StockTakeItem({
    required this.id,
    required this.productName,
    this.productSku,
    required this.unit,
    required this.systemQuantity,
    this.countedQuantity,
  });

  factory StockTakeItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>;
    return StockTakeItem(
      id: json['id'] as int,
      productName: product['name'] as String,
      productSku: product['sku'] as String?,
      unit: product['unit'] as String? ?? 'unite',
      systemQuantity: json['system_quantity'] as int,
      countedQuantity: json['counted_quantity'] as int?,
    );
  }
}
