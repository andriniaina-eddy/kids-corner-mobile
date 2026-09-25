class SaleItemLine {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  SaleItemLine({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory SaleItemLine.fromJson(Map<String, dynamic> json) {
    return SaleItemLine(
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: double.tryParse('${json['unit_price']}') ?? 0,
      lineTotal: double.tryParse('${json['line_total']}') ?? 0,
    );
  }
}

class Sale {
  final int id;
  final String saleNumber;
  final String shop;
  final String customer;
  final double total;
  final double margin;
  final int itemsCount;
  final String? soldAt;

  Sale({
    required this.id,
    required this.saleNumber,
    required this.shop,
    required this.customer,
    required this.total,
    required this.margin,
    required this.itemsCount,
    this.soldAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as int,
      saleNumber: json['sale_number'] as String,
      shop: json['shop'] as String,
      customer: json['customer'] as String? ?? 'Client de passage',
      total: double.tryParse('${json['total']}') ?? 0,
      margin: double.tryParse('${json['margin']}') ?? 0,
      itemsCount: json['items_count'] as int? ?? 0,
      soldAt: json['sold_at'] as String?,
    );
  }
}
