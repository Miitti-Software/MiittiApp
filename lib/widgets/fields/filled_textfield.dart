import 'package:flutter/material.dart';

/// A text field with a filled background.
class FilledTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final void Function(String)? onChange;
  final void Function(String)? onSubmit;

  const FilledTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.onChange,
    this.onSubmit,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
      keyboardType: keyboardType,
      onTapOutside: (PointerDownEvent event) {
        FocusScope.of(context).unfocus();
      },
      onChanged: onChange,
      onSubmitted: onSubmit,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
        ),
        hintText: hintText,
        hintStyle: Theme.of(context).textTheme.labelLarge,
        fillColor: Theme.of(context).colorScheme.primary.withAlpha(55),
        filled: true,
      ),
    );
  }
}