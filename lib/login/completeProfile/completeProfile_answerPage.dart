import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/constants_customButton.dart';

import 'package:miitti_app/constants/constants_styles.dart';
import 'package:miitti_app/utils/utils.dart';

class CompleteProfileAnswerPage extends StatefulWidget {
  final String question;
  final String? questionAnswer;

  const CompleteProfileAnswerPage({
    required this.question,
    required this.questionAnswer,
    super.key,
  });

  @override
  State<CompleteProfileAnswerPage> createState() =>
      _CompleteProfileAnswerPageState();
}

class _CompleteProfileAnswerPageState extends State<CompleteProfileAnswerPage> {
  late TextEditingController answerController;

  @override
  void initState() {
    super.initState();
    answerController = TextEditingController();
    if (widget.questionAnswer != null) {
      answerController.text = widget.questionAnswer!;
    }
  }

  @override
  void dispose() {
    answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.question,
                  style: ConstantStyles.question,
                ),
                ConstantStyles().gapH10,
                TextFormField(
                  maxLines: 5,
                  maxLength: 150,
                  controller: answerController,
                  style: ConstantStyles.hintText.copyWith(color: Colors.white),
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(
                        color: ConstantStyles.pink,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(
                        color: ConstantStyles.pink,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                ConstantStyles().gapH20,
                ConstantsCustomButton(
                  buttonText: 'Tallenna',
                  onPressed: () {
                    Navigator.pop(context, answerController.text.trim());
                  },
                ),
                ConstantStyles().gapH10,
                ConstantsCustomButton(
                  buttonText: 'Takaisin',
                  isWhiteButton: true,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
