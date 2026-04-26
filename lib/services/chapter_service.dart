import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chapter_model.dart';

class ChapterService {
  final SupabaseClient _client;
  ChapterService(this._client);

  Future<List<ChapterModel>> fetchChaptersBySubject(String subjectId) async {
    try {
      final response = await _client
          .schema('academy')
          .from('chapters')
          .select('id, subject_id, name, chapter_no, created_at')
          .eq('subject_id', subjectId)
          .order('chapter_no');

      if (response is! List) {
        throw Exception('Unexpected response format: Expected a list but got ${response.runtimeType}');
      }

      return response
          .map((json) => ChapterModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch chapters: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while fetching chapters: $e');
    }
  }
}