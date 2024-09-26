import 'package:flutter/material.dart';
import 'package:miitti_app/constants/app_style.dart';
//TODO: Seperate styles
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String mainText;
  final String cancelButtonText;
  final String confirmButtonText;

  const ConfirmDialog({
    required this.title,
    required this.mainText,
    required this.cancelButtonText,
    required this.confirmButtonText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppStyle.darkPurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Sora',
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      content: Text(
        mainText,
        style: const TextStyle(
          fontFamily: 'Rubik',
          fontSize: 16.0,
          color: Colors.white70,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            // User pressed the cancel button
            Navigator.of(context).pop(false);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey, // Set the button color
            foregroundColor: Colors.white, // Set the text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: Text(
            confirmButtonText,
            style: const TextStyle(
              fontFamily: 'Rubik',
              fontSize: 16.0,
              color: Colors.white,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // User pressed the delete button
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyle.red, // Set the button color
            foregroundColor: AppStyle.white, // Set the text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: Text(
            cancelButtonText,
            style: const TextStyle(
              fontFamily: 'Rubik',
              fontSize: 16.0,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
