import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardItems = <_DashboardItem>[
      _DashboardItem(
        title: 'Tests',
        icon: Icons.assignment_rounded,
        onTap: () => context.go(RouteConstants.assignedTests),
      ),
      _DashboardItem(
        title: 'Video Lectures',
        icon: Icons.play_circle_fill_rounded,
        onTap: () => context.go(RouteConstants.videoSubjects),
      ),
      _DashboardItem(
        title: 'Study Material',
        icon: Icons.menu_book_rounded,
        onTap: () => context.go(RouteConstants.materialSubjects),
      ),
      _DashboardItem(
        title: 'Syllabus',
        icon: Icons.picture_as_pdf_rounded,
        onTap: () => context.go(RouteConstants.syllabus),
      ),
      _DashboardItem(
        title: 'Timetable',
        icon: Icons.calendar_today_rounded,
        onTap: () => context.go(RouteConstants.studentTimetable),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: dashboardItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final item = dashboardItems[index];

              return _StudentDashboardTile(
                title: item.title,
                icon: item.icon,
                onTap: item.onTap,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StudentDashboardTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _StudentDashboardTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 42,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}