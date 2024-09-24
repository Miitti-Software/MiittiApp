// import 'package:flutter/material.dart';
// import 'package:miitti_app/constants/app_style.dart';

// class OnboardingScreen2 extends StatefulWidget {
//   @override
//   _OnboardingScreen2State createState() => _OnboardingScreen2State();
// }

// class _OnboardingScreen2State extends State<OnboardingScreen2> {
//   late TextEditingController titleController;
//   late TextEditingController subTitleController;
//   bool isActivityFree = true;
//   double activityParticipantsCount = 5.0;
//   bool isActivityTimeUndefined = true;
//   Timestamp activityTime = Timestamp.fromDate(DateTime.now());

//   @override
//   void initState() {
//     super.initState();
//     titleController = TextEditingController();
//     subTitleController = TextEditingController();
//   }

//   @override
//   void dispose() {
//     titleController.dispose();
//     subTitleController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     ref.read(analyticsServiceProvider).logScreenView('create_activity_details_screen');
//     return Scaffold(
//       appBar: AppBar(title: Text('Write Info About Activity')),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           getCustomTextFormField(
//             controller: titleController,
//             hintText: 'Miittisi ytimekäs otsikko',
//             maxLength: 100,
//             maxLines: 1,
//           ),
//           gapH20,
//           getCustomTextFormField(
//             controller: subTitleController,
//             hintText: 'Mitä muuta haluaisit kertoa miitistä?',
//             maxLength: 5000,
//             maxLines: 4,
//           ),
//           gapH20,
//           ListTile(
//             contentPadding: EdgeInsets.zero,
//             leading: CupertinoSwitch(
//               activeColor: AppStyle.pink,
//               value: isActivityFree,
//               onChanged: (bool value) {
//                 setState(() {
//                   isActivityFree = value;
//                 });
//               },
//             ),
//             title: Text(
//               isActivityFree
//                   ? 'Maksuton, ei vaadi pääsylippua'
//                   : "Maksullinen, vaatii pääsylipun",
//               style: AppStyle.activityName.copyWith(
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//           ),
//           gapH10,
//           SliderTheme(
//             data: SliderThemeData(
//               overlayShape: SliderComponentShape.noOverlay,
//             ),
//             child: Slider(
//               activeColor: AppStyle.pink,
//               value: activityParticipantsCount,
//               min: 2,
//               max: 10,
//               label: activityParticipantsCount.round().toString(),
//               onChanged: (newValue) {
//                 setState(() {
//                   activityParticipantsCount = newValue;
//                 });
//               },
//             ),
//           ),
//           gapH10,
//           Align(
//             alignment: Alignment.centerRight,
//             child: Text(
//               "${activityParticipantsCount.round()} osallistujaa",
//               style: AppStyle.activityName.copyWith(
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//           ),
//           gapH10,
//           ListTile(
//             contentPadding: EdgeInsets.zero,
//             leading: CupertinoSwitch(
//               activeColor: AppStyle.pink,
//               value: isActivityTimeUndefined,
//               onChanged: (bool value) {
//                 setState(() {
//                   isActivityTimeUndefined = value;
//                 });
//                 if (!isActivityTimeUndefined) {
//                   pickDate(
//                     context: context,
//                     onDateTimeChanged: (dateTime) {
//                       setState(() {
//                         activityTime = Timestamp.fromDate(dateTime);
//                       });
//                     },
//                   );
//                 }
//               },
//             ),
//             title: Text(
//               isActivityTimeUndefined
//                   ? 'Sovitaan tarkempi aika myöhemmin'
//                   : timestampToString(activityTime),
//               style: AppStyle.activityName.copyWith(
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }