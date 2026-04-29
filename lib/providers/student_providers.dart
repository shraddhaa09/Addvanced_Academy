import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/faculty_upload_model.dart';
import '../models/study_material_model.dart';
import '../models/video_lecture_model.dart';
import '../models/student_model.dart';
import '../models/timetable_model.dart';
import '../services/faculty_upload_service.dart';
import '../services/student_service.dart';
import 'faculty_providers.dart';
import 'auth_provider.dart';

final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService(Supabase.instance.client);
});

final currentStudentIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final authState = ref.watch(authProvider);
  final authId = authState.userId;
  if (authId == null) return null;

  try {
    final row = await Supabase.instance.client
        .schema('academy')
        .from('users')
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();

    if (row == null) return null;
    return row['id'] as String?;
  } catch (e) {
    return null;
  }
});

final studentProfileProvider = FutureProvider.autoDispose<StudentModel?>((ref) async {
  final studentId = await ref.watch(currentStudentIdProvider.future);
  if (studentId == null) return null;

  final service = ref.watch(studentServiceProvider);
  return service.fetchProfile(studentId);
});

final studentStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final studentId = await ref.watch(currentStudentIdProvider.future);
  if (studentId == null) return {'tests_taken': 0, 'materials_read': 0, 'attendance': '0%'};

  final service = ref.watch(studentServiceProvider);
  return service.fetchStudentStats(studentId);
});

final studentScheduleProvider = FutureProvider.autoDispose<List<TimetableModel>>((ref) async {
  final profile = await ref.watch(studentProfileProvider.future);
  if (profile == null) return [];

  final service = ref.watch(timetableServiceProvider);
  return service.fetchTimetableByBatch(profile.batch);
});

final studentRecentUploadsProvider =
    FutureProvider.autoDispose.family<List<FacultyUploadModel>, int?>(
        (ref, limit) async {
  // For students, we fetch recent uploads across all faculties
  try {
    final response = await Supabase.instance.client
        .schema('academy')
        .from('v_faculty_uploads')
        .select()
        .eq('is_visible', true)
        .order('uploaded_at', ascending: false);

    final uploads = (response as List)
        .map((json) => FacultyUploadModel.fromJson(json))
        .toList();
        
    return limit != null ? uploads.take(limit).toList() : uploads;
  } catch (e) {
    return [];
  }
});

final studentMaterialsProvider =
    FutureProvider.autoDispose.family<List<StudyMaterialModel>, String>(
        (ref, chapterId) async {
  final service = ref.watch(materialServiceProvider);
  return service.fetchMaterialsByChapter(chapterId);
});

final studentVideosProvider =
    FutureProvider.autoDispose.family<List<VideoLectureModel>, String>(
        (ref, subjectId) async {
  final service = ref.watch(videoServiceProvider);
  return service.fetchVideosBySubject(subjectId);
});
