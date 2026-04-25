import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timetable_model.dart';

class TimetableService {
  final SupabaseClient _client;
  TimetableService(this._client);

  Future<List<TimetableModel>> fetchFacultySchedule(String facultyId) async {
    try {
      final response = await _client
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
}
