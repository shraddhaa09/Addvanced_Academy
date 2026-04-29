import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/route_constants.dart';
import '../../../models/faculty_upload_model.dart';
import '../../../providers/faculty_providers.dart';
import '../widgets/recent_upload_tile.dart';

// ---------------------------------------------------------------------------
// Helpers
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

class FacultyMaterialsScreen extends ConsumerStatefulWidget {
  const FacultyMaterialsScreen({super.key});

  @override
  ConsumerState<FacultyMaterialsScreen> createState() =>
      _FacultyMaterialsScreenState();
}

class _FacultyMaterialsScreenState
    extends ConsumerState<FacultyMaterialsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  /// 'all' | 'material' | 'video'
  String _activeFilter = 'all';

  static const _filters = [
    ('all', 'All', Icons.apps_rounded),
    ('material', 'Materials', Icons.description_outlined),
    ('video', 'Videos', Icons.play_circle_outline),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(recentFacultyUploadsProvider);
    ref.invalidate(facultyStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final uploadsAsync =
    ref.watch(recentFacultyUploadsProvider(null));
    final profileAsync = ref.watch(facultyProfileProvider);
    final statsAsync = ref.watch(facultyStatsProvider);
    final facultyIdAsync = ref.watch(currentFacultyIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '${RouteConstants.facultyDashboard}/${RouteConstants.uploadMaterial}',
        ),
        backgroundColor: const Color(0xFF5B4FCF),
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text(
          'Upload Material',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF5B4FCF),
          onRefresh: () async => _refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(profileAsync),
                const SizedBox(height: 20),
                const Text(
                  'Study Materials',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage and track all your uploaded content.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),
                _buildLatestUpload(uploadsAsync),
                const SizedBox(height: 16),
                _buildStats(statsAsync),
                const SizedBox(height: 20),
                _buildSearch(),
                const SizedBox(height: 12),
                _buildFilterChips(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Uploads',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const Spacer(),
                    uploadsAsync.maybeWhen(
                      data: (uploads) {
                        final count = uploads
                            .where((u) =>
                                _activeFilter == 'all' ||
                                u.contentType == _activeFilter)
                            .where((u) =>
                                _searchQuery.isEmpty ||
                                u.title
                                    .toLowerCase()
                                    .contains(_searchQuery))
                            .length;
                        return Text(
                          '$count item${count == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildList(uploadsAsync, facultyIdAsync),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader(AsyncValue<dynamic> profileAsync) {
    return profileAsync.when(
      data: (profile) {
        final name = profile?.name as String?;
        final subject = profile?.subject as String?;
        final color = _subjectColor(subject);
        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withAlpha(30),
              child: Text(
                _initials(name),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${name?.split(' ').first ?? 'Professor'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                if (subject != null)
                  Text(
                    subject,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.campaign_outlined,
                  color: Color(0xFF1A1A2E)),
              onPressed: () => context.push(
                  '${RouteConstants.facultyDashboard}/${RouteConstants.facultyAnnouncements}'),
              tooltip: 'Notices',
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          _ShimmerBox(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 12),
          _ShimmerBox(width: 140, height: 16, borderRadius: 8),
        ],
      ),
      error: (_, __) => Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFEDE9FF),
            child: Icon(Icons.person, color: Color(0xFF5B4FCF)),
          ),
          const SizedBox(width: 12),
          const Text('Hello, Professor',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.campaign_outlined,
                color: Color(0xFF1A1A2E)),
            onPressed: () => context.push(
                '${RouteConstants.facultyDashboard}/${RouteConstants.facultyAnnouncements}'),
            tooltip: 'Notices',
          ),
        ],
      ),
      error: (_, __) => const Text('Error loading profile'),
    );
  }

  // ── Latest Upload — gradient hero card ────────────────────────────────────

  Widget _buildLatestUpload(AsyncValue uploadsAsync) {
    return uploadsAsync.when(
      data: (uploads) {
        final latest = uploads.isNotEmpty ? uploads.first : null;
        if (latest == null) return const SizedBox.shrink();

        final isVideo = latest.contentType.toLowerCase() == 'video';
        final accent =
            isVideo ? const Color(0xFF5B4FCF) : const Color(0xFF1E8C6E);
        final lightAccent =
            isVideo ? const Color(0xFF7C6FE0) : const Color(0xFF3BAD8A);

        return GestureDetector(
          onTap: () => _viewItem(latest),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, lightAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: accent.withAlpha(60),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background icon
                Positioned(
                  right: -12,
                  bottom: -12,
                  child: Icon(
                    isVideo
                        ? Icons.play_circle_fill_rounded
                        : Icons.menu_book_rounded,
                    size: 100,
                    color: Colors.white.withAlpha(20),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isVideo ? 'Latest Video' : 'Latest Material',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.open_in_new_rounded,
                            color: Colors.white70, size: 16),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      latest.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${latest.subject}  ·  ${latest.chapter}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      latest.uploadedAt != null
                          ? 'Uploaded ${timeago.format(latest.uploadedAt!)}'
                          : 'Recently uploaded',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          _ShimmerBox(width: double.infinity, height: 140, borderRadius: 18),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Widget _buildStats(AsyncValue statsAsync) {
    return statsAsync.when(
      data: (stats) => Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Videos',
              value: '${stats['videos']}',
              icon: Icons.video_library_outlined,
              color: const Color(0xFF5B4FCF),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Materials',
              value: '${stats['materials']}',
              icon: Icons.description_outlined,
              color: const Color(0xFF1E8C6E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Total',
              value: '${stats['total_uploads']}',
              icon: Icons.cloud_done_outlined,
              color: const Color(0xFFE65100),
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: [
          Expanded(
              child: _ShimmerBox(
                  width: double.infinity, height: 84, borderRadius: 14)),
          const SizedBox(width: 10),
          Expanded(
              child: _ShimmerBox(
                  width: double.infinity, height: 84, borderRadius: 14)),
          const SizedBox(width: 10),
          Expanded(
              child: _ShimmerBox(
                  width: double.infinity, height: 84, borderRadius: 14)),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (val) =>
          setState(() => _searchQuery = val.toLowerCase().trim()),
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9CA3AF)),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded,
                    size: 18, color: Color(0xFF9CA3AF)),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        hintText: 'Search by title, subject…',
        hintStyle:
            const TextStyle(color: Color(0xFFB0B8C4), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF5B4FCF), width: 1.5),
        ),
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final (key, label, icon) = f;
          final selected = _activeFilter == key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 14,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF6B7280)),
                  const SizedBox(width: 5),
                  Text(label),
                ],
              ),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF6B7280),
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF5B4FCF),
              checkmarkColor: Colors.white,
              showCheckmark: false,
              side: BorderSide(
                color: selected
                    ? const Color(0xFF5B4FCF)
                    : const Color(0xFFE5E7EB),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (_) => setState(() => _activeFilter = key),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────

  Widget _buildList(
    AsyncValue<List<FacultyUploadModel>> uploadsAsync,
    AsyncValue<String?> facultyIdAsync,
  ) {
    return facultyIdAsync.when(
      data: (facultyId) {
        if (facultyId == null) return const SizedBox();

        final viewCountsAsync =
            ref.watch(contentViewCountsProvider(facultyId));

        return viewCountsAsync.when(
          data: (viewCounts) {
            return uploadsAsync.when(
              data: (uploads) {
                final filtered = uploads
                    .where((u) =>
                        _activeFilter == 'all' ||
                        u.contentType == _activeFilter)
                    .where((u) =>
                        _searchQuery.isEmpty ||
                        u.title.toLowerCase().contains(_searchQuery) ||
                        u.subject.toLowerCase().contains(_searchQuery))
                    .toList();

                if (filtered.isEmpty) {
                  return _EmptyState(
                      query: _searchQuery, filter: _activeFilter);
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return RecentUploadTile(
                      upload: item,
                      viewCount: viewCounts[item.id],
                      onTap: () => _viewItem(item),
                      onEdit: () => context.push(
                        '${RouteConstants.facultyDashboard}/${RouteConstants.editUpload}',
                        extra: item,
                      ),
                      onDelete: () => _confirmDelete(context, item),
                    );
                  },
                );
              },
              loading: () => _buildShimmerList(),
              error: (e, _) => _buildError(),
            );
          },
          loading: () => _buildShimmerList(),
          error: (e, _) => _buildError(),
        );
      },
      loading: () => _buildShimmerList(),
      error: (e, _) => _buildError(),
    );
  }

  void _viewItem(FacultyUploadModel item) {
    final isVideo = item.contentType.toLowerCase() == 'video';
    final route =
        isVideo ? RouteConstants.videoViewer : RouteConstants.materialViewer;
    context.push('${RouteConstants.facultyDashboard}/$route', extra: item);
  }

  Widget _buildShimmerList() {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ShimmerBox(
              width: double.infinity, height: 80, borderRadius: 12),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 44, color: Color(0xFFB0B8C4)),
            const SizedBox(height: 12),
            const Text(
              'Could not load uploads',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5B4FCF),
                side: const BorderSide(color: Color(0xFF5B4FCF)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete Confirmation ────────────────────────────────────────────────────

  Future<void> _confirmDelete(
      BuildContext context, FacultyUploadModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 32),
        title: const Text(
          'Delete This Upload?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently remove "${item.title}" and it will no longer '
          'be accessible to students. This cannot be undone.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.query = '', this.filter = 'all'});

  final String query;
  final String filter;

  @override
  Widget build(BuildContext context) {
    final isSearch = query.isNotEmpty;
    final isFiltered = filter != 'all';
    final label = isSearch
        ? 'No results for "$query"'
        : isFiltered
            ? 'No ${filter == 'video' ? 'videos' : 'materials'} uploaded yet'
            : 'No uploads yet';
    final sub = isSearch || isFiltered
        ? 'Try adjusting your search or filter.'
        : 'Tap "Upload Material" below to get started.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEEECFD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSearch ? Icons.search_off_rounded : Icons.upload_file_outlined,
              size: 36,
              color: const Color(0xFF5B4FCF),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  Widget _buildShimmerList() => const CircularProgressIndicator();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('No data'));
  }
}