class Customer {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final int salesCount;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.salesCount = 0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      salesCount: json['sales_count'] as int? ?? 0,
    );
  }
}
