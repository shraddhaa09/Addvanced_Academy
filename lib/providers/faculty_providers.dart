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

final subjectsProvider =
FutureProvider.autoDispose<List<SubjectModel>>((ref) async {
  final service = ref.watch(subjectServiceProvider);
  return service.fetchSubjects();
});

final chaptersProvider =
FutureProvider.autoDispose.family<List<ChapterModel>, String>(
        (ref, subjectId) async {
      if (subjectId.isEmpty) return [];
      final service = ref.watch(chapterServiceProvider);
      return service.fetchChaptersBySubject(subjectId);
    });

final currentFacultyIdProvider = Provider.autoDispose<String?>((ref) {
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

    if (row == null) {
      debugPrint('No faculty row found for auth user: $authId');
      return null;
    }

    return row['id'] as String?;
  } catch (e) {
    debugPrint('Error in currentFacultyIdProvider: $e');
    return null;
  }
});

final recentFacultyUploadsProvider =
FutureProvider.autoDispose.family<List<FacultyUploadModel>, int?>(
    (ref, limit) async {
  final facultyId = ref.watch(currentFacultyIdProvider);
  if (facultyId == null) return [];

  final service = ref.watch(facultyUploadServiceProvider);
  final uploads = await service.fetchRecentUploads(facultyId);
  return limit != null ? uploads.take(limit).toList() : uploads;
});

final facultyProfileProvider = FutureProvider.autoDispose<FacultyModel?>((ref) async {
  final facultyId = ref.watch(currentFacultyIdProvider);
  if (facultyId == null) return null;

  final service = ref.watch(facultyServiceProvider);
  return service.fetchProfile(facultyId);
});

final facultyStatsProvider =
FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final facultyId = ref.watch(currentFacultyIdProvider);
  if (facultyId == null) {
    return {'videos': 0, 'materials': 0, 'total_uploads': 0, 'students': 0};
  }

  final service = ref.watch(facultyServiceProvider);
  return service.fetchFacultyStats(facultyId);
});

final contentViewCountsProvider =
    FutureProvider.autoDispose.family<Map<String, int>, String>((ref, facultyId) async {
  final service = ref.watch(facultyServiceProvider);
  return service.fetchContentViewCounts(facultyId);
});

final timetableProvider =
FutureProvider.autoDispose.family<List<TimetableModel>, String>(
        (ref, dayOfWeek) async {
      final facultyId = ref.watch(currentFacultyIdProvider);
      if (facultyId == null) return [];

      final service = ref.watch(timetableServiceProvider);
      return service.fetchScheduleByDay(facultyId, dayOfWeek);
    });

final facultyScheduleProvider =
FutureProvider.autoDispose<List<TimetableModel>>((ref) async {
  final facultyId = ref.watch(currentFacultyIdProvide);
  if (facultyId == null) return [];

  final service = ref.watch(timetableServiceProvider);
  return service.fetchFacultySchedule(facultyId);
});