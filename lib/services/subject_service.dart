import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subject_model.dart';

class SubjectService {
  final SupabaseClient _client;
  SubjectService(this._client);

  Future<List<SubjectModel>> fetchSubjects() async {
    final response = await _client.from('subjects').select().order('name');
    return (response as List).map((json) => SubjectModel.fromJson(json)).toList();
  }
}
