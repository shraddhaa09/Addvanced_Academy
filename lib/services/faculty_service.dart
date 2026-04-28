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

  Future<void> updateProfile({
    required String name,
    required String qualification,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .schema('academy')
        .from('faculty')
        .update({
          'name': name,
          'qualification': qualification,
        })
        .eq('id', userId);
  }

  Future<Map<String, int>> fetchContentViewCounts(String facultyId) async {
  final videoIdsResponse = await _client
      .schema('academy')
      .from('video_lectures')
      .select('id')
      .eq('faculty_id', facultyId);

  final materialIdsResponse = await _client
      .schema('academy')
      .from('study_materials')
      .select('id')
      .eq('faculty_id', facultyId);

  final videoIds = (videoIdsResponse as List)
      .map((row) => row['id'] as String)
      .toList();

  final materialIds = (materialIdsResponse as List)
      .map((row) => row['id'] as String)
      .toList();

  final counts = <String, int>{};

  if (videoIds.isNotEmpty) {
    final videoViews = await _client
        .schema('academy')
        .from('content_views')
        .select('content_id')
        .eq('content_type', 'video')
        .inFilter('content_id', videoIds);

    for (final row in videoViews as List) {
      final id = row['content_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }

  if (materialIds.isNotEmpty) {
    final materialViews = await _client
        .schema('academy')
        .from('content_views')
        .select('content_id')
        .eq('content_type', 'material')
        .inFilter('content_id', materialIds);

    for (final row in materialViews as List) {
      final id = row['content_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }

  return counts;
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