import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/faculty_model.dart';

class FacultyService {
  final SupabaseClient _client;

  FacultyService(this._client);

  Future<FacultyModel?> fetchProfile(String userId) async {
    try {
      final response = await _client
          .schema('academy')
          .from('faculty')
          .select()
          .eq('id', userId)
          .single();

      return FacultyModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchFacultyStats(String facultyId) async {
    try {

      final videoResponse = await _client
          .schema('academy')
          .from('video_lectures')
          .select('id')
          .eq('faculty_id', facultyId)
          .count(CountOption.exact);

      final materialResponse = await _client
          .schema('academy')
          .from('study_materials')
          .select('id')
          .eq('faculty_id', facultyId)
          .count(CountOption.exact);

      final videoCount = videoResponse.count ?? 0;
      final materialCount = materialResponse.count ?? 0;

      return {
        'videos': videoCount,
        'materials': materialCount,
        'total_uploads': videoCount + materialCount,
        'students': 0, // placeholder (needs student relation table)
      };
    } catch (e) {
      return {
        'videos': 0,
        'materials': 0,
        'total_uploads': 0,
        'students': 0,
      };
    }
  }
}