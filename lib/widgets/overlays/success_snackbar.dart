import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

class SuccessSnackbar {
  static void show(BuildContext context, String message) {
    showOverlayNotification(
      (context) {
        return Card(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green,
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
            ),
          ),
        );
      },
      duration: const Duration(seconds: 2),
      position: NotificationPosition.bottom,
    );
  }
}