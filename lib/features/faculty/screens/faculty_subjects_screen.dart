import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/faculty_providers.dart';
import '../../../models/timetable_model.dart';

// ---------------------------------------------------------------------------
// Helpers — extract to core/utils/faculty_ui_helpers.dart to share across screens
// ---------------------------------------------------------------------------

Color _subjectColor(String? subject) {
  switch (subject?.toLowerCase()) {
    case 'physics':
      return const Color(0xFF1565C0);
    case 'chemistry':
      return const Color(0xFF2E7D32);
    case 'maths':
      return const Color(0xFFE65100);
    case 'biology':
      return const Color(0xFF6A1B9A);
    default:
      return const Color(0xFF5B4FCF);
  }
}

IconData _subjectIcon(String? subject) {
  switch (subject?.toLowerCase()) {
    case 'physics':
      return Icons.science_outlined;
    case 'chemistry':
      return Icons.biotech_outlined;
    case 'maths':
      return Icons.calculate_outlined;
    case 'biology':
      return Icons.eco_outlined;
    default:
      return Icons.menu_book_rounded;
  }
}

// ---------------------------------------------------------------------------
// Demo batch data — replace with a real Supabase provider when batches are live
// ---------------------------------------------------------------------------

class _BatchData {
  _BatchData({
    required this.name,
    required this.time,
    required this.days,
    required this.color,
  });

  final String name;
  final String time;
  final String days;
  final Color color;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class FacultySubjectsScreen extends ConsumerWidget {
  const FacultySubjectsScreen({super.key});

  List<_BatchData> _groupScheduleIntoBatches(List<TimetableModel> schedule) {
    // Group by subject and time slots
    final grouped = <String, List<TimetableModel>>{};
    for (final item in schedule) {
      final key = '${item.subjectName}_${item.startTime}_${item.endTime}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped.entries.map((entry) {
      final items = entry.value;
      final first = items.first;
      final days = items.map((i) => i.dayOfWeek.substring(0, 3)).join(', ');
      return _BatchData(
        name: '${first.subjectName} Batch',
        time: '${first.startTime} – ${first.endTime}',
        days: days,
        color: _subjectColor(first.subjectName),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(facultyProfileProvider);
    final scheduleAsync = ref.watch(facultyScheduleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'My Subjects',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => scheduleAsync.when(
            data: (schedule) {
              if (profile == null) {
                return const _ErrorState(message: 'Profile not found.');
              }

              final subject = profile.subject as String?;
              final subjectColor = _subjectColor(subject);
              final batches = _groupScheduleIntoBatches(schedule);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Specialization ─────────────────────────────────────
                    const _SectionHeader(title: 'Your Specialization'),
                    const SizedBox(height: 14),

                    _SubjectCard(
                      subject: subject ?? 'Not assigned',
                      color: subjectColor,
                    ),
                    const SizedBox(height: 32),

                    // ── Assigned Batches ───────────────────────────────────
                    const _SectionHeader(title: 'Assigned Batches'),
                    const SizedBox(height: 14),

                    if (batches.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF0F0F0)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No batches assigned',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    else
                      ...batches.map((batch) => _BatchTile(batch: batch)),
                    const SizedBox(height: 32),

                    // ── Admin note ─────────────────────────────────────────
                    const _AdminNote(
                      message:
                      'Your subject specialization and batch allocations are '
                          'managed by the academic coordinator. To request a batch '
                          'change or report a discrepancy, please contact the admin office.',
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
            loading: () => const _LoadingSkeleton(),
            error: (e, _) => _ErrorState(message: 'Could not load schedule.\n$e'),
          ),
          loading: () => const _LoadingSkeleton(),
          error: (e, _) => _ErrorState(message: 'Could not load profile.\n$e'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Accent-bar section header — consistent with other faculty screens.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF5B4FCF),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// Subject specialization card — color-coded by subject.
class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.color,
  });

  final String subject;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Subject icon badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withAlpha(22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _subjectIcon(subject),
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Primary Specialization',
                  style: TextStyle(color: Colors.black45, fontSize: 13),
                ),
              ],
            ),
          ),
          // Subject color accent pill on the right
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Active',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Batch tile — each batch carries its own [_BatchData.color].
class _BatchTile extends StatelessWidget {
  const _BatchTile({required this.batch});

  final _BatchData batch;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch color icon badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: batch.color.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.people_alt_outlined,
                color: batch.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.access_time_outlined,
                    label: batch.time,
                    color: batch.color,
                  ),
                  const SizedBox(height: 4),
                  _InfoRow(
                    icon: Icons.calendar_month_outlined,
                    label: batch.days,
                    color: batch.color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon + label row used inside batch tiles.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color.withAlpha(160)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}

/// Admin note — consistent with other faculty screens.
class _AdminNote extends StatelessWidget {
  const _AdminNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5B4FCF).withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5B4FCF).withAlpha(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF5B4FCF), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF5B4FCF),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 160, height: 16, borderRadius: 8),
          const SizedBox(height: 14),
          _ShimmerBox(width: double.infinity, height: 96, borderRadius: 20),
          const SizedBox(height: 32),
          _ShimmerBox(width: 140, height: 16, borderRadius: 8),
          const SizedBox(height: 14),
          ...List.generate(
            2,
                (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShimmerBox(
                width: double.infinity,
                height: 88,
                borderRadius: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer box — extract to core/widgets/shimmer_box.dart
// ---------------------------------------------------------------------------

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
      ),
    );
  }
}