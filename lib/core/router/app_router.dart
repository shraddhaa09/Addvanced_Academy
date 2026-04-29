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
import '../../features/faculty/widgets/faculty_scaffold.dart';

// Student
import '../../features/student/screens/student_dashboard_screen.dart';
import '../../features/student/screens/videos/video_subjects_screen.dart';
import '../../features/student/screens/videos/video_list_screen.dart';
import '../../features/student/screens/videos/video_player_screen.dart';
import '../../models/video_lecture_model.dart';
import '../../features/student/screens/materials/material_subjects_screen.dart';
import '../../features/student/screens/materials/material_chapters_screen.dart';
import '../../features/student/screens/materials/material_list_screen.dart';
import '../../features/student/screens/timetable/student_timetable_screen.dart';

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
          (_, _) => notifyListeners(),
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
      GoRoute(
        path: RouteConstants.landing,
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.adminDashboard,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Admin Dashboard',
        ),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return FacultyScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.facultyDashboard,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FacultyDashboardScreen(),
                ),
                routes: [
                  GoRoute(
                    path: RouteConstants.uploadVideo,
                    builder: (context, state) => const UploadVideoScreen(),
                  ),
                  GoRoute(
                    path: RouteConstants.uploadMaterial,
                    builder: (context, state) => const UploadMaterialScreen(),
                  ),
                  GoRoute(
                    path: RouteConstants.editUpload,
                    builder: (context, state) {
                      // Replace `YourUploadModel` with your real model class
                      final upload = state.extra as dynamic;
                      return EditUploadScreen(upload: upload);
                    },
                  ),
                ],
              ),
            ],
          ),
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
                    builder: (context, state) =>
                    const FacultyPersonalDetailsScreen(),
                  ),
                  GoRoute(
                    path: RouteConstants.mySubjects,
                    builder: (context, state) => const FacultySubjectsScreen(),
                  ),
                  GoRoute(
                    path: RouteConstants.uploadHistory,
                    builder: (context, state) =>
                    const FacultyUploadHistoryScreen(),
                  ),
                  GoRoute(
                    path: RouteConstants.helpSupport,
                    builder: (context, state) => const FacultySupportScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: RouteConstants.studentDashboard,
        builder: (context, state) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: RouteConstants.videoSubjects,
        builder: (context, state) => const VideoSubjectsScreen(),
      ),
      GoRoute(
        path: RouteConstants.videoList,
        builder: (context, state) {
          final subject = state.pathParameters['subject'] ?? '';
          return VideoListScreen(subject: subject);
        },
      ),
      GoRoute(
        path: RouteConstants.videoPlayer,
        builder: (context, state) {
          final video = state.extra as VideoLectureModel;
          return VideoPlayerScreen(video: video);
        },
      ),
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
      GoRoute(
        path: RouteConstants.materialSubjects,
        builder: (context, state) => const MaterialSubjectsScreen(),
      ),
      GoRoute(
        path: RouteConstants.materialChapters,
        builder: (context, state) {
          final subject = state.pathParameters['subject'] ?? '';
          return MaterialChaptersScreen(subject: subject);
        },
      ),
      GoRoute(
        path: RouteConstants.materialList,
        builder: (context, state) {
          final subject = state.pathParameters['subject'] ?? '';
          final chapter = state.pathParameters['chapter'] ?? '';
          return MaterialListScreen(
            subjectId: subject,
            chapterId: chapter,
          );
        },
      ),
      GoRoute(
        path: RouteConstants.studentTimetable,
        builder: (context, state) => const StudentTimetableScreen(),
      ),
      GoRoute(
        path: RouteConstants.studentSyllabus,
        builder: (context, state) =>
        const PlaceholderScreen(title: 'Syllabus'),
      ),
    ],
  );
});

class PlaceholderScreen extends ConsumerWidget {
  final String title;

  const PlaceholderScreen({
    required this.title,
    super.key,
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
