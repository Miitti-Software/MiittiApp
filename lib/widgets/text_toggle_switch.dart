import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

class TextToggleSwitch extends StatelessWidget {
  final String label1;
  final String label2;
  final int initialLabelIndex;
  final void Function(int?)? onToggle;

  const TextToggleSwitch({
    Key? key,
    required this.label1,
    required this.label2,
    required this.initialLabelIndex,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ToggleSwitch(
      minWidth: 200,
      initialLabelIndex: initialLabelIndex,
      inactiveBgColor: Colors.transparent,
      borderWidth: 3,
      radiusStyle: true,
      cornerRadius: 10,
      totalSwitches: 2,
      curve: Curves.linear,
      customTextStyles: [
        Theme.of(context).textTheme.bodyMedium,
      ],
      labels: [
        label1,
        label2,
      ],
      activeBgColors: [
        [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
        [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
      ],
      onToggle: onToggle,
    );
  }
}