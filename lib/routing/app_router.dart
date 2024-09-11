import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/functions/notification_message.dart';
import 'package:miitti_app/main.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/routing/modal_page.dart';
import 'package:miitti_app/widgets/data_containers/activity_details.dart';
import 'package:miitti_app/screens/authentication/completeProfile/accept_norms_screen.dart';
import 'package:miitti_app/screens/authentication/completeProfile/accept_push_notifications.dart';
import 'package:miitti_app/screens/authentication/completeProfile/input_activities_screen.dart';
import 'package:miitti_app/screens/authentication/completeProfile/input_areas_screen.dart';
import 'package:miitti_app/screens/authentication/completeProfile/input_birthday_screen.dart';
import 'package:miitti_app/screens/authentication/completeProfile/input_gender_screen.dart';
import 'package:miitti_app/screens/authentication/completeProfile/input_language_screen.dart';
import 'package:miitti_app/screens/authentication/completeProfile/input_life_situation_screen.dart';
import 'package:miitti_app/screens/authentication/completeProfile/input_name_screen.dart';
import 'package:miitti_app/screens/authentication/completeProfile/input_organization_screen.dart';
import 'package:miitti_app/screens/authentication/completeProfile/input_profile_picture_screen.dart';
import 'package:miitti_app/screens/authentication/completeProfile/input_qa_card_answer_screen.dart';
import 'package:miitti_app/screens/authentication/completeProfile/input_qa_cards_screen.dart';
import 'package:miitti_app/screens/authentication/welcome_screen.dart';
import 'package:miitti_app/screens/authentication/login_screen.dart';
import 'package:miitti_app/screens/authentication/login_intro.dart';
import 'package:miitti_app/screens/create_miitti/create_miitti_onboarding.dart';
import 'package:miitti_app/screens/maintenance_break_screen.dart';
import 'package:miitti_app/screens/navBarScreens/calendar_screen.dart';
import 'package:miitti_app/screens/navBarScreens/map_screen.dart';
import 'package:miitti_app/screens/navBarScreens/people_screen.dart';
import 'package:miitti_app/screens/navBarScreens/profile_screen.dart';
import 'package:miitti_app/screens/navBarScreens/settings_screen.dart';
import 'package:miitti_app/screens/navigation_shell_scaffold.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/screens/update_screen.dart';

// A class to define the app's routing configuration and behavior
class AppRouter {
  final WidgetRef ref;
  String previousRoute = '/';
  bool firstRedirect = true;

  AppRouter(this.ref);

  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _chatNavigatorKey = GlobalKey<NavigatorState>();
  final _mapNavigatorKey = GlobalKey<NavigatorState>();
  final _createActivityNavigatorKey = GlobalKey<NavigatorState>();
  final _peopleNavigatorKey = GlobalKey<NavigatorState>();
  final _profileNavigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: ValueNotifier<bool>(ref.watch(userStateProvider.notifier).isSignedIn),
    initialLocation: '/',
    routes: _buildRoutes(),
    redirect: _handleRedirect,
    errorBuilder: _buildErrorPage,
  );

  List<RouteBase> _buildRoutes() {
    return [
      GoRoute(
        path: '/notificationmessage',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const NotificationMessage()),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const LoginIntroScreen(),
        routes: _buildLoginRoutes(),
      ),
      GoRoute(
        path: '/maintenance-break', 
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const MaintenanceBreakScreen())
      ),
      GoRoute(
        path: '/update/:force',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final forceUpdate = state.pathParameters['force']! == 'true';
          return UpdateScreen(forceUpdate, previousRoute);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => NavigationShellScaffold(
          navigationShell: navigationShell,
        ),
        branches: [
          _buildChatBranch(),
          _buildMapBranch(),
          _buildCreateActivityBranch(),
          _buildPeopleBranch(),
          _buildProfileBranch()
        ],
      )
    ];
  }

  StatefulShellBranch _buildChatBranch() {
    return StatefulShellBranch(
      navigatorKey: _chatNavigatorKey,
        routes: [
          GoRoute(
            path: '/chat',
            pageBuilder: _buildNoTransitionPage(const CalendarScreen()),
          ),
        ],
    );
  }

  StatefulShellBranch _buildMapBranch() {
    return StatefulShellBranch(
      navigatorKey: _mapNavigatorKey,
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: _buildNoTransitionPage(const MapScreen()),
            routes: [
              GoRoute(
                parentNavigatorKey: _rootNavigatorKey,
                path: 'activity/:id',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  final id = state.pathParameters['id'] as String;
                  return ModalPage<void>(child: ActivityDetails(activityId: id));
                },
              ),
            ],
          ),
        ],
    );
  }

  StatefulShellBranch _buildCreateActivityBranch() {
    return StatefulShellBranch(
      navigatorKey: _createActivityNavigatorKey,
        routes: [
          GoRoute(
            path: '/create-activity',
            pageBuilder: _buildNoTransitionPage(const CreateMiittiOnboarding()),
          ),
        ],
    );
  }

  StatefulShellBranch _buildPeopleBranch() {
    return StatefulShellBranch(
      navigatorKey: _peopleNavigatorKey,
        routes: [
          GoRoute(
            path: '/people',
            pageBuilder: _buildNoTransitionPage(const PeopleScreen()),
          ),
        ],
    );
  }

  StatefulShellBranch _buildProfileBranch() {
    return StatefulShellBranch(
      navigatorKey: _profileNavigatorKey,
        routes: [
          GoRoute(
            path: '/profile',
            pageBuilder: _buildNoTransitionPage(const ProfileScreen()),
            routes: [
              GoRoute(
                path: 'settings',
                pageBuilder: _buildNoTransitionPage(const SettingsScreen()),
              ),
            ]
          ),
        ],
    );
  }

  List<GoRoute> _buildLoginRoutes() {
    return [
      GoRoute(
        path: 'authenticate',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const LoginScreen()),
      ),
      GoRoute(
        path: 'welcome',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const WelcomeScreen()),
        // onExit: (context, state) {
        //   context.go('/');
        //   return true;
        // },
      ),
      GoRoute(
        path: 'complete-profile/name',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputNameScreen()),
      ),
      GoRoute(
        path: 'complete-profile/birthday',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputBirthdayScreen()),
      ),
      GoRoute(
        path: 'complete-profile/gender',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputGenderScreen()),
      ),
      GoRoute(
        path: 'complete-profile/languages',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputLanguagesScreen()),
      ),
      GoRoute(
        path: 'complete-profile/areas',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputAreasScreen()),
      ),
      GoRoute(
        path: 'complete-profile/life-situation',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputLifeSituationScreen()),
      ),
      GoRoute(
        path: 'complete-profile/organization',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputOrganizationScreen()),
      ),
      GoRoute(
        path: 'complete-profile/qa-cards',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputQACardsScreen()),
      ),
      GoRoute(
        path: 'complete-profile/qa-card/:question',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final question = state.pathParameters['question']!;
          return NoTransitionPage(child: InputQACardAnswerScreen(question));
        },
      ),
      GoRoute(
        path: 'complete-profile/profile-picture',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputProfilePictureScreen()),
      ),
      GoRoute(
        path: 'complete-profile/activities',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputActivitiesScreen()),
      ),
      GoRoute(
        path: 'complete-profile/push-notifications',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const AcceptPushNotificationsScreen()),
      ),
      GoRoute(
        path: 'complete-profile/community-norms',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const AcceptNormsScreen()),
      ),
    ];
  }

  // List<GoRoute> _buildShellRoutes() {
  //   // TODO: Implement
  // }

  Page<void> Function(BuildContext, GoRouterState) _buildNoTransitionPage(Widget child) {
    return (context, state) => NoTransitionPage<void>(
      key: state.pageKey,
      child: child,
    );
  }

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final userState = ref.watch(userStateProvider.notifier);
    final isMaintenanceBreak = ref.watch(remoteConfigServiceProvider).getBool('maintenance_break');
    final currentAppVersion = parseVersionNumber(appVersion);  // The current app version defined in main.dart
    final latestAppVersion = parseVersionNumber(ref.watch(remoteConfigServiceProvider).getString('latest_app_version'));
    final forceUpdateVersion = parseVersionNumber(ref.watch(remoteConfigServiceProvider).getString('force_update_version'));

    if (isMaintenanceBreak) {
      if (state.matchedLocation != '/maintenance-break') {
        previousRoute = state.matchedLocation;
      }
      return '/maintenance-break';
    }

    if (state.matchedLocation == '/maintenance-break' && !isMaintenanceBreak) {
      return previousRoute;
    }

    if (currentAppVersion < forceUpdateVersion) {
      return '/update/true';
    }

    if (state.matchedLocation == '/update/true') {
      return previousRoute;
    }

    if (firstRedirect && currentAppVersion < latestAppVersion && state.matchedLocation == '/') {
      previousRoute = state.matchedLocation;
      firstRedirect = false;
      return '/update/false';
    }

    if (state.matchedLocation == '/login/complete-profile') {
      firstRedirect = false;
      return '/login/complete-profile/name';  // First step of the profile completion process
    }

    if (!userState.isSignedIn && state.matchedLocation != '/login' && state.matchedLocation != '/login/authenticate') {
      return '/login';  
    }

    // TODO: Add redirection to /login/welcome if user is signed in but profile is incomplete

    // TODO: Remove when redundant
    if (userState.isSignedIn && state.matchedLocation != '/login/welcome') {
      ref.watch(firestoreServiceProvider).checkExistingUser(userState.uid!);
    }

    return null;
  }

  Widget _buildErrorPage(BuildContext context, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Text('${ref.watch(remoteConfigServiceProvider).get<String>('routing-error')}\n\n${state.error}\n\n${ref.watch(remoteConfigServiceProvider).get<String>('error-message-action-prompt')}'),
      ),
    );
  }

  int parseVersionNumber(String version) {
    List versionCells = version.split('.');
    versionCells = versionCells.map((i) => int.parse(i)).toList();
    return versionCells[0] * 100000000 + versionCells[1] * 10000 + versionCells[2];
  }
}