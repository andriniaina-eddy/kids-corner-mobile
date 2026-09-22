class TransferItemLine {
  final String product;
  final int quantity;

  TransferItemLine({required this.product, required this.quantity});

  factory TransferItemLine.fromJson(Map<String, dynamic> json) {
    return TransferItemLine(
      product: json['product'] as String,
      quantity: json['quantity'] as int,
    );
  }
}

class Transfer {
  final int id;
  final String shopSource;
  final String shopTarget;
  final String createdBy;
  final String status;
  final List<TransferItemLine> items;
  final String createdAt;

  Transfer({
    required this.id,
    required this.shopSource,
    required this.shopTarget,
    required this.createdBy,
    required this.status,
    required this.items,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';

  factory Transfer.fromJson(Map<String, dynamic> json) {
    return Transfer(
      id: json['id'] as int,
      shopSource: json['shop_source'] as String,
      shopTarget: json['shop_target'] as String,
      createdBy: json['created_by'] as String,
      status: json['status'] as String,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => TransferItemLine.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String,
    );
  }
}
