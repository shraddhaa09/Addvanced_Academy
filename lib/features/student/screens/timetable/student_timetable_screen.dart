import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final studentTimetableRepositoryProvider = Provider<StudentTimetableRepository>((ref) {
  return StudentTimetableRepository(Supabase.instance.client);
});

final selectedWeekProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return _startOfWeek(now);
});

final selectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final timetableForSelectedDayProvider = FutureProvider.autoDispose<List<TimetableEntry>>((ref) async {
  final repo = ref.watch(studentTimetableRepositoryProvider);
  final weekStart = ref.watch(selectedWeekProvider);
  final selectedDay = ref.watch(selectedDayProvider);
  return repo.fetchDaySchedule(weekStart: weekStart, selectedDay: selectedDay);
});

class StudentTimetableScreen extends ConsumerWidget {
  const StudentTimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedWeek = ref.watch(selectedWeekProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final timetableAsync = ref.watch(timetableForSelectedDayProvider);
    final visibleDays = List.generate(7, (index) => selectedWeek.add(Duration(days: index)));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: SafeArea(
        child: Column(
          children: [
            _TimetableAppBar(
              onBack: () => context.pop(),
              onCalendarTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDay,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2032),
                );
                if (picked == null) return;
                ref.read(selectedWeekProvider.notifier).state = _startOfWeek(picked);
                ref.read(selectedDayProvider.notifier).state = DateTime(picked.year, picked.month, picked.day);
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WeekSwitcherCard(
                      weekStart: selectedWeek,
                      onPrevious: () {
                        final previous = selectedWeek.subtract(const Duration(days: 7));
                        ref.read(selectedWeekProvider.notifier).state = previous;
                        final currentSelection = ref.read(selectedDayProvider);
                        ref.read(selectedDayProvider.notifier).state = previous.add(Duration(days: currentSelection.weekday - 1));
                      },
                      onNext: () {
                        final next = selectedWeek.add(const Duration(days: 7));
                        ref.read(selectedWeekProvider.notifier).state = next;
                        final currentSelection = ref.read(selectedDayProvider);
                        ref.read(selectedDayProvider.notifier).state = next.add(Duration(days: currentSelection.weekday - 1));
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 118,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final day = visibleDays[index];
                          final isSelected = _isSameDate(day, selectedDay);
                          return _DayChip(
                            date: day,
                            isSelected: isSelected,
                            onTap: () => ref.read(selectedDayProvider.notifier).state = day,
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemCount: visibleDays.length,
                      ),
                    ),
                    const SizedBox(height: 18),
                    timetableAsync.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const _EmptyTimetableState();
                        }
                        return _TimelineList(items: items);
                      },
                      loading: () => const _TimetableLoadingState(),
                      error: (error, stack) => _TimetableErrorState(message: error.toString()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _StudentBottomNav(currentIndex: 1),
    );
  }
}

class StudentTimetableRepository {
  StudentTimetableRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<TimetableEntry>> fetchDaySchedule({
    required DateTime weekStart,
    required DateTime selectedDay,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final studentRow = await _supabase.schema('academy').from('users').select('id, students(batch)').eq('authid', user.id).maybeSingle();
    if (studentRow == null) throw Exception('Student profile not found');

    final nestedStudent = studentRow['students'];
    final batch = nestedStudent is Map<String, dynamic> ? nestedStudent['batch'] as String? : null;
    if (batch == null || batch.isEmpty) throw Exception('Student batch not assigned');

    final response = await _supabase
        .schema('academy')
        .from('timetable')
        .select('id, weekstart, day, starttime, endtime, room, isrecurring, batch, subjects:subjectid(label), faculty:facultyid(name)')
        .eq('weekstart', DateFormat('yyyy-MM-dd').format(weekStart))
        .eq('day', _weekdayToEnum(selectedDay.weekday))
        .eq('batch', batch)
        .order('starttime');

    return (response as List<dynamic>).map((json) => TimetableEntry.fromMap(json as Map<String, dynamic>)).toList();
  }

  String _weekdayToEnum(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      case DateTime.sunday:
        return 'sun';
      default:
        throw Exception('Invalid weekday');
    }
  }
}

class TimetableEntry {
  TimetableEntry({required this.id, required this.subject, required this.facultyName, required this.room, required this.batch, required this.startTime, required this.endTime, required this.isRecurring});

  final String id;
  final String subject;
  final String facultyName;
  final String room;
  final String batch;
  final String startTime;
  final String endTime;
  final bool isRecurring;

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    final subjectMap = map['subjects'] as Map<String, dynamic>?;
    final facultyMap = map['faculty'] as Map<String, dynamic>?;
    return TimetableEntry(
      id: map['id'] as String,
      subject: (subjectMap?['label'] as String?) ?? 'Unknown Subject',
      facultyName: (facultyMap?['name'] as String?) ?? 'Faculty TBD',
      room: (map['room'] as String?) ?? 'Room TBA',
      batch: (map['batch'] as String?) ?? '-',
      startTime: (map['starttime'] as String?) ?? '08:00:00',
      endTime: (map['endtime'] as String?) ?? '09:00:00',
      isRecurring: (map['isrecurring'] as bool?) ?? false,
    );
  }

  String get formattedTimeRange => '${_formatTime(startTime)} - ${_formatTime(endTime)}';

  static String _formatTime(String raw) {
    final parts = raw.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('hh:mm a').format(dt);
  }
}

class _TimetableAppBar extends StatelessWidget {
  const _TimetableAppBar({required this.onBack, required this.onCalendarTap});
  final VoidCallback onBack;
  final VoidCallback onCalendarTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new_rounded), color: const Color(0xFF574CFF)),
          const SizedBox(width: 6),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('My Timetable', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF141414))),
              SizedBox(height: 2),
              Text('Current Week Schedule', style: TextStyle(fontSize: 14, color: Color(0xFF8B8EA3), fontWeight: FontWeight.w500)),
            ]),
          ),
          IconButton(onPressed: onCalendarTap, icon: const Icon(Icons.calendar_today_rounded), color: const Color(0xFF574CFF)),
        ],
      ),
    );
  }
}

class _WeekSwitcherCard extends StatelessWidget {
  const _WeekSwitcherCard({required this.weekStart, required this.onPrevious, required this.onNext});
  final DateTime weekStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final label = '${DateFormat('d MMM').format(weekStart)} - ${DateFormat('d MMM').format(weekEnd)}';
    return Container(
      height: 108,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 8))]),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(children: [
        _CircleIconButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
        Expanded(child: Center(child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))))),
        _CircleIconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ]),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.date, required this.isSelected, required this.onTap});
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? const Color(0xFF625BFF) : Colors.white;
    final fg = isSelected ? Colors.white : const Color(0xFF6F7183);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 84,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24), boxShadow: isSelected ? const [BoxShadow(color: Color(0x33625BFF), blurRadius: 20, offset: Offset(0, 10))] : const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 4))]),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(DateFormat('E').format(date), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
          const SizedBox(height: 10),
          Text(DateFormat('dd').format(date), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
        ]),
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.items});
  final List<TimetableEntry> items;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i == 2) children.add(const _LunchBreakBanner());
      children.add(_TimelineTile(entry: items[i], color: _tileAccent(i), isLast: i == items.length - 1));
      if (i != items.length - 1) children.add(const SizedBox(height: 18));
    }
    return Column(children: children);
  }

  Color _tileAccent(int index) {
    const palette = [Color(0xFF625BFF), Color(0xFF58D78D), Color(0xFF8E8AA8), Color(0xFFFFB25B), Color(0xFF69A9FF)];
    return palette[index % palette.length];
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry, required this.color, required this.isLast});
  final TimetableEntry entry;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 46,
          child: Column(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color.withOpacity(0.22), shape: BoxShape.circle),
              child: Center(child: Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.black.withOpacity(0.55), width: 2))))),
            if (!isLast) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 8), color: const Color(0xFFD7D9E4))),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 8))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(entry.formattedTimeRange, style: TextStyle(color: color.darken(), fontSize: 14, fontWeight: FontWeight.w800))),
              if (entry.isRecurring) Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(999)),
                child: Text('RECURRING', style: TextStyle(color: color.darken(), fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: 0.8)),
              ),
            ]),
            const SizedBox(height: 18),
            Text(entry.subject, style: const TextStyle(fontSize: 20, height: 1.25, fontWeight: FontWeight.w700, color: Color(0xFF17181C))),
            const SizedBox(height: 18),
            Row(children: [Expanded(child: _MetaChip(icon: Icons.person, label: entry.facultyName)), const SizedBox(width: 12), Expanded(child: _MetaChip(icon: Icons.meeting_room_rounded, label: entry.room))]),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFF0F1F5)),
            const SizedBox(height: 14),
            RichText(text: TextSpan(children: [
              const TextSpan(text: 'BATCH:  ', style: TextStyle(color: Color(0xFF8B8EA3), fontSize: 13, fontWeight: FontWeight.w600)),
              TextSpan(text: entry.batch, style: const TextStyle(color: Color(0xFF23252D), fontSize: 18, fontWeight: FontWeight.w700)),
            ])),
          ]),
        )),
      ]),
    );
  }
}

class _LunchBreakBanner extends StatelessWidget {
  const _LunchBreakBanner();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: const BoxDecoration(color: Color(0xFFFFB25B), shape: BoxShape.circle), child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0xFFD8D7DD))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('LUNCH BREAK • 1 HOUR', style: TextStyle(color: Color(0xFFB1804C), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2.1))),
        const Expanded(child: Divider(color: Color(0xFFD8D7DD))),
      ]),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 36, height: 36, decoration: const BoxDecoration(color: Color(0xFFF3F4F8), shape: BoxShape.circle), child: Icon(icon, size: 18, color: const Color(0xFF767A8D))),
      const SizedBox(width: 10),
      Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Color(0xFF4F5265), fontWeight: FontWeight.w500))),
    ]);
  }
}

class _StudentBottomNav extends StatelessWidget {
  const _StudentBottomNav({required this.currentIndex});
  final int currentIndex;
  @override
  Widget build(BuildContext context) {
    final items = const [
      _BottomNavItemData('Dashboard', Icons.grid_view_rounded),
      _BottomNavItemData('Timetable', Icons.calendar_month_rounded),
      _BottomNavItemData('Courses', Icons.school_rounded),
      _BottomNavItemData('Tasks', Icons.assignment_rounded),
      _BottomNavItemData('Profile', Icons.person_rounded),
    ];
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, -6))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == currentIndex;
          return Expanded(child: GestureDetector(
            onTap: () {
              switch (index) {
                case 0: context.go('/student/dashboard'); break;
                case 1: context.go('/student/timetable'); break;
                case 2: context.go('/student/courses'); break;
                case 3: context.go('/student/tasks'); break;
                case 4: context.go('/student/profile'); break;
              }
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: selected ? const Color(0xFFF0EEFF) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                child: Icon(item.icon, color: selected ? const Color(0xFF625BFF) : const Color(0xFF95A0B8), size: 26),
              ),
              const SizedBox(height: 6),
              Text(item.label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? const Color(0xFF625BFF) : const Color(0xFF95A0B8))),
            ]),
          ));
        })),
      ),
    );
  }
}

class _BottomNavItemData {
  const _BottomNavItemData(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(width: 44, height: 44, child: Icon(icon, color: const Color(0xFF7F8295), size: 28)),
    );
  }
}

class _EmptyTimetableState extends StatelessWidget {
  const _EmptyTimetableState();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: const Column(children: [
        Icon(Icons.event_busy_rounded, size: 44, color: Color(0xFF98A1B3)),
        SizedBox(height: 12),
        Text('No classes scheduled for this day.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF20232A))),
        SizedBox(height: 6),
        Text('Try another day or ask the admin to update the timetable.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF8D92A3))),
      ]),
    );
  }
}

class _TimetableLoadingState extends StatelessWidget {
  const _TimetableLoadingState();
  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator(color: Color(0xFF625BFF))));
  }
}

class _TimetableErrorState extends StatelessWidget {
  const _TimetableErrorState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        const Icon(Icons.error_outline_rounded, size: 42, color: Color(0xFFE36D6D)),
        const SizedBox(height: 12),
        const Text('Unable to load timetable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF20232A))),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF8D92A3))),
      ]),
    );
  }
}

DateTime _startOfWeek(DateTime date) => DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

extension TimetableColorX on Color {
  Color darken([double amount = .12]) {
    final hsl = HSLColor.fromColor(this);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }
}