import 'package:flutter/material.dart';

class ConstantsOnboarding {
  String title;
  String? warningText;
  String? hintText;

  TextInputType? keyboardType;

  bool isFullView = false;

  ConstantsOnboarding({
    required this.title,
    this.warningText,
    this.hintText,
    this.keyboardType,
    this.isFullView = false,
  });
}
