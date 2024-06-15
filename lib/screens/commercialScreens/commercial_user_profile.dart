import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/models/commercial_user.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:url_launcher/url_launcher.dart';

class CommercialProfileScreen extends StatefulWidget {
  final CommercialUser user;
  final bool? comingFromAdmin;
  const CommercialProfileScreen(
      {required this.user, this.comingFromAdmin, super.key});

  @override
  State<CommercialProfileScreen> createState() =>
      _CommercialProfileScreenState();
}

class _CommercialProfileScreenState extends State<CommercialProfileScreen> {
  Color miittiColor = const Color.fromRGBO(255, 136, 27, 1);

  @override
  void initState() {
    super.initState();
    //Initialize the list from given data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.h),
        child: AppBar(
          backgroundColor: AppStyle.black,
          automaticallyImplyLeading: false,
          title: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(top: 20.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.user.name,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: EdgeInsets.symmetric(
              vertical: 12.h,
              horizontal: 12.w,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  child: Image.network(
                    widget.user.profilePicture,
                    height: 400.h,
                    width: 400.w,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                Positioned(
                  top: 10.h,
                  left: 10.w,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(15.w),
                      decoration: BoxDecoration(
                        color: miittiColor,
                        gradient: AppStyle.pinkGradient,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 30.r,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 10.h,
          ),
          Padding(
            padding: EdgeInsets.all(8.0.w),
            child: InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.user.linkTitle,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 17.0.sp,
                        color: AppStyle.lightPurple,
                      ),
                    ),
                    SizedBox(
                      width: 4.0.w,
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12.0.sp,
                      color: Colors.white,
                    )
                  ],
                ),
                onTap: () async {
                  await launchUrl(Uri.parse(widget.user.hyperlink));
                }),
          ),
          SizedBox(
            height: 10.h,
          ),
          Padding(
            padding: EdgeInsets.all(8.0.w),
            child: Text(
              widget.user.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 17.0.sp,
                color: AppStyle.white,
              ),
            ),
          ),
          SizedBox(
            height: 10.h,
          ),
        ],
      ),
    );
  }
}
