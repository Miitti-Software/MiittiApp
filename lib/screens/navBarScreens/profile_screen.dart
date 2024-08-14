//TODO: New UI

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/screens/adminPanel/admin_homepage.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/anonymous_dialog.dart';
import 'package:miitti_app/screens/anonymous_user_screen.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/screens/my_profile_edit_form.dart';
import 'package:miitti_app/functions/utils.dart';


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
    Future.delayed(const Duration(milliseconds: 10)).then((value) {
      if (ref.read(firestoreServiceProvider).isAnonymous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => const AnonymousDialog(),
          );
        });
      } else {
        filteredActivities = ref
            .read(firestoreServiceProvider)
            .miittiUser!
            .favoriteActivities
            .toList();
      }
    });
  }

  Widget getAdminButton() {
    if (adminId.contains(ref.read(authServiceProvider).uid)) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AdminHomePage()));
        },
        child: Container(
          margin: const EdgeInsets.only(left: 20),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            size: 30,
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
    bool anonymous = ref.read(firestoreServiceProvider).isAnonymous;

    if (anonymous) {
      return const AnonymousUserScreen();
    } else {
      List<String> answeredQuestions = questionOrder
          .where((question) => ref
              .read(firestoreServiceProvider)
              .miittiUser!
              .qaAnswers
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
            ref.read(firestoreServiceProvider).miittiUser!.name,
            style: const TextStyle(
              fontSize: 30,
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
                        user: ref.read(firestoreServiceProvider).miittiUser!,
                      )));
            },
            child: const Icon(
              Icons.settings,
              size: 30,
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
        ref.read(firestoreServiceProvider).miittiUser!.qaAnswers[firstQuestion]!;
    widgets.add(buildQuestionCard(firstQuestion, firstAnswer));
    widgets.add(buildUserDetailsCard());

    // If there are more than one answered questions, add activities grid and subsequent question cards
    if (answeredQuestions.length > 1) {
      for (var i = 1; i < answeredQuestions.length; i++) {
        String question = answeredQuestions[i];
        String answer =
            ref.read(firestoreServiceProvider).miittiUser!.qaAnswers[question]!;
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
      margin: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 15,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        child: Image.network(
          ref.read(firestoreServiceProvider).miittiUser!.profilePicture,
          height: 400,
          width: 400,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget buildQuestionCard(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
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
            style: const TextStyle(
              color: AppStyle.violet,
              fontSize: 18,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            answer,
            maxLines: 4,
            style: const TextStyle(
              color: Colors.black,
              overflow: TextOverflow.clip,
              fontSize: 20,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUserDetailsCard() {
    MiittiUser miittiUser = ref.read(firestoreServiceProvider).miittiUser!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 15,
      ),
      child: Container(
        height: miittiUser.associatedOrganization.isNotEmpty ? 330 : 240,
        margin: const EdgeInsets.only(
          left: 5,
          top: 10,
        ),
        child: Column(
          children: [
            buildUserDetailTile(Icons.location_on, miittiUser.area),
            buildDivider(),
            buildUserDetailTile(Icons.person, miittiUser.gender),
            buildDivider(),
            buildUserDetailTile(
                Icons.cake, calculateAge(miittiUser.birthday).toString()),
            buildDivider(),
            buildUserDetailTile(
                Icons.g_translate, miittiUser.languages.join(', ')),
            miittiUser.associatedOrganization.isNotEmpty ? buildDivider() : Container(),
            miittiUser.associatedOrganization.isNotEmpty
                ? buildUserDetailTile(Icons.next_week, miittiUser.associatedOrganization)
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
        size: 30,
      ),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
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
      return 375;
    } else if (listLenght > 3) {
      return 250;
    } else {
      return 125;
    }
  }

  Widget buildActivitiesGrid() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
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
      height: 100,
      width: 50,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      child: Column(
        children: [
          Text(
            activity.emojiData,
            style: const TextStyle(fontSize: 50.0),
          ),
          Text(
            activity.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Rubik',
              fontSize: 15.0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
