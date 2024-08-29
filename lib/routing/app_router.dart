import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/functions/notification_message.dart';
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
import 'package:miitti_app/screens/index_page.dart';
import 'package:miitti_app/screens/maintenance_break_screen.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';

// A class to define the app's routing configuration and behavior
class AppRouter {
  final WidgetRef ref;

  AppRouter(this.ref);

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: ValueNotifier<bool>(ref.watch(userStateProvider.notifier).isSignedIn),
    initialLocation: '/',
    routes: _buildRoutes(),
    redirect: _handleRedirect,
    errorBuilder: _buildErrorPage,
  );

  List<RouteBase> _buildRoutes() {
    return [
      GoRoute(
        path: '/',
        pageBuilder: _buildNoTransitionPage(const IndexPage()),
      ),
      GoRoute(
        path: '/notificationmessage',
        pageBuilder: _buildNoTransitionPage(const NotificationMessage()),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginIntroScreen(),
        routes: _buildLoginRoutes(),
      ),
      GoRoute(
        path: '/maintenance-break', 
        pageBuilder: _buildNoTransitionPage(const MaintenanceBreakScreen())
      ),
      // TODO: Implement ShellRoute
      // ShellRoute(
      //   builder: (context, state, child) => ScaffoldWithBottomNavBar(child: child),
      //   routes: _buildShellRoutes(),
      // ),
    ];
  }

  List<GoRoute> _buildLoginRoutes() {
    return [
      GoRoute(
        path: 'authenticate',
        pageBuilder: _buildNoTransitionPage(const LoginScreen()),
      ),
      GoRoute(
        path: 'welcome',
        pageBuilder: _buildNoTransitionPage(const WelcomeScreen()),
      ),
      GoRoute(
        path: 'complete-profile/name',
        pageBuilder: _buildNoTransitionPage(const InputNameScreen()),
      ),
      GoRoute(
        path: 'complete-profile/birthday',
        pageBuilder: _buildNoTransitionPage(const InputBirthdayScreen()),
      ),
      GoRoute(
        path: 'complete-profile/gender',
        pageBuilder: _buildNoTransitionPage(const InputGenderScreen()),
      ),
      GoRoute(
        path: 'complete-profile/languages',
        pageBuilder: _buildNoTransitionPage(const InputLanguagesScreen()),
      ),
      GoRoute(
        path: 'complete-profile/areas',
        pageBuilder: _buildNoTransitionPage(const InputAreasScreen()),
      ),
      GoRoute(
        path: 'complete-profile/life-situation',
        pageBuilder: _buildNoTransitionPage(const InputLifeSituationScreen()),
      ),
      GoRoute(
        path: 'complete-profile/organization',
        pageBuilder: _buildNoTransitionPage(const InputOrganizationScreen()),
      ),
      GoRoute(
        path: 'complete-profile/qa-cards',
        pageBuilder: _buildNoTransitionPage(const InputQACardsScreen()),
      ),
      GoRoute(
        path: 'complete-profile/qa-card/:question',
        pageBuilder: (context, state) {
          final question = state.pathParameters['question']!;
          return NoTransitionPage(child: InputQACardAnswerScreen(question));
        },
      ),
      GoRoute(
        path: 'complete-profile/profile-picture',
        pageBuilder: _buildNoTransitionPage(const InputProfilePictureScreen()),
      ),
      GoRoute(
        path: 'complete-profile/activities',
        pageBuilder: _buildNoTransitionPage(const InputActivitiesScreen()),
      ),
      GoRoute(
        path: 'complete-profile/push-notifications',
        pageBuilder: _buildNoTransitionPage(const AcceptPushNotificationsScreen()),
      ),
      GoRoute(
        path: 'complete-profile/community-norms',
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
    final isAuthenticated = ref.watch(userStateProvider.notifier).isSignedIn;
    final isMaintenanceBreak = ref.watch(remoteConfigServiceProvider).getBool('maintenance_break');

    if (isMaintenanceBreak) {
      return '/maintenance-break';
    }

    if (state.matchedLocation == '/login/complete-profile') {
      return '/login/complete-profile/name';  // First step of the profile completion process
    }

    if (!isAuthenticated && state.matchedLocation != '/login' && state.matchedLocation != '/login/authenticate') {
      return '/login';  
    }

    if (isAuthenticated && state.matchedLocation != '/login/welcome') {
      ref.watch(firestoreServiceProvider).checkExistingUser(ref.watch(userStateProvider.notifier).uid!);
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
}