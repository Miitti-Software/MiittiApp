import 'package:flutter/material.dart';
import 'package:miitti_app/constants/app_style.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: const SafeArea(
        child: Center(
          child: Text(
            'COMING SOON...',
            style: TextStyle(
              color: AppStyle.black,
              fontSize: 40,
            ),
          ),
        ),
      ),
    );
  }
}
