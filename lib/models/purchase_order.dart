class PurchaseOrderItem {
  final int id;
  final String productName;
  final int quantityOrdered;
  final int quantityReceived;
  final int remaining;
  final double unitCost;

  PurchaseOrderItem({
    required this.id,
    required this.productName,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.remaining,
    required this.unitCost,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      id: json['id'] as int,
      productName: json['product_name'] as String,
      quantityOrdered: json['quantity_ordered'] as int,
      quantityReceived: json['quantity_received'] as int,
      remaining: json['remaining'] as int,
      unitCost: double.tryParse('${json['unit_cost']}') ?? 0,
    );
  }
}

class PurchaseOrder {
  final int id;
  final String referenceNumber;
  final String supplier;
  final String shop;
  final String status;
  final double totalCost;
  final String createdAt;

  PurchaseOrder({
    required this.id,
    required this.referenceNumber,
    required this.supplier,
    required this.shop,
    required this.status,
    required this.totalCost,
    required this.createdAt,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] as int,
      referenceNumber: json['reference_number'] as String,
      supplier: json['supplier'] as String,
      shop: json['shop'] as String,
      status: json['status'] as String,
      totalCost: double.tryParse('${json['total_cost']}') ?? 0,
      createdAt: json['created_at'] as String,
    );
  }
}
