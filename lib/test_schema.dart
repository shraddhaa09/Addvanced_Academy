import 'package:supabase_flutter/supabase_flutter.dart';

void test() async {
  await Supabase.initialize(
    url: 'test',
    anonKey: 'test',
    postgrestOptions: const PostgrestClientOptions(schema: 'academy'),
  );
}
