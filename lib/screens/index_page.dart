// import 'package:custom_navigation_bar/custom_navigation_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:miitti_app/constants/app_style.dart';
// import 'package:miitti_app/screens/create_miitti/create_miitti_onboarding.dart';

// import 'package:miitti_app/state/service_providers.dart';
// import 'package:miitti_app/state/user.dart';
// import 'package:miitti_app/widgets/anonymous_dialog.dart';
// import 'package:miitti_app/widgets/other_widgets.dart';

// import 'navBarScreens/calendar_screen.dart';
// import 'navBarScreens/settings_screen.dart';
// import 'navBarScreens/map_screen.dart';
// import 'navBarScreens/old_people_screen.dart';
// import 'navBarScreens/profile_screen.dart';

// // Index page that contains the bottom navigation bar and the body of the app
// //TODO: Refactor
// class IndexPage extends ConsumerStatefulWidget {
//   final int? initialPage;

//   const IndexPage({super.key, this.initialPage});

//   @override
//   IndexPageState createState() => IndexPageState();
// }

// class IndexPageState extends ConsumerState<IndexPage> {
//   //Integer index that is used for deciding which screen gets to be displayed in body
//   int _currentIndex = 1;

//   // List of screen widgets
//   static const List<Widget> _pages = <Widget>[
//     CalendarScreen(),
//     MapScreen(),
//     OldPeopleScreen(),
//     ProfileScreen(),
//     SettingsScreen(),
//   ];

//   @override
//   void initState() {
//     super.initState();

//     // Initialize selected index if an initialPage is provided
//     if (widget.initialPage != null &&
//         widget.initialPage! >= 0 &&
//         widget.initialPage! < 5) {
//       _currentIndex = widget.initialPage!;
//     }

//     //_pageController = PageController(initialPage: currentIndex);

//     // Update user status on initialization
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: _currentIndex == 1
//           ? SizedBox(
//               height: 60,
//               width: 60,
//               child: getFloatingButton(
//                 onPressed: () async {
//                   if (ref.read(userStateProvider).isAnonymous) {
//                     showDialog(
//                         context: context,
//                         builder: (context) => const AnonymousDialog());
//                   } else {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const CreateMiittiOnboarding(),
//                       ),
//                     );
//                   }
//                 },
//               ),
//             )
//           : null,
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//       bottomNavigationBar: _buildBottomNavigationBar(),
//       body: _pages[_currentIndex],
//     );
//   }

//   Widget _buildBottomNavigationBar() {
//     return CustomNavigationBar(
//       iconSize: 35,
//       selectedColor: AppStyle.pink,
//       unSelectedColor: Colors.white,
//       strokeColor: AppStyle.black.withOpacity(0.9),
//       backgroundColor: AppStyle.black.withOpacity(0.9),
//       items: [
//         CustomNavigationBarItem(
//           icon: const Icon(Icons.chat_bubble_outline),
//         ),
//         CustomNavigationBarItem(
//           icon: const Icon(Icons.map_outlined),
//         ),
//         CustomNavigationBarItem(
//           icon: const Icon(Icons.people_outline),
//         ),
//         CustomNavigationBarItem(
//           icon: const Icon(Icons.person_add_alt_outlined),
//         ),
//         CustomNavigationBarItem(
//           icon: const Icon(Icons.settings),
//         ),
//       ],
//       currentIndex: _currentIndex,
//       onTap: (index) {
//         setState(() {
//           _currentIndex = index;
//         });
//       },
//     );
//   }
// }
// /**
//  * SizedBox(
//               height: 65.h,
//               width: 65.h,
//               child: getMyFloatingButton(
//                 onPressed: () async {
//                   if (ap.isAnonymous) {
//                     showDialog(
//                         context: context,
//                         builder: (context) => const AnonymousDialog());
//                   } else {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const ActivityOnboarding(),
//                       ),
//                     );
//                   }
//                 },
//               ),
//             )
//  */