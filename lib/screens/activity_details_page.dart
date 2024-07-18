import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/screens/chat_page.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/models/person_activity.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/services/firestore_service.dart';
import 'package:miitti_app/services/service_providers.dart';
import 'package:miitti_app/widgets/anonymous_dialog.dart';
import 'package:miitti_app/widgets/confirmdialog.dart';
import 'package:miitti_app/screens/navBarScreens/profile_screen.dart';
import 'package:miitti_app/screens/user_profile_edit_screen.dart';
import 'package:miitti_app/functions/utils.dart';

import 'package:miitti_app/widgets/buttons/my_elevated_button.dart';
import 'package:miitti_app/widgets/safe_scaffold.dart';
import 'package:path_provider/path_provider.dart';

import '../models/miitti_user.dart';

//TODO: New UI

class ActivityDetailsPage extends ConsumerStatefulWidget {
  const ActivityDetailsPage({
    required this.myActivity,
    super.key,
  });

  final PersonActivity myActivity;

  @override
  ConsumerState<ActivityDetailsPage> createState() =>
      _ActivityDetailsPageState();
}

class _ActivityDetailsPageState extends ConsumerState<ActivityDetailsPage> {
  late LatLng myCameraPosition;

  UserStatusInActivity userStatus = UserStatusInActivity.none;

  late Future<List<MiittiUser>> filteredUsers;

  int participantCount = 0;
  bool isAnonymous = false;

  @override
  void initState() {
    super.initState();
    userStatus = getStatusInActivity();
    filteredUsers = fetchUsersJoinedActivity();
    filteredUsers.then((users) {
      setState(() {
        participantCount = users.length;
      });
    });

    myCameraPosition = LatLng(
      widget.myActivity.activityLati,
      widget.myActivity.activityLong,
    );
  }

  /*_onMapCreated(MapboxMapController controller) {
    myController = controller;
  }*/

  /*_onStyleLoadedCallBack() {
    myController.addSymbol(
      SymbolOptions(
        geometry: LatLng(
          widget.myActivity.activityLati,
          widget.myActivity.activityLong,
        ),
        iconImage:
            'images/${Activity.solveActivityId(widget.myActivity.activityCategory)}.png',
        iconSize: 0.8.r,
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(providerLoading);

    return SafeScaffold(
      Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FutureBuilder(
                    future: getPath(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      return FlutterMap(
                          options: MapOptions(
                              keepAlive: true,
                              backgroundColor: AppStyle.black,
                              initialCenter: myCameraPosition,
                              initialZoom: 13.0,
                              interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.pinchZoom),
                              minZoom: 5.0,
                              maxZoom: 18.0,
                              onMapReady: () {}),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://api.mapbox.com/styles/v1/miittiapp/clt1ytv8s00jz01qzfiwve3qm/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                              additionalOptions: const {
                                'accessToken': mapboxAccess,
                              },
                              tileProvider: CachedTileProvider(
                                  store: HiveCacheStore(
                                snapshot.data.toString(),
                              )),
                            ),
                          ]);
                    }),
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 10, top: 40),
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: AppStyle.pinkGradient,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'images/${Activity.solveActivityId(widget.myActivity.activityCategory)}.png',
                        height: 90,
                      ),
                      Flexible(
                        child: Text(
                          widget.myActivity.activityTitle,
                          style: AppStyle.title,
                        ),
                      ),
                    ],
                  ),
                  FutureBuilder(
                    future: filteredUsers,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<MiittiUser>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        participantCount = snapshot.data!.length;
                        return SizedBox(
                          height: 75.0,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (BuildContext context, int index) {
                              MiittiUser user = snapshot.data![index];
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: GestureDetector(
                                  onTap: () {
                                    if (isAnonymous) {
                                      showDialog(
                                          context: context,
                                          builder: (context) =>
                                              const AnonymousDialog());
                                    } else {
                                      String uid = ref.read(authService).uid;
                                      pushPage(
                                          context,
                                          uid == user.uid
                                              ? const ProfileScreen()
                                              : UserProfileEditScreen(
                                                  user: user));
                                    }
                                  },
                                  child: CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(user.profilePicture),
                                    backgroundColor: AppStyle.violet,
                                    radius: 25,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      } else {
                        return const CircularProgressIndicator(
                          color: AppStyle.violet,
                        );
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      widget.myActivity.activityDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 17.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: SizedBox(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people,
                        color: AppStyle.lightPurple,
                      ),
                      Text(
                        '  $participantCount/${widget.myActivity.personLimit} osallistujaa',
                        style: AppStyle.body,
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppStyle.lightPurple,
                      ),
                      Text(
                        widget.myActivity.activityAdress,
                        style: AppStyle.body,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.airplane_ticket_outlined,
                        color: AppStyle.lightPurple,
                      ),
                      Text(
                        widget.myActivity.isMoneyRequired
                            ? 'Pääsymaksu'
                            : 'Maksuton',
                        style: AppStyle.body,
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      const Icon(
                        Icons.calendar_month,
                        color: AppStyle.lightPurple,
                      ),
                      Text(
                        widget.myActivity.timeString,
                        style: AppStyle.body,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
          getMyButton(isLoading),
          reportActivity(),
        ],
      ),
    );
  }

  Widget reportActivity() {
    if (userStatus == UserStatusInActivity.joined) {
      return Center(
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const ConfirmDialog(
                  title: 'Varmistus',
                  leftButtonText: 'Ilmianna',
                  mainText: 'Oletko varma, että haluat ilmiantaa aktiviteetin?',
                );
              },
            ).then(
              (confirmed) {
                if (confirmed) {
                  ref.read(firestoreService).reportActivity(
                      widget.myActivity.activityUid, 'Activity blocked');
                  afterFrame(() {
                    Navigator.of(context).pop();
                    showSnackBar(context, "Aktiviteetti ilmiannettu",
                        Colors.green.shade800);
                  });
                }
              },
            );
          },
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            child: const Text(
              "Ilmianna aktiviteetti",
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 19,
                color: Colors.red,
              ),
            ),
          ),
        ),
      );
    }
    return Container();
  }

  void sendActivityRequest() async {
    if (userStatus != UserStatusInActivity.none) return;
    if (isAnonymous) return;
    FirestoreService firestore = ref.read(firestoreService);
    firestore
        .joinOrRequestActivity(widget.myActivity.activityUid)
        .then((newStatus) {
      if (newStatus == UserStatusInActivity.requested) {
        ref
            .read(notificationService)
            .sendRequestNotification(widget.myActivity);
        setState(() {
          userStatus = UserStatusInActivity.requested;
          widget.myActivity.requests.add(firestore.miittiUser!.uid);
        });
      } else if (newStatus == UserStatusInActivity.joined) {
        setState(() {
          userStatus = UserStatusInActivity.joined;
          widget.myActivity.participants.add(firestore.miittiUser!.uid);
        });
      }
    });
  }

  Widget getMyButton(bool isLoading) {
    String buttonText = getButtonText();

    return MyElevatedButton(
      height: 50,
      onPressed: () {
        if (userStatus == UserStatusInActivity.none &&
            participantCount < widget.myActivity.personLimit) {
          if (isAnonymous) {
            showDialog(
                context: context,
                builder: (context) => const AnonymousDialog());
          } else {
            sendActivityRequest();
          }
        } else if (userStatus == UserStatusInActivity.joined) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(activity: widget.myActivity),
            ),
          );
        }
      },
      child: isLoading
          ? LoadingAnimationWidget.waveDots(
              color: Colors.white,
              size: 50,
            )
          : Text(
              buttonText,
              style: const TextStyle(
                fontSize: 19,
                color: Colors.white,
                fontFamily: 'Rubik',
              ),
            ),
    );
  }

  Future<List<MiittiUser>> fetchUsersJoinedActivity() {
    return ref
        .read(firestoreService)
        .fetchUsersByUids(widget.myActivity.participants.toList());
  }

  UserStatusInActivity getStatusInActivity() {
    if (isAnonymous) {
      isAnonymous = true;
      return UserStatusInActivity.none;
    }
    final userId = ref.read(authService).uid;
    return widget.myActivity.participants.contains(userId)
        ? UserStatusInActivity.joined
        : widget.myActivity.requests.contains(userId)
            ? UserStatusInActivity.requested
            : UserStatusInActivity.none;
  }

  String getButtonText() {
    if (userStatus == UserStatusInActivity.requested) {
      return 'Odottaa hyväksyntää';
    } else if (userStatus == UserStatusInActivity.joined) {
      return 'Siirry keskusteluun';
    } else {
      return participantCount < widget.myActivity.personLimit
          ? 'Osallistun'
          : 'Täynnä';
    }
  }

  Future<String> getPath() async {
    final cacheDirectory = await getTemporaryDirectory();
    return cacheDirectory.path;
  }
}

enum UserStatusInActivity {
  none,
  requested,
  joined,
}
