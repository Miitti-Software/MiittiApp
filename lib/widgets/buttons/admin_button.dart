import 'package:flutter/material.dart';
import 'package:miitti_app/constants/app_style.dart';

class AdminButton extends StatelessWidget {
  final Function()? onTap;

  const AdminButton({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: Text(
            'Kirjaudu Sisään',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              color: AppStyle.white,
            ),
          ),
        ),
      ),
    );
  }
}
