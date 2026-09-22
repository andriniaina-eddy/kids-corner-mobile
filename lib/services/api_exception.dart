class ApiException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;
  final int? statusCode;

  ApiException(this.message, {this.errors, this.statusCode});

  /// Premier message d'erreur de validation pour un champ donné, s'il existe.
  String? errorFor(String field) {
    final fieldErrors = errors?[field];
    if (fieldErrors == null || fieldErrors.isEmpty) return null;
    return fieldErrors.first;
  }

  @override
  String toString() => message;
}
