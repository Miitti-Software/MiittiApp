import 'package:flutter/material.dart';

class SafeScaffold extends StatelessWidget {
  final Widget child;
  const SafeScaffold(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: child,
      ),
    );
  }
}
