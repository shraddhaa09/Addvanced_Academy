class RouteConstants {
  // AUTH
  static const String login = '/login';
  static const String adminDashboard = '/admin';
  static const String facultyDashboard = '/faculty';

  static const String uploadVideo = '/faculty/upload-video';
  static const String uploadMaterial = '/faculty/upload-material';

  static const String questionBank = '/question-bank';
  static const String addQuestion = '/add-question';

  static const String createTest = '/create-test';
  static const String assignTest = '/assign-test';

  static const String timetable = '/timetable';

  // ===========================
  // FACULTY MODULE
  // ===========================
  static const String uploadVideo = '/upload-video';
  static const String uploadMaterial = '/upload-material';

  // ===========================
  // STUDENT MODULE
  // ===========================

  // VIDEO FLOW (video_lectures table)
  static const String videoSubjects = '/video-subjects';
  static const String videoList = '/video-list';
  static const String videoPlayer = '/video-player';

  // MATERIAL FLOW (study_materials table)
  static const String materialSubjects = '/material-subjects';
  static const String materialChapters = '/material-chapters';
  static const String materialList = '/material-list';

  // SYLLABUS
  static const String syllabus = '/syllabus';

  // TIMETABLE
  static const String studentTimetable = '/student-timetable';

  // ===========================
  // TEST MODULE (SCHEMA CORE)
  // ===========================
  static const String assignedTests = '/assigned-tests';
  static const String testSelection = '/test-selection';
  static const String chapterSelection = '/chapter-selection';
  static const String testConfirmation = '/test-confirmation';
  static const String testEngine = '/test-engine';
  static const String result = '/result';
  static const String answerReview = '/answer-review';
}