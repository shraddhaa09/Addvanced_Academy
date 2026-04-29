import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../providers/auth_provider.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final dashboardItems = <_DashboardItem>[
      _DashboardItem(
        title: 'Tests',
        icon: Icons.assignment_rounded,
        route: RouteConstants.assignedTests,
      ),
      _DashboardItem(
        title: 'Video Lectures',
        icon: Icons.play_circle_fill_rounded,
        route: RouteConstants.videoSubjects,
      ),
      _DashboardItem(
        title: 'Study Material',
        icon: Icons.menu_book_rounded,
        route: RouteConstants.materialSubjects,
      ),
      _DashboardItem(
        title: 'Timetable',
        icon: Icons.calendar_today_rounded,
        route: RouteConstants.studentTimetable,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      /// APP BAR
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      /// BODY
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// HEADER (future: student.name, batch)
              _HeaderCard(
                email: authState.email ?? '',
              ),

              const SizedBox(height: 20),

              /// GRID
              Expanded(
                child: GridView.builder(
                  itemCount: dashboardItems.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
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
                      onTap: () => context.go(item.route),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// HEADER CARD (extend later with students table)
class _HeaderCard extends StatelessWidget {
  final String email;

  const _HeaderCard({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B5FEF), Color(0xFF4B4FD6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// GRID TILE
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
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

/// MODEL
class _DashboardItem {
  final String title;
  final IconData icon;
  final String route;

  const _DashboardItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}