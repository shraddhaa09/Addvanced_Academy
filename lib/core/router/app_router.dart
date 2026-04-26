import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// AUTH
import '../../features/auth/screens/login_screen.dart';

// FACULTY
import '../../features/faculty/screens/faculty_dashboard_screen.dart';
import '../../features/faculty/screens/upload_material_screen.dart';
import '../../features/faculty/screens/upload_video_screen.dart';

// STUDENT
import '../../features/student/screens/student_dashboard_screen.dart';


import '../../features/test/screens/assigned_tests_screen.dart';
import '../../features/test/screens/test_selection_screen.dart'; 
import '../../features/test/screens/chapter_selection_screen.dart';
import '../../features/test/screens/test_confirmation_screen.dart';
import '../../features/test/screens/test_engine_screen.dart';
import '../../features/test/screens/result_screen.dart';
import '../../features/test/screens/answer_review_screen.dart';

// PROVIDER
import '../../providers/auth_provider.dart';

// CONSTANTS
import '../constants/route_constants.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this.ref) {
    _subscription = ref.listen<AuthStateModel>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref ref;
  late final ProviderSubscription<AuthStateModel> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: RouteConstants.login,
    refreshListenable: refreshNotifier,

    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == RouteConstants.login;

      if (!isLoggedIn) {
        return isLoginRoute ? null : RouteConstants.login;
      }

      if (isLoginRoute) {
        switch (authState.role) {
          case AppUserRole.admin:
            return RouteConstants.adminDashboard;
          case AppUserRole.faculty:
            return RouteConstants.facultyDashboard;
          case AppUserRole.student:
            return RouteConstants.studentDashboard;
          case AppUserRole.unknown:
            return RouteConstants.login;
        }
      }

      return null;
    },

    routes: [
      // AUTH
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // ADMIN
      GoRoute(
        path: RouteConstants.adminDashboard,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Admin Dashboard'))),
      ),

      // FACULTY
      GoRoute(
        path: RouteConstants.facultyDashboard,
        builder: (context, state) => const FacultyDashboardScreen(),
      ),
      GoRoute(
        path: RouteConstants.uploadVideo,
        builder: (context, state) => const UploadVideoScreen(),
      ),
      GoRoute(
        path: RouteConstants.uploadMaterial,
        builder: (context, state) => const UploadMaterialScreen(),
      ),

      // STUDENT
      GoRoute(
        path: RouteConstants.studentDashboard,
        builder: (context, state) => const StudentDashboardScreen(),
      ),

      // ================= TEST FLOW (FIXED) =================
      GoRoute(
        path: RouteConstants.assignedTests,
        builder: (context, state) => const AssignedTestsScreen(),
      ),
      GoRoute(
        path: RouteConstants.testSelection,
        builder: (context, state) => const TestSelectionScreen(),
      ),
      GoRoute(
        path: RouteConstants.chapterSelection,
        builder: (context, state) => const ChapterSelectionScreen(),
      ),
      GoRoute(
        path: RouteConstants.testConfirmation,
        builder: (context, state) => const TestConfirmationScreen(),
      ),
      GoRoute(
        path: RouteConstants.testEngine,
        builder: (context, state) => const TestEngineScreen(),
      ),
      GoRoute(
        path: RouteConstants.result,
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: RouteConstants.answerReview,
        builder: (context, state) => const AnswerReviewScreen(),
      ),
    ],
  );
});