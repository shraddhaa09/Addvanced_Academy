class RouteConstants {
  const RouteConstants._();

  // ===========================
  // AUTH
  // ===========================
  static const String login = '/login';
  static const String adminDashboard = '/admin';

  // ===========================
  // FACULTY ROOT
  // ===========================
  static const String facultyDashboard = '/faculty';
  static const String facultySchedule = '/faculty/schedule';
  static const String facultyMaterials = '/faculty/materials';
  static const String facultyProfile = '/faculty/profile';

  // ===========================
  // FACULTY CHILD ROUTES
  // ===========================
  static const String uploadVideo = 'upload-video';
  static const String uploadMaterial = 'upload-material';

  static const String personalDetails = 'personal-details';
  static const String mySubjects = 'my-subjects';
  static const String uploadHistory = 'upload-history';
  static const String helpSupport = 'help-support';
  static const String editUpload = 'edit-upload';

  // ===========================
  // STUDENT
  // ===========================
  static const String studentDashboard = '/student';

  static const String videoSubjects = '/video-subjects';
  static const String videoList = '/video-list';
  static const String videoPlayer = '/video-player';

  static const String materialSubjects = '/material-subjects';
  static const String materialChapters = '/material-chapters';
  static const String materialList = '/material-list';

  static const String syllabus = '/syllabus';
  static const String studentTimetable = '/student-timetable';

  // ===========================
  // TEST MODULE
  // ===========================
  static const String assignedTests = '/assigned-tests';
  static const String testSelection = '/test-selection';
  static const String chapterSelection = '/chapter-selection';
  static const String testConfirmation = '/test-confirmation';
  static const String testEngine = '/test-engine';
  static const String result = '/result';
  static const String answerReview = '/answer-review';
}