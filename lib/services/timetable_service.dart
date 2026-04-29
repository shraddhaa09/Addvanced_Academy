import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timetable_model.dart';

class TimetableService {
  TimetableService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<TimetableModel>> fetchFacultySchedule(String facultyId) async {
    try {
      final response = await _client
          .schema('academy')
          .from('timetable')
          .select('*, subjects!subject_id(name)')   // join subject name
          .eq('faculty_id', facultyId)
          .order('start_time');

      return (response as List).map((json) => TimetableModel.fromJson(json)).toList();
    } catch (e, st) {
      debugPrint('[TimetableService.fetchFacultySchedule] ERROR: $e\n$st');
      return [];
    }
  }

  Future<List<TimetableModel>> fetchScheduleByDay(String facultyId, String dayOfWeek) async {
    debugPrint('[TimetableService] fetchScheduleByDay → facultyId=$facultyId  day=$dayOfWeek');
    try {
      final response = await _client
          .schema('academy')
          .from('timetable')
          .select('*, subjects!subject_id(name)')   // join subject name
          .eq('faculty_id', facultyId)
          .eq('day', dayOfWeek)
          .order('start_time');

      debugPrint('[TimetableService] rows returned: ${(response as List).length}');
      return (response as List).map((json) => TimetableModel.fromJson(json)).toList();
    } catch (e, st) {
      debugPrint('[TimetableService.fetchScheduleByDay] ERROR: $e\n$st');
      rethrow; // let the provider surface the error so the UI shows Retry
    }
  }

  Future<List<TimetableModel>> fetchStudentTimetable({
    required String batch,
    required DateTime weekStart,
  }) async {
    try {
      final endOfWeek = weekStart.add(const Duration(days: 6));

      final response = await _client
          .schema('academy')
          .from('timetable')
          .select()
          .eq('batch', batch)
          .gte('week_start_date', weekStart.toIso8601String())
          .lte('week_start_date', endOfWeek.toIso8601String())
          .order('day_of_week')
          .order('start_time');

      return (response as List)
          .map((json) => TimetableModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<TimetableModel>> fetchTimetableByBatch(String batch) async {
    try {
      final response = await _client
          .schema('academy')
          .from('timetable')
          .select()
          .eq('batch', batch)
          .order('day_of_week')
          .order('start_time');

      return (response as List)
          .map((json) => TimetableModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }
}