import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/main.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/routing/modal_page.dart';
import 'package:miitti_app/screens/activityManagement/activity_management_shell_scaffold.dart';
import 'package:miitti_app/screens/activityManagement/chat_screen.dart';
import 'package:miitti_app/screens/activityManagement/chats_screen.dart';
import 'package:miitti_app/screens/activityManagement/others_activities_screen.dart';
import 'package:miitti_app/screens/activityManagement/own_activities_screen.dart';
import 'package:miitti_app/screens/activityManagement/createMiitti/choose_activity_category_screen.dart';
import 'package:miitti_app/screens/activityManagement/createMiitti/choose_activity_location_screen.dart';
import 'package:miitti_app/screens/activityManagement/createMiitti/create_activity_review_screen.dart';
import 'package:miitti_app/screens/activityManagement/createMiitti/fill_activity_details_screen.dart';
import 'package:miitti_app/screens/activityManagement/createMiitti/invite_screen.dart';
import 'package:miitti_app/screens/peopleManagement/filter_users_screen.dart';
import 'package:miitti_app/screens/peopleManagement/people_screen.dart';
import 'package:miitti_app/screens/peopleManagement/profile_screen.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/map_state.dart';
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
import 'package:miitti_app/screens/maintenance_break_screen.dart';
import 'package:miitti_app/screens/map_screen.dart';
import 'package:miitti_app/screens/peopleManagement/settings_screen.dart';
import 'package:miitti_app/screens/navigation_shell_scaffold.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/screens/update_screen.dart';
import 'package:miitti_app/widgets/data_containers/participants_list.dart';
import 'package:miitti_app/widgets/data_containers/requests_list.dart';

// A class to define the app's routing configuration and behavior
class AppRouter {
  final Ref ref;
  String previousRoute = '/';
  bool firstRedirect = true;

  AppRouter(this.ref, this.rootNavigatorKey);

  GlobalKey<NavigatorState> rootNavigatorKey;
  final _chatNavigatorKey = GlobalKey<NavigatorState>();
  final _mapNavigatorKey = GlobalKey<NavigatorState>();
  final _createActivityNavigatorKey = GlobalKey<NavigatorState>();
  final _peopleNavigatorKey = GlobalKey<NavigatorState>();
  final _profileNavigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: ValueNotifier<bool>(ref.watch(signedInProvider)),
    observers: [
      FirebaseAnalyticsObserver(
        analytics: ref.watch(analyticsServiceProvider).instance,
        nameExtractor: (state) {return state.name;},
      ),
    ],
    initialLocation: '/',
    routes: _buildRoutes(),
    redirect: _handleRedirect,
    errorBuilder: _buildErrorPage,
  );

  List<RouteBase> _buildRoutes() {
    return [
      // GoRoute(
      //   name: 'notificationmessage',
      //   path: '/notificationmessage',
      //   parentNavigatorKey: rootNavigatorKey,
      //   pageBuilder: _buildNoTransitionPage(const NotificationMessage()),
      // ),
      GoRoute(
        name: 'login',
        path: '/login',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, __) => const LoginIntroScreen(),
        routes: _buildLoginRoutes(),
      ),
      GoRoute(
        name: 'maintenance-break',
        path: '/maintenance-break', 
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const MaintenanceBreakScreen())
      ),
      GoRoute(
        name: 'update',
        path: '/update/:force',
        parentNavigatorKey: rootNavigatorKey,
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
          _buildChatShellBranch(),
          _buildMapBranch(),
          _buildCreateActivityBranch(),
          _buildPeopleBranch(),
          _buildProfileBranch()
        ],
      )
    ];
  }

  StatefulShellBranch _buildChatShellBranch() {
    return StatefulShellBranch(
      navigatorKey: _chatNavigatorKey,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => ActivityManagementShellScaffold(
              navigationShell: navigationShell,
            ),
            branches: [
              _buildChatBranch(),
              _buildOwnActivitiesBranch(),
              _buildOthersActivitiesBranch(),
            ],
          ),
        ],
    );
  }

  StatefulShellBranch _buildChatBranch() {
    return StatefulShellBranch(
        routes: [
          GoRoute(
            name: 'chats',
            path: '/chats',
            pageBuilder: _buildNoTransitionPage(const ChatsScreen()),
          ),
        ],
    );
  }

  StatefulShellBranch _buildOwnActivitiesBranch() {
    return StatefulShellBranch(
      routes: [
        GoRoute(
          name: 'own-activities',
          path: '/own-activities',
          pageBuilder: _buildNoTransitionPage(const OwnActivitiesScreen()),
        ),
      ],
    );
  }

  StatefulShellBranch _buildOthersActivitiesBranch() {
    return StatefulShellBranch(
      routes: [
        GoRoute(
          name: 'others-activities',
          path: '/others-activities',
          pageBuilder: _buildNoTransitionPage(const OthersActivitiesScreen()),
        ),
      ],
    );
  }

  StatefulShellBranch _buildMapBranch() {
    return StatefulShellBranch(
      navigatorKey: _mapNavigatorKey,
        routes: [
          GoRoute(
            name: 'map',
            path: '/',
            pageBuilder: _buildNoTransitionPage(const MapScreen()),
            routes: [
              GoRoute(
                parentNavigatorKey: rootNavigatorKey,
                name: 'activity',
                path: 'activity/:id',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  final id = state.pathParameters['id'] as String;
                  return ModalPage<void>(child: ActivityDetails(activityId: id));
                },
                onExit: (context, state) {
                  ref.read(mapStateProvider.notifier).restoreZoom();
                  ref.read(mapStateProvider.notifier).reverseOffSetLocationVertically();
                  return true;
                },
                routes: [
                  GoRoute(
                    parentNavigatorKey: rootNavigatorKey,
                    name: 'participants',
                    path: 'participants',
                    pageBuilder: (BuildContext context, GoRouterState state) {
                      return NoTransitionPage<void>(child: ParticipantsList());
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: rootNavigatorKey,
                    name: 'requests',
                    path: 'requests',
                    pageBuilder: (BuildContext context, GoRouterState state) {
                      return NoTransitionPage<void>(child: RequestsList());
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: rootNavigatorKey,
                    name: 'chat',
                    path: 'chat',
                    pageBuilder: (BuildContext context, GoRouterState state) {
                      return NoTransitionPage<void>(child: ChatScreen());
                    },
                  ),
                ],
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
          // GoRoute(
          //   name: 'create-activity',
          //   path: '/create-activity',
          //   pageBuilder: _buildNoTransitionPage(const CreateMiittiOnboarding()),
          // ),
          GoRoute(
            name: 'create-activity/category',
            path: '/create-activity/category',
            pageBuilder: _buildNoTransitionPage(const ChooseActivityCategoryScreen()),
          ),
          GoRoute(
            name: 'create-activity/location',
            path: '/create-activity/location',
            pageBuilder: _buildNoTransitionPage(const ChooseActivityLocationScreen()),
          ),
          GoRoute(
            name: 'create-activity/details',
            path: '/create-activity/details',
            pageBuilder: _buildNoTransitionPage(const FillActivityDetailsScreen()),
          ),
          GoRoute(
            name: 'create-activity/invite',
            path: '/create-activity/invite',
            pageBuilder: _buildNoTransitionPage(const InviteScreen()),
          ),
          GoRoute(
            name: 'create-activity/review',
            path: '/create-activity/review',
            pageBuilder: _buildNoTransitionPage(const CreateActivityReviewScreen()),
          ),
        ],
    );
  }

  StatefulShellBranch _buildPeopleBranch() {
    return StatefulShellBranch(
      navigatorKey: _peopleNavigatorKey,
        routes: [
          GoRoute(
            name: 'people',
            path: '/people',
            pageBuilder: _buildNoTransitionPage(const PeopleScreen()),
            routes: [
              GoRoute(
                name: 'filter',
                path: 'filter',
                pageBuilder: _buildNoTransitionPage(const FilterUsersSettingsPage()),
              ),
              GoRoute(
                parentNavigatorKey: rootNavigatorKey,
                name: 'user',
                path: 'user/:id',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  final id = state.pathParameters['id'] as String;
                  return NoTransitionPage<void>(child: UserProfilePage(userId: id));
                },
              ),
            ],
          ),
        ],
    );
  }

  StatefulShellBranch _buildProfileBranch() {
    return StatefulShellBranch(
      navigatorKey: _profileNavigatorKey,
        routes: [
          GoRoute(
            name: 'profile',
            path: '/profile',
            pageBuilder: (BuildContext context, GoRouterState state) {
              bool isAnonymous = ref.read(userStateProvider).isAnonymous;
              if (isAnonymous) { router.refresh(); }
              MiittiUser? userData = !isAnonymous ? ref.read(userStateProvider).data.toMiittiUser() : null;
              return NoTransitionPage<void>(child: UserProfilePage(userId: userData?.uid));
            },
            routes: [
              GoRoute(
                name: 'settings',
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
        name: 'authenticate',
        path: 'authenticate',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const LoginScreen()),
      ),
      GoRoute(
        name: 'welcome',
        path: 'welcome',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const WelcomeScreen()),
      ),
      GoRoute(
        name: 'input-name',
        path: 'complete-profile/name',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputNameScreen()),
      ),
      GoRoute(
        name: 'input-profile',
        path: 'complete-profile/birthday',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputBirthdayScreen()),
      ),
      GoRoute(
        name: 'input-gender',
        path: 'complete-profile/gender',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputGenderScreen()),
      ),
      GoRoute(
        name: 'input-languages',
        path: 'complete-profile/languages',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputLanguagesScreen()),
      ),
      GoRoute(
        name: 'input-areas',
        path: 'complete-profile/areas',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputAreasScreen()),
      ),
      GoRoute(
        name: 'input-life-situation',
        path: 'complete-profile/life-situation',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputLifeSituationScreen()),
      ),
      GoRoute(
        name: 'input-organization',
        path: 'complete-profile/organization',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputOrganizationScreen()),
      ),
      GoRoute(
        name: 'input-qa-cards',
        path: 'complete-profile/qa-cards',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputQACardsScreen()),
      ),
      GoRoute(
        name: 'input-answer-qa-card',
        path: 'complete-profile/qa-card/:question',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final question = state.pathParameters['question']!;
          return NoTransitionPage(child: InputQACardAnswerScreen(question));
        },
      ),
      GoRoute(
        name: 'input-profile-picture',
        path: 'complete-profile/profile-picture',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputProfilePictureScreen()),
      ),
      GoRoute(
        name: 'input-activities',
        path: 'complete-profile/activities',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const InputActivitiesScreen()),
      ),
      GoRoute(
        name: 'push-notifications',
        path: 'complete-profile/push-notifications',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const AcceptPushNotificationsScreen()),
      ),
      GoRoute(
        name: 'accept-norms',
        path: 'complete-profile/community-norms',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: _buildNoTransitionPage(const AcceptNormsScreen()),
      ),
    ];
  }

  Page<void> Function(BuildContext, GoRouterState) _buildNoTransitionPage(Widget child) {
    return (context, state) => NoTransitionPage<void>(
      key: state.pageKey,
      name: state.name,
      child: child,
    );
  }

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final userState = ref.read(userStateProvider);
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

    if (firstRedirect && userState.isSignedIn && userState.isAnonymous && state.matchedLocation == '/') {
      firstRedirect = false;
      return '/login/welcome';
    }

    if (state.matchedLocation == '/login/complete-profile') {
      firstRedirect = false;
      return '/login/complete-profile/name';  // First step of the profile completion process
    }

    if (!userState.isSignedIn && state.matchedLocation != '/login' && state.matchedLocation != '/login/authenticate') {
      return '/login';  
    }

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