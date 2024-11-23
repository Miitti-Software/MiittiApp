import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

class ErrorSnackbar {
  static void show(BuildContext context, String message) {
    showOverlayNotification(
      (context) {
        return Card(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.error,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
              ),
            ),
          ),
        );
      },
      duration: const Duration(seconds: 4),
      position: NotificationPosition.bottom,
    );
  }
}