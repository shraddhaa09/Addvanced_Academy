import 'package:flutter/material.dart';

class HeroBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;
  final List<Color> gradientColors;
  final IconData? backgroundIcon;

  const HeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.tag = 'Active Term',
    this.gradientColors = const [Color(0xFF5B4FCF), Color(0xFF7C6FE0)],
    this.backgroundIcon = Icons.school_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
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
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (backgroundIcon != null)
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                backgroundIcon,
                size: 90,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
        ],
      ),
    );
  }
}
