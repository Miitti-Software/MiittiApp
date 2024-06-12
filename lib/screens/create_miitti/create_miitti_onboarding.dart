import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/constants/constants_styles.dart';
import 'package:miitti_app/data/commercial_spot.dart';
import 'package:miitti_app/data/onboarding_part.dart';
import 'package:miitti_app/data/person_activity.dart';
import 'package:miitti_app/data/activity.dart';
import 'package:miitti_app/utils/auth_provider.dart';
import 'package:miitti_app/utils/utils.dart';
import 'package:miitti_app/widgets/custom_button.dart';
import 'package:location/location.dart' as location;
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class CreateMiittiOnboarding extends StatefulWidget {
  const CreateMiittiOnboarding({super.key});

  @override
  State<CreateMiittiOnboarding> createState() => _CreateMiittiOnboardingState();
}

class _CreateMiittiOnboardingState extends State<CreateMiittiOnboarding> {
  late PageController _pageController;

  final List<ConstantsOnboarding> onboardingScreens = [
    ConstantsOnboarding(
      title: 'Mitä haluaisit tehdä, valitse\nsopivin kategoria!',
    ),
    ConstantsOnboarding(
      title: 'Missä haluat tavata, valitse tapaamispaikka kartalta',
    ),
    ConstantsOnboarding(
      title: 'Mitä haluaisit\nkertoa miitistäsi?',
    ),
    ConstantsOnboarding(
        title: 'Tässä vielä yhteenveto\ntulevasta miitistäsi',
        isFullView: true),
  ];

  //PAGE 0 SELECT ACTIVITY CATEGORY
  String favoriteActivity = "";

  //PAGE 1 PICK ACTIVITY LOCATION
  final location.Location _location = location.Location();

  LatLng myCameraPosition = const LatLng(60.166082, 24.939744);

  LatLng? markerCoordinates;

  bool isLoading = false;

  List<CommercialSpot> spots = [];
  late ValueNotifier<int> selectedSpotNotifier;

  String activityCity = "";

  //PAGE 2 WRITE INFO ABOUT ACTIVITY
  late TextEditingController titleController;
  late TextEditingController subTitleController;

  bool isActivityFree = true;

  double activityParticipantsCount = 5.0;

  bool isActivityTimeUndefined = true;
  Timestamp activityTime = Timestamp.fromDate(DateTime.now());

  //PAGE 3 SUMMARY

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    titleController = TextEditingController();
    subTitleController = TextEditingController();
    selectedSpotNotifier = ValueNotifier<int>(-1);
    initializeLocationAndSave();
    fetchSpots();
  }

  @override
  void dispose() {
    _pageController.dispose();
    titleController.dispose();
    subTitleController.dispose();
    super.dispose();
  }

  void initializeLocationAndSave() async {
    bool? serviceEnabled;
    PermissionStatus? permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
    }

    LocationData locationData = await _location.getLocation();
    LatLng currentLatLng =
        LatLng(locationData.latitude!, locationData.longitude!);

    setState(() {
      myCameraPosition = currentLatLng;
    });
  }

  /*void onStyleLoadedCallBack() {
    summaryMapController.addSymbol(
      SymbolOptions(
        geometry: LatLng(
          markerCoordinates!.latitude,
          markerCoordinates!.longitude,
        ),
        iconImage: 'images/${Activity.solveActivityId(favoriteActivity)}.png',
        iconSize: 0.8.r,
      ),
    );
  }*/

  void fetchSpots() {
    AuthProvider ap = Provider.of<AuthProvider>(context, listen: false);

    ap.fetchCommercialSpots().then((value) {
      setState(() {
        spots = value;
      });
    });
  }

  Widget mainWidgetsForScreens(int page) {
    switch (page) {
      case 0:
        return Expanded(
          child: GridView.builder(
            itemCount: activities.keys.toList().length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20.0,
              mainAxisSpacing: 10.0,
            ),
            itemBuilder: (context, index) {
              final activity = activities.keys.toList()[index];
              final isSelected = favoriteActivity == activity;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (favoriteActivity == activity) {
                      favoriteActivity = "";
                    } else {
                      favoriteActivity = activity;
                    }
                  });
                },
                child: Container(
                  width: 100.w,
                  padding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? ConstantStyles.pink : Colors.transparent,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10.0),
                    ),
                    border: Border.all(color: ConstantStyles.pink),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        Activity.getActivity(activity).emojiData,
                        style: ConstantStyles.title,
                      ),
                      Text(
                        Activity.getActivity(activity).name,
                        overflow: TextOverflow.ellipsis,
                        style: ConstantStyles.warning.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      case 1:
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 300.w,
                width: 350.w,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: FutureBuilder(
                      future: getPath(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        return FlutterMap(
                            //mapController: mapController,
                            options: MapOptions(
                              keepAlive: true,
                              backgroundColor: AppColors.backgroundColor,
                              initialCenter: myCameraPosition,
                              initialZoom: 13.0,
                              interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.pinchZoom |
                                      InteractiveFlag.drag),
                              minZoom: 5.0,
                              maxZoom: 18.0,
                              onMapReady: () {},
                              onPositionChanged: (position, hasGesture) {
                                debugPrint(
                                    "Location changed ${position.center}");
                                for (int i = 0; i < spots.length; i++) {
                                  bool onSpot = (spots[i].lati -
                                                  position.center!.latitude)
                                              .abs() <
                                          0.0002 &&
                                      (spots[i].long -
                                                  position.center!.longitude)
                                              .abs() <
                                          0.0002;
                                  if (onSpot) {
                                    selectedSpotNotifier.value = i;
                                    myCameraPosition = position.center!;
                                    return;
                                  }
                                }

                                selectedSpotNotifier.value = -1;
                                myCameraPosition = position.center!;
                              },
                            ),
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
                              Center(
                                child: Image.asset(
                                  'images/location.png',
                                  height: 65.h,
                                ),
                              ),
                            ]);
                      }),
                  /* MapboxMap(
                        styleString: MapboxStyles.MAPBOX_STREETS,
                        onMapCreated: (mapController) =>
                            this.mapController = mapController,
                        myLocationEnabled: true,
                        trackCameraPosition: true,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        compassEnabled: false,
                        gestureRecognizers: {
                          Factory<OneSequenceGestureRecognizer>(
                              () => EagerGestureRecognizer())
                        },
                        myLocationTrackingMode:
                            MyLocationTrackingMode.TrackingGPS,
                        initialCameraPosition: myCameraPosition,
                        onCameraIdle: () {
                          for (int i = 0; i < spots.length; i++) {
                            bool onSpot = (spots[i].lati -
                                            mapController.cameraPosition!.target
                                                .latitude)
                                        .abs() <
                                    0.0002 &&
                                (spots[i].long -
                                            mapController.cameraPosition!.target
                                                .longitude)
                                        .abs() <
                                    0.0002;
                            if (onSpot) {
                              setState(() {
                                selectedSpot = i;
                              });
                              return;
                            }
                          }

                          setState(() {
                            selectedSpot = -1;
                          });
                        },
                      ),*/
                ),
              ),
              ConstantStyles().gapH20,
              spots.isNotEmpty
                  ? Text(
                      "Valitse Miitti-Spotti:",
                      style: ConstantStyles.activityName,
                    )
                  : Container(),
              ConstantStyles().gapH5,
              spots.isNotEmpty
                  ? Expanded(
                      child: ValueListenableBuilder<int>(
                          valueListenable: selectedSpotNotifier,
                          builder: (context, selectedSpot, kid) {
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: spots.length,
                              itemBuilder: (BuildContext context, int index) {
                                return GestureDetector(
                                    onTap: () => setState(() {
                                          selectedSpotNotifier.value = index;
                                          myCameraPosition = LatLng(
                                              spots[index].lati,
                                              spots[index].long);
                                        }),
                                    child: spots[index]
                                        .getWidget(index == selectedSpot));
                              },
                            );
                          }),
                    )
                  : Container(),
            ],
          ),
        );
      case 2:
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OtherWidgets().getCustomTextFormField(
                controller: titleController,
                hintText: 'Miittisi ytimekäs otsikko',
                maxLength: 30,
                maxLines: 1,
              ),
              ConstantStyles().gapH20,
              OtherWidgets().getCustomTextFormField(
                controller: subTitleController,
                hintText: 'Mitä muuta haluaisit kertoa miitistä?',
                maxLength: 150,
                maxLines: 4,
              ),
              ConstantStyles().gapH20,
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CupertinoSwitch(
                  activeColor: ConstantStyles.pink,
                  value: isActivityFree,
                  onChanged: (bool value) {
                    setState(() {
                      isActivityFree = value;
                    });
                  },
                ),
                title: Text(
                  isActivityFree
                      ? 'Maksuton, ei vaadi pääsylippua'
                      : "Maksullinen, vaatii pääsylipun",
                  style: ConstantStyles.activityName.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              ConstantStyles().gapH10,
              SliderTheme(
                data: SliderThemeData(
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  activeColor: ConstantStyles.pink,
                  value: activityParticipantsCount,
                  min: 2,
                  max: 10,
                  label: activityParticipantsCount.round().toString(),
                  onChanged: (newValue) {
                    setState(() {
                      activityParticipantsCount = newValue;
                    });
                  },
                ),
              ),
              ConstantStyles().gapH10,
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "${activityParticipantsCount.round()} osallistujaa",
                  style: ConstantStyles.activityName.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              ConstantStyles().gapH10,
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CupertinoSwitch(
                  activeColor: ConstantStyles.pink,
                  value: isActivityTimeUndefined,
                  onChanged: (bool value) {
                    setState(() {
                      isActivityTimeUndefined = value;
                    });
                    if (!isActivityTimeUndefined) {
                      pickDate(
                        context: context,
                        onDateTimeChanged: (dateTime) {
                          setState(() {
                            activityTime = Timestamp.fromDate(dateTime);
                          });
                        },
                      );
                    } else {}
                  },
                ),
                title: Text(
                  isActivityTimeUndefined
                      ? 'Sovitaan tarkempi aika myöhemmin'
                      : timestampToString(activityTime),
                  style: ConstantStyles.activityName.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      case 3:
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 300.w,
                width: 350.w,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: FutureBuilder(
                          future: getPath(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }
                            return FlutterMap(
                                options: MapOptions(
                                    keepAlive: true,
                                    backgroundColor: AppColors.backgroundColor,
                                    initialCenter: myCameraPosition,
                                    initialZoom: 13.0,
                                    interactionOptions:
                                        const InteractionOptions(
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
                    ),
                    Center(
                      child: Image.asset(
                        'images/${Activity.solveActivityId(favoriteActivity)}.png',
                        height: 65.h,
                      ),
                    ),
                  ],
                ),
              ),
              ConstantStyles().gapH20,
              Text(
                titleController.text.trim(),
                style: ConstantStyles.body.copyWith(fontSize: 24.sp),
              ),
              ConstantStyles().gapH10,
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: ConstantStyles.pink,
                  ),
                  ConstantStyles().gapW10,
                  Text(
                    isActivityTimeUndefined
                        ? 'Sovitaan myöhemmin'
                        : timestampToString(activityTime),
                    style: ConstantStyles.activitySubName,
                  ),
                  ConstantStyles().gapW20,
                  const Icon(
                    Icons.map_outlined,
                    color: ConstantStyles.pink,
                  ),
                  ConstantStyles().gapW10,
                  Flexible(
                    child: Text(
                      activityCity,
                      overflow: TextOverflow.ellipsis,
                      style: ConstantStyles.activitySubName.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              ConstantStyles().gapH5,
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: ConstantStyles.pink,
                  ),
                  ConstantStyles().gapW10,
                  Text(
                    isActivityFree ? 'Maksuton' : 'Pääsymaksu',
                    textAlign: TextAlign.center,
                    style: ConstantStyles.activitySubName,
                  ),
                  ConstantStyles().gapW20,
                  const Icon(
                    Icons.people_outline,
                    color: ConstantStyles.pink,
                  ),
                  ConstantStyles().gapW10,
                  Text(
                    'max. ${activityParticipantsCount.round()} osallistujaa',
                    style: ConstantStyles.activitySubName,
                  ),
                ],
              ),
              ConstantStyles().gapH10,
              Text(
                subTitleController.text.trim(),
                style: ConstantStyles.question,
              ),
            ],
          ),
        );
      default:
        {
          return const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: ConstantStyles.pink,
              ),
            ),
          );
        }
    }
  }

  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      setState(() {
        isLoading == true;
      });
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String address = placemark.subLocality!.isEmpty
            ? '${placemark.locality}'
            : '${placemark.subLocality}, ${placemark.locality}';
        setState(() {
          isLoading == false;
        });
        return address;
      } else {
        setState(() {
          isLoading == false;
        });
        return "Suomi";
      }
    } catch (e) {
      setState(() {
        isLoading == false;
      });
      return "Suomi";
    }
  }

  Future<void> errorHandlingScreens(int page) async {
    final currentPage = _pageController.page!.toInt();

    switch (currentPage) {
      case 0:
        if (favoriteActivity.isEmpty) {
          showSnackBar(
            context,
            'Valitse 1 sopivaa kategoria miittillesi!',
            ConstantStyles.red,
          );
          return;
        }
      case 1:
        markerCoordinates = myCameraPosition;
        activityCity = selectedSpotNotifier.value > -1
            ? spots[selectedSpotNotifier.value].address
            : await getAddressFromCoordinates(
                markerCoordinates!.latitude, markerCoordinates!.longitude);

      case 2:
        if (titleController.text.trim().isEmpty ||
            subTitleController.text.trim().isEmpty) {
          showSnackBar(
            context,
            'Varmista, että olet täyttänyt kaikki kohdat!',
            ConstantStyles.red,
          );
          return;
        }
    }

    if (page != 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.linear,
      );
    } else {
      //Register miitti
      PersonActivity activity = PersonActivity(
        activityTitle: titleController.text.trim(),
        activityDescription: subTitleController.text.trim(),
        activityCategory: favoriteActivity,
        admin: '',
        activityUid: '',
        activityLong: markerCoordinates!.longitude,
        activityLati: markerCoordinates!.latitude,
        activityAdress: activityCity,
        activityTime: activityTime,
        isMoneyRequired: !isActivityFree,
        personLimit: activityParticipantsCount.round(),
        participants: {},
        requests: {},
        adminGender: '',
        adminAge: 0,
        timeDecidedLater: isActivityTimeUndefined,
      );
      saveMiittiToFirebase(activity);
    }
  }

  Future<void> saveMiittiToFirebase(PersonActivity personActivity) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.saveMiittiActivityDataToFirebase(
      context: context,
      activityModel: personActivity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Flex(
          direction: Axis.vertical,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingScreens.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  ConstantsOnboarding screen = onboardingScreens[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstantStyles().gapH10,
                        Text(
                          screen.title,
                          style: ConstantStyles.activityName
                              .copyWith(fontSize: 20.sp),
                        ),
                        ConstantStyles().gapH20,
                        mainWidgetsForScreens(index),
                        ConstantStyles().gapH10,
                        CustomButton(
                          buttonText: screen.isFullView == true
                              ? 'Julkaise'
                              : 'Seuraava',
                          onPressed: () => errorHandlingScreens(index),
                        ),
                        ConstantStyles().gapH10,
                        CustomButton(
                          buttonText: 'Takaisin',
                          isWhiteButton: true,
                          onPressed: () {
                            if (_pageController.page != 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.linear,
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> getPath() async {
    final cacheDirectory = await getTemporaryDirectory();
    return cacheDirectory.path;
  }
}

/**
 * onPressed: () async {
                markerCoordinates = mapController.cameraPosition!.target;

                if (markerCoordinates != null) {
                  double latitude = markerCoordinates!.latitude;
                  double longitude = markerCoordinates!.longitude;

                  widget.activity.activityLati = latitude;
                  widget.activity.activityLong = longitude;
                  widget.activity.activityAdress = selectedSpot > -1
                      ? spots[selectedSpot].address
                      : await getAddressFromCoordinates(latitude, longitude);

                  widget.onActivityDataChanged(widget.activity);

                  widget.mapController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.linear,
                  );
                } else {
                  showSnackBar(
                      context,
                      'Tapaamispaikka ei voi olla tyhjä, yritä uudeelleen',
                      Colors.red.shade800);
                }
 */
