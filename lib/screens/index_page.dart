import 'package:custom_navigation_bar/custom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/screens/create_miitti/create_miitti_onboarding.dart';

import 'package:miitti_app/services/auth_provider.dart';
import 'package:miitti_app/functions/push_notifications.dart';
import 'package:miitti_app/widgets/anonymous_dialog.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:provider/provider.dart';

import 'navBarScreens/calendar_screen.dart';
import 'navBarScreens/settings_screen.dart';
import 'navBarScreens/maps_screen.dart';
import 'navBarScreens/people_screen.dart';
import 'navBarScreens/profile_screen.dart';

//TODO: Refactor
class IndexPage extends StatefulWidget {
  final int? initialPage;

  const IndexPage({super.key, this.initialPage});

  @override
  IndexPageState createState() => IndexPageState();
}

class IndexPageState extends State<IndexPage> with WidgetsBindingObserver {
  //Integer index that is used for deciding which screen gets to be displayed in body
  int _currentIndex = 1;

  // List of screen widgets
  static const List<Widget> _pages = <Widget>[
    CalendarScreen(),
    MapsScreen(),
    PeopleScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    initPushNotifications();

    WidgetsBinding.instance.addObserver(this);

    // Initialize selected index if an initialPage is provided
    if (widget.initialPage != null &&
        widget.initialPage! >= 0 &&
        widget.initialPage! < 5) {
      _currentIndex = widget.initialPage!;
    }

    //_pageController = PageController(initialPage: currentIndex);

    // Update user status on initialization
    setUserStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Update user status on lifecycle changes
    if (state == AppLifecycleState.resumed) {
      setUserStatus();
    }
  }

  // Helper function to update the user status

  void setUserStatus() {
    final ap = Provider.of<AuthProvider>(context, listen: false);
    ap.setUserStatus();
  }

  void initPushNotifications() {
    final ap = Provider.of<AuthProvider>(context, listen: false);
    PushNotifications.init(ap);
    PushNotifications.localNotiInit();
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider ap = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      floatingActionButton: _currentIndex == 1
          ? SizedBox(
              height: 60.h,
              width: 60.h,
              child: getFloatingButton(
                onPressed: () async {
                  if (ap.isAnonymous) {
                    showDialog(
                        context: context,
                        builder: (context) => const AnonymousDialog());
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateMiittiOnboarding(),
                      ),
                    );
                  }
                },
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigationBar(ap),
      body: _pages[_currentIndex],
    );
  }

  Widget _buildBottomNavigationBar(AuthProvider ap) {
    return CustomNavigationBar(
      iconSize: 35.sp,
      selectedColor: AppStyle.pink,
      unSelectedColor: Colors.white,
      strokeColor: AppStyle.black.withOpacity(0.9),
      backgroundColor: AppStyle.black.withOpacity(0.9),
      items: [
        CustomNavigationBarItem(
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        CustomNavigationBarItem(
          icon: const Icon(Icons.map_outlined),
        ),
        CustomNavigationBarItem(
          icon: const Icon(Icons.people_outline),
        ),
        CustomNavigationBarItem(
          icon: const Icon(Icons.person_add_alt_outlined),
        ),
        CustomNavigationBarItem(
          icon: const Icon(Icons.settings),
        ),
      ],
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}
/**
 * SizedBox(
              height: 65.h,
              width: 65.h,
              child: getMyFloatingButton(
                onPressed: () async {
                  if (ap.isAnonymous) {
                    showDialog(
                        context: context,
                        builder: (context) => const AnonymousDialog());
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActivityOnboarding(),
                      ),
                    );
                  }
                },
              ),
            )
 */