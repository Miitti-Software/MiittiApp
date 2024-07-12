import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/app_texts.dart';
import 'package:miitti_app/services/providers.dart';
import 'package:miitti_app/widgets/buttons/custom_button.dart';
import 'package:miitti_app/widgets/fields/custom_textfield.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/widgets/safe_scaffold.dart';

//TODO: Refactor
class PhoneAuth extends ConsumerStatefulWidget {
  const PhoneAuth({super.key});

  @override
  ConsumerState<PhoneAuth> createState() => _PhoneAuthState();
}

class _PhoneAuthState extends ConsumerState<PhoneAuth> {
  late FocusNode myFocusNode;

  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    myFocusNode = FocusNode();
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            gapH50,
            Center(child: getMiittiLogo),

            const Spacer(),

            Text(
              t('whats-your-phone-number'),
              style: AppStyle.title.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            gapH20,

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 60,
                decoration: const BoxDecoration(
                  color: AppStyle.pink,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                child: Text(
                  '+358',
                  textAlign: TextAlign.center,
                  style: AppStyle.hintText.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              title: MyTextField(
                hintText: '000000000',
                controller: phoneController,
                keyboardType: TextInputType.number,
                focusNode: myFocusNode,
              ),
            ),

            gapH8,

            Text(
              t('we-send-verif-code-soon'),
              style: AppStyle.warning,
            ),

            const Spacer(),

            MyButton(
              buttonText: t('next'),
              onPressed: () {
                if (phoneController.text.trim().isNotEmpty) {
                  sendPhoneNumberToFirebase();
                } else {
                  showSnackBar(
                      context, t('phone-number-cannot-be-empty'), AppStyle.red);
                }
              },
            ), //Removed extra padding in ConstantsCustomButton
            gapH10,

            MyButton(
              buttonText: 'Takaisin',
              isWhiteButton: true,
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            if (myFocusNode.hasFocus) gapH20
          ],
        ),
      ),
    );
  }

  void sendPhoneNumberToFirebase() {
    String phoneNumber = phoneController.text.trim();
    if (phoneNumber[0] == '0') {
      // Remove the first character of the phone so it can be put to the format +358449759068
      phoneNumber = phoneNumber.substring(1);
    }
    ref.read(authService).signInWithPhone(context, "+358$phoneNumber");
  }
}
