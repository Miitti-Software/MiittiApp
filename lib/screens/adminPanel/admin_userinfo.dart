import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_user.dart';

class AdminUserInfo extends StatefulWidget {
  final MiittiUser user;
  const AdminUserInfo({required this.user, super.key});

  @override
  State<AdminUserInfo> createState() => _AdminUserInfoState();
}

class _AdminUserInfoState extends State<AdminUserInfo> {
  String userLastOpenDate = "";

  @override
  void initState() {
    userLastOpenDate = widget.user.userStatus.isEmpty
        ? ''
        : DateFormat('MMMM d, HH:mm')
            .format(DateTime.tryParse(widget.user.userStatus)!);
    super.initState();
  }

  //Creates 3 of the purple info boxes
  Widget createPurpleBox(
      String title, String mainText, BuildContext context, bool isCopy) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.h),
      height: 100.h,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppStyle.violet,
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          mainText,
          style: TextStyle(
            fontSize: 18.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: isCopy
            ? IconButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: mainText));
                },
                icon: Icon(
                  Icons.copy,
                  size: 20.sp,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget getRichText(String normalText, String boldedText) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black),
        children: <TextSpan>[
          TextSpan(
            text: normalText,
            style: TextStyle(fontSize: 15.sp),
          ),
          TextSpan(
            text: boldedText,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 40.h),
                  height: 60.h,
                  width: 60.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: AppStyle.pinkGradient,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30.r,
                  ),
                ),
              ),
              Text(
                'Käyttäjätiedot',
                style: TextStyle(
                  fontSize: 20.sp,
                ),
              ),
              createPurpleBox('Etunimi', widget.user.userName, context, false),
              createPurpleBox(
                  'Sähköposti', widget.user.userEmail, context, true),
              createPurpleBox(
                  'Puhelinnumero', widget.user.userPhoneNumber, context, true),
              getRichText('Ollut viimeksi aktiivisena:   ', userLastOpenDate),
              SizedBox(height: 5.h),
              getRichText(
                  'Profiili luotu:  ', widget.user.userRegistrationDate),
              SizedBox(height: 5.h),
              getRichText('Käytössä oleva sovellusversio:  ', '1.2.8'),
            ],
          ),
        ),
      ),
    );
  }
}
