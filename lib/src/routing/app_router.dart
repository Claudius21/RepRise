import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/plans/plans_screen.dart';
import '../screens/plans/plan_edit_screen.dart';
import '../screens/workout/workout_detail_screen.dart';
import '../screens/workout/workout_tracking_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/layout/main_scaffold.dart';
import '../models/workout_plan.dart';

abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String plans = '/plans';
  static const String workoutDetail = '/plans/detail';
  static const String planEdit = '/plans/edit';
  static const String workoutTracking = '/tracking';
  static const String progress = '/progress';
  static const String profile = '/profile';
}

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // Still restoring session – don't redirect yet
      if (authState.status == AuthStatus.loading) return null;

      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.onboarding;

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.plans,
            builder: (context, state) => const PlansScreen(),
          ),
          GoRoute(
            path: AppRoutes.progress,
            builder: (context, state) => const ProgressScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.planEdit,
        builder: (context, state) {
          final plan = state.extra as WorkoutPlan;
          return PlanEditScreen(plan: plan);
        },
      ),
      GoRoute(
        path: AppRoutes.workoutDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return WorkoutDetailScreen(
            plan: extra['plan'] as WorkoutPlan,
            dayIndex: extra['dayIndex'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.workoutTracking,
        builder: (context, state) => const WorkoutTrackingScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
