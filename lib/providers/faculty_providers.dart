import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chapter_model.dart';
import '../models/faculty_model.dart';
import '../models/faculty_upload_model.dart';
import '../models/subject_model.dart';
import '../models/timetable_model.dart';
import '../services/chapter_service.dart';
import '../services/faculty_service.dart';
import '../services/faculty_upload_service.dart';
import '../services/material_service.dart';
import '../services/subject_service.dart';
import '../services/timetable_service.dart';
import '../services/video_service.dart';
import 'auth_provider.dart';

// Services
final subjectServiceProvider = Provider<SubjectService>((ref) {
  return SubjectService(Supabase.instance.client);
});

final chapterServiceProvider = Provider<ChapterService>((ref) {
  return ChapterService(Supabase.instance.client);
});

final videoServiceProvider = Provider<VideoService>((ref) {
  return VideoService(Supabase.instance.client);
});

final materialServiceProvider = Provider<MaterialService>((ref) {
  return MaterialService(Supabase.instance.client);
});

final facultyUploadServiceProvider = Provider<FacultyUploadService>((ref) {
  return FacultyUploadService(Supabase.instance.client);
});

final facultyServiceProvider = Provider<FacultyService>((ref) {
  return FacultyService(Supabase.instance.client);
});

final timetableServiceProvider = Provider<TimetableService>((ref) {
  return TimetableService(Supabase.instance.client);
});

// Data Providers
final subjectsProvider = FutureProvider.autoDispose<List<SubjectModel>>((ref) async {
  final service = ref.watch(subjectServiceProvider);
  return service.fetchSubjects();
});

final chaptersProvider = FutureProvider.autoDispose.family<List<ChapterModel>, String>((ref, subjectId) async {
  if (subjectId.isEmpty) return [];
  final service = ref.watch(chapterServiceProvider);
  return service.fetchChaptersBySubject(subjectId);
});

final currentFacultyIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final authState = ref.watch(authProvider);
  final authId = authState.userId;
  if (authId == null) return null;
  
  try {
    // According to the schema: auth.users.id -> academy.users.auth_id -> academy.users.id (which is faculty_id)
    final response = await Supabase.instance.client
        .schema('academy')
        .from('users')
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();

    return response?['id'] as String?;
  } catch (e) {
    debugPrint('Error in currentFacultyIdProvider: $e');
    return null;
  }
});

final recentFacultyUploadsProvider = FutureProvider.autoDispose<List<FacultyUploadModel>>((ref) async {
  final facultyId = await ref.watch(currentFacultyIdProvider.future);
  if (facultyId == null) return [];
  
  final service = ref.watch(facultyUploadServiceProvider);
  return service.fetchRecentUploads(facultyId);
});

final facultyProfileProvider = FutureProvider.autoDispose<FacultyModel?>((ref) async {
  final facultyId = await ref.watch(currentFacultyIdProvider.future);
  if (facultyId == null) return null;
  
  final service = ref.watch(facultyServiceProvider);
  return service.fetchProfile(facultyId);
});

final facultyStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final facultyId = await ref.watch(currentFacultyIdProvider.future);
  if (facultyId == null) return {'videos': 0, 'materials': 0, 'total_uploads': 0, 'students': 0};
  
  final service = ref.watch(facultyServiceProvider);
  return service.fetchFacultyStats(facultyId);
});

final timetableProvider = FutureProvider.autoDispose.family<List<TimetableModel>, String>((ref, dayOfWeek) async {
  final facultyId = await ref.watch(currentFacultyIdProvider.future);
  if (facultyId == null) return [];
  
  final service = ref.watch(timetableServiceProvider);
  return service.fetchScheduleByDay(facultyId, dayOfWeek);
});
