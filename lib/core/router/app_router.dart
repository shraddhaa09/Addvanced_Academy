import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../constants/route_constants.dart';

// Public
import '../../features/landing/screens/landing_screen.dart';
import '../../features/auth/screens/login_screen.dart';

//admin


// Faculty
import '../../features/faculty/screens/faculty_dashboard_screen.dart';
import '../../features/faculty/screens/faculty_materials_screen.dart';
import '../../features/faculty/screens/faculty_profile_screen.dart';
import '../../features/faculty/screens/faculty_schedule_screen.dart';
import '../../features/faculty/screens/upload_material_screen.dart';
import '../../features/faculty/screens/upload_video_screen.dart';
import '../../features/faculty/screens/edit_upload_screen.dart';
import '../../features/faculty/screens/faculty_personal_details_screen.dart';
import '../../features/faculty/screens/faculty_subjects_screen.dart';
import '../../features/faculty/screens/faculty_upload_history_screen.dart';
import '../../features/faculty/screens/faculty_support_screen.dart';
import '../../features/faculty/screens/faculty_announcement_screen.dart';
import '../../features/faculty/widgets/faculty_scaffold.dart';

// STUDENT
import '../../features/student/screens/student_dashboard_screen.dart';
import '../../features/student/screens/materials/material_subjects_screen.dart';
import '../../features/student/screens/materials/material_chapters_screen.dart';
import '../../features/student/screens/materials/material_list_screen.dart';
import '../../features/student/screens/videos/video_subjects_screen.dart';
import '../../features/student/screens/videos/video_list_screen.dart';
import '../../features/student/screens/videos/video_player_screen.dart';
import '../../features/student/screens/timetable/student_timetable_screen.dart';
import '../../features/student/screens/student_profile_screen.dart';
import '../../features/student/screens/student_support_screen.dart';
import '../../features/student/screens/student_announcement_screen.dart';
import '../../features/student/screens/student_personal_details_screen.dart';
import '../../features/student/widgets/student_scaffold.dart';

// MODELS
import '../../models/faculty_upload_model.dart';
import '../../models/video_lecture_model.dart';

// PROVIDERS
import '../../providers/auth_provider.dart';

// Tests
import '../../features/test/screens/answer_review_screen.dart';
import '../../features/test/screens/assigned_tests_screen.dart';
import '../../features/test/screens/chapter_selection_screen.dart';
import '../../features/test/screens/result_screen.dart';
import '../../features/test/screens/test_confirmation_screen.dart';
import '../../features/test/screens/test_engine_screen.dart';
import '../../features/test/screens/test_selection_screen.dart';

// Replace this import with the correct model used by EditUploadScreen
// Example:
// import '../../models/upload_model.dart';

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
    initialLocation: RouteConstants.landing,
    refreshListenable: refreshNotifier,

    // ---------------- REDIRECT ----------------
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final path = state.uri.path;

      final isLoginRoute = path == RouteConstants.login;
      final isAdminArea = path.startsWith('/admin');
      final isFacultyArea = path.startsWith('/faculty');
      final isStudentArea = path.startsWith('/student');

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

      switch (authState.role) {
        case AppUserRole.admin:
          return null;
        case AppUserRole.faculty:
          if (isAdminArea || isStudentArea) {
            return RouteConstants.facultyDashboard;
          }
          return null;
        case AppUserRole.student:
          if (isAdminArea || isFacultyArea) {
            return RouteConstants.studentDashboard;
          }
          return null;
        case AppUserRole.unknown:
          return RouteConstants.login;
      }
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
                  GoRoute(
                    path: 'edit-upload',
                    builder: (context, state) => EditUploadScreen(
                      upload: state.extra as FacultyUploadModel,
                    ),
                  ),
                  GoRoute(
                    path: 'announcements',
                    builder: (context, state) => const FacultyAnnouncementScreen(),
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

      // =========================================================
      // STUDENT SHELL
      // =========================================================
      // =========================================================
      // STUDENT SHELL
      // =========================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StudentScaffold(navigationShell: navigationShell);
        },
        branches: [
          // DASHBOARD
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.studentDashboard,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: StudentDashboardScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'announcements',
                    builder: (context, state) => const StudentAnnouncementScreen(),
                  ),
                  GoRoute(
                    path: 'tests',
                    builder: (context, state) => const AssignedTestsScreen(),
                    routes: [
                      GoRoute(
                        path: 'selection/:subject',
                        builder: (context, state) => TestSelectionScreen(
                          subject: state.pathParameters['subject'] ?? '',
                        ),
                      ),
                      GoRoute(
                        path: 'chapters/:subject',
                        builder: (context, state) => ChapterSelectionScreen(
                          subject: state.pathParameters['subject'] ?? '',
                        ),
                      ),
                      GoRoute(
                        path: 'confirmation',
                        builder: (context, state) => const TestConfirmationScreen(),
                      ),
                      GoRoute(
                        path: 'engine',
                        builder: (context, state) => const TestEngineScreen(),
                      ),
                      GoRoute(
                        path: 'result',
                        builder: (context, state) => const ResultScreen(),
                      ),
                      GoRoute(
                        path: 'review',
                        builder: (context, state) => const AnswerReviewScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // SCHEDULE
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.studentSchedule,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: StudentTimetableScreen(),
                ),
              ),
            ],
          ),

          // MATERIALS / VIDEOS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.studentMaterials,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MaterialSubjectsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'chapters/:subject',
                    builder: (context, state) => MaterialChaptersScreen(
                      subject: state.pathParameters['subject'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'list/:subject/:chapter',
                    builder: (context, state) => MaterialListScreen(
                      subjectId: state.pathParameters['subject'] ?? '',
                      chapterId: state.pathParameters['chapter'] ?? '',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: RouteConstants.studentVideos,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: VideoSubjectsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'list/:subject',
                    builder: (context, state) => VideoListScreen(
                      subject: state.pathParameters['subject'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'player',
                    builder: (context, state) => VideoPlayerScreen(
                      video: state.extra as VideoLectureModel,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // PROFILE
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.studentProfile,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: StudentProfileScreen(),
                ),
                routes: [
                  GoRoute(
                    path: RouteConstants.personalDetails,
                    builder: (context, state) => const StudentPersonalDetailsScreen(),
                  ),
                  GoRoute(
                    path: RouteConstants.studentSupport,
                    builder: (context, state) => const StudentSupportScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
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
