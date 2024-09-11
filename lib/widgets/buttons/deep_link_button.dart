import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeepLinkButton extends StatefulWidget {
  final String route;

  const DeepLinkButton({Key? key, required this.route}) : super(key: key);

  @override
  _LinkButtonState createState() => _LinkButtonState();
}

class _LinkButtonState extends State<DeepLinkButton> {
  bool linkCreated = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          linkCreated = true;
        });
        await Clipboard.setData(ClipboardData(text: widget.route));
        ScaffoldMessenger.of(context).showSnackBar(                                       // TODO: Use Flutter toast?
          const SnackBar(content: Text('Route copied to clipboard!')),
        );
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: AnimatedRotation(
        turns: linkCreated ? 0.5 : 0,
        duration: const Duration(milliseconds: 500),
        child: CircleAvatar(
          backgroundColor: linkCreated ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Theme.of(context).colorScheme.primary,
          child: Icon(
            Icons.link,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}