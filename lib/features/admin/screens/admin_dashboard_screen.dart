import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/route_constants.dart';

// ─────────────────────────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────────────────────────

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final supabase = Supabase.instance.client;

  // FIX: In Supabase v2, count is handled differently.
  // We use the 'count' parameter in select() and access it from the 'PostgrestResponse'.
  final results = await Future.wait([
    supabase.from('students').select('*').count(CountOption.exact),
    supabase.from('faculty').select('*').count(CountOption.exact),
    supabase.from('tests').select('*').count(CountOption.exact),
  ]);

  return AdminStats(
    studentCount: results[0].count,
    facultyCount: results[1].count,
    testCount: results[2].count,
  );
});

final onlineFacultyProvider = FutureProvider<List<FacultyAvatar>>((ref) async {
  final supabase = Supabase.instance.client;
  // .select() returns a PostgrestList which is a List<Map<String, dynamic>>
  final List<dynamic> data = await supabase.from('faculty').select('id, name').limit(14);

  return data
      .map((e) => FacultyAvatar(
    id: e['id'] as String,
    name: e['name'] as String,
  ))
      .toList();
});

// ─────────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────────

class AdminStats {
  final int studentCount;
  final int facultyCount;
  final int testCount;

  const AdminStats({
    required this.studentCount,
    required this.facultyCount,
    required this.testCount,
  });
}

class FacultyAvatar {
  final String id;
  final String name;

  const FacultyAvatar({required this.id, required this.name});
}

// ─────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final facultyAsync = ref.watch(onlineFacultyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(adminStatsProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(),
                const SizedBox(height: 24),
                statsAsync.when(
                  loading: () => _StatsRowSkeleton(),
                  error: (e, _) => _StatsRowError(error: e.toString()),
                  data: (stats) => _StatsRow(stats: stats),
                ),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Core Modules',
                ),
                const SizedBox(height: 16),
                _CoreModulesGrid(),
                const SizedBox(height: 24),
                facultyAsync.when(
                  loading: () => const _AcademyStatusBanner(facultyAvatars: []),
                  error: (_, __) => const _AcademyStatusBanner(facultyAvatars: []),
                  data: (list) => _AcademyStatusBanner(facultyAvatars: list),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade300,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/admin_avatar.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF3D3D8F),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage Academy Operations',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(
            Icons.logout_rounded,
            color: Color(0xFF4F46E5),
            size: 26,
          ),
          tooltip: 'Logout',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STATS ROW
// ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final AdminStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_alt_rounded,
            iconBg: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF6D28D9),
            value: _formatNumber(stats.studentCount),
            label: 'Students',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.school_rounded,
            iconBg: const Color(0xFFD1FAE5),
            iconColor: const Color(0xFF059669),
            value: _formatNumber(stats.facultyCount),
            label: 'Faculty',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.assignment_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            value: _formatNumber(stats.testCount),
            label: 'Tests',
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // FIX: Deprecated withOpacity
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION HEADER & MODULES
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              'VIEW ALL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F46E5),
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

class _CoreModulesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final modules = _moduleItems(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, i) => _ModuleCard(item: modules[i]),
    );
  }

  List<_ModuleItem> _moduleItems(BuildContext context) => [
    _ModuleItem(
      title: 'Students',
      subtitle: 'Register and\nManage Students',
      icon: Icons.person_rounded,
      iconBg: const Color(0xFFEDE9FE),
      iconColor: const Color(0xFF6D28D9),
      onTap: () => context.push(RouteConstants.studentDatabase),
    ),
    _ModuleItem(
      title: 'Faculty',
      subtitle: 'Register and\nManage Faculty',
      icon: Icons.supervised_user_circle_rounded,
      iconBg: const Color(0xFFD1FAE5),
      iconColor: const Color(0xFF059669),
      onTap: () => context.push(RouteConstants.facultyRegistration),
    ),
    _ModuleItem(
      title: 'Question Bank',
      subtitle: 'Manage MCQ\nQuestions',
      icon: Icons.help_outline_rounded,
      iconBg: const Color(0xFFFEF3C7),
      iconColor: const Color(0xFFD97706),
      onTap: () => context.push(RouteConstants.questionBank),
    ),
    _ModuleItem(
      title: 'Tests',
      subtitle: 'Create and Assign\nTests',
      icon: Icons.fact_check_rounded,
      iconBg: const Color(0xFFFEE2E2),
      iconColor: const Color(0xFFDC2626),
      onTap: () => context.push(RouteConstants.tests),
    ),
    _ModuleItem(
      title: 'Timetable',
      subtitle: 'Weekly Schedule\nManagement',
      icon: Icons.calendar_today_rounded,
      iconBg: const Color(0xFFF3F4F6),
      iconColor: const Color(0xFF6B7280),
      onTap: () => context.push(RouteConstants.adminTimetable),
    ),
    _ModuleItem(
      title: 'Reports',
      subtitle: 'Student\nPerformance\nOverview',
      icon: Icons.bar_chart_rounded,
      iconBg: const Color(0xFFEEF2FF),
      iconColor: const Color(0xFF4F46E5),
      onTap: () => context.push(RouteConstants.adminReports),
    ),
  ];
}

class _ModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _ModuleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });
}

class _ModuleCard extends StatefulWidget {
  final _ModuleItem item;
  const _ModuleCard({required this.item});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.item.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.item.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.item.icon,
                  color: widget.item.iconColor,
                  size: 26,
                ),
              ),
              const Spacer(),
              Text(
                widget.item.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ACADEMY STATUS BANNER
// ─────────────────────────────────────────────────────────────

class _AcademyStatusBanner extends StatelessWidget {
  final List<FacultyAvatar> facultyAvatars;

  const _AcademyStatusBanner({required this.facultyAvatars});

  @override
  Widget build(BuildContext context) {
    final shown = facultyAvatars.take(2).toList();
    final overflowCount = (facultyAvatars.length - 2).clamp(0, 99);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academy Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Platform active. All systems operational.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: shown.length * 28.0 + (overflowCount > 0 ? 32 : 0),
                height: 36,
                child: Stack(
                  children: [
                    ...shown.asMap().entries.map((entry) {
                      return Positioned(
                        left: entry.key * 22.0,
                        child: _FacultyAvatarChip(avatar: entry.value),
                      );
                    }),
                    if (overflowCount > 0)
                      Positioned(
                        left: shown.length * 22.0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '+$overflowCount',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Faculty online',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FacultyAvatarChip extends StatelessWidget {
  final FacultyAvatar avatar;
  const _FacultyAvatarChip({required this.avatar});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF7C3AED),
      const Color(0xFF2563EB),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
    ];
    final colorIndex = avatar.name.codeUnits.first % colors.length;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors[colorIndex],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          avatar.name.isNotEmpty ? avatar.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FEEDBACK WIDGETS
// ─────────────────────────────────────────────────────────────

class _StatsRowSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
            (i) => Expanded(
          child: Container(
            height: 120,
            margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const _ShimmerBox(),
          ),
        ),
      ),
    );
  }
}

class _StatsRowError extends StatelessWidget {
  final String error;
  const _StatsRowError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Failed to load stats',
              style: TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}