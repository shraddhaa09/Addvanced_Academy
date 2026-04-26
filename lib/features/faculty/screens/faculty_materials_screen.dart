import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/route_constants.dart';
import '../../../providers/faculty_providers.dart';
import '../widgets/recent_upload_tile.dart';

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
    final uploadsAsync = ref.watch(recentFacultyUploadsProvider);
    final profileAsync = ref.watch(facultyProfileProvider);
    final statsAsync = ref.watch(facultyStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(
            '${RouteConstants.facultyDashboard}/${RouteConstants.uploadMaterial}',
          );
        },
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
                // HEADER
                _buildHeader(profileAsync),

                const SizedBox(height: 24),

                const Text(
                  "Study Materials",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // LATEST UPLOAD
                _buildLatestUpload(uploadsAsync),

                const SizedBox(height: 16),

                // STATS
                _buildStats(statsAsync),

                const SizedBox(height: 24),

                // SEARCH
                _buildSearch(),

                const SizedBox(height: 24),

                const Text(
                  "Recent Uploads",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // LIST
                _buildList(uploadsAsync),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader(AsyncValue profileAsync) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
              const Color(0xFF5B4FCF).withOpacity(0.1),
              child: const Icon(Icons.person,
                  color: Color(0xFF5B4FCF)),
            ),
            const SizedBox(width: 12),
            profileAsync.when(
              data: (profile) => Text(
                "Hello, ${profile?.name?.split(' ').first ?? 'Professor'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              loading: () => const Text("Hello, Professor"),
              error: (_, __) => const Text("Hello, Professor"),
            ),
          ],
        ),
        const Icon(Icons.notifications_none),
      ],
    );
  }

  // ---------------- LATEST ----------------
  Widget _buildLatestUpload(AsyncValue uploadsAsync) {
    return uploadsAsync.when(
      data: (uploads) {
        if (uploads.isEmpty) return const SizedBox();

        final latest = uploads.first;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF5B4FCF).withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Latest Upload",
                style: TextStyle(
                  color: Color(0xFF5B4FCF),
                  fontWeight: FontWeight.bold,
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
                    ? "Uploaded ${timeago.format(latest.uploadedAt!)}"
                    : "Recently uploaded",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        );
      },
      loading: () => const ShimmerCard(),
      error: (_, __) => const SizedBox(),
    );
  }

  // ---------------- STATS ----------------
  Widget _buildStats(AsyncValue statsAsync) {
    return statsAsync.when(
      data: (stats) => Row(
        children: [
          Expanded(
            child: _statCard(
              "Videos",
              "${stats['videos']} files",
              Icons.video_library,
              const Color(0xFF5B4FCF),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _statCard(
              "Materials",
              "${stats['materials']} files",
              Icons.assignment,
              const Color(0xFF1E8C6E),
            ),
          ),
        ],
      ),
      loading: () => const Row(
        children: [
          Expanded(child: ShimmerCard()),
          SizedBox(width: 16),
          Expanded(child: ShimmerCard()),
        ],
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _statCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value,
              style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  // ---------------- SEARCH ----------------
  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (val) {
        setState(() => _searchQuery = val.toLowerCase());
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: "Search materials...",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ---------------- LIST ----------------
  Widget _buildList(AsyncValue uploadsAsync) {
    return uploadsAsync.when(
      data: (uploads) {
        final filtered = _searchQuery.isEmpty
            ? uploads
            : uploads
            .where((e) =>
            e.title.toLowerCase().contains(_searchQuery))
            .toList();

        if (filtered.isEmpty) {
          return const Center(child: Text("No uploads found"));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];

            return RecentUploadTile(
              upload: item,
              onEdit: () {
                context.push(
                  '${RouteConstants.facultyDashboard}/${RouteConstants.editUpload}',
                  extra: item,
                );
              },
              onDelete: () async {
                await _confirmDelete(context, item);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, dynamic item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete?"),
        content:
        const Text("Are you sure you want to delete this?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(facultyUploadServiceProvider)
            .deleteUpload(item.id, item.contentType);

        _refresh();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }
    }
  }
}

// ---------------- SHIMMER ----------------
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}