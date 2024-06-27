import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/screens/commercialScreens/comact_detailspage.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/person_activity.dart';
import 'package:miitti_app/screens/activity_details_page.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/services/providers.dart';

class AdminSearchMiitti extends ConsumerStatefulWidget {
  const AdminSearchMiitti({super.key});

  @override
  ConsumerState<AdminSearchMiitti> createState() => _AdminSearchMiittiState();
}

class _AdminSearchMiittiState extends ConsumerState<AdminSearchMiitti> {
  int showAllMiitit = 0;

  //All Users
  List<MiittiActivity> _miittiActivities = [];

  int participantCount = 0;

  @override
  void initState() {
    showAllMiitit == 0 ? getAllTheActivities() : getReportedActivities();
    super.initState();
  }

  //Fetching all the users from Google Firebase and assigning the list with them
  Future<void> getAllTheActivities() async {
    List<MiittiActivity> activities =
        await ref.read(firestoreService).fetchActivities();

    _miittiActivities = activities.reversed.toList();
    setState(() {});
  }

  //Fetching all the users from Google Firebase and assigning the list with them
  Future<void> getReportedActivities() async {
    _miittiActivities =
        await ref.read(firestoreService).fetchReportedActivities();
    setState(() {});
  }

  Widget getRichText() {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: <TextSpan>[
          TextSpan(
            text: _miittiActivities.length.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
          ),
          TextSpan(
            text: ' miittiä löydetty',
            style: TextStyle(fontSize: 15.sp),
          ),
        ],
      ),
    );
  }

  Future<void> removeActivity(String activityId) async {
    await ref.read(firestoreService).removeActivity(activityId);
    showAllMiitit == 0 ? getAllTheActivities() : getReportedActivities();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showSnackBar(
          context, 'Miitin poistaminen onnistui!', Colors.green.shade600);
    });
  }

  Widget getListTileButton(Color mainColor, String text, Function() onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
        ),
        minimumSize: Size(0, 35.h),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Column(
          children: [
            createMainToggleSwitch(
              text1: 'Kaikki miitit',
              text2: 'Ilmiannetut',
              initialLabelIndex: showAllMiitit,
              onToggle: (index) {
                setState(
                  () {
                    showAllMiitit = index!;
                    showAllMiitit == 0
                        ? getAllTheActivities()
                        : getReportedActivities();
                  },
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: getRichText(),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _miittiActivities.length,
                itemBuilder: (BuildContext context, int index) {
                  MiittiActivity activity = _miittiActivities[index];

                  List<String> addressParts =
                      activity.activityAdress.split(',');
                  String cityName = addressParts[0].trim();

                  return Container(
                    height: 160.h,
                    margin:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppStyle.black,
                      border: Border.all(color: AppStyle.violet, width: 2.0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Activity.getSymbol(activity),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  activity.activityTitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppStyle.title,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month,
                                    color: AppStyle.violet,
                                  ),
                                  SizedBox(width: 4.w),
                                  Flexible(
                                    child: Text(
                                      activity.timeString,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppStyle.body,
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: AppStyle.lightPurple,
                                  ),
                                  SizedBox(width: 4.w),
                                  Flexible(
                                    child: Text(
                                      cityName,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppStyle.body,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  getListTileButton(
                                    AppStyle.violet,
                                    'Katso lisätiedot',
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => activity
                                                    is PersonActivity
                                                ? ActivityDetailsPage(
                                                    myActivity: activity,
                                                  )
                                                : ComActDetailsPage(
                                                    myActivity: activity
                                                        as CommercialActivity))),
                                  ),
                                  SizedBox(
                                    width: 10.w,
                                  ),
                                  getListTileButton(
                                    AppStyle.red,
                                    'Poista miitti',
                                    () => removeActivity(activity.activityUid),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
