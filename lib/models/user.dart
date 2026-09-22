class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? companyName;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.companyName,
  });

  bool get isAdmin => role == 'admin';
  bool get isEmployee => role == 'employee';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      companyName: json['company_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'company_name': companyName,
      };
}
