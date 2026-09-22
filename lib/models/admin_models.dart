class TrashedShop {
  final int id;
  final String name;
  final String code;
  final String deletedAt;
  final int inventoriesCount;

  TrashedShop({
    required this.id,
    required this.name,
    required this.code,
    required this.deletedAt,
    required this.inventoriesCount,
  });

  factory TrashedShop.fromJson(Map<String, dynamic> json) {
    return TrashedShop(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      deletedAt: json['deleted_at'] as String,
      inventoriesCount: json['inventories_count'] as int? ?? 0,
    );
  }
}

class TrashedProduct {
  final int id;
  final String name;
  final String? sku;
  final String deletedAt;

  TrashedProduct({required this.id, required this.name, this.sku, required this.deletedAt});

  factory TrashedProduct.fromJson(Map<String, dynamic> json) {
    return TrashedProduct(
      id: json['id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      deletedAt: json['deleted_at'] as String,
    );
  }
}

class PendingAdmin {
  final int id;
  final String name;
  final String companyName;
  final String email;
  final String statusValidation;
  final String createdAt;

  PendingAdmin({
    required this.id,
    required this.name,
    required this.companyName,
    required this.email,
    required this.statusValidation,
    required this.createdAt,
  });

  factory PendingAdmin.fromJson(Map<String, dynamic> json) {
    return PendingAdmin(
      id: json['id'] as int,
      name: json['name'] as String,
      companyName: json['company_name'] as String? ?? '—',
      email: json['email'] as String,
      statusValidation: json['status_validation'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}
