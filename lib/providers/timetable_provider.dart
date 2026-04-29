import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/timetable_service.dart';

final timetableServiceProvider = Provider<TimetableService>((ref) {
  return TimetableService(Supabase.instance.client);
});
