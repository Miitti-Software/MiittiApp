import 'package:flutter/material.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';

class BottomSheetDialog {
  static void show({
    required BuildContext context,
    required String title,
    required String body,
    required String confirmText,
    required String cancelText,
    required VoidCallback onConfirmPressed,
    required VoidCallback onCancelPressed,
    String? disclaimer,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: (MediaQuery.of(context).size.width - AppSizes.fullContentWidth) / 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  color: Theme.of(context).colorScheme.onPrimary,
                  thickness: 2.0,
                  indent: 100,
                  endIndent: 100,
                ),
                const SizedBox(height: AppSizes.minVerticalPadding),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSizes.verticalSeparationPadding),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                const SizedBox(height: AppSizes.verticalSeparationPadding),
                ForwardButton(
                  buttonText: confirmText,
                  onPressed: onConfirmPressed,
                ),
                const SizedBox(height: AppSizes.minVerticalPadding),
                BackwardButton(
                  buttonText: cancelText,
                  onPressed: onCancelPressed,
                ),
                const SizedBox(height: AppSizes.minVerticalPadding),
                if (disclaimer != null)
                  Text(
                    disclaimer,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                const SizedBox(height: AppSizes.minVerticalEdgePadding,)
              ],
            ),
          ),
        );
      },
    );
  }
}