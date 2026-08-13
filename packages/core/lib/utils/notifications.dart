import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

class AppNotification {
  static void showNotification(
    BuildContext context, {
    required String title,
    Duration duration = const Duration(seconds: 3),
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    BotToast.showSimpleNotification(
      title: title,
      titleStyle: theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.onPrimary,
      ),
      subTitle: subtitle,
      subTitleStyle: theme.textTheme.bodyMedium!.copyWith(
        color: theme.colorScheme.onPrimary,
      ),
      backgroundColor: theme.colorScheme.secondary,
      duration: duration,
      hideCloseButton: true,
    );
  }

  static void showNotificationError(
    BuildContext context, {
    required String title,
    Duration duration = const Duration(seconds: 3),
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    BotToast.showSimpleNotification(
      title: title,
      titleStyle: theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.onError,
      ),
      subTitle: subtitle,
      subTitleStyle: theme.textTheme.bodyMedium!.copyWith(
        color: theme.colorScheme.onError,
      ),
      backgroundColor: theme.colorScheme.error,
      duration: duration,
      hideCloseButton: true,
    );
  }

  ///Show a normal toast
  static void showToast(
    BuildContext context, {
    required String text,
    Duration? duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    BotToast.showText(
      text: text,
      textStyle: theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.surface,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      borderRadius: BorderRadius.circular(10),
      contentColor: theme.colorScheme.onSurface,
      duration: duration,
      clickClose: true,
    );
  }

  ///Show a toast with style for errors
  static void showToastError(
    BuildContext context, {
    required String text,
    Duration? duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    BotToast.showText(
      text: text,
      textStyle: theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.onError,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      borderRadius: BorderRadius.circular(10),
      contentColor: theme.colorScheme.error,
      duration: duration,
      clickClose: true,
    );
  }
}
