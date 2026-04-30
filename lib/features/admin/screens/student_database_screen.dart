import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Supabase ─────────────────────────────────────────────────────────────────
final _supabase = Supabase.instance.client;

// ─── Models ───────────────────────────────────────────────────────────────────
class StudentRecord {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String parentMobile;
  final String batch;
  final DateTime createdAt;
  final bool isActive;

  const StudentRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.parentMobile,
    required this.batch,
    required this.createdAt,
    required this.isActive,
  });

  factory StudentRecord.fromMap(Map<String, dynamic> m) => StudentRecord(
        id: m['id'] as String,
        name: m['name'] as String,
        email: m['users']?['email'] as String? ?? '',
        mobile: m['mobile'] as String,
        parentMobile: m['parent_mobile'] as String,
        batch: m['batch'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        isActive: m['users']?['is_active'] as bool? ?? true,
      );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

// Filter state
class _FilterState {
  final String search;
  final String? batch; // null = All Batches
  final _SortOrder sort;

  const _FilterState({
    this.search = '',
    this.batch,
    this.sort = _SortOrder.newestFirst,
  });

  _FilterState copyWith({
    String? search,
    Object? batch = _sentinel,
    _SortOrder? sort,
  }) =>
      _FilterState(
        search: search ?? this.search,
        batch: batch == _sentinel ? this.batch : batch as String?,
        sort: sort ?? this.sort,
      );
}

const _sentinel = Object();

enum _SortOrder { newestFirst, oldestFirst, nameAZ, nameZA }

class _FilterNotifier extends StateNotifier<_FilterState> {
  _FilterNotifier() : super(const _FilterState());

  void setSearch(String v) => state = state.copyWith(search: v);
  void setBatch(String? v) => state = state.copyWith(batch: v);
  void setSort(_SortOrder v) => state = state.copyWith(sort: v);
}

final _filterProvider =
    StateNotifierProvider.autoDispose<_FilterNotifier, _FilterState>(
  (_) => _FilterNotifier(),
);

// Students raw list
final _studentsRawProvider = FutureProvider.autoDispose<List<StudentRecord>>(
  (ref) async {
    final res = await _supabase
        .from('students')
        .select('id, name, mobile, parent_mobile, batch, created_at, users(email, is_active)')
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => StudentRecord.fromMap(e as Map<String, dynamic>))
        .toList();
  },
);

// Filtered + sorted list
final _filteredStudentsProvider =
    Provider.autoDispose<AsyncValue<List<StudentRecord>>>((ref) {
  final raw = ref.watch(_studentsRawProvider);
  final filter = ref.watch(_filterProvider);

  return raw.whenData((students) {
    var list = students.where((s) {
      // Search
      if (filter.search.isNotEmpty) {
        final q = filter.search.toLowerCase();
        if (!s.name.toLowerCase().contains(q) &&
            !s.email.toLowerCase().contains(q) &&
            !s.mobile.contains(q)) {
          return false;
        }
      }
      // Batch
      if (filter.batch != null && s.batch != filter.batch) return false;
      return true;
    }).toList();

    // Sort
    switch (filter.sort) {
      case _SortOrder.newestFirst:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortOrder.oldestFirst:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortOrder.nameAZ:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _SortOrder.nameZA:
        list.sort((a, b) => b.name.compareTo(a.name));
    }
    return list;
  });
});

// Distinct batches
final _batchesProvider = Provider.autoDispose<AsyncValue<List<String>>>((ref) {
  final raw = ref.watch(_studentsRawProvider);
  return raw.whenData(
    (students) =>
        students.map((s) => s.batch).toSet().toList()..sort(),
  );
});

// Stats
final _statsProvider = Provider.autoDispose<AsyncValue<({int total, int active})>>(
  (ref) {
    final raw = ref.watch(_studentsRawProvider);
    return raw.whenData((students) => (
          total: students.length,
          active: students.where((s) => s.isActive).length,
        ));
  },
);

// ─── Avatar color palette ─────────────────────────────────────────────────────
const _avatarColors = [
  Color(0xFF3D52D5), // indigo
  Color(0xFF2E7D32), // green
  Color(0xFFE67E22), // orange
  Color(0xFF8E44AD), // purple
  Color(0xFF2980B9), // blue
  Color(0xFFC0392B), // red
  Color(0xFF16A085), // teal
  Color(0xFFD35400), // dark orange
];

Color _avatarColor(String id) =>
    _avatarColors[id.codeUnits.fold(0, (a, b) => a + b) % _avatarColors.length];

// ─── Screen ───────────────────────────────────────────────────────────────────
class StudentDatabaseScreen extends ConsumerStatefulWidget {
  const StudentDatabaseScreen({super.key});

  @override
  ConsumerState<StudentDatabaseScreen> createState() =>
      _StudentDatabaseScreenState();
}

class _StudentDatabaseScreenState
    extends ConsumerState<StudentDatabaseScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(_studentsRawProvider);
  }

  void _openStudentOptions(BuildContext ctx, StudentRecord student) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StudentOptionsSheet(student: student, onRefresh: _refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(_filteredStudentsProvider);
    final statsAsync = ref.watch(_statsProvider);
    final filter = ref.watch(_filterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: _buildAppBar(),
      floatingActionButton: _buildFab(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF3D52D5),
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Stats cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildStatsRow(statsAsync),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildSearchBar(),
              ),
            ),

            // Filters row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildFiltersRow(filter),
              ),
            ),

            // List
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            filteredAsync.when(
              data: (students) => students.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _StudentCard(
                              student: students[i],
                              onOptions: () =>
                                  _openStudentOptions(ctx, students[i]),
                            ),
                          ),
                          childCount: students.length,
                        ),
                      ),
                    ),
              loading: () => SliverToBoxAdapter(child: _buildShimmerList()),
              error: (e, _) => SliverToBoxAdapter(
                child: _buildError(e.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Color(0xFF1A1D2E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Student Database',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1D2E),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded,
                color: Color(0xFF1A1D2E), size: 22),
            onPressed: () {
              // Scroll to search
              _scrollCtrl.animateTo(
                120,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8ECF4)),
        ),
      );

  Widget _buildFab() => FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed(
            '/admin/students/register',
          );
          if (result == true) _refresh();
        },
        backgroundColor: const Color(0xFF3D52D5),
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      );

  // ─── Stats Row ───────────────────────────────────────────────────────────
  Widget _buildStatsRow(AsyncValue<({int total, int active})> statsAsync) =>
      Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.people_outline_rounded,
              iconBg: const Color(0xFFEEF0FF),
              iconColor: const Color(0xFF3D52D5),
              label: 'Total Students',
              value: statsAsync.when(
                data: (s) => s.total.toString(),
                loading: () => '—',
                error: (_, __) => '—',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.person_add_alt_1_rounded,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
              label: 'Active Students',
              value: statsAsync.when(
                data: (s) => s.active.toString(),
                loading: () => '—',
                error: (_, __) => '—',
              ),
            ),
          ),
        ],
      );

  // ─── Search Bar ──────────────────────────────────────────────────────────
  Widget _buildSearchBar() => Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: ref.read(_filterProvider.notifier).setSearch,
          style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1D2E),
              fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: 'Search by name, email, mobile...',
            hintStyle: const TextStyle(
                color: Color(0xFFADB5C7), fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded,
                color: Color(0xFFADB5C7), size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFFADB5C7), size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(_filterProvider.notifier).setSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );

  // ─── Filters Row ─────────────────────────────────────────────────────────
  Widget _buildFiltersRow(_FilterState filter) {
    final batchesAsync = ref.watch(_batchesProvider);
    final batches = batchesAsync.valueOrNull ?? [];

    return Row(
      children: [
        // Batch filter
        Expanded(
          child: _FilterDropdown<String?>(
            value: filter.batch,
            hint: 'All Batches',
            icon: Icons.keyboard_arrow_down_rounded,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Batches')),
              ...batches.map((b) => DropdownMenuItem(value: b, child: Text(b))),
            ],
            onChanged: ref.read(_filterProvider.notifier).setBatch,
          ),
        ),
        const SizedBox(width: 10),
        // Sort filter
        Expanded(
          child: _FilterDropdown<_SortOrder>(
            value: filter.sort,
            hint: 'Sort',
            icon: Icons.swap_vert_rounded,
            items: const [
              DropdownMenuItem(
                  value: _SortOrder.newestFirst, child: Text('Newest First')),
              DropdownMenuItem(
                  value: _SortOrder.oldestFirst, child: Text('Oldest First')),
              DropdownMenuItem(
                  value: _SortOrder.nameAZ, child: Text('Name A–Z')),
              DropdownMenuItem(
                  value: _SortOrder.nameZA, child: Text('Name Z–A')),
            ],
            onChanged: ref.read(_filterProvider.notifier).setSort,
          ),
        ),
      ],
    );
  }

  // ─── Empty / Error / Shimmer ─────────────────────────────────────────────
  Widget _buildEmptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No students found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8896AB)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try adjusting filters or search query',
              style: TextStyle(fontSize: 13, color: Color(0xFFADB5C7)),
            ),
          ],
        ),
      );

  Widget _buildError(String msg) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFE53E3E)),
            const SizedBox(height: 12),
            Text(
              'Failed to load students',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF1A1D2E)),
            ),
            const SizedBox(height: 6),
            Text(msg,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF8896AB))),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  Widget _buildShimmerList() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          children: List.generate(
            4,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 140,
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

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8896AB),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D2E),
                    letterSpacing: -0.5)),
          ],
        ),
      );
}

// ─── Filter Dropdown ──────────────────────────────────────────────────────────
class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDDE1ED), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            icon: Icon(icon, size: 18, color: const Color(0xFF8896AB)),
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A1D2E),
                fontWeight: FontWeight.w500),
            borderRadius: BorderRadius.circular(12),
            items: items,
            onChanged: (v) {
              if (v != null || T == String?) onChanged(v as T);
            },
          ),
        ),
      );
}

// ─── Student Card ─────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final StudentRecord student;
  final VoidCallback onOptions;

  const _StudentCard({required this.student, required this.onOptions});

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}';
  }

  String _formatMobile(String m) {
    if (m.length == 10) {
      return '+91 ${m.substring(0, 5)} ${m.substring(5)}';
    }
    return '+91 $m';
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _avatarColor(student.id),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        student.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D2E),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          student.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8896AB),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Options
                  InkWell(
                    onTap: onOptions,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.more_vert_rounded,
                          color: Color(0xFF8896AB), size: 20),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF0F2F8)),
              const SizedBox(height: 14),

              // Info grid
              Row(
                children: [
                  Expanded(
                    child: _InfoCell(
                      label: 'Batch',
                      child: _BatchChip(label: student.batch),
                    ),
                  ),
                  Expanded(
                    child: _InfoCell(
                      label: 'Registration',
                      value: _formatDate(student.createdAt),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoCell(
                      label: 'Mobile',
                      value: _formatMobile(student.mobile),
                    ),
                  ),
                  Expanded(
                    child: _InfoCell(
                      label: 'Parent Mobile',
                      value: _formatMobile(student.parentMobile),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

// ─── Info Cell ────────────────────────────────────────────────────────────────
class _InfoCell extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _InfoCell({required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFFADB5C7),
                letterSpacing: 0.2),
          ),
          const SizedBox(height: 4),
          if (child != null)
            child!
          else
            Text(
              value ?? '—',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D2E)),
            ),
        ],
      );
}

// ─── Batch Chip ───────────────────────────────────────────────────────────────
class _BatchChip extends StatelessWidget {
  final String label;

  const _BatchChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE67E22),
            letterSpacing: 0.4,
          ),
        ),
      );
}

// ─── Student Options Bottom Sheet ─────────────────────────────────────────────
class _StudentOptionsSheet extends ConsumerStatefulWidget {
  final StudentRecord student;
  final VoidCallback onRefresh;

  const _StudentOptionsSheet(
      {required this.student, required this.onRefresh});

  @override
  ConsumerState<_StudentOptionsSheet> createState() =>
      _StudentOptionsSheetState();
}

class _StudentOptionsSheetState extends ConsumerState<_StudentOptionsSheet> {
  bool _isDeleting = false;

  Future<void> _deleteStudent() async {
    setState(() => _isDeleting = true);
    try {
      // Deleting from users cascades to students (ON DELETE CASCADE)
      await _supabase
          .from('users')
          .delete()
          .eq('id', widget.student.id);
      if (mounted) {
        Navigator.pop(context);
        widget.onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.student.name} removed'),
            backgroundColor: const Color(0xFF38A169),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Student',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF1A1D2E))),
        content: Text(
          'Are you sure you want to remove ${widget.student.name}? This action cannot be undone.',
          style:
              const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8896AB))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteStudent();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Remove',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE1ED),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Student name header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _avatarColor(s.id),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    s.initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1A1D2E))),
                  Text(s.batch,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8896AB))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF0F2F8)),
          const SizedBox(height: 8),
          _OptionTile(
            icon: Icons.visibility_outlined,
            iconColor: const Color(0xFF3D52D5),
            label: 'View Profile',
            onTap: () {
              Navigator.pop(context);
              // Navigate to student detail screen
              // Navigator.pushNamed(context, '/admin/students/detail', arguments: s);
            },
          ),
          _OptionTile(
            icon: Icons.edit_outlined,
            iconColor: const Color(0xFF2E7D32),
            label: 'Edit Student',
            onTap: () {
              Navigator.pop(context);
              // Navigate to edit screen
            },
          ),
          _OptionTile(
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFFE67E22),
            label: 'View Test History',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _OptionTile(
            icon: Icons.delete_outline_rounded,
            iconColor: const Color(0xFFE53E3E),
            label: _isDeleting ? 'Removing...' : 'Remove Student',
            labelColor: const Color(0xFFE53E3E),
            onTap: _isDeleting ? null : _confirmDelete,
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor ?? const Color(0xFF1A1D2E),
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
}

// ─── Shimmer placeholder ──────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Opacity(
          opacity: _anim.value,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _shimmer(48, 48, circle: true),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmer(120, 14),
                        const SizedBox(height: 6),
                        _shimmer(160, 11),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _shimmer(double.infinity, 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _shimmer(80, 26, radius: 20),
                    const Spacer(),
                    _shimmer(100, 13),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _shimmer(110, 13),
                    const Spacer(),
                    _shimmer(110, 13),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _shimmer(double w, double h,
          {bool circle = false, double radius = 6}) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECF4),
          borderRadius:
              circle ? BorderRadius.circular(h) : BorderRadius.circular(radius),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
        ),
      );
}