import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subject_model.dart';

class SubjectService {
  SubjectService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<SubjectModel>> fetchSubjects() async {
    final response = await _client
        .from('subjects')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((item) => SubjectModel.fromJson(item))
        .toList();
  }
}
