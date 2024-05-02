import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/utils/utils.dart';

class SecondChatPage extends StatefulWidget {
  const SecondChatPage({super.key});

  @override
  State<SecondChatPage> createState() => _SecondChatPageState();
}

class _SecondChatPageState extends State<SecondChatPage> {
  late TextEditingController messageController;
  late FocusNode messageChatFocus;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    messageChatFocus = FocusNode();
  }

  @override
  void dispose() {
    messageController.dispose();
    messageChatFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            getOurTextField(
              myController: messageController,
              myPadding: EdgeInsets.all(8.0.w),
              myFocusNode: messageChatFocus,
              myOnTap: () {
                if (messageChatFocus.hasFocus) {
                  messageChatFocus.unfocus();
                }
              },
              mySuffixIcon: GestureDetector(
                onTap: () {},
                child: Container(
                  height: 50.w,
                  width: 50.w,
                  margin: EdgeInsets.all(10.0.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.lightRedColor,
                        AppColors.orangeColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              myKeyboardType: TextInputType.multiline,
              maxLines: 8,
              minLines: 1,
              maxLenght: 200,
            ),
          ],
        ),
      ),
    );
  }
}
