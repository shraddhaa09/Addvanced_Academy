import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';

class StudentService {
  StudentService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<StudentModel?> fetchProfile(String studentId) async {
    try {
      final response = await _client
          .schema('academy')
          .from('students')
          .select()
          .eq('id', studentId)
          .single();

      return StudentModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile({
    required String studentId,
    required String name,
    String? rollNo,
  }) async {
    await _client
        .schema('academy')
        .from('students')
        .update({
          'name': name,
          'roll_no': rollNo,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', studentId);
  }

  Future<Map<String, dynamic>> fetchStudentStats(String studentId) async {
    try {
      // Fetch number of tests attempted
      final testsResponse = await _client
          .schema('academy')
          .from('test_attempts')
          .select('id')
          .eq('student_id', studentId);
      
      // Fetch content views (materials read)
      final viewsResponse = await _client
          .schema('academy')
          .from('content_views')
          .select('id')
          .eq('user_id', studentId);

      return {
        'tests_taken': testsResponse.length,
        'materials_read': viewsResponse.length,
        'attendance': '92%', // Placeholder for now
      };
    } catch (e) {
      return {
        'tests_taken': 0,
        'materials_read': 0,
        'attendance': '0%',
      };
    }
  }
}
