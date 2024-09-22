import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

class SuccessSnackbar {
  static void show(BuildContext context, String message) {
    showOverlayNotification(
      (context) {
        return Card(
          child: Container(
            height: 80,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green,
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
      duration: const Duration(seconds: 2),
      position: NotificationPosition.bottom,
    );
  }
}