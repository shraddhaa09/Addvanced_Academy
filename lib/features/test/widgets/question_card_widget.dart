import 'package:flutter/material.dart';

// ── Design Tokens (same theme) ─────────────────────────────
const Color _primary = Color(0xFF6C5CE7);
const Color _primaryLight = Color(0xFFEEECFD);
const Color _bg = Color(0xFFF4F3FB);
const Color _textDark = Color(0xFF1A1A2E);
const Color _textMuted = Color(0xFF9B9BB4);

// ── MODEL ─────────────────────────────────────────────
class QuestionModel {
  final String question;
  final List<String> options;
  final int? selectedIndex;

  QuestionModel({
    required this.question,
    required this.options,
    this.selectedIndex,
  });
}

// ── WIDGET ─────────────────────────────────────────────
class QuestionCardWidget extends StatelessWidget {
  final int questionNumber;
  final QuestionModel question;
  final Function(int) onOptionSelected;

  const QuestionCardWidget({
    super.key,
    required this.questionNumber,
    required this.question,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Question Number ─────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Question $questionNumber',
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Question Text ─────────────────────────
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textDark,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          // ── Options ─────────────────────────
          Column(
            children: List.generate(
              question.options.length,
              (index) => _OptionTile(
                index: index,
                text: question.options[index],
                isSelected: question.selectedIndex == index,
                onTap: () => onOptionSelected(index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── OPTION TILE ─────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _primaryLight : _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Option Circle
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _primary : _textMuted,
                  width: 1.5,
                ),
                color: isSelected ? _primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            // Option Text
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? _textDark : _textMuted,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}