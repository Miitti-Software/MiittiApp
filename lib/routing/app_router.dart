import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/functions/notification_message.dart';
import 'package:miitti_app/screens/authentication/completeProfile/complete_profile_onboard.dart';
import 'package:miitti_app/screens/authentication/explore_decision_screen.dart';
import 'package:miitti_app/screens/authentication/login_screen.dart';
import 'package:miitti_app/screens/authentication/login_intro.dart';
import 'package:miitti_app/screens/index_page.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';

// A class to define the app's routing configuration and behavior
class AppRouter {
  final WidgetRef ref;

  AppRouter(this.ref);

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: ValueNotifier<bool>(ref.watch(authServiceProvider).isSignedIn),
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
        path: 'explore',
        pageBuilder: _buildNoTransitionPage(const ExploreDecisionScreen()),
      ),
      GoRoute(
        path: 'complete-profile',
        pageBuilder: _buildNoTransitionPage(const CompleteProfileOnboard()),
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

    if (!isAuthenticated && state.matchedLocation != '/login' && state.matchedLocation != '/login/authenticate') {
      return '/login';
    }

    if (isAuthenticated && state.matchedLocation != '/login/explore') {
      ref.watch(firestoreServiceProvider).checkExistingUser(ref.watch(userStateProvider.notifier).uid);
    }

    return null;
  }

  Widget _buildErrorPage(BuildContext context, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Text('Error navigating to the requested page: ${state.error}'),
      ),
    );
  }
}