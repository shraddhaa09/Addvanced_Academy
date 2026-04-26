import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// AUTH
import '../../features/auth/screens/login_screen.dart';

// FACULTY
import '../../features/faculty/screens/faculty_dashboard_screen.dart';
import '../../features/faculty/screens/faculty_materials_screen.dart';
import '../../features/faculty/screens/faculty_profile_screen.dart';
import '../../features/faculty/screens/faculty_schedule_screen.dart';
import '../../features/faculty/screens/upload_material_screen.dart';
import '../../features/faculty/screens/upload_video_screen.dart';
import '../../features/student/screens/student_dashboard_screen.dart';
import '../../providers/auth_provider.dart';

// CONSTANTS
import '../constants/route_constants.dart';


// ---------------- ROUTER REFRESH ----------------
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


// ---------------- APP ROUTER ----------------
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: RouteConstants.login,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final path = state.uri.path;

      final isLoginRoute = path == RouteConstants.login;

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
    routes: <RouteBase>[
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.adminDashboard,
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Admin Dashboard',
        ),
      ),
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

class _PlaceholderScreen extends ConsumerWidget {
  final String title;

  const _PlaceholderScreen({
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Text(title),
      ),
    );
  }
}