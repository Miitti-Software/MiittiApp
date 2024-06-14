import 'package:flutter/material.dart';
import 'package:miitti_app/constants/app_style.dart';

class AnonymousUserScreen extends StatelessWidget {
  const AnonymousUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Et ole vielä viimeistellyt profiiliasi, joten\n et voi käyttää vielä sovelluksen kaikkia ominaisuuksia.',
          style: AppStyle.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
