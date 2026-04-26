import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/faculty_providers.dart';

// ---------------------------------------------------------------------------
// Helpers — keep in sync with other faculty screens or extract to
// core/utils/faculty_ui_helpers.dart
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

String _initials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class FacultyPersonalDetailsScreen extends ConsumerWidget {
  const FacultyPersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(facultyProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Personal Details',
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
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const _ErrorState(message: 'Profile not found.');
          }

          final subjectColor = _subjectColor(profile.subject as String?);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar + name hero ──────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      // Initials avatar — subject-color coded
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: subjectColor.withAlpha(30),
                        child: Text(
                          _initials(profile.name),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: subjectColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Qualification badge
                      if (profile.qualification != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E8C6E).withAlpha(22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            profile.qualification!,
                            style: const TextStyle(
                              color: Color(0xFF1E8C6E),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Text(
                          'Faculty Member',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Subject pill — color-coded
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: subjectColor.withAlpha(22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          profile.subject ?? 'Faculty',
                          style: TextStyle(
                            color: subjectColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // ── Account Information ────────────────────────────────
                const _SectionHeader(title: 'Account Information'),
                const SizedBox(height: 12),

                _DetailTile(
                  icon: Icons.badge_outlined,
                  label: 'Full Name',
                  value: profile.name,
                  accentColor: const Color(0xFF5B4FCF),
                ),
                _DetailTile(
                  icon: Icons.phone_android_outlined,
                  label: 'Mobile Number',
                  value: '+91 ${profile.mobile}',
                  accentColor: const Color(0xFF1E8C6E),
                ),
                _DetailTile(
                  icon: Icons.school_outlined,
                  label: 'Qualification',
                  value: profile.qualification ?? 'Not provided',
                  accentColor: const Color(0xFF1565C0),
                ),
                _DetailTile(
                  icon: Icons.menu_book_outlined,
                  label: 'Primary Subject',
                  value: profile.subject ?? 'Not assigned',
                  accentColor: subjectColor,
                  // Subject value gets its own color tint
                  valueColor: subjectColor,
                ),
                const SizedBox(height: 24),

                // ── Membership ─────────────────────────────────────────
                const _SectionHeader(title: 'Membership'),
                const SizedBox(height: 12),

                _DetailTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Joined Academy',
                  value: DateFormat('MMMM dd, yyyy').format(profile.createdAt),
                  accentColor: const Color(0xFFE65100),
                ),
                const SizedBox(height: 28),

                // ── Admin note ─────────────────────────────────────────
                _AdminNote(
                  message:
                  'To update your personal details or contact information, '
                      'please reach out to the academy administration office.',
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const _LoadingSkeleton(),
        error: (e, _) => _ErrorState(message: 'Could not load profile.\n$e'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Subtle section header with a left accent bar.
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

/// Individual field tile. Each tile carries its own [accentColor] for the
/// icon container, keeping the list visually differentiated.
class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  /// Optional override for the value text color (e.g. subject tile).
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon badge — each has its own accent color
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Admin-contact info note at the bottom of the screen.
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
        children: [
          // Avatar shimmer
          Center(
            child: Column(
              children: [
                _ShimmerBox(width: 104, height: 104, borderRadius: 52),
                const SizedBox(height: 16),
                _ShimmerBox(width: 160, height: 18, borderRadius: 8),
                const SizedBox(height: 8),
                _ShimmerBox(width: 100, height: 14, borderRadius: 8),
              ],
            ),
          ),
          const SizedBox(height: 36),
          // Tiles shimmer
          ...List.generate(
            5,
                (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ShimmerBox(
                width: double.infinity,
                height: 68,
                borderRadius: 14,
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
// Shimmer box — extract to shared widgets file to avoid duplication
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