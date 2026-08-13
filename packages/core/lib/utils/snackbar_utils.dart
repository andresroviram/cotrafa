import 'package:core/errors/error.dart';
import 'package:flutter/material.dart';

abstract final class SnackbarUtils {
  static void showErrorSnackbar(BuildContext context, Failure failure) {
    final String message;
    if (failure is NetworkFailure) {
      message = 'Sin conexión a internet';
    } else if (failure is ServerFailure) {
      message = failure.message;
    } else {
      message = 'Ocurrió un error inesperado';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
