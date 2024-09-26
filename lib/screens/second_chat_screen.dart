import 'package:flutter/material.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/widgets/safe_scaffold.dart';

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
    return SafeScaffold(
      Column(
        children: [
          getOurTextField(
            myController: messageController,
            myPadding: const EdgeInsets.all(8.0),
            myFocusNode: messageChatFocus,
            myOnTap: () {
              if (messageChatFocus.hasFocus) {
                messageChatFocus.unfocus();
              }
            },
            mySuffixIcon: GestureDetector(
              onTap: () {},
              child: Container(
                height: 50,
                width: 50,
                margin: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppStyle.red,
                      AppStyle.pink,
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
    );
  }
}
