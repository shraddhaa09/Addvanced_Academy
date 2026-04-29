class RouteConstants {
  const RouteConstants._();

  static const String landing = '/';
  static const String login = '/login';

  // Faculty Routes
  static const String facultyDashboard = '/faculty';
  static const String facultySchedule = '/faculty/schedule';
  static const String facultyMaterials = '/faculty/materials';
  static const String facultyProfile = '/faculty/profile';

  // Faculty Sub-routes (relative)
  static const String uploadVideo = 'upload-video';
  static const String uploadMaterial = 'upload-material';
  static const String editUpload = 'edit-upload';
  static const String facultyAnnouncements = 'announcements';
  static const String mySubjects = 'my-subjects';
  static const String uploadHistory = 'upload-history';

  // Student Routes
  static const String studentDashboard = '/student';
  static const String studentAnnouncements = '/student/announcements';
  static const String studentSchedule = '/student/schedule';
  static const String studentMaterials = '/student/materials';
  static const String studentVideos = '/student/videos';
  static const String studentProfile = '/student/profile';
  static const String studentSupport = '/student/support';
  static const String studentSyllabus = '/student/syllabus';

  // Student Sub-routes (relative or specific)
  static const String personalDetails = 'personal-details';
  static const String myResults = 'my-results';
  static const String helpSupport = 'help-support';
  
  // Materials/Videos navigation
  static const String materialChapters = 'chapters/:subject';
  static const String materialList = 'list/:subject/:chapter';
  static const String videoList = 'list/:subject';
  static const String videoPlayer = 'player';

  // Test Engine Routes
  static const String assignedTests = '/student/tests';
  static const String testSelection = 'selection/:subject';
  static const String chapterSelection = 'chapters/:subject';
  static const String testConfirmation = 'confirmation';
  static const String testEngine = 'engine';
  static const String result = 'result';
  static const String answerReview = 'review';

  // Generic
  static const String videoViewer = 'video-viewer';
  static const String materialViewer = 'material-viewer';
  
  // Legacy/Deprecated compatibility (optional cleanup)
  static const String studentTimetable = studentSchedule;
  static const String videoSubjects = studentVideos;
  static const String materialSubjects = studentMaterials;
}