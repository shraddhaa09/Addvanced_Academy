import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';

class AssignedTestsScreen extends StatelessWidget {
  const AssignedTestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tests'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Assigned Tests'),
              Tab(text: 'Create Own Test'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AssignedTestsTab(),
            _CreateOwnTestTab(),
          ],
        ),
      ),
    );
  }
}

class _AssignedTestsTab extends StatelessWidget {
  const _AssignedTestsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionInfoCard(
          title: 'Assigned by Academy',
          subtitle:
              'View the tests assigned to your batch and check completed attempts.',
        ),
        const SizedBox(height: 16),
        _TestOptionCard(
          title: 'Pending Tests',
          description: 'See all tests assigned to you that are not yet attempted.',
          icon: Icons.pending_actions_rounded,
          onTap: () {
            context.go('${RouteConstants.testSelection}?mode=assigned&status=pending');
          },
        ),
        const SizedBox(height: 16),
        _TestOptionCard(
          title: 'Completed Tests',
          description:
              'View completed tests, scores, and answer review for previous attempts.',
          icon: Icons.task_alt_rounded,
          onTap: () {
            context.go('${RouteConstants.testSelection}?mode=assigned&status=completed');
          },
        ),
      ],
    );
  }
}

class _CreateOwnTestTab extends StatelessWidget {
  const _CreateOwnTestTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionInfoCard(
          title: 'Create Your Own Test',
          subtitle:
              'Choose a test type, select subjects or topics, and generate a practice test.',
        ),
        const SizedBox(height: 16),
        _TestOptionCard(
          title: 'Subjective Test',
          description:
              'Choose one subject, select topics, and generate a random 30-question test.',
          icon: Icons.menu_book_rounded,
          onTap: () {
            context.go('${RouteConstants.testSelection}?mode=custom&type=subjective');
          },
        ),
        const SizedBox(height: 16),
        _TestOptionCard(
          title: 'Complete Test',
          description:
              'Choose PCM or PCB, select topics for each subject, and generate a full test.',
          icon: Icons.science_rounded,
          onTap: () {
            context.go('${RouteConstants.testSelection}?mode=custom&type=complete');
          },
        ),
      ],
    );
  }
}

class _SectionInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionInfoCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TestOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _TestOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 1.5,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}