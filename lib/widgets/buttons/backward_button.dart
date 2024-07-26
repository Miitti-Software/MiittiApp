import 'package:flutter/material.dart';
import 'package:miitti_app/constants/miitti_theme.dart';

// A button widget meant for navigating to the previous screen, signaling pausing or going back
class BackwardButton extends StatelessWidget {
  final String buttonText;
  final Function() onPressed;

  const BackwardButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(
          Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(
            width: 1,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        minimumSize: WidgetStateProperty.all<Size>(
          const Size(Sizes.fullContentWidth, Sizes.fullContentWidth / 7),
        ),
      ),
        
      onPressed: onPressed,
      child: Text(
        buttonText,
        style: Theme.of(context).textTheme.bodyMedium,
      )
    );
  }
}