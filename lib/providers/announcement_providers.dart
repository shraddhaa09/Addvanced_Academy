import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import 'faculty_providers.dart';
import 'auth_provider.dart';

final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  return AnnouncementService(Supabase.instance.client);
});

final facultyAnnouncementsProvider =
    FutureProvider.autoDispose<List<AnnouncementModel>>((ref) async {
  final facultyId = await ref.watch(currentFacultyIdProvider.future);
  if (facultyId == null) return [];
  
  final service = ref.watch(announcementServiceProvider);
  return service.fetchFacultyAnnouncements(facultyId);
});

final studentAnnouncementsProvider =
    FutureProvider.autoDispose<List<AnnouncementModel>>((ref) async {
  // We need the student's batch. We'll fetch it from the students table.
  final authState = ref.watch(authProvider);
  final authId = authState.userId;
  if (authId == null) return [];

  final client = Supabase.instance.client;
  
  // Get student info including batch
  final studentRow = await client
      .schema('academy')
      .from('students')
      .select('batch')
      .eq('id', (await client.schema('academy').from('users').select('id').eq('auth_id', authId).single())['id'])
      .maybeSingle();

  if (studentRow == null) return [];
  final batch = studentRow['batch'] as String;

  final service = ref.watch(announcementServiceProvider);
  return service.fetchStudentAnnouncements(batch);
});
