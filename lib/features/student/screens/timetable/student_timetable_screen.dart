import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../models/timetable_model.dart';
import '../../../../providers/student_providers.dart';
import '../../../../core/widgets/empty_state.dart';

class StudentTimetableScreen extends ConsumerStatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  ConsumerState<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends ConsumerState<StudentTimetableScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(studentScheduleProvider);
    final dayName = DateFormat('EEEE').format(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          _SliverAppBar(
            selectedDate: _selectedDate,
            onDateSelected: (date) => setState(() => _selectedDate = date),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Text(
                    dayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(color: Color(0xFFD1D5DB), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM d, y').format(_selectedDate),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          scheduleAsync.when(
            data: (schedule) {
              final dailyLectures = schedule.where((item) => item.dayOfWeek == dayName).toList();
              
              if (dailyLectures.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: AppEmptyState(
                      title: 'No lectures scheduled',
                      message: 'Enjoy your day off! No classes found for this date.',
                      icon: Icons.event_busy_rounded,
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _LectureCard(lecture: dailyLectures[index]),
                    childCount: dailyLectures.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _SliverAppBar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _SliverAppBar({required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(color: Colors.white),
      ),
      title: const Text(
        'Class Schedule',
        style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w800, fontSize: 20),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            _WeekStrip(selectedDate: selectedDate, onDateSelected: onDateSelected),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          ],
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _WeekStrip({required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final date = monday.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          final isToday = DateUtils.isSameDay(date, now);

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF5B4FCF) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected ? Border.all(color: const Color(0xFF5B4FCF), width: 1.5) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date)[0],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LectureCard extends StatelessWidget {
  final TimetableModel lecture;
  const _LectureCard({required this.lecture});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF5B4FCF),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF5B4FCF).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            lecture.subjectName,
                            style: const TextStyle(color: Color(0xFF5B4FCF), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Text(
                              '${lecture.startTime} - ${lecture.endTime}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lecture.type,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.meeting_room_rounded, size: 14, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Text(
                          lecture.room ?? 'Room TBD',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
                          child: const Text(
                            'Active',
                            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
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
