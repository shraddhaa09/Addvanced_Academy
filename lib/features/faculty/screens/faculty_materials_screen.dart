import 'dart:math' as math;

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

/// Subject → brand color mapping (matches spec §8.4 color coding).
Color _subjectColor(String? subject) {
  switch (subject?.toLowerCase()) {
    case 'physics':
      return const Color(0xFF1565C0); // blue
    case 'chemistry':
      return const Color(0xFF2E7D32); // green
    case 'maths':
      return const Color(0xFFE65100); // orange
    case 'biology':
      return const Color(0xFF6A1B9A); // purple
    default:
      return const Color(0xFF5B4FCF); // brand default
  }
}

/// Returns up to 2 initials from a full name.
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
          '${RouteConstants.facultyDashboard}/${RouteConstants.uploadMaterial}',
        ),
        backgroundColor: const Color(0xFF5B4FCF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(profileAsync),
                const SizedBox(height: 24),
                const Text(
                  'Study Materials',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildLatestUpload(uploadsAsync),
                const SizedBox(height: 16),
                _buildStats(statsAsync),
                const SizedBox(height: 24),
                _buildSearch(),
                const SizedBox(height: 24),
                const Text(
                  'Recent Uploads',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildList(uploadsAsync, facultyIdAsync),
                // Extra space so FAB never covers last item
                const SizedBox(height: 88),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(AsyncValue profileAsync) {
    return profileAsync.when(
      data: (profile) {
        final name = profile?.name;
        final subject = profile?.subject as String?;
        final color = _subjectColor(subject);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Initials avatar — spec F-11 §Header
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
                Text(
                  'Hello, ${name?.split(' ').first ?? 'Professor'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.campaign_outlined, color: Color(0xFF1A1A2E)),
              onPressed: () => context.push('${RouteConstants.facultyDashboard}/${RouteConstants.facultyAnnouncements}'),
              tooltip: 'Notices',
            ),
          ],
        );
      },
      // While loading show a shimmer row
      loading: () => Row(
        children: [
          _ShimmerBox(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 12),
          _ShimmerBox(width: 120, height: 16, borderRadius: 8),
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
          const Text('Hello, Professor', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.campaign_outlined, color: Color(0xFF1A1A2E)),
            onPressed: () => context.push('${RouteConstants.facultyDashboard}/${RouteConstants.facultyAnnouncements}'),
            tooltip: 'Notices',
          ),
        ],
      ),
    );
  }

  // ── Latest Upload ─────────────────────────────────────────────────────────

  /// Only surfaces the latest *study material* (not videos) on this screen.
  Widget _buildLatestUpload(AsyncValue uploadsAsync) {
    return uploadsAsync.when(
      data: (uploads) {
        // Filter to materials only — this is the materials screen
        final materials = uploads
            .where((u) => u.contentType == 'material')
            .toList();

        if (materials.isEmpty) return const SizedBox.shrink();

        final latest = materials.first;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF5B4FCF).withAlpha(50)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Latest Upload',
                style: TextStyle(
                  color: Color(0xFF5B4FCF),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                latest.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                latest.uploadedAt != null
                    ? 'Uploaded ${timeago.format(latest.uploadedAt!)}'
                    : 'Recently uploaded',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        );
      },
      loading: () => _ShimmerBox(width: double.infinity, height: 100, borderRadius: 16),
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
              value: '${stats['videos']} files',
              icon: Icons.video_library_outlined,
              color: const Color(0xFF5B4FCF),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              label: 'Materials',
              value: '${stats['materials']} files',
              icon: Icons.description_outlined,
              color: const Color(0xFF1E8C6E),
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: [
          Expanded(child: _ShimmerBox(width: double.infinity, height: 88, borderRadius: 16)),
          const SizedBox(width: 16),
          Expanded(child: _ShimmerBox(width: double.infinity, height: 88, borderRadius: 16)),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, size: 20),
        hintText: 'Search materials…',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────

  Widget _buildList(AsyncValue<List<FacultyUploadModel>> uploadsAsync, AsyncValue<String?> facultyIdAsync) {
    return facultyIdAsync.when(
      data: (facultyId) {
        if (facultyId == null) return const SizedBox.shrink();

        final viewCountsAsync = ref.watch(contentViewCountsProvider(facultyId));

        return viewCountsAsync.when(
          data: (viewCounts) {
            return uploadsAsync.when(
              data: (uploads) {
                // Filter to materials only, then apply search and type filter
                final materials = uploads
                    .where((u) => u.contentType == 'material')
                    .where((u) =>
                        _searchQuery.isEmpty ||
                        u.title.toLowerCase().contains(_searchQuery))
                    .where((u) => 
                        _activeFilter == 'all' || 
                        u.contentType == _activeFilter)
                    .toList();

                if (materials.isEmpty) return _EmptyState(query: _searchQuery);

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final item = materials[index];
                    return RecentUploadTile(
                      upload: item,
                      viewCount: viewCounts[item.id],
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
              error: (e, _) => _buildError(e),
            );
          },
          loading: () => _buildShimmerList(),
          error: (e, _) => _buildError(e),
        );
      },
      loading: () => _buildShimmerList(),
      error: (e, _) => _buildError(e),
    );
  }

  Widget _buildShimmerList() {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child:
              _ShimmerBox(width: double.infinity, height: 76, borderRadius: 12),
        ),
      ),
    );
  }

  Widget _buildError(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          'Could not load uploads.\n$e',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black45),
        ),
      ),
    );
  }

  // ── Delete Confirmation (spec F-10) ───────────────────────────────────────

  Future<void> _confirmDelete(BuildContext context, dynamic item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 32),
        title: const Text(
          'Delete This Upload?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          // Match F-10 body copy from spec
          'This will permanently remove "${item.title}" and it will no longer '
              'be accessible to students. This cannot be undone.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(facultyUploadServiceProvider)
          .deleteUpload(item.id, item.contentType);
      _refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete. Please try again.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Extracted Sub-widgets
// ---------------------------------------------------------------------------

/// Stat card used in the stats row.
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Empty state shown when the filtered list is empty.
class _EmptyState extends StatelessWidget {
  const _EmptyState({this.query = ''});

  final String query;

  @override
  Widget build(BuildContext context) {
    final isSearch = query.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.upload_file_outlined,
            size: 56,
            color: Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No results for "$query"' : 'No materials uploaded yet.',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 8),
            const Text(
              'Tap the + button below to upload your first material.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black38, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// A shimmering placeholder box — no extra package required.
///
/// Animates opacity between 0.4 and 1.0 to simulate a loading skeleton.
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    super.key,
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

  @override
  void dispose() {
    _controller.dispose();
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
