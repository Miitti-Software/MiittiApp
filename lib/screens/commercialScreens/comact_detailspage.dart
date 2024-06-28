import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/screens/commercialScreens/comchat_page.dart';
import 'package:miitti_app/screens/commercialScreens/commercial_user_profile.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/commercial_user.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/services/providers.dart';
import 'package:miitti_app/screens/user_profile_edit_screen.dart';

import 'package:miitti_app/widgets/buttons/my_elevated_button.dart';
import 'package:miitti_app/widgets/safe_scaffold.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/miitti_user.dart';

class ComActDetailsPage extends ConsumerStatefulWidget {
  final bool? comingFromAdmin;

  const ComActDetailsPage({
    required this.myActivity,
    this.comingFromAdmin,
    super.key,
  });

  final CommercialActivity myActivity;

  @override
  ConsumerState<ComActDetailsPage> createState() => _ActivityDetailsPageState();
}

class _ActivityDetailsPageState extends ConsumerState<ComActDetailsPage> {
  late LatLng myCameraPosition;

  bool isAlreadyJoined = false;

  CommercialUser? company;
  int participantCount = 0;
  List<MiittiUser> participantList = [];

  @override
  void initState() {
    super.initState();
    checkIfJoined();
    fetchAdmin();
    fetchUsersJoinedActivity();
    myCameraPosition = LatLng(
      widget.myActivity.activityLati,
      widget.myActivity.activityLong,
    );
  }

  /*_onStyleLoadedCallBack() {
    myController.addSymbol(
      SymbolOptions(
        geometry: LatLng(
          widget.myActivity.activityLati,
          widget.myActivity.activityLong,
        ),
        iconImage:
            'images/${widget.myActivity.activityCategory.toLowerCase()}.png',
        iconSize: 0.8.r,
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
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
                      margin: EdgeInsets.only(left: 10.w, top: 40.h),
                      height: 60.h,
                      width: 60.h,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: AppStyle.pinkGradient),
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
                      Padding(
                        padding: EdgeInsets.all(13.0.h),
                        child: CircleAvatar(
                          backgroundColor: AppStyle.violet,
                          radius: 37.r,
                          child: CircleAvatar(
                            backgroundImage:
                                NetworkImage(widget.myActivity.activityPhoto),
                            radius: 34.r,
                            onBackgroundImageError: (exception, stackTrace) =>
                                AssetImage(
                                    'images/${Activity.solveActivityId(widget.myActivity.activityCategory)}.png'),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          widget.myActivity.activityTitle,
                          style: AppStyle.title,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 16.0.w, right: 8.0.w),
                        child: GestureDetector(
                          onTap: () {
                            if (company != null) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          CommercialProfileScreen(
                                              user: company!)));
                            }
                          },
                          child: CircleAvatar(
                            backgroundImage:
                                NetworkImage(company!.profilePicture),
                            backgroundColor: AppStyle.violet,
                            radius: 25.r,
                            child: const Align(
                              alignment: Alignment.topRight,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: AppStyle.violet,
                                    size: 21,
                                  ),
                                  Icon(
                                    Icons.verified,
                                    color: AppStyle.lightPurple,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 75.0.h,
                          width: double.infinity,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                participantCount < 10 ? participantCount : 10,
                            itemBuilder: (BuildContext context, int index) {
                              MiittiUser user = participantList[index];
                              debugPrint("$index: ${user.userName} osallistuu");
                              return Padding(
                                padding: EdgeInsets.only(left: 16.0.w),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                UserProfileEditScreen(
                                                    user: user)));
                                  },
                                  child: CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(user.profilePicture),
                                    backgroundColor: AppStyle.violet,
                                    radius: 25.r,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(8.0.w),
                      child: SingleChildScrollView(
                        child: Text(
                          widget.myActivity.activityDescription,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Rubik',
                            fontSize: 15.0.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  /*Expanded(
                    child: SizedBox(),'
                  ),*/
                  Padding(
                    padding: EdgeInsets.all(8.0.w),
                    child: InkWell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.myActivity.linkTitle,
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
                          await launchUrl(
                              Uri.parse(widget.myActivity.hyperlink));
                        }),
                  ),
                  SizedBox(
                    width: 8.0.w,
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
                      SizedBox(
                        width: 20.w,
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
                      SizedBox(
                        width: 20.w,
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
                  SizedBox(
                    height: 10.h,
                  ),
                ],
              ),
            ),
          ),
          widget.comingFromAdmin == true
              ? Container()
              : getMyButton(ref.watch(providerLoading)),
        ],
      ),
    );
  }

  void checkIfJoined() async {
    if (isAlreadyJoined) return;

    final activityUid = widget.myActivity.activityUid;

    await ref
        .read(firestoreService)
        .checkIfUserJoined(activityUid, commercial: true)
        .then((joined) {
      if (joined) {
        setState(() {
          isAlreadyJoined = true;
        });
      }
    });
  }

  void joinActivity() async {
    checkIfJoined();
    if (!isAlreadyJoined) {
      await ref
          .read(firestoreService)
          .joinCommercialActivity(widget.myActivity.activityUid);
      setState(() {
        isAlreadyJoined = true;
        widget.myActivity.participants.add(ref.read(authService).uid);
      });
    }
  }

  Widget getMyButton(bool isLoading) {
    String buttonText = getButtonText();

    //There is still place left
    return MyElevatedButton(
      height: 50.h,
      onPressed: () {
        if (!isAlreadyJoined &&
            participantCount < widget.myActivity.personLimit) {
          joinActivity();
        } else if (isAlreadyJoined) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComChatPage(activity: widget.myActivity),
            ),
          );
        }
      },
      child: isLoading
          ? LoadingAnimationWidget.waveDots(
              color: Colors.white,
              size: 50.r,
            )
          : Text(
              buttonText,
              style: TextStyle(
                fontSize: 19.sp,
                color: Colors.white,
                fontFamily: 'Rubik',
              ),
            ),
    );
  }

  void fetchUsersJoinedActivity() async {
    ref
        .read(firestoreService)
        .fetchUsersByUids(widget.myActivity.participants.toList())
        .then((value) => setState(() {
              participantList = value;
              participantCount = value.length;
            }));
  }

  void fetchAdmin() async {
    ref
        .read(firestoreService)
        .getCommercialUser(widget.myActivity.admin)
        .then((value) => setState(() {
              company = value;
            }));
  }

  String getButtonText() {
    return isAlreadyJoined
        ? 'Siirry infokanavalle'
        : (participantCount < widget.myActivity.personLimit)
            ? 'Osallistun'
            : 'Täynnä';
  }

  Future<String> getPath() async {
    final cacheDirectory = await getTemporaryDirectory();
    return cacheDirectory.path;
  }
}
