class RouteConstants {
  const RouteConstants._();

  static const String landing = '/';
  static const String login = '/login';

  // Admin
  static const String adminDashboard = '/admin';

  // Faculty
  static const String facultyDashboard = '/faculty';
  static const String facultySchedule = '/faculty/schedule';
  static const String facultyMaterials = '/faculty/materials';
  static const String facultyProfile = '/faculty/profile';

  // Faculty Sub-routes (Relative paths for nesting)
  static const String uploadVideo = 'upload-video';
  static const String uploadMaterial = 'upload-material';
  static const String editUpload = 'edit-upload';

  // Faculty Profile Sub-routes (Relative paths)
  static const String personalDetails = 'personal-details';
  static const String mySubjects = 'my-subjects';
  static const String uploadHistory = 'upload-history';
  static const String helpSupport = 'help-support';

  // Student
  static const String studentDashboard = '/student';

  // Student Tests
  static const String assignedTests = '/student/tests';
  static const String testSelection = '/student/test-selection';
  static const String chapterSelection = '/student/tests/chapters';
  static const String testConfirmation = '/student/tests/confirmation';
  static const String testEngine = '/student/tests/engine';
  static const String result = '/student/tests/result';
  static const String answerReview = '/student/tests/review';

  // Student Videos
  static const String videoSubjects = '/student/videos';
  static const String videoList = '/student/videos/:subject';
  static const String videoPlayer = '/student/video-player';

  // Student Materials
  static const String materialSubjects = '/student/materials';
  static const String materialChapters = '/student/materials/:subject/chapters';
  static const String materialList = '/student/materials/:subject/:chapter';

  // Student Timetable
  static const String studentTimetable = '/student/timetable';

  // Student Syllabus
  static const String studentSyllabus = '/student/syllabus';
}