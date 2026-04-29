import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/route_constants.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/widgets/hero_banner.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/announcement_providers.dart';
import '../../../providers/student_providers.dart';
import '../../../models/announcement_model.dart';
import '../../../models/faculty_upload_model.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const _DashboardAppBar(),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => RefreshIndicator(
            onRefresh: () async {
              await ref.read(studentAnnouncementsProvider.future);
              await ref.read(studentRecentUploadsProvider(3).future);
              ref.invalidate(studentProfileProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _GreetingSection(
                  greeting: _greeting(),
                  name: profile?.name ?? 'Student',
                ),
                const SizedBox(height: 20),
                const HeroBanner(
                  title: 'Academic Session',
                  subtitle: 'MHT-CET Preparation · 2025–26',
                ),
                const SizedBox(height: 28),
                const _SectionLabel('Quick Actions'),
                const SizedBox(height: 12),
                
                ActionCard(
                  title: 'Video Lectures',
                  subtitle: 'Watch recorded classes & tutorials',
                  icon: Icons.play_circle_fill_rounded,
                  accentColor: const Color(0xFF5B4FCF),
                  iconBackground: const Color(0xFFEEECFD),
                  onTap: () => context.go(RouteConstants.videoSubjects),
                ),
                const SizedBox(height: 12),
                ActionCard(
                  title: 'Study Materials',
                  subtitle: 'Access notes, PDFs and resources',
                  icon: Icons.menu_book_rounded,
                  accentColor: const Color(0xFF2BB5A0),
                  iconBackground: const Color(0xFFE6F4F1),
                  onTap: () => context.go(RouteConstants.materialSubjects),
                ),
                const SizedBox(height: 12),
                ActionCard(
                  title: 'Assigned Tests',
                  subtitle: 'Check and take your pending exams',
                  icon: Icons.assignment_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  iconBackground: const Color(0xFFFEF3C7),
                  onTap: () => context.go(RouteConstants.assignedTests),
                ),
                const SizedBox(height: 12),
                ActionCard(
                  title: 'Class Timetable',
                  subtitle: 'View your weekly schedule',
                  icon: Icons.calendar_today_rounded,
                  accentColor: const Color(0xFFEF4444),
                  iconBackground: const Color(0xFFFEE2E2),
                  onTap: () => context.go(RouteConstants.studentTimetable),
                ),
                
                const SizedBox(height: 28),
                const _AnnouncementsSection(),
                
                const SizedBox(height: 28),
                const _RecentUploadsSection(),
              ],
            ),
          ),
          loading: () => const DashboardSkeleton(),
          error: (e, _) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentProfileProvider),
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(child: Text('Error: $e')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _DashboardAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                onPressed: () => context.push('/student/announcements'),
                tooltip: 'Notices',
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
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF1A1A2E), size: 24),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            tooltip: 'Logout',
          ),
        ),
      ],
    );
  }
}

class _GreetingSection extends StatelessWidget {
  final String greeting;
  final String name;

  const _GreetingSection({required this.greeting, required this.name});

      /// APP BAR
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: authState.isLoading 
              ? null 
              : () async {
                  await ref.read(authProvider.notifier).signOut();
                },
            icon: authState.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.logout),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Track your progress and study materials.',
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

class _AnnouncementsSection extends ConsumerWidget {
  const _AnnouncementsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(studentAnnouncementsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Important Notices'),
        const SizedBox(height: 12),
        announcementsAsync.when(
          data: (announcements) {
            if (announcements.isEmpty) {
              return const AppEmptyState(
                title: 'No active notices',
                message: 'You are all caught up with recent academy updates.',
                icon: Icons.notifications_none_rounded,
              );
            }
            return SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  return _AnnouncementCard(announcement: announcements[index]);
                },
              ),
            );
          },
          loading: () => const ShimmerBox(width: double.infinity, height: 140, borderRadius: 14),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  announcement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                timeago.format(announcement.createdAt, locale: 'en_short'),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              announcement.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3),
            ),
          ),
          if (announcement.subject != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF5B4FCF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                announcement.subject!,
                style: const TextStyle(color: Color(0xFF5B4FCF), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentUploadsSection extends ConsumerWidget {
  const _RecentUploadsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadsAsync = ref.watch(studentRecentUploadsProvider(3));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel('Recent Study Material'),
            TextButton(
              onPressed: () => context.go(RouteConstants.materialSubjects),
              child: const Text('View all', style: TextStyle(fontSize: 13, color: Color(0xFF5B4FCF))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        uploadsAsync.when(
          data: (uploads) {
            if (uploads.isEmpty) {
              return const AppEmptyState(
                title: 'No recent uploads',
                message: 'Check back later for new study material and videos.',
                icon: Icons.cloud_off_rounded,
              );
            }
            return Column(
              children: uploads.map((upload) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RecentUploadCard(upload: upload),
              )).toList(),
            );
          },
          loading: () => Column(
            children: List.generate(3, (i) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: ShimmerBox(width: double.infinity, height: 72, borderRadius: 12),
            )),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }
}

class _RecentUploadCard extends StatelessWidget {
  const _RecentUploadCard({required this.upload});
  final FacultyUploadModel upload;

  @override
  Widget build(BuildContext context) {
    final isVideo = upload.contentType == 'video';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isVideo ? const Color(0xFF5B4FCF).withOpacity(0.08) : const Color(0xFF1E8C6E).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isVideo ? Icons.play_circle_outline : Icons.picture_as_pdf,
              color: isVideo ? const Color(0xFF5B4FCF) : const Color(0xFF1E8C6E),
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
                  '${upload.subject} • ${upload.facultyName ?? "Professor"}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            upload.uploadedAt != null ? timeago.format(upload.uploadedAt!) : 'Now',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }
}