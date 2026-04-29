import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timetable_model.dart';

class TimetableService {
  final SupabaseClient _client;
  TimetableService(this._client);

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
}
