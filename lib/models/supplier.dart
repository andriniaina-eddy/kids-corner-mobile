class Supplier {
  final int id;
  final String name;
  final String? contactName;
  final String? email;
  final String? phone;
  final bool isActive;
  final int purchaseOrdersCount;

  Supplier({
    required this.id,
    required this.name,
    this.contactName,
    this.email,
    this.phone,
    this.isActive = true,
    this.purchaseOrdersCount = 0,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as int,
      name: json['name'] as String,
      contactName: json['contact_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      purchaseOrdersCount: json['purchase_orders_count'] as int? ?? 0,
    );
  }
}
