import 'package:flutter/material.dart';
import '../services/api_exception.dart';

void showErrorSnackBar(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : 'Une erreur est survenue.';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade600,
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green.shade600,
    ),
  );
}
