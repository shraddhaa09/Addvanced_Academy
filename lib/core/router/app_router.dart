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
import '../../features/faculty/screens/faculty_personal_details_screen.dart';
import '../../features/faculty/screens/faculty_subjects_screen.dart';
import '../../features/faculty/screens/faculty_upload_history_screen.dart';
import '../../features/faculty/screens/faculty_support_screen.dart';
import '../../features/faculty/widgets/faculty_scaffold.dart';

// STUDENT
import '../../features/student/screens/student_dashboard_screen.dart';

// PROVIDERS
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

    // ---------------- REDIRECT ----------------
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

    routes: [

      // ===== LOGIN =====
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // ===== ADMIN =====
      GoRoute(
        path: RouteConstants.adminDashboard,
        builder: (context, state) =>
        const _PlaceholderScreen(title: 'Admin Dashboard'),
      ),

      // =========================================================
      // FACULTY SHELL (CORRECT VERSION)
      // =========================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return FacultyScaffold(navigationShell: navigationShell);
        },
        branches: [

          // DASHBOARD
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.facultyDashboard,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FacultyDashboardScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'upload-video',
                    builder: (context, state) => const UploadVideoScreen(),
                  ),
                  GoRoute(
                    path: 'upload-material',
                    builder: (context, state) => const UploadMaterialScreen(),
                  ),
                ],
              ),
            ],
          ),

          // SCHEDULE
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.facultySchedule,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FacultyScheduleScreen(),
                ),
              ),
            ],
          ),

          // MATERIALS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.facultyMaterials,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FacultyMaterialsScreen(),
                ),
              ),
            ],
          ),

          // PROFILE
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.facultyProfile,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FacultyProfileScreen(),
                ),
                routes: [
                  GoRoute(
                    path: RouteConstants.personalDetails,
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: FacultyPersonalDetailsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: RouteConstants.mySubjects,
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: FacultySubjectsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: RouteConstants.uploadHistory,
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: FacultyUploadHistoryScreen(),
                    ),
                  ),
                  GoRoute(
                    path: RouteConstants.helpSupport,
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: FacultySupportScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ===== STUDENT =====
      GoRoute(
        path: RouteConstants.studentDashboard,
        builder: (context, state) => const StudentDashboardScreen(),
      ),
    ],
  );
});


// ---------------- PLACEHOLDER ----------------
class _PlaceholderScreen extends ConsumerWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

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
      body: Center(child: Text(title)),
    );
  }
}