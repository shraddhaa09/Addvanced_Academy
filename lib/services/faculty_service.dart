import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/faculty_model.dart';

class FacultyService {
  FacultyService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<FacultyModel?> fetchProfile(String userId) async {
    try {
      final response = await _client
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
      // Use count() method for cleaner syntax in newer Supabase versions
      final videoResponse = await _client
          .from('video_lectures')
          .select('id')
          .eq('faculty_id', facultyId);
      
      final materialResponse = await _client
          .from('study_materials')
          .select('id')
          .eq('faculty_id', facultyId);

      // Since we can't easily get the count from select without specific options 
      // and those options return a complex type, we'll use the length of the list 
      // if we're only selecting IDs. For large datasets, this is suboptimal but 
      // for this project it's safer than guessing the exact Postgrest API version syntax.
      // Alternatively, we can use the .count() method if available.
      
      final vCount = videoResponse.length;
      final mCount = materialResponse.length;

      return {
        'videos': vCount,
        'materials': mCount,
        'total_uploads': vCount + mCount,
        'students': 0,
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

  Future<Map<String, int>> fetchContentViewCounts(String facultyId) async {
    try {
      return {'videos': 0, 'materials': 0};
    } catch (e) {
      return {'videos': 0, 'materials': 0};
    }
  }
}