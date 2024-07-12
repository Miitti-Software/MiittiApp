import 'package:flutter/material.dart';
import 'package:miitti_app/constants/app_style.dart';

class AdminSearchBar extends StatelessWidget {
  final Function(String)? onChanged;
  const AdminSearchBar({required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Etsi käyttäjiä:',
          prefixIcon: const Icon(
            Icons.search,
            color: AppStyle.violet,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(50)),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          fillColor: Colors.grey.shade200,
          filled: true,
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }
}
