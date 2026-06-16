import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../providers/faculty_providers.dart';
import '../widgets/recent_upload_tile.dart';

class FacultyUploadHistoryScreen extends ConsumerStatefulWidget {
  const FacultyUploadHistoryScreen({super.key});

  @override
  ConsumerState<FacultyUploadHistoryScreen> createState() => _FacultyUploadHistoryScreenState();
}

class _FacultyUploadHistoryScreenState extends ConsumerState<FacultyUploadHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Extract facultyId from the AsyncValue without triggering UI loading logic.
    final String? facultyId = facultyIdAsync.valueOrNull;

    final uploadsAsync = ref.watch(recentFacultyUploadsProvider(null));

    // Provide a fallback empty string to avoid provider resolution crashes when ID is null.
    final viewCountsAsync = ref.watch(contentViewCountsProvider(facultyId ?? ''));

    final _ = ref.watch(facultyStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Upload History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentFacultyIdProvider);
            ref.invalidate(recentFacultyUploadsProvider);
            ref.invalidate(facultyStatsProvider);
            ref.invalidate(contentViewCountsProvider);
          },
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: facultyIdAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (id) {
                    if (id == null) return _buildEmptyState();
                    return _buildContent(id);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the search bar and filter chips for the upload history list.
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search uploads...',
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: ['all', 'video', 'material'].map((type) => _buildFilterChip(type)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String facultyId) {
    final uploadsAsync = ref.watch(recentFacultyUploadsProvider(null));
    final viewCountsAsync = ref.watch(contentViewCountsProvider(facultyId));

    return uploadsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Uploads Error: $err')),
      data: (uploads) {
        final viewCounts = viewCountsAsync.valueOrNull ?? {};

        // Apply local filtering based on search query and chip selection
        final filtered = uploads.where((u) {
          final matchesSearch = u.title.toLowerCase().contains(_searchQuery) ||
              u.subject.toLowerCase().contains(_searchQuery);
          final matchesFilter = _filterType == 'all' || u.contentType == _filterType;
          return matchesSearch && matchesFilter;
        }).toList();

        if (filtered.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            return RecentUploadTile(
              upload: item,
              viewCount: viewCounts[item.id],
              onEdit: () => context.push(
                  '${RouteConstants.facultyDashboard}/${RouteConstants.editUpload}',
                  extra: item
              ),
              onDelete: () => _handleDelete(item),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String type) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(type[0].toUpperCase() + type.substring(1)),
        selected: isSelected,
        onSelected: (val) => setState(() => _filterType = type),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text("No uploads found"));

  Future<void> _handleDelete(dynamic item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(facultyUploadServiceProvider).deleteUpload(item.id, item.contentType);

        if (!mounted) return;

        ref.invalidate(recentFacultyUploadsProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}