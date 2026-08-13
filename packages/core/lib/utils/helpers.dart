import 'package:core/errors/error.dart';
import 'package:core/utils/notifications.dart';
import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

class ShowFailure {
  ShowFailure._();
  static final ShowFailure instance = ShowFailure._();

  void mapFailuresToNotification(
    BuildContext context, {
    required Failure failure,
    bool validSession = true,
  }) {
    switch (failure.runtimeType) {
      case const (NetworkFailure):
        AppNotification.showNotification(
          context,
          title: 'Revisa tu conexión a internet',
        );
        break;
      case const (TimeoutFailure):
        AppNotification.showNotification(
          context,
          title: 'No pudimos comunicarnos con el servidor',
        );
        break;
      case const (AuthFailure):
        AppNotification.showNotification(
          context,
          title: 'Datos incorrectos o su token expiro',
        );
        if (validSession) {
          // context.go(LoginView.path);
        }
        break;
      case const (UnknownFailure):
      default:
        AppNotification.showNotification(context, title: 'A ocurrido un error');
    }
  }
}
