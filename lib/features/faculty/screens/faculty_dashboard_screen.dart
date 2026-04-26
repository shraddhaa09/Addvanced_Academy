import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  int _selectedIndex = 0;

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: const CircleAvatar(
            backgroundColor: Color(0xFFD9DDF7),
            child: Icon(Icons.person, color: Color(0xFF1A1A2E)),
          ),
        ),
        titleSpacing: 0,
        title: const Text(
          'Hello, Faculty',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none_rounded, color: Color(0xFF1A1A2E)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: [
                  Text(
                    'Welcome back, Professor',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your classroom activities for today.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    height: 170,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B5FEF), Color(0xFF4B4FD6)],
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Active Term',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Advanced Academy',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Spring Semester 2024',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          right: -6,
                          bottom: -4,
                          child: Icon(
                            Icons.school_rounded,
                            size: 100,
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _FacultyActionTile(
                    title: 'Upload Video Lecture',
                    subtitle: 'Share new video content with students',
                    icon: Icons.play_circle_fill_rounded,
                    iconBackground: const Color(0xFFEEECFD),
                    iconColor: const Color(0xFF5B5FEF),
                    onTap: () => context.go(
                      '${RouteConstants.facultyDashboard}/${RouteConstants.uploadVideo}',
                    ),
                  ),

                  const SizedBox(height: 12),

                  _FacultyActionTile(
                    title: 'Upload Study Material',
                    subtitle: 'Add PDFs, notes, or research papers',
                    icon: Icons.menu_book_rounded,
                    iconBackground: const Color(0xFFE6F4F1),
                    iconColor: const Color(0xFF2BB5A0),
                    onTap: () => context.go(
                      '${RouteConstants.facultyDashboard}/${RouteConstants.uploadMaterial}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Home',
                  active: _selectedIndex == 0,
                  onTap: () => _onNavTap(0),
                ),
                _BottomNavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                  active: _selectedIndex == 1,
                  onTap: () => _onNavTap(1),
                ),
                _BottomNavItem(
                  icon: Icons.library_books_rounded,
                  label: 'Materials',
                  active: _selectedIndex == 2,
                  onTap: () => _onNavTap(2),
                ),
                _BottomNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  active: _selectedIndex == 3,
                  onTap: () => _onNavTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ================= FIX: ADD THESE CLASSES =================

class _FacultyActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  const _FacultyActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF5B5FEF) : Colors.grey;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}