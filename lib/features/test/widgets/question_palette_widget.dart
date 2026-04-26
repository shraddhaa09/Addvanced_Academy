import 'package:flutter/material.dart';

// ── Design Tokens (same theme) ─────────────────────────────
const Color _primary = Color(0xFF6C5CE7);
const Color _primaryLight = Color(0xFFEEECFD);
const Color _textDark = Color(0xFF1A1A2E);
const Color _textMuted = Color(0xFF9B9BB4);

// Status colors (schema-based)
const Color _answered = Color(0xFF00B894);
const Color _visited = Color(0xFFFFB300);
const Color _notVisited = Color(0xFFE0E0E0);

// ── MODEL ─────────────────────────────────────────────
enum QuestionStatus {
  notVisited,
  visited,
  answered,
}

// ── MAIN WIDGET ─────────────────────────────────────────────
class QuestionPaletteWidget extends StatelessWidget {
  final int totalQuestions;
  final int currentIndex;
  final List<QuestionStatus> statusList;
  final Function(int) onQuestionTap;

  const QuestionPaletteWidget({
    super.key,
    required this.totalQuestions,
    required this.currentIndex,
    required this.statusList,
    required this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          const Text(
            'Question Palette',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),

          const SizedBox(height: 14),

          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalQuestions,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              return _PaletteItem(
                index: index,
                status: statusList[index],
                isCurrent: index == currentIndex,
                onTap: () => onQuestionTap(index),
              );
            },
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _LegendItem(color: _answered, label: 'Answered'),
              _LegendItem(color: _visited, label: 'Visited'),
              _LegendItem(color: _notVisited, label: 'Not Visited'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── GRID ITEM ─────────────────────────────────────────────
class _PaletteItem extends StatelessWidget {
  final int index;
  final QuestionStatus status;
  final bool isCurrent;
  final VoidCallback onTap;

  const _PaletteItem({
    required this.index,
    required this.status,
    required this.isCurrent,
    required this.onTap,
  });

  Color _getColor() {
    switch (status) {
      case QuestionStatus.answered:
        return _answered;
      case QuestionStatus.visited:
        return _visited;
      case QuestionStatus.notVisited:
        return _notVisited;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent ? _primaryLight : color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrent ? _primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isCurrent ? _primary : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── LEGEND ITEM ─────────────────────────────────────────────
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}