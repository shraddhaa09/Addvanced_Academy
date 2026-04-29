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
    final uploadsAsync =
    ref.watch(recentFacultyUploadsProvider(null));
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
                const SizedBox(height: 88),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withAlpha(30),
                  child: Text(
                    _initials(name),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
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
              icon: const Icon(Icons.campaign_outlined),
              onPressed: () => context.push(
                '${RouteConstants.facultyDashboard}/${RouteConstants.facultyAnnouncements}',
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: const [
          CircleAvatar(radius: 20),
          SizedBox(width: 12),
          Text('Loading...'),
        ],
      ),
      error: (_, __) => const Text('Error loading profile'),
    );
  }

  // LIST
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
                final materials = uploads
                    .where((u) => u.contentType == 'material')
                    .where((u) =>
                    (u.title ?? '')
                        .toLowerCase()
                        .contains(_searchQuery))
                    .toList();

                if (materials.isEmpty) {
                  return _EmptyState(query: _searchQuery);
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final item = materials[index];
                    return RecentUploadTile(
                      upload: item,
                      viewCount: viewCounts[item.id],
                      onEdit: () {},
                      onDelete: () {},
                    );
                  },
                );
              },
              loading: () => _buildShimmerList(),
              error: (e, _) => Text('$e'),
            );
          },
          loading: () => _buildShimmerList(),
          error: (e, _) => Text('$e'),
        );
      },
      loading: () => _buildShimmerList(),
      error: (e, _) => Text('$e'),
    );
  }

  // LATEST
  Widget _buildLatestUpload(
      AsyncValue<List<FacultyUploadModel>> uploadsAsync) {
    return uploadsAsync.when(
      data: (uploads) {
        final materials =
        uploads.where((u) => u.contentType == 'material').toList();

        if (materials.isEmpty) return const SizedBox();

        final latest = materials.first;

        return Text(latest.title);
      },
      loading: () => _buildShimmerList(),
      error: (_, __) => const SizedBox(),
    );
  }

  // STATS
  Widget _buildStats(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) => Text("Videos: ${stats['videos']}"),
      loading: () => _buildShimmerList(),
      error: (_, __) => const SizedBox(),
    );
  }

  // SEARCH
  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() {
        _searchQuery = val.toLowerCase();
      }),
      decoration: const InputDecoration(hintText: 'Search'),
    );
  }

  Widget _buildShimmerList() => const CircularProgressIndicator();
}

// EMPTY STATE
class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key, this.query = ''});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('No data'));
  }
}