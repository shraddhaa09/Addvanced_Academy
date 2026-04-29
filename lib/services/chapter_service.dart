import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chapter_model.dart';

class ChapterService {
  ChapterService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<ChapterModel>> fetchChaptersBySubject(String subjectId) async {
    final response = await _client
        .from('chapters')
        .select()
        .eq('subject_id', subjectId)
        .order('chapter_no');
    return (response as List).map((json) => ChapterModel.fromJson(json)).toList();
  }
}
