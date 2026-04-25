import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../providers/faculty_providers.dart';

class FacultyDashboardScreen extends ConsumerStatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  ConsumerState<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends ConsumerState<FacultyDashboardScreen> {
  bool _showNotice = true;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(facultyProfileProvider);
    final statsAsync = ref.watch(facultyStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF5B4FCF).withOpacity(0.1),
                        child: const Icon(Icons.person, color: Color(0xFF5B4FCF), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hello, Faculty',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          profileAsync.when(
                            data: (profile) => Text(
                              profile?.name ?? 'Professor',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            loading: () => const SizedBox(height: 20, width: 80, child: LinearProgressIndicator()),
                            error: (_, __) => const Text('Professor'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Notice/Notification Button
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Show the notice if it was dismissed, or scroll to it
                          if (!_showNotice) {
                            setState(() => _showNotice = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Latest Announcement restored.')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF5B4FCF)),
                        ),
                      ),
                      if (_showNotice)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Notice Board Preview (Dismissible)
              if (_showNotice) ...[
                _buildNoticeBoard(context),
                const SizedBox(height: 32),
              ],
              
              // Active Term Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF5B4FCF),
                      const Color(0xFF5B4FCF).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B4FCF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Active Term',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Advanced Academy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          profileAsync.when(
                            data: (profile) => Text(
                              profile?.subject ?? 'General Faculty',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 15,
                              ),
                            ),
                            loading: () => const Text('Loading...', style: TextStyle(color: Colors.white70)),
                            error: (_, __) => const Text('General Faculty', style: TextStyle(color: Colors.white70)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.school_rounded,
                      size: 64,
                      color: Colors.white24,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      context,
                      'Videos',
                      Icons.video_call_rounded,
                      const Color(0xFF5B4FCF),
                      '${RouteConstants.facultyDashboard}/${RouteConstants.uploadVideo}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionTile(
                      context,
                      'Materials',
                      Icons.file_upload_rounded,
                      const Color(0xFF1E8C6E),
                      '${RouteConstants.facultyDashboard}/${RouteConstants.uploadMaterial}',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              const Text(
                'Teaching Stats',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              
              statsAsync.when(
                data: (stats) => Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        title: 'Total Videos',
                        value: stats['videos'].toString(),
                        progress: stats['videos'] > 0 ? 0.75 : 0.0,
                        color: const Color(0xFF5B4FCF),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatBox(
                        title: 'Study Materials',
                        value: stats['materials'].toString(),
                        progress: stats['materials'] > 0 ? 0.85 : 0.0,
                        color: const Color(0xFF1E8C6E),
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Error loading stats'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeBoard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB74D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Color(0xFFE65100), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Latest Announcement',
                style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() => _showNotice = false);
                },
                child: const Icon(Icons.close, size: 18, color: Color(0xFFE65100)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'New faculty meeting scheduled for tomorrow at 10 AM in the main hall.',
            style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}