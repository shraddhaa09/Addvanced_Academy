import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _LandingNavBar(
              onLoginTap: () => context.go(RouteConstants.login),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _HeroSection(
                      onGetStartedTap: () => context.go(RouteConstants.login),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Why Addvanced Academy?',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const _FeatureCardsSection(),
                    const SizedBox(height: 32),
                    const _FooterSection(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingNavBar extends StatelessWidget {
  final VoidCallback onLoginTap;

  const _LandingNavBar({
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Addvanced Academy',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          FilledButton(
            onPressed: onLoginTap,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onGetStartedTap;

  const _HeroSection({
    required this.onGetStartedTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE8F0FC),
            Color(0xFFDFF7F6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MHT-CET preparation made structured, smart, and simple.',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Practice with online tests, learn from video lectures, and access organized study material — all in one mobile learning platform.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onGetStartedTap,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}

class _FeatureCardsSection extends StatelessWidget {
  const _FeatureCardsSection();

  @override
  Widget build(BuildContext context) {
    final items = <_FeatureItem>[
      const _FeatureItem(
        icon: Icons.assignment_rounded,
        title: 'Online Tests',
        description: 'Take structured practice tests with a timed exam-style experience.',
      ),
      const _FeatureItem(
        icon: Icons.ondemand_video_rounded,
        title: 'Video Lectures',
        description: 'Learn chapter-wise concepts through recorded subject lectures.',
      ),
      const _FeatureItem(
        icon: Icons.menu_book_rounded,
        title: 'Study Material',
        description: 'Access notes, PDFs, and academic resources in one place.',
      ),
    ];

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _FeatureCard(item: item),
            ),
          )
          .toList(),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _FeatureItem item;

  const _FeatureCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.10),
              child: Icon(
                item.icon,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 14),
        Text(
          'Addvanced Academy',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Contact: +91 00000 00000 | support@addvancedacademy.com',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
