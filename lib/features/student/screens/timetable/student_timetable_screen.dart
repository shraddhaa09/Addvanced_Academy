import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/faculty_providers.dart';
import '../../../../models/timetable_model.dart';

class StudentTimetableScreen extends ConsumerStatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  ConsumerState<StudentTimetableScreen> createState() =>
      _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends ConsumerState<StudentTimetableScreen> {
  bool _loading = true;
  List<TimetableModel> _items = [];

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  DateTime _getMonday(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: diff));
  }

  Future<void> _loadTimetable() async {
    const String studentBatch = 'CET-2026'; // replace later with auth/provider value
    final weekStart = _getMonday(DateTime.now());

    final data = await ref.read(timetableServiceProvider).fetchStudentTimetable(
          batch: studentBatch,
          weekStart: weekStart,
        );

    if (!mounted) return;

    setState(() {
      _items = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text('No timetable found for this week.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.subjectName),
                        subtitle: Text(
                          '${item.dayOfWeek} • ${item.startTime} - ${item.endTime}'
                          '${item.room != null && item.room!.isNotEmpty ? ' • Room ${item.room}' : ''}',
                        ),
                        trailing: Text(item.type),
                      ),
                    );
                  },
                ),
    );
  }
}
