import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final uploadsAsync = ref.watch(recentFacultyUploadsProvider(null));
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
                _buildUploadCountHeader(uploadsAsync),
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

  Widget _buildUploadCountHeader(AsyncValue<List<FacultyUploadModel>> uploadsAsync) {
    return Row(
      children: [
        const Text(
          'Uploads',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
        ),
        const Spacer(),
        uploadsAsync.maybeWhen(
          data: (uploads) {
            final count = uploads
                .where((u) => _activeFilter == 'all' || u.contentType == _activeFilter)
                .where((u) => _searchQuery.isEmpty || u.title.toLowerCase().contains(_searchQuery))
                .length;
            return Text(
              '$count item${count == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

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
              backgroundColor: color.withValues(alpha: 0.1),
              child: Text(_initials(name), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${name?.split(' ').first ?? 'Professor'}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A2E)),
                ),
                if (subject != null)
                  Text(subject, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.campaign_outlined, color: Color(0xFF1A1A2E)),
              onPressed: () => context.push('${RouteConstants.facultyDashboard}/${RouteConstants.facultyAnnouncements}'),
            ),
          ],
        );
      },
      loading: () => const Row(
        children: [
          _ShimmerBox(width: 40, height: 40, borderRadius: 20),
          SizedBox(width: 12),
          _ShimmerBox(width: 140, height: 16, borderRadius: 8),
        ],
      ),
      error: (err, stack) => const Text('Error loading profile'),
    );
  }

  Widget _buildLatestUpload(AsyncValue uploadsAsync) {
    return uploadsAsync.when(
      data: (uploads) {
        final latest = (uploads as List).isNotEmpty ? uploads.first : null;
        if (latest == null) return const SizedBox.shrink();

        final isVideo = latest.contentType.toLowerCase() == 'video';
        final accent = isVideo ? const Color(0xFF5B4FCF) : const Color(0xFF1E8C6E);

        return GestureDetector(
          onTap: () => _viewItem(latest),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(latest.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('${latest.subject} · ${latest.chapter}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        );
      },
      loading: () => const _ShimmerBox(width: double.infinity, height: 140, borderRadius: 18),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStats(AsyncValue statsAsync) {
    return statsAsync.when(
      data: (stats) => Row(
        children: [
          Expanded(child: _StatCard(label: 'Videos', value: '${stats['videos']}', icon: Icons.video_library_outlined, color: const Color(0xFF5B4FCF))),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Materials', value: '${stats['materials']}', icon: Icons.description_outlined, color: const Color(0xFF1E8C6E))),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Total', value: '${stats['total_uploads']}', icon: Icons.cloud_done_outlined, color: const Color(0xFFE65100))),
        ],
      ),
      loading: () => Row(
          children: List.generate(
              3,
                  (_) => const Expanded(
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: _ShimmerBox(width: double.infinity, height: 84, borderRadius: 14)
                  )
              )
          )
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9CA3AF)),
        hintText: 'Search by title, subject…',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final (key, label, _) = f;
          final selected = _activeFilter == key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selected,
              label: Text(label),
              onSelected: (_) => setState(() => _activeFilter = key),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF5B4FCF),
              labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList(AsyncValue<List<FacultyUploadModel>> uploadsAsync, AsyncValue<String?> facultyIdAsync) {
    return facultyIdAsync.when(
      data: (facultyId) {
        if (facultyId == null) return const SizedBox();
        final viewCountsAsync = ref.watch(contentViewCountsProvider(facultyId));

        return viewCountsAsync.when(
          data: (viewCounts) => uploadsAsync.when(
            data: (uploads) {
              final filtered = uploads
                  .where((u) => _activeFilter == 'all' || u.contentType == _activeFilter)
                  .where((u) => _searchQuery.isEmpty || u.title.toLowerCase().contains(_searchQuery))
                  .toList();

              if (filtered.isEmpty) return _EmptyState(query: _searchQuery);

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) => RecentUploadTile(
                  upload: filtered[index],
                  viewCount: viewCounts[filtered[index].id],
                  onTap: () => _viewItem(filtered[index]),
                ),
              );
            },
            loading: () => _buildShimmerList(),
            error: (e, _) => _buildError(),
          ),
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
    final route = isVideo ? RouteConstants.videoViewer : RouteConstants.materialViewer;
    context.push('${RouteConstants.facultyDashboard}/$route', extra: item);
  }

  Widget _buildShimmerList() {
    return Column(
        children: List.generate(
            3,
                (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _ShimmerBox(width: double.infinity, height: 80, borderRadius: 12)
            )
        )
    );
  }

  Widget _buildError() => const Center(child: Text('Could not load uploads'));
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: color)),
          Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.query = ''});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.upload_file_outlined, size: 40, color: Color(0xFF5B4FCF)),
          const SizedBox(height: 10),
          Text(query.isEmpty ? 'No uploads yet' : 'No results found'),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width, height, borderRadius;
  const _ShimmerBox({required this.width, required this.height, required this.borderRadius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 0.8).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(widget.borderRadius)
        ),
      ),
    );
  }
}