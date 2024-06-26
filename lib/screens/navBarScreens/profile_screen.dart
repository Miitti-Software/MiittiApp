//TODO: New UI

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/screens/adminPanel/admin_homepage.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/services/providers.dart';
import 'package:miitti_app/widgets/anonymous_dialog.dart';
import 'package:miitti_app/screens/anonymous_user_screen.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/screens/my_profile_edit_form.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late List<String> filteredActivities = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500)).then((value) {
      if (ref.read(isAnonymous)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => const AnonymousDialog(),
          );
        });
      } else {
        filteredActivities = ref
            .read(firestoreService)
            .miittiUser!
            .userFavoriteActivities
            .toList();
      }
    });
  }

  Widget getAdminButton() {
    if (adminId.contains(ref.read(authService).uid)) {
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
    bool isLoading = ref.watch(providerLoading);
    bool anonymous = ref.read(isAnonymous);

    if (anonymous) {
      return const AnonymousUserScreen();
    } else {
      List<String> answeredQuestions = questionOrder
          .where((question) => ref
              .read(firestoreService)
              .miittiUser!
              .userChoices
              .containsKey(question))
          .toList();
      return Scaffold(
        appBar: buildAppBar(),
        body: buildBody(isLoading, answeredQuestions),
      );
    }
  }

  AppBar buildAppBar() {
    return AppBar(
      backgroundColor: AppStyle.black,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            ref.read(firestoreService).miittiUser!.userName,
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
                        user: ref.read(firestoreService).miittiUser!,
                      )));
            },
            child: Icon(
              Icons.settings,
              size: 30.r,
              color: Colors.white,
            ),
          ),
          getAdminButton(),
        ],
      ),
    );
  }

  Widget buildBody(bool isLoading, List<String> answeredQuestions) {
    List<Widget> widgets = [];

    // Always add the profile image card at the beginning
    widgets.add(buildProfileImageCard());

    // Add the first question card and user details card
    String firstQuestion = answeredQuestions[0];
    String firstAnswer =
        ref.read(firestoreService).miittiUser!.userChoices[firstQuestion]!;
    widgets.add(buildQuestionCard(firstQuestion, firstAnswer));
    widgets.add(buildUserDetailsCard());

    // If there are more than one answered questions, add activities grid and subsequent question cards
    if (answeredQuestions.length > 1) {
      for (var i = 1; i < answeredQuestions.length; i++) {
        String question = answeredQuestions[i];
        String answer =
            ref.read(firestoreService).miittiUser!.userChoices[question]!;
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

  Widget buildProfileImageCard() {
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
          ref.read(firestoreService).miittiUser!.profilePicture,
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

  Widget buildUserDetailsCard() {
    MiittiUser miittiUser = ref.read(firestoreService).miittiUser!;
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
        height: miittiUser.userSchool.isNotEmpty ? 330.w : 240.w,
        margin: EdgeInsets.only(
          left: 5.w,
          top: 10.h,
        ),
        child: Column(
          children: [
            buildUserDetailTile(Icons.location_on, miittiUser.userArea),
            buildDivider(),
            buildUserDetailTile(Icons.person, miittiUser.userGender),
            buildDivider(),
            buildUserDetailTile(
                Icons.cake, calculateAge(miittiUser.userBirthday).toString()),
            buildDivider(),
            buildUserDetailTile(
                Icons.g_translate, miittiUser.userLanguages.join(', ')),
            miittiUser.userSchool.isNotEmpty ? buildDivider() : Container(),
            miittiUser.userSchool.isNotEmpty
                ? buildUserDetailTile(Icons.next_week, miittiUser.userSchool)
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
