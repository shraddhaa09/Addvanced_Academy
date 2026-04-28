import 'dart:typed_data';
import 'dart:io' as io;
import 'package:supabase_flutter/supabase_flutter.dart';

class MaterialService {
  final SupabaseClient _client;
  MaterialService(this._client);

  Future<String> uploadMaterialFile({
    required dynamic file, // Uint8List or io.File
    required String fileName,
    required String facultyId,
    required String subjectId,
    required String chapterId,
  }) async {
    final path =
        'materials/$facultyId/$subjectId/$chapterId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    try {
      if (file is Uint8List) {
        await _client.storage.from('study-materials').uploadBinary(
          path,
          file,
          fileOptions: const FileOptions(upsert: false),
        );
      } else if (file is io.File) {
        await _client.storage.from('study-materials').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: false),
        );
      } else {
        throw Exception('Unsupported file type: ${file.runtimeType}');
      }
      return path;
    } on StorageException catch (e) {
      throw Exception('Storage upload failed: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected upload error: $e');
    }
  }

  Future<Map<String, dynamic>> createStudyMaterial({
    required String facultyId,
    required String subjectId,
    required String chapterId,
    required String title,
    required String storagePath,
    String? description,
    required String materialType,
    required bool isVisible,
    int? fileSizeKb,
  }) async {
    final payload = {
      'faculty_id': facultyId,
      'subject_id': subjectId,
      'chapter_id': chapterId,
      'title': title,
      'storage_path': storagePath,
      'description': description,
      'material_type': materialType,
      'is_visible': isVisible,
      'file_size_kb': fileSizeKb,
    };

    try {
      final response = await _client
          .schema('academy')
          .from('study_materials')
          .insert(payload)
          .select()
          .single();

      return Map<String, dynamic>.from(response as Map);
    } on PostgrestException catch (e) {
      throw Exception('Database Error: ${e.message} (Code: ${e.code})');
    } catch (e) {
      throw Exception('Unexpected Database Error: $e');
    }
  }
}