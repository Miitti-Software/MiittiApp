import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// A widget that displays rich text with underlined, clickable links
class DynamicRichText extends StatelessWidget {
  final List<Map<String, dynamic>> richTextData;
  final TextStyle? textStyle;
  final TextAlign? textAlign;

  const DynamicRichText({super.key, required this.richTextData, required this.textStyle, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      text: TextSpan(
        style: textStyle,
        children: richTextData.map<TextSpan>((item) {
          if (item.containsKey('url')) {
            return TextSpan(
              text: item['text'],
              style: textStyle?.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: textStyle?.color,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  launchUrl(Uri.parse(item['url']));
                },
            );
          } else {
            return TextSpan(text: item['text']);
          }
        }).toList(),
      ),
    );
  }
}