import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/services/providers.dart';
import 'package:miitti_app/widgets/buttons/custom_button.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/widgets/other_widgets.dart';

class ConfirmNotificationsDialog extends ConsumerWidget {
  const ConfirmNotificationsDialog({super.key, required this.nextPage});

  final Function nextPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              alignment: Alignment.bottomCenter,
              decoration: const BoxDecoration(
                color: AppStyle.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  children: [
                    const Divider(
                      color: Colors.white,
                      thickness: 2.0,
                      indent: 100,
                      endIndent: 100,
                    ),
                    Text(
                      'Hei!',
                      style: AppStyle.title,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Text(
                        'Oletko aivan varma valinnastasi. Sovellusilmoitukset ovat sinua varten. Missaat paljon ilman niitä.',
                        style: AppStyle.body,
                      ),
                    ),
                    getSomeSpace(10),
                    MyButton(
                      buttonText: 'Hyväksy ilmoitukset',
                      onPressed: () async {
                        bool granted = await ref
                            .read(notificationService)
                            .requestPermission(true);
                        if (granted) {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          nextPage();
                        } else {
                          if (context.mounted) {
                            showSnackBar(
                                context,
                                "Sinun täytyy sallia ilmoitukset myös laitteeltasi jatkaaksesi",
                                AppStyle.red);
                          }
                        }
                      },
                    ), //Removed extra padding in ConstantsCustomButton
                    gapH10,
                    MyButton(
                      buttonText: 'Ei vielä',
                      isWhiteButton: true,
                      onPressed: () {
                        Navigator.pop(context);
                        nextPage();
                      },
                    ), //Removed extra padding in ConstantsCustomButton
                    getSomeSpace(10.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
