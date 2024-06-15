import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/models/person_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/widgets/confirmdialog.dart';
import 'package:miitti_app/services/auth_provider.dart';
import 'package:miitti_app/functions/push_notifications.dart';

import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/widgets/my_elevated_button.dart';
import 'package:provider/provider.dart';

class UserProfileEditScreen extends StatefulWidget {
  final MiittiUser user;
  final bool? comingFromAdmin;

  const UserProfileEditScreen({
    required this.user,
    this.comingFromAdmin,
    super.key,
  });

  @override
  State<UserProfileEditScreen> createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<UserProfileEditScreen> {
  Color miittiColor = const Color.fromRGBO(255, 136, 27, 1);

  List<String> filteredActivities = [];
  List<PersonActivity> userRequests = [];

  @override
  void initState() {
    super.initState();
    //Initialize the list from given data
    initRequests(Provider.of<AuthProvider>(context, listen: false));
    filteredActivities = widget.user.userFavoriteActivities.toList();
  }

  void initRequests(AuthProvider ap) async {
    ap.fetchActivitiesRequestsFrom(widget.user.uid).then((value) {
      setState(() {
        userRequests = value;
      });
      debugPrint("Fetched ${value.length} requests");
    });
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider ap = Provider.of<AuthProvider>(context, listen: true);
    //final isLoading = ap.isLoading;

    List<String> answeredQuestions = questionOrder
        .where((question) => widget.user.userChoices.containsKey(question))
        .toList();

    return Scaffold(
      appBar: buildAppBar(),
      body: buildBody(ap.isLoading, ap, answeredQuestions),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      backgroundColor: AppStyle.black,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.user.userName,
            style: TextStyle(
              fontSize: 30.sp,
              fontFamily: 'Sora',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          buildUserStatus(),
        ],
      ),
    );
  }

  Widget buildBody(
      bool isLoading, AuthProvider ap, List<String> answeredQuestions) {
    List<Widget> widgets = [];

    if (isLoading) {
      debugPrint("IsLoading");
    }

    // Always add the profile image card at the beginning
    widgets.add(buildProfileImageCard());

    // Add the first question card and user details card
    String firstQuestion = answeredQuestions[0];
    String firstAnswer = widget.user.userChoices[firstQuestion]!;
    widgets.add(buildQuestionCard(firstQuestion, firstAnswer));
    widgets.add(buildUserDetailsCard());

    // If there are more than one answered questions, add activities grid and subsequent question cards
    if (answeredQuestions.length > 1) {
      for (var i = 1; i < answeredQuestions.length; i++) {
        String question = answeredQuestions[i];
        String answer = widget.user.userChoices[question]!;
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

    // Add invite button and report user button
    if (userRequests.isNotEmpty) {
      widgets.add(requestList(ap));
    }

    widgets.add(buildInviteButton(isLoading, ap));
    widgets.add(buildReportUserButton(ap));

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
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            child: Image.network(
              widget.user.profilePicture,
              height: 400.h,
              width: 400.w,
              fit: BoxFit.cover,
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
    );
  }

  Widget buildAnsweredQuestionsCard(List<String> answeredQuestions) {
    return SizedBox(
      height: 210.h,
      child: PageView.builder(
        itemCount: widget.user.userChoices.length,
        itemBuilder: (context, index) {
          String question = answeredQuestions[index];
          String answer = widget.user.userChoices[question]!;
          return buildQuestionCard(question, answer);
        },
      ),
    );
  }

  Widget buildQuestionCard(String question, String answer) {
    return Container(
      padding: EdgeInsets.all(15.w),
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            textAlign: TextAlign.start,
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
        height: 320.w,
        margin: EdgeInsets.only(
          left: 5.w,
          top: 10.h,
        ),
        child: Column(
          children: [
            buildUserDetailTile(Icons.location_on, widget.user.userArea),
            buildDivider(),
            buildUserDetailTile(Icons.person, widget.user.userGender),
            buildDivider(),
            buildUserDetailTile(
                Icons.cake, calculateAge(widget.user.userBirthday).toString()),
            buildDivider(),
            buildUserDetailTile(
                Icons.g_translate, widget.user.userLanguages.join(', ')),
            buildDivider(),
            buildUserDetailTile(Icons.next_week, 'Opiskelija'),
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

  Widget buildInviteButton(bool isLoading, AuthProvider ap) {
    return widget.comingFromAdmin != null
        ? Container()
        : Container(
            margin: EdgeInsets.symmetric(
              vertical: 15.h,
              horizontal: 15.w,
            ),
            child: MyElevatedButton(
              onPressed: () => inviteToYourActivity(),
              child: isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : Text(
                      'Kutsu miittiin',
                      style: AppStyle.body,
                    ),
            ),
          );
  }

  Widget buildReportUserButton(AuthProvider ap) {
    return Center(
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return const ConfirmDialog(
                title: 'Vahvistus',
                leftButtonText: 'Ilmianna',
                mainText: 'Oletko varma, että haluat ilmiantaa käyttäjän?',
              );
            },
          ).then((confirmed) {
            if (confirmed) {
              ap.reportUser('User blocked', widget.user.uid, ap.uid);

              Navigator.of(context).pop();
              showSnackBar(
                  context, "Käyttäjä ilmiannettu", Colors.green.shade800);
            }
          });
        },
        child: Text(
          "Ilmianna käyttäjä",
          style: TextStyle(
            fontFamily: 'Rubik',
            fontSize: 19.sp,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Future<void> inviteToYourActivity() async {
    final ap = Provider.of<AuthProvider>(context, listen: false);
    List<PersonActivity> myActivities = await ap.fetchAdminActivities();

    if (myActivities.isNotEmpty) {
      if (myActivities.length == 1 &&
          myActivities.first.participants.length <
              myActivities.first.personLimit &&
          !myActivities.first.participants.contains(widget.user.uid) &&
          !myActivities.first.requests.contains(widget.user.uid)) {
        ap
            .inviteUserToYourActivity(
                widget.user.uid, myActivities.first.activityUid)
            .then((value) {
          PushNotifications.sendInviteNotification(
              ap.miittiUser, widget.user, myActivities.first);
          showDialog(
            context: context,
            barrierColor: Colors.white.withOpacity(0.9),
            builder: (BuildContext context) {
              return createInviteActivityDialog();
            },
          );
        });
      } else if (myActivities.length > 1) {
        //If user has 2 or more activites to invite to
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierColor: Colors.white.withOpacity(0.9),
            builder: (BuildContext context) {
              return createSelectBetweenActivitesDialog(myActivities);
            },
          );
        });
      } else {
        // Show some red dialog
        debugPrint("You do not have any activities for people to invite");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showSnackBar(
              context,
              "Sinulla ei ole miittejä, joihin voit kutsua tämän henkilön.",
              Colors.red.shade800);
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSnackBar(context, "Sinun täytyy luoda miitti ensin!",
            Colors.orange.shade800);
      });
    }
  }

  Widget buildUserStatus() {
    Color color;
    String status = getUserStatus();

    switch (status) {
      case 'Paikalla':
        color = Colors.green;
        break;
      case 'Paikalla äskettäin':
        color = Colors.lightGreen;
        break;
      case 'Paikalla tänään':
        color = Colors.lightBlue.shade300;
        break;
      case 'Paikalla tällä viikolla':
        color = Colors.orange;
        break;
      case 'Epäaktiivinen':
      default:
        color = Colors.red;
    }
    return Text(
      status.isNotEmpty ? '● $status' : "",
      style: TextStyle(
        color: color,
        fontSize: 15.0.sp,
        fontFamily: 'Sora',
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String getUserStatus() {
    if (widget.user.userStatus.isEmpty || widget.user.userStatus == 'Online') {
      return '';
    } else {
      String lastActiveString = widget.user.userStatus;
      DateTime lastActiveDate = DateTime.parse(lastActiveString).toLocal();
      Duration difference = DateTime.now().difference(lastActiveDate);

      if (difference < const Duration(minutes: 5)) {
        return 'Paikalla';
      } else if (difference < const Duration(hours: 1)) {
        return 'Paikalla äskettäin';
      } else if (difference < const Duration(hours: 24)) {
        return 'Paikalla tänään';
      } else if (difference < const Duration(days: 7)) {
        return 'Paikalla tällä viikolla';
      } else if (difference > const Duration(days: 7)) {
        return 'Epäaktiivinen';
      } else {
        return 'Paikalla';
      }
    }
  }

  Widget createSelectBetweenActivitesDialog(List<PersonActivity> myActivities) {
    final ap = Provider.of<AuthProvider>(context, listen: false);

    return AlertDialog(
      backgroundColor: AppStyle.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: SizedBox(
        height: 330.w,
        width: 330.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'images/thinkingFace.png',
              height: 125.w,
              width: 125.w,
            ),
            Text(
              'Valitse kutsuttava aktiviteetti',
              textAlign: TextAlign.center,
              style: AppStyle.body,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: myActivities.length,
                itemBuilder: (context, index) {
                  PersonActivity activity = myActivities[index];
                  return ListTile(
                    leading: Image.asset(
                      'images/${activity.activityCategory.toLowerCase()}.png',
                    ),
                    subtitle: Text(
                      activity.activityDescription,
                      style: const TextStyle(
                        fontFamily: 'Rubik',
                        overflow: TextOverflow.ellipsis,
                        color: AppStyle.white,
                      ),
                    ),
                    title: Text(
                      activity.activityTitle,
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 19.sp,
                        overflow: TextOverflow.ellipsis,
                        color: AppStyle.white,
                      ),
                    ),
                    onTap: () {
                      if (activity.participants.length < activity.personLimit &&
                          !activity.participants.contains(widget.user.uid) &&
                          !activity.requests.contains(widget.user.uid)) {
                        ap
                            .inviteUserToYourActivity(
                                widget.user.uid, activity.activityUid)
                            .then((value) {
                          PushNotifications.sendInviteNotification(
                              ap.miittiUser, widget.user, activity);
                          Navigator.of(context).pop(); // Close the SimpleDialog
                          showDialog(
                            context: context,
                            barrierColor: Colors.white.withOpacity(0.9),
                            builder: (BuildContext context) {
                              return createInviteActivityDialog();
                            },
                          );
                        });
                      } else {
                        Navigator.of(context).pop();
                        // Show a dialog or some other UI element indicating that this activity is full or the user is already a participant/requested to join
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget createInviteActivityDialog() {
    return AlertDialog(
      backgroundColor: AppStyle.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: SizedBox(
        height: 300.w,
        width: 300.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'images/postbox.png',
              height: 125.w,
              width: 125.w,
            ),
            Text(
              'Kutsu miittisi on lähetetty',
              textAlign: TextAlign.center,
              style: AppStyle.body,
            ),
            Text(
              'Kun ${widget.user.userName} on hyväksynyt kutsun liittyvä miittisi, saat siitä push ilmoituksen',
              textAlign: TextAlign.center,
              style: AppStyle.body,
            ),
            MyElevatedButton(
              height: 45.h,
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, 2);
              },
              child: Text(
                'Kutsu muita',
                style: AppStyle.title,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget requestList(AuthProvider ap) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 15.h,
        horizontal: 15.w,
      ),
      padding: EdgeInsets.all(15.0.w),
      decoration: BoxDecoration(
        color: AppStyle.black,
        border: Border.all(
          color: AppStyle.darkPurple,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${widget.user.userName} on pyytäny päästä miittiisi:",
              textAlign: TextAlign.start,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontFamily: 'Rubik',
              )),
          Column(
              children: userRequests
                  .map<Widget>((activity) => requestItem(activity, ap))
                  .toList()),
        ],
      ),
    );
  }

  Widget requestItem(PersonActivity activity, AuthProvider ap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.0.h),
        Text(
            "${activities[activity.activityCategory]?.emojiData} ${activity.activityTitle}",
            textAlign: TextAlign.start,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 17.sp,
              fontFamily: 'Rubik',
            )),
        SizedBox(
          height: 6.0.h,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyElevatedButton(
              height: 40.h,
              width: 140.w,
              onPressed: () async {
                ap
                    .updateUserJoiningActivity(
                        activity.activityUid, widget.user.uid, false)
                    .then((value) {
                  setState(() {
                    initRequests(ap);
                  });
                });
              },
              child: Text(
                "Hylkää",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
            SizedBox(
              width: 12.w,
            ),
            MyElevatedButton(
              height: 40.h,
              width: 140.w,
              onPressed: () async {
                ap
                    .updateUserJoiningActivity(
                        activity.activityUid, widget.user.uid, true)
                    .then((value) {
                  setState(() {
                    initRequests(ap);
                  });
                  if (value) {
                    PushNotifications.sendAcceptedNotification(
                        widget.user, activity);
                  }
                });
              },
              child: Text(
                "Hyväksy",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
