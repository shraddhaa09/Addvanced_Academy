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
          .select()
          .eq('faculty_id', facultyId)
          .order('start_time');

      return (response as List).map((json) => TimetableModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<TimetableModel>> fetchScheduleByDay(String facultyId, String dayOfWeek) async {
    try {
      final response = await _client
          .schema('academy')
          .from('timetable')
          .select()
          .eq('faculty_id', facultyId)
          .eq('day_of_week', dayOfWeek)
          .order('start_time');

      return (response as List).map((json) => TimetableModel.fromJson(json)).toList();
    } catch (e) {
      return [];
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