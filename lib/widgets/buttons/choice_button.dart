import 'package:flutter/material.dart';
import 'package:miitti_app/constants/app_style.dart';

class ChoiceButton extends StatelessWidget {
  const ChoiceButton(
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1026),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected ? AppStyle.pink : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Text(
          text,
          style: AppStyle.warning,
        ),
      ),
    );
  }
}
