import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subject_model.dart';

class SubjectService {
  SubjectService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<SubjectModel>> fetchSubjects() async {
    final response = await _client
        .schema('academy')
        .from('subjects')
        .select('id, name, label, created_at')
        .order('name');

    return (response as List<dynamic>)
        .map((json) => SubjectModel.fromJson(
      Map<String, dynamic>.from(json as Map),
    ))
        .toList();
  }
}