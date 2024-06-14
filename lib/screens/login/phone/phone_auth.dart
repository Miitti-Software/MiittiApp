import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/widgets/custom_button.dart';
import 'package:miitti_app/widgets/custom_textfield.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:miitti_app/services/auth_provider.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:provider/provider.dart';

class PhoneAuth extends StatefulWidget {
  const PhoneAuth({super.key});

  @override
  State<PhoneAuth> createState() => _PhoneAuthState();
}

class _PhoneAuthState extends State<PhoneAuth> {
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

  void sendPhoneNumberToFirebase(AuthProvider authProvider) {
    String phoneNumber = phoneController.text.trim();
    if (phoneNumber[0] == '0') {
      // Remove the first character of the phone so  it is in this format +358449759068
      phoneNumber = phoneNumber.substring(1);
    }
    authProvider.signInWithPhone(context, "+358$phoneNumber");
  }

  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AuthProvider>(context, listen: true);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppStyle.gapH50,
              Center(child: OtherWidgets.getMiittiLogo),

              const Spacer(),

              Text(
                'Mikä on puhelinnumerosi?',
                style: AppStyle.title.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              AppStyle.gapH20,

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 60.w,
                  decoration: const BoxDecoration(
                    color: AppStyle.pink,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 13.h,
                  ),
                  child: Text(
                    '+358',
                    textAlign: TextAlign.center,
                    style: AppStyle.hintText.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                title: ConstantsCustomTextField(
                  hintText: '453301000',
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  focusNode: myFocusNode,
                ),
              ),

              AppStyle.gapH8,

              Text(
                'Lähetämme hetken kuluttua vahvistuskoodin sisältävän tekstiviestin.',
                style: AppStyle.warning,
              ),

              const Spacer(),

              CustomButton(
                buttonText: 'Seuraava',
                onPressed: () {
                  if (phoneController.text.trim().isNotEmpty) {
                    sendPhoneNumberToFirebase(ap);
                  } else {
                    showSnackBar(
                        context,
                        'Huom! Sinun täytyy antaa puhelinnumerosi kirjautuaksesi sisään.',
                        AppStyle.red);
                  }
                },
              ), //Removed extra padding in ConstantsCustomButton
              AppStyle.gapH10,

              CustomButton(
                buttonText: 'Takaisin',
                isWhiteButton: true,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),

              if (myFocusNode.hasFocus) AppStyle.gapH20
            ],
          ),
        ),
      ),
    );
  }
}
