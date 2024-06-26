//TODO: Implement new UI

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/screens/anonymous_user_screen.dart';
import 'package:miitti_app/services/auth_provider.dart';
import 'package:miitti_app/screens/user_profile_edit_screen.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/services/providers.dart';
import 'package:miitti_app/widgets/anonymous_dialog.dart';
import 'package:miitti_app/widgets/buttons/my_elevated_button.dart';
import 'package:provider/provider.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  Color miittiColor = const Color.fromRGBO(255, 136, 27, 1);

  final batchSize = 6;

  List<bool> listLoading = [true, true, true];

  List<DocumentSnapshot?> lastDocuments = [null, null, null];

  final List<List<MiittiUser>> _filteredUsers = [[], [], []];

  @override
  void initState() {
    super.initState();
    initLists();
  }

  void initLists() async {
    if (ref.read(isAnonymous)) {
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        showDialog(
            context: context, builder: (context) => const AnonymousDialog());
      });

      return;
    }

    List responses = await Future.wait([initList(0), initList(1), initList(2)]);

    setState(() {
      for (int i = 0; i < 3; i++) {
        _filteredUsers[i] = responses[i];
        listLoading[i] = false;
      }
    });
  }

  Future<List<MiittiUser>> initList(int type) async {
    try {
      QuerySnapshot snapshot =
          await ref.read(firestoreService).lazyFilteredUsers(type, batchSize);
      if (snapshot.docs.isNotEmpty) {
        lastDocuments[type] = snapshot.docs.last;
        return snapshot.docs
            .map((doc) => MiittiUser.fromDoc(doc))
            .where((user) =>
                user.uid != ref.read(authService).uid && user.userName != "")
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  void loadMoreUsers(int type) async {
    if (listLoading[type] || lastDocuments[type] == null) {
      return;
    }

    listLoading[type] = true;
    final snapshot = await ref.read(firestoreService).lazyFilteredUsers(
        type, batchSize + _filteredUsers.length, lastDocuments[type]);
    if (snapshot.docs.isNotEmpty) {
      if (snapshot.docs.length < batchSize) {
        lastDocuments[type] = null;
      } else {
        lastDocuments[type] = snapshot.docs.last;
        debugPrint("updatedLastDoc");
      }

      setState(() {
        _filteredUsers[type].addAll(snapshot.docs
            .map((doc) => MiittiUser.fromDoc(doc))
            .where((user) => user.uid != ref.read(authService).uid)
            .toList());
      });
    } else {
      lastDocuments[type] = null;
    }
    listLoading[type] = false;
  }

  @override
  Widget build(BuildContext context) {
    if (ref.read(isAnonymous)) {
      return const AnonymousUserScreen();
    } else {
      return SafeArea(
          child: ListView(
        padding: EdgeInsets.only(left: 20.w),
        children: [
          _buildSectionHeader("Löydä kavereita läheltä"),
          myListView(0),
          _buildSectionHeader("Yhteisiä kiinnostuksen kohteita"),
          myListView(1),
          _buildSectionHeader("Miitin uudet käyttäjät"),
          myListView(2),
        ],
      ));
    }
  }

  Widget _buildSectionHeader(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30.h),
        Text(
          text,
          style: TextStyle(
            fontSize: 20.sp,
            color: Colors.white,
            fontFamily: 'Rubik',
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  Widget buildCard(MiittiUser user) {
    return Container(
      height: 225.w,
      width: 160.w,
      decoration: BoxDecoration(
        color: AppStyle.black,
        border: Border.all(color: AppStyle.violet, width: 2.0),
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.0.w),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 45.r,
              backgroundImage: CachedNetworkImageProvider(user.profilePicture,
                  maxHeight: 120, maxWidth: 120, scale: 0.5),
            ),
          ),
          _buildUserInfo(user),
          SizedBox(
            height: 5.h,
          ),
          _buildElevatedButton(user),
        ],
      ),
    );
  }

  Widget buildUserActivitiesText(MiittiUser user) {
    List<String> activities = user.userFavoriteActivities.toList();
    int maxActivitiesToShow = 5;
    List<String> limitedActivities =
        activities.take(maxActivitiesToShow).toList();
    String activitiesText =
        limitedActivities.map((e) => Activity.getActivity(e).name).join(", ");
    return Text(
      activitiesText,
      maxLines: 2,
      overflow: TextOverflow.clip,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13.sp,
        color: AppStyle.lightPurple,
        fontFamily: 'Rubik',
      ),
    );
  }

  Widget _buildUserInfo(MiittiUser user) {
    return Column(
      children: [
        Text(
          "${user.userName}, ${calculateAge(user.userBirthday)}",
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18.sp,
            color: Colors.white,
            fontFamily: 'Rubik',
          ),
        ),
        SizedBox(height: 8.h),
        buildUserActivitiesText(user),
      ],
    );
  }

  Widget _buildElevatedButton(MiittiUser user) {
    return MyElevatedButton(
      height: 35.h,
      width: 110.w,
      onPressed: () {
        if (ref.read(isAnonymous)) {
          showDialog(
              context: context, builder: (context) => const AnonymousDialog());
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => UserProfileEditScreen(
                        user: user,
                      )));
        }
      },
      child: Text(
        'Tutustu',
        style: TextStyle(
          fontFamily: 'Rubik',
          color: Colors.white,
          fontSize: 15.0.sp,
        ),
      ),
    );
  }

  Widget myListView(int type) {
    final list = _filteredUsers[type];
    if (list.isEmpty) {
      return SizedBox(
          height: 225.w,
          child: Center(
              child: Text(
            'Ei tuloksia',
            style: TextStyle(color: Colors.white, fontSize: 20.sp),
          )));
    }
    return SizedBox(
      height: 225.w,
      child: NotificationListener(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent / 2 &&
                notification.scrollDelta! > 0) {
              loadMoreUsers(type);
            }
          }
          return true;
        },
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          itemBuilder: (context, index) {
            final user = list[index];
            return Row(
              children: [
                buildCard(user),
                if (index != list.length - 1) SizedBox(width: 20.w),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
