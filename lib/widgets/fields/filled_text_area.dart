import 'package:flutter/material.dart';

/// A text area with a filled background.
class FilledTextArea extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final void Function(String)? onChange;
  final void Function(String)? onSubmit;
  final bool autofocus;

  const FilledTextArea({
    super.key,
    required this.hintText,
    required this.controller,
    this.onChange,
    this.onSubmit,
    this.keyboardType = TextInputType.multiline,
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 5,
      autofocus: autofocus,
      controller: controller,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
      keyboardType: keyboardType,
      textInputAction: TextInputAction.newline,
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