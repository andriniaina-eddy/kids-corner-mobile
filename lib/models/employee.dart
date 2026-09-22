class EmployeeShop {
  final int id;
  final String name;

  EmployeeShop({required this.id, required this.name});

  factory EmployeeShop.fromJson(Map<String, dynamic> json) {
    return EmployeeShop(id: json['id'] as int, name: json['name'] as String);
  }
}

class Employee {
  final int id;
  final String name;
  final String email;
  final bool isActive;
  final List<EmployeeShop> shops;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.shops,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      isActive: json['is_active'] as bool? ?? true,
      shops: (json['shops'] as List<dynamic>? ?? [])
          .map((s) => EmployeeShop.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
