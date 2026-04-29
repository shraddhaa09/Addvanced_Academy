import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/timetable_model.dart';
import '../../../providers/faculty_providers.dart';

class FacultyScheduleScreen extends ConsumerStatefulWidget {
  const FacultyScheduleScreen({super.key});

  @override
  ConsumerState<FacultyScheduleScreen> createState() =>
      _FacultyScheduleScreenState();
}

class _FacultyScheduleScreenState extends ConsumerState<FacultyScheduleScreen> {
  static const _primary = Color(0xFF5B4FCF);

  DateTime _selectedDate = _stripTime(DateTime.now());

  static DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  List<DateTime> _weekDays(DateTime anchor) {
    final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEEE').format(_selectedDate);
    final timetableAsync = ref.watch(timetableProvider(dayName));
    final week = _weekDays(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const _ScheduleAppBar(),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: () async => ref.invalidate(timetableProvider(dayName)),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _MonthHeader(
                selectedDate: _selectedDate,
                onDatePicked: (picked) =>
                    setState(() => _selectedDate = _stripTime(picked)),
              ),
            ),
            SliverToBoxAdapter(
              child: _WeekStrip(
                week: week,
                selectedDate: _selectedDate,
                onDayTap: (date) =>
                    setState(() => _selectedDate = _stripTime(date)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: _DayLabel(date: _selectedDate),
              ),
            ),
            timetableAsync.when(
              data: (sessions) => sessions.isEmpty
                  ? SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: _EmptyState(),
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SessionCard(session: sessions[i]),
                    ),
                    childCount: sessions.length,
                  ),
                ),
              ),
              loading: () => SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _SessionSkeleton(),
                    ),
                    childCount: 3,
                  ),
                ),
              ),
              error: (_, __) => SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  onRetry: () => ref.invalidate(timetableProvider(dayName)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ScheduleAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const Text(
        'My Schedule',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
          letterSpacing: -0.3,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDatePicked;

  const _MonthHeader({
    required this.selectedDate,
    required this.onDatePicked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(selectedDate),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.4,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF5B4FCF),
              size: 20,
            ),
            tooltip: 'Pick a date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 60)),
                lastDate: DateTime.now().add(const Duration(days: 60)),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF5B4FCF),
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) onDatePicked(picked);
            },
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final List<DateTime> week;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDayTap;

  const _WeekStrip({
    required this.week,
    required this.selectedDate,
    required this.onDayTap,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        physics: const BouncingScrollPhysics(),
        itemCount: week.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final date = week[i];
          final selected = _isSameDay(date, selectedDate);
          final today = _isToday(date);

          return GestureDetector(
            onTap: () => onDayTap(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 54,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                  colors: [Color(0xFF5B4FCF), Color(0xFF7C6FE0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : today
                      ? const Color(0xFF5B4FCF).withOpacity(0.4)
                      : const Color(0xFFEEEEEE),
                ),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: const Color(0xFF5B4FCF).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).substring(0, 2),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white70 : const Color(0xFF9CA3AF),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? Colors.white
                          : today
                          ? const Color(0xFF5B4FCF)
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final DateTime date;

  const _DayLabel({required this.date});

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(date);
    return Row(
      children: [
        Text(
          isToday ? "Today's Lectures" : "${DateFormat('EEEE').format(date)}'s Lectures",
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.2,
          ),
        ),
        if (isToday) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEEECFD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Today',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5B4FCF),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final TimetableModel session;

  const _SessionCard({required this.session});

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'lecture':
        return const Color(0xFF5B4FCF);
      case 'lab':
        return const Color(0xFF1D9E75);
      case 'tutorial':
        return const Color(0xFFBA7517);
      default:
        return const Color(0xFF2196F3);
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'lecture':
        return Icons.menu_book_rounded;
      case 'lab':
        return Icons.science_rounded;
      case 'tutorial':
        return Icons.quiz_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(session.type);
    final roomText = (session.room != null && session.room!.trim().isNotEmpty)
        ? session.room!.trim()
        : 'Room not set';
    final timeText = '${session.startTime} - ${session.endTime}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _typeIcon(session.type),
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.subjectName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            session.type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.room_rounded, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          roomText,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionSkeleton extends StatelessWidget {
  const _SessionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEEECFD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Color(0xFF5B4FCF),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No lectures scheduled',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your timetable for this day will\nappear here once set by Admin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFFB0B0B0)),
            const SizedBox(height: 12),
            const Text(
              'Could not load schedule',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF5B4FCF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Color(0xFF5B4FCF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}