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
  String _filterType = 'all'; // 'all', 'video', 'material'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. ALL WATCH CALLS MUST BE AT THE TOP LEVEL
    final facultyIdResult = ref.watch(currentFacultyIdProvider);

    // We extract the ID safely to use in other providers
    final String? facultyId = facultyIdResult.maybeWhen(
      data: (id) => id,
      orElse: () => null,
    );

    final uploadsAsync = ref.watch(recentFacultyUploadsProvider(null));
    // statsAsync is now used here to clear the "unused variable" warning
    final statsAsync = ref.watch(facultyStatsProvider);
    final viewCountsAsync = ref.watch(contentViewCountsProvider(facultyId ?? ''));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Upload History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(recentFacultyUploadsProvider);
            ref.invalidate(facultyStatsProvider);
            ref.invalidate(contentViewCountsProvider);
          },
          child: Column(
            children: [
              // Search and Filter section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                        decoration: const InputDecoration(
                          icon: Icon(Icons.search, color: Colors.grey, size: 20),
                          hintText: 'Search by title or subject...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Videos', 'video'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Materials', 'material'),
                      ],
                    ),
                  ],
                ),
              ),

              // UI logic - combined into a single clean flow
              Expanded(
                child: facultyIdResult.when(
                  data: (id) {
                    if (id == null) return _buildEmptyState();

                    return uploadsAsync.when(
                      data: (uploads) {
                        return viewCountsAsync.when(
                          data: (viewCounts) {
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
                                  onEdit: () {
                                    context.push(
                                      '${RouteConstants.facultyDashboard}/${RouteConstants.editUpload}',
                                      extra: item,
                                    );
                                  },
                                  onDelete: () => _handleDelete(context, item),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          // Fixed: Use _ to avoid "multiple underscores" warning
                          error: (e, _) => Center(child: Text('Error loading counts: $e')),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error loading uploads: $e')),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error fetching Faculty ID: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B4FCF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B4FCF) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No uploads yet' : 'No results found',
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, dynamic item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Upload?'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(facultyUploadServiceProvider).deleteUpload(item.id, item.contentType);
        ref.invalidate(recentFacultyUploadsProvider);
        ref.invalidate(facultyStatsProvider);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}