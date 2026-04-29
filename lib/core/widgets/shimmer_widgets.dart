import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const ShimmerBox(width: 200, height: 24),
        const SizedBox(height: 8),
        const ShimmerBox(width: 150, height: 16),
        const SizedBox(height: 20),
        const ShimmerBox(width: double.infinity, height: 160, borderRadius: 16),
        const SizedBox(height: 28),
        const ShimmerBox(width: 100, height: 13),
        const SizedBox(height: 12),
        ...List.generate(3, (i) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerBox(width: double.infinity, height: 80, borderRadius: 14),
        )),
      ],
    );
  }
}
