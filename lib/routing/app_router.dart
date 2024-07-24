import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/functions/notification_message.dart';
import 'package:miitti_app/screens/authentication/login/completeProfile/complete_profile_onboard.dart';
import 'package:miitti_app/screens/authentication/login/explore_decision_screen.dart';
import 'package:miitti_app/screens/authentication/login/login_auth.dart';
import 'package:miitti_app/screens/authentication/login/login_intro.dart';
import 'package:miitti_app/screens/index_page.dart';
import 'package:miitti_app/screens/navBarScreens/calendar_screen.dart';
import 'package:miitti_app/screens/navBarScreens/maps_screen.dart';
import 'package:miitti_app/screens/navBarScreens/people_screen.dart';
import 'package:miitti_app/screens/navBarScreens/profile_screen.dart';
import 'package:miitti_app/screens/navBarScreens/settings_screen.dart';
import 'package:miitti_app/services/service_providers.dart';

class AppRouter {
  final WidgetRef ref;

  AppRouter(this.ref);

  late final router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: ValueNotifier<bool>(ref.watch(authService).isSignedIn),
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const IndexPage(),                                 // TODO refactor out entirely in favor of ShellRoute
        ),
      ),
      GoRoute(
        path: '/notificationmessage',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const NotificationMessage(),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginIntro(),
        routes: [
          GoRoute(
            path: 'authenticate',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const LoginAuth(),
            ),
          ),
          GoRoute(
            path: 'explore',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const ExploreDecisionScreen(),
            ),
          ),
          GoRoute(
            path: 'complete-profile',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const CompleteProfileOnboard(),
            ),
          ),
        ],
      ),
      // ShellRoute(
      //   builder: (context, state, child) {
      //     return ScaffoldWithBottomNavBar(child: child);
      //   },
      //   routes: [
      //     GoRoute(
      //       path: '/map',
      //       pageBuilder: (context, state) => NoTransitionPage<void>(
      //         key: state.pageKey,
      //         child: const MapsScreen(),
      //       ),
      //     ),
      //     GoRoute(
      //       path: '/calendar',
      //       pageBuilder: (context, state) => NoTransitionPage<void>(
      //         key: state.pageKey,
      //         child: const CalendarScreen(),
      //       ),
      //     ),
      //     GoRoute(
      //       path: '/people',
      //       pageBuilder: (context, state) => NoTransitionPage<void>(
      //         key: state.pageKey,
      //         child: const PeopleScreen(),
      //       ),
      //     ),
      //     GoRoute(
      //       path: '/profile',
      //       pageBuilder: (context, state) => NoTransitionPage<void>(
      //         key: state.pageKey,
      //         child: const ProfileScreen(),
      //       ),
      //     ),
      //     GoRoute(
      //       path: '/settings',
      //       pageBuilder: (context, state) => NoTransitionPage<void>(
      //         key: state.pageKey,
      //         child: const SettingsScreen(),
      //       ),
      //     ),
      //   ],
      // ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isSignInRoute = state.matchedLocation == '/login'; // Use `subloc` instead of `matchedLocation` for more accurate matching.
      final isAuthenticated = ref.watch(authService).isSignedIn;

      // Redirect unauthenticated users to the login screen if they are not already there.
      if (!isAuthenticated && !isSignInRoute && state.matchedLocation != '/login/authenticate') {
        return '/login';
      }
      // Redirect authenticated users to the home screen if they are on the login screen.
      if (isAuthenticated && isSignInRoute) {
        return '/';
      }
      // No redirection needed
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}

// class ScaffoldWithBottomNavBar extends StatelessWidget {
//   const ScaffoldWithBottomNavBar({super.key, required this.child});
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: child,
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
//           BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Calendar'),
//           BottomNavigationBarItem(icon: Icon(Icons.people), label: 'People'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.settings), label: 'Settings'),
//         ],
//         currentIndex: _calculateSelectedIndex(context),
//         onTap: (int idx) => _onItemTapped(idx, context),
//       ),
//     );
//   }

//   static int _calculateSelectedIndex(BuildContext context) {
//     final String location = GoRouterState.of(context).matchedLocation;
//     if (location.startsWith('/map')) return 0;
//     if (location.startsWith('/calendar')) return 1;
//     if (location.startsWith('/people')) return 2;
//     if (location.startsWith('/profile')) return 3;
//     if (location.startsWith('/settings')) return 4;
//     return 0;
//   }

//   void _onItemTapped(int index, BuildContext context) {
//     switch (index) {
//       case 0:
//         GoRouter.of(context).go('/map');
//         break;
//       case 1:
//         GoRouter.of(context).go('/calendar');
//         break;
//       case 2:
//         GoRouter.of(context).go('/people');
//         break;
//       case 3:
//         GoRouter.of(context).go('/profile');
//         break;
//       case 4:
//         GoRouter.of(context).go('/settings');
//         break;
//     }
//   }
// }
