//TODO: New UI

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/screens/adminPanel/admin_homepage.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/widgets/anonymous_dialog.dart';
import 'package:miitti_app/screens/anonymous_user_screen.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/screens/my_profile_edit_form.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late List<String> filteredActivities = [];

  @override
  void initState() {
    super.initState();
    final ap = Provider.of<AuthProvider>(context, listen: false);
    Future.delayed(const Duration(milliseconds: 500)).then((value) {
      if (ap.isAnonymous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => const AnonymousDialog(),
          );
        });
      } else {
        filteredActivities = ap.miittiUser.userFavoriteActivities.toList();
      }
    });
  }

  Widget getAdminButton(AuthProvider ap) {
    if (adminId.contains(ap.miittiUser.uid)) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AdminHomePage()));
        },
        child: Container(
          margin: EdgeInsets.only(left: 20.w),
          child: Icon(
            Icons.admin_panel_settings_rounded,
            size: 30.r,
            color: Colors.white,
          ),
        ),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider ap = Provider.of<AuthProvider>(context, listen: true);
    bool isLoading = ap.isLoading;
    bool isAnonymous = ap.isAnonymous;

    if (isAnonymous) {
      return const AnonymousUserScreen();
    } else {
      List<String> answeredQuestions = questionOrder
          .where((question) => ap.miittiUser.userChoices.containsKey(question))
          .toList();
      return Scaffold(
        appBar: buildAppBar(ap),
        body: buildBody(isLoading, ap, answeredQuestions),
      );
    }
  }

  AppBar buildAppBar(AuthProvider ap) {
    return AppBar(
      backgroundColor: AppStyle.black,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            ap.miittiUser.userName,
            style: TextStyle(
              fontSize: 30.sp,
              fontFamily: 'Sora',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Expanded(child: SizedBox()),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => MyProfileEditForm(
                        user: ap.miittiUser,
                      )));
            },
            child: Icon(
              Icons.settings,
              size: 30.r,
              color: Colors.white,
            ),
          ),
          getAdminButton(ap),
        ],
      ),
    );
  }

  Widget buildBody(
      bool isLoading, AuthProvider ap, List<String> answeredQuestions) {
    List<Widget> widgets = [];

    // Always add the profile image card at the beginning
    widgets.add(buildProfileImageCard(ap));

    // Add the first question card and user details card
    String firstQuestion = answeredQuestions[0];
    String firstAnswer = ap.miittiUser.userChoices[firstQuestion]!;
    widgets.add(buildQuestionCard(firstQuestion, firstAnswer));
    widgets.add(buildUserDetailsCard(ap));

    // If there are more than one answered questions, add activities grid and subsequent question cards
    if (answeredQuestions.length > 1) {
      for (var i = 1; i < answeredQuestions.length; i++) {
        String question = answeredQuestions[i];
        String answer = ap.miittiUser.userChoices[question]!;
        widgets.add(buildQuestionCard(question, answer));

        // Add activities grid after the first additional question card
        if (i == 1) {
          widgets.add(buildActivitiesGrid());
        }
      }
    } else {
      // If there's only one answered question, add activities grid
      widgets.add(buildActivitiesGrid());
    }

    return ListView(children: widgets);
  }

  Widget buildProfileImageCard(AuthProvider ap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.symmetric(
        vertical: 15.h,
        horizontal: 15.w,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        child: Image.network(
          ap.miittiUser.profilePicture,
          height: 400.h,
          width: 400.w,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget buildQuestionCard(String question, String answer) {
    return Container(
      padding: EdgeInsets.all(15.w),
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 15.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppStyle.violet,
              fontSize: 18.sp,
              fontFamily: 'Rubik',
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            answer,
            maxLines: 4,
            style: TextStyle(
              color: Colors.black,
              overflow: TextOverflow.clip,
              fontSize: 20.sp,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUserDetailsCard(AuthProvider ap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.symmetric(
        vertical: 15.h,
        horizontal: 15.w,
      ),
      child: Container(
        height: ap.miittiUser.userSchool.isNotEmpty ? 330.w : 240.w,
        margin: EdgeInsets.only(
          left: 5.w,
          top: 10.h,
        ),
        child: Column(
          children: [
            buildUserDetailTile(Icons.location_on, ap.miittiUser.userArea),
            buildDivider(),
            buildUserDetailTile(Icons.person, ap.miittiUser.userGender),
            buildDivider(),
            buildUserDetailTile(Icons.cake,
                calculateAge(ap.miittiUser.userBirthday).toString()),
            buildDivider(),
            buildUserDetailTile(
                Icons.g_translate, ap.miittiUser.userLanguages.join(', ')),
            ap.miittiUser.userSchool.isNotEmpty ? buildDivider() : Container(),
            ap.miittiUser.userSchool.isNotEmpty
                ? buildUserDetailTile(Icons.next_week, ap.miittiUser.userSchool)
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget buildUserDetailTile(IconData icon, String text) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppStyle.lightPurple,
        size: 30.sp,
      ),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 24.sp,
          color: Colors.black,
          fontFamily: 'Rubik',
        ),
      ),
    );
  }

  Widget buildDivider() {
    return const Divider(
      color: Colors.grey,
      thickness: 0.75,
      height: 0,
      endIndent: 10.0,
      indent: 10.0,
    );
  }

  double returnActivitiesGridSize(int listLenght) {
    if (listLenght > 6) {
      return 375.w;
    } else if (listLenght > 3) {
      return 250.w;
    } else {
      return 125.w;
    }
  }

  Widget buildActivitiesGrid() {
    return Padding(
      padding: EdgeInsets.all(15.0.w),
      child: SizedBox(
        height: returnActivitiesGridSize(filteredActivities.length),
        child: GridView.builder(
          itemCount: filteredActivities.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemBuilder: (context, index) {
            final activity = filteredActivities[index];
            return buildActivityItem(Activity.getActivity(activity));
          },
        ),
      ),
    );
  }

  Widget buildActivityItem(Activity activity) {
    return Container(
      height: 100.h,
      width: 50.w,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      child: Column(
        children: [
          Text(
            activity.emojiData,
            style: TextStyle(fontSize: 50.0.sp),
          ),
          Text(
            activity.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Rubik',
              fontSize: 15.0.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
