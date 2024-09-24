import 'package:flutter/material.dart';

class NavigationChoiceButton extends StatelessWidget {
  const NavigationChoiceButton(
      {super.key,
      required this.text,
      required this.isSelected,
      required this.onSelected});

  final String text;
  final bool isSelected;
  final Function(bool) onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onSelected(isSelected);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15, right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(25),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary,
            width: 1.0,
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
