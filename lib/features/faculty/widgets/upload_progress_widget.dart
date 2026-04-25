import 'package:flutter/material.dart';

class UploadProgressWidget extends StatelessWidget {
  final double progress;
  final String leftText;
  final String rightText;

  const UploadProgressWidget({
    super.key,
    required this.progress,
    this.leftText = 'Uploading...',
    this.rightText = '',
  });

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    final percentage = (value * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF5B5FEF),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftText,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            Text(
              rightText.isNotEmpty ? rightText : '$percentage%',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5B5FEF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}