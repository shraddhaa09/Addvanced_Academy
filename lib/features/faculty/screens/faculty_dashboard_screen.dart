import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../providers/faculty_providers.dart';
import '../widgets/recent_upload_tile.dart';

import '../../../core/constants/route_constants.dart';
import '../../../models/faculty_upload_model.dart';

class FacultyDashboardScreen extends ConsumerWidget {
  const FacultyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const _DashboardAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            const _GreetingSection(),
            const SizedBox(height: 20),
            const _HeroBanner(),
            const SizedBox(height: 28),
            const _SectionLabel('Quick Actions'),
            const SizedBox(height: 12),
            _ActionCard(
              title: 'Upload Video Lecture',
              subtitle: 'Share a recorded lecture with students',
              icon: Icons.play_circle_fill_rounded,
              accentColor: const Color(0xFF5B4FCF),
              iconBackground: const Color(0xFFEEECFD),
              onTap: () => context.push('${RouteConstants.facultyDashboard}/${RouteConstants.uploadVideo}'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              title: 'Upload Study Material',
              subtitle: 'Add notes, PDFs or chapter documents',
              icon: Icons.menu_book_rounded,
              accentColor: const Color(0xFF2BB5A0),
              iconBackground: const Color(0xFFE6F4F1),
              onTap: () => context.push('${RouteConstants.facultyDashboard}/${RouteConstants.uploadMaterial}'),
            ),
            const SizedBox(height: 28),
            _RecentUploadsSection(),
          ],
        ),
      ),
    );
  }
}

class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DashboardAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: const Color(0xFFEEEEEE)),
      ),
      leadingWidth: 72,
      leading: const Padding(
        padding: EdgeInsets.only(left: 20),
        child: CircleAvatar(
          backgroundColor: Color(0xFFEEECFD),
          child: Icon(Icons.person_rounded, color: Color(0xFF5B4FCF), size: 20),
        ),
      ),
      titleSpacing: 8,
      title: const Text(
        'Addvanced Academy',
        style: TextStyle(
          color: Color(0xFF1A1A2E),
          fontWeight: FontWeight.w700,
          fontSize: 17,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.campaign_rounded, color: Color(0xFF1A1A2E), size: 24),
                onPressed: () => context.push('${RouteConstants.facultyDashboard}/${RouteConstants.facultyAnnouncements}'),
                tooltip: 'Manage Notices',
              ),
              Positioned(
                right: 8,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B4FCF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GreetingSection extends ConsumerWidget {
  const _GreetingSection();

  String _getGreetingText(String? name) {
    final hour = DateTime.now().hour;
    final prefix = hour < 12 
        ? 'Good morning' 
        : (hour < 17 ? 'Good afternoon' : 'Good evening');
    
    // Fallback to Professor if name is null or empty
    final displayName = (name != null && name.trim().isNotEmpty) ? name : 'Professor';
    return '$prefix, $displayName';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(facultyProfileProvider);

    final greetingText = profileAsync.maybeWhen(
      data: (profile) => _getGreetingText(profile?.name),
      orElse: () => _getGreetingText(null),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greetingText,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage your content and schedule.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B4FCF), Color(0xFF7C6FE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Active Term',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Addvanced Academy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'MHT-CET Preparation · 2025–26',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.school_rounded,
              size: 90,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
        letterSpacing: 0.6,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color iconBackground;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: accentColor.withOpacity(0.06),
        highlightColor: accentColor.withOpacity(0.03),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: accentColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentUploadsSection extends ConsumerWidget {
  const _RecentUploadsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadsAsync = ref.watch(recentFacultyUploadsProvider(3));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel('Recent Uploads'),
            TextButton(
              onPressed: () => context.go(RouteConstants.facultyMaterials),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B4FCF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        uploadsAsync.when(
          data: (uploads) {
            if (uploads.isEmpty) return const _EmptyUploadsState();
            return Column(
              children: uploads.map((upload) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RecentUploadCard(upload: upload),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading uploads: $e')),
        ),
      ],
    );
  }
}

class _RecentUploadCard extends StatelessWidget {
  const _RecentUploadCard({required this.upload});
  final FacultyUploadModel upload;

  void _onTap(BuildContext context) {
    final isVideo = upload.contentType.toLowerCase() == 'video';
    final route = isVideo ? RouteConstants.videoViewer : RouteConstants.materialViewer;
    context.push('${RouteConstants.facultyDashboard}/$route', extra: upload);
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = upload.contentType == 'video';
    final accentColor = isVideo ? const Color(0xFF5B4FCF) : const Color(0xFF1E8C6E);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _onTap(context),
        borderRadius: BorderRadius.circular(12),
        splashColor: accentColor.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isVideo ? Icons.play_circle_outline : Icons.picture_as_pdf,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upload.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      upload.subject,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                upload.uploadedAt != null ? timeago.format(upload.uploadedAt!) : 'Unknown',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyUploadsState extends StatelessWidget {
  const _EmptyUploadsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEEECFD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              color: Color(0xFF5B4FCF),
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nothing uploaded yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Use the quick actions above to upload\nyour first lecture or material.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}