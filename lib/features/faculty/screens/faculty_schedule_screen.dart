import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/faculty_providers.dart';
import '../../../models/timetable_model.dart';

class FacultyScheduleScreen extends ConsumerStatefulWidget {
  const FacultyScheduleScreen({super.key});

  @override
  ConsumerState<FacultyScheduleScreen> createState() => _FacultyScheduleScreenState();
}

class _FacultyScheduleScreenState extends ConsumerState<FacultyScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEEE').format(_selectedDate);
    final timetableAsync = ref.watch(timetableProvider(dayName));
    final profileAsync = ref.watch(facultyProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSessionInfo(),
        backgroundColor: const Color(0xFF5B4FCF),
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(timetableProvider(dayName)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Notification Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF5B4FCF).withOpacity(0.1),
                          child: const Icon(Icons.person, color: Color(0xFF5B4FCF), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Faculty Schedule', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            profileAsync.when(
                              data: (profile) => Text(
                                profile?.name ?? 'Professor',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              loading: () => const SizedBox(height: 16, width: 60, child: LinearProgressIndicator()),
                              error: (_, __) => const Text('Professor'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildNotificationButton(context),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Calendar Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF5B4FCF), size: 20),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Improved Date Strip
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _getWeekDays().map((date) {
                      final isSelected = DateFormat('yyyy-MM-dd').format(date) == 
                                        DateFormat('yyyy-MM-dd').format(_selectedDate);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = date),
                        child: _buildDatePill(
                          DateFormat('EEE').format(date),
                          DateFormat('d').format(date),
                          isSelected,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // Dynamic Timetable Content
                timetableAsync.when(
                  data: (sessions) {
                    if (sessions.isEmpty) return _buildEmptyState();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today\'s Lectures',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        ...sessions.map((s) => _buildSessionCard(s)),
                      ],
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                  error: (e, __) => Center(child: Text('Error: $e')),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No new schedule alerts.')),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF5B4FCF), size: 22),
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }

  List<DateTime> _getWeekDays() {
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => firstDayOfWeek.add(Duration(days: index)));
  }

  Widget _buildDatePill(String day, String date, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: isActive 
          ? const LinearGradient(
              colors: [Color(0xFF5B4FCF), Color(0xFF7E72ED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
        color: isActive ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive ? [
          BoxShadow(color: const Color(0xFF5B4FCF).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
        ] : null,
        border: isActive ? null : Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              color: isActive ? Colors.white70 : Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(TimetableModel session) {
    final sessionColor = _getColorForType(session.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sessionColor.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: sessionColor.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sessionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getIconForType(session.type), color: sessionColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.subjectName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.startTime} - ${session.endTime}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sessionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.type.toUpperCase(),
                  style: TextStyle(color: sessionColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          if (session.room != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF1F1F1)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.room_outlined, size: 16, color: sessionColor.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Text(
                    'Classroom: ${session.room}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 4, spreadRadius: 1),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE SOON',
                    style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'meeting': return const Color(0xFF5B4FCF); // Purple
      case 'lab': return const Color(0xFF1E8C6E); // Green
      case 'mentorship': return const Color(0xFFE65100); // Orange
      default: return const Color(0xFF2196F3); // Blue
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'meeting': return Icons.groups_rounded;
      case 'lab': return Icons.science_rounded;
      case 'mentorship': return Icons.psychology_rounded;
      default: return Icons.school_rounded;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), shape: BoxShape.circle),
            child: Icon(Icons.event_note_rounded, size: 48, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Lectures Scheduled',
            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy your free time or prepare for upcoming sessions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showAddSessionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Timetable Management'),
        content: const Text(
          'Academic schedules are managed by the administration to prevent room conflicts. '
          '\n\nPlease reach out to the coordinator for any adjustments.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: Color(0xFF5B4FCF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
