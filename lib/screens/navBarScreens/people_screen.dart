//TODO: Implement new UI

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/screens/anonymous_user_screen.dart';
import 'package:miitti_app/screens/user_profile_edit_screen.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/anonymous_dialog.dart';
import 'package:miitti_app/widgets/buttons/my_elevated_button.dart';

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
    if (ref.read(userStateProvider.notifier).isAnonymous) {
      Future.delayed(const Duration(milliseconds: 10)).then((value) {
        if (mounted) {
          showDialog(
              context: context, builder: (context) => const AnonymousDialog());
        }
      });

      return;
    }

    List responses = await Future.wait([initList(0), initList(1), initList(2)]);

  if (mounted) {
      setState(() {
        for (int i = 0; i < 3; i++) {
          _filteredUsers[i] = responses[i];
          listLoading[i] = false;
        }
      });
    }
  }

  Future<List<MiittiUser>> initList(int type) async {
    try {
      QuerySnapshot snapshot =
          await ref.read(firestoreServiceProvider).lazyFilteredUsers(type, batchSize);
      if (snapshot.docs.isNotEmpty) {
        lastDocuments[type] = snapshot.docs.last;
        return snapshot.docs
            .map((doc) => MiittiUser.fromFirestore(doc))
            .where((user) =>
                user.uid != ref.read(userStateProvider.notifier).data.uid && user.name != "")
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
    final snapshot = await ref.read(firestoreServiceProvider).lazyFilteredUsers(
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
            .map((doc) => MiittiUser.fromFirestore(doc))
            .where((user) => user.uid != ref.read(userStateProvider.notifier).data.uid)
            .toList());
      });
    } else {
      lastDocuments[type] = null;
    }
    listLoading[type] = false;
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(userStateProvider.notifier).isAnonymous) {
      return const AnonymousUserScreen();
    } else {
      return SafeArea(
          child: ListView(
        padding: const EdgeInsets.only(left: 20),
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
        const SizedBox(height: 30),
        Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontFamily: 'Rubik',
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget buildCard(MiittiUser user) {
    return Container(
      height: 225,
      width: 160,
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
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 45,
              backgroundImage: CachedNetworkImageProvider(user.profilePictures[0],
                  maxHeight: 120, maxWidth: 120, scale: 0.5),
            ),
          ),
          _buildUserInfo(user),
          const SizedBox(
            height: 5,
          ),
          _buildElevatedButton(user),
        ],
      ),
    );
  }

  Widget buildUserActivitiesText(MiittiUser user) {
    List<String> activities = user.favoriteActivities.toList();
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
      style: const TextStyle(
        fontSize: 13,
        color: AppStyle.lightPurple,
        fontFamily: 'Rubik',
      ),
    );
  }

  Widget _buildUserInfo(MiittiUser user) {
    return Column(
      children: [
        Text(
          "${user.name}, ${calculateAge(user.birthday)}",
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Rubik',
          ),
        ),
        const SizedBox(height: 8),
        buildUserActivitiesText(user),
      ],
    );
  }

  Widget _buildElevatedButton(MiittiUser user) {
    return MyElevatedButton(
      height: 35,
      width: 110,
      onPressed: () {
        if (ref.read(userStateProvider.notifier).isAnonymous) {
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
      child: const Text(
        'Tutustu',
        style: TextStyle(
          fontFamily: 'Rubik',
          color: Colors.white,
          fontSize: 15.0,
        ),
      ),
    );
  }

  Widget myListView(int type) {
    final list = _filteredUsers[type];
    if (list.isEmpty) {
      return const SizedBox(
          height: 225,
          child: Center(
              child: Text(
            'Ei tuloksia',
            style: TextStyle(color: Colors.white, fontSize: 20),
          )));
    }
    return SizedBox(
      height: 225,
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
                if (index != list.length - 1) const SizedBox(width: 20),
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
