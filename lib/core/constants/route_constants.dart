class RouteConstants {
  const RouteConstants._();

  static const String landing = '/';
  static const String login = '/login';

  static const String adminDashboard = '/admin';
  static const String studentDatabase     = '/admin/students';
  static const String studentRegistration = '/admin/students/register';
  static const String facultyRegistration = '/admin/faculty/register';
  static const String questionBank = '/admin/question-bank';
  static const String addQuestion  = '/admin/question-bank/add';
  static const String tests      = '/admin/tests';
  static const String createTest = '/admin/tests/create';
  static const String assignTest = '/admin/tests/:testId/assign';
  static const String adminTimetable = '/admin/timetable';
  static const String adminReports   = '/admin/reports';

  static const String facultyDashboard = '/faculty';
  static const String facultySchedule = '/faculty/schedule';
  static const String facultyMaterials = '/faculty/materials';
  static const String facultyProfile = '/faculty/profile';

  static const String uploadVideo = 'upload-video';
  static const String uploadMaterial = 'upload-material';
  static const String editUpload = 'edit-upload';

  static const String personalDetails = 'personal-details';
  static const String mySubjects = 'my-subjects';
  static const String uploadHistory = 'upload-history';
  static const String helpSupport = 'help-support';
  static const String facultyAnnouncements = 'announcements';

  static const String videoViewer = 'video-viewer';
  static const String materialViewer = 'material-viewer';

  static const String studentDashboard = '/student';

  static const String assignedTests = '/student/tests';
  static const String testSelection = '/student/test-selection';
  static const String chapterSelection = '/student/tests/chapters';
  static const String testConfirmation = '/student/tests/confirmation';
  static const String testEngine = '/student/tests/engine';
  static const String result = '/student/tests/result';
  static const String answerReview = '/student/tests/review';

  static const String videoSubjects = '/student/videos';
  static const String videoList = '/student/videos/:subject';
  static const String videoPlayer = '/student/video-player';

  static const String materialSubjects = '/student/materials';
  static const String materialChapters = '/student/materials/:subject/chapters';
  static const String materialList = '/student/materials/:subject/:chapter';

  static const String studentTimetable = '/student/timetable';
  static const String studentSyllabus = '/student/syllabus';

  // Specific getters needed by app_router
  static const String studentSchedule = studentTimetable;
  static const String studentMaterials = materialSubjects;
  static const String studentVideos = videoSubjects;
  static const String studentProfile = '/student/profile';
  static const String studentSupport = '/student/support';
}