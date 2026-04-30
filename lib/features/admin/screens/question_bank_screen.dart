import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────

enum SubjectFilter { all, physics, chemistry, maths, biology }

enum DifficultyFilter { all, easy, medium, hard }

enum StatusFilter { all, active, inactive, draft }

enum Difficulty { easy, medium, hard }

enum QuestionStatus { active, inactive, draft }

class QuestionModel {
  final String id;
  final String subject;
  final String chapter;
  final String body;
  final Difficulty difficulty;
  final QuestionStatus status;
  final double marksCorrect;
  final double marksWrong;
  final DateTime createdAt;
  final String? creatorAvatarUrl;

  const QuestionModel({
    required this.id,
    required this.subject,
    required this.chapter,
    required this.body,
    required this.difficulty,
    required this.status,
    required this.marksCorrect,
    required this.marksWrong,
    required this.createdAt,
    this.creatorAvatarUrl,
  });
}

// ─────────────────────────────────────────────────────────────
//  DUMMY DATA
// ─────────────────────────────────────────────────────────────

final List<QuestionModel> _dummyQuestions = [
  QuestionModel(
    id: '1',
    subject: 'PHYSICS',
    chapter: 'ROTATION',
    body:
        'Calculate the moment of inertia of a solid cylinder of mass M and radius R about it...',
    difficulty: Difficulty.medium,
    status: QuestionStatus.active,
    marksCorrect: 4,
    marksWrong: -1,
    createdAt: DateTime(2023, 10, 24),
  ),
  QuestionModel(
    id: '2',
    subject: 'BIOLOGY',
    chapter: 'GENETICS',
    body:
        'Explain the process of DNA replication in prokaryotic cells, focusing on the role o...',
    difficulty: Difficulty.hard,
    status: QuestionStatus.active,
    marksCorrect: 3,
    marksWrong: -0.5,
    createdAt: DateTime(2023, 11, 12),
  ),
  QuestionModel(
    id: '3',
    subject: 'CHEMISTRY',
    chapter: 'THERMODYNAMICS',
    body:
        'Determine the change in entropy for the isothermal expansion of an ideal gas...',
    difficulty: Difficulty.easy,
    status: QuestionStatus.inactive,
    marksCorrect: 2,
    marksWrong: 0,
    createdAt: DateTime(2023, 12, 1),
  ),
  QuestionModel(
    id: '4',
    subject: 'MATHS',
    chapter: 'CALCULUS',
    body:
        'Find the area enclosed between the curves y = x² and y = 2x using definite integration...',
    difficulty: Difficulty.medium,
    status: QuestionStatus.active,
    marksCorrect: 2,
    marksWrong: -0.5,
    createdAt: DateTime(2024, 1, 8),
  ),
  QuestionModel(
    id: '5',
    subject: 'PHYSICS',
    chapter: 'ELECTROSTATICS',
    body:
        'Two point charges +q and -q are placed at a distance d apart. Find the electric field...',
    difficulty: Difficulty.easy,
    status: QuestionStatus.draft,
    marksCorrect: 2,
    marksWrong: 0,
    createdAt: DateTime(2024, 1, 15),
  ),
];

// ─────────────────────────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────────────────────────

final subjectFilterProvider = StateProvider<SubjectFilter>(
  (ref) => SubjectFilter.all,
);

final difficultyFilterProvider = StateProvider<DifficultyFilter>(
  (ref) => DifficultyFilter.all,
);

final statusFilterProvider = StateProvider<StatusFilter>(
  (ref) => StatusFilter.all,
);

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredQuestionsProvider = Provider<List<QuestionModel>>((ref) {
  final subject = ref.watch(subjectFilterProvider);
  final difficulty = ref.watch(difficultyFilterProvider);
  final status = ref.watch(statusFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return _dummyQuestions.where((q) {
    if (subject != SubjectFilter.all &&
        q.subject.toLowerCase() != subject.name) {
      return false;
    }
    if (difficulty != DifficultyFilter.all &&
        q.difficulty.name != difficulty.name) {
      return false;
    }
    if (status != StatusFilter.all && q.status.name != status.name) {
      return false;
    }
    if (query.isNotEmpty &&
        !q.body.toLowerCase().contains(query) &&
        !q.chapter.toLowerCase().contains(query) &&
        !q.subject.toLowerCase().contains(query)) {
      return false;
    }
    return true;
  }).toList();
});

// Stats
final totalQuestionsProvider = Provider<int>((ref) => 12450);
final activeQuestionsProvider = Provider<int>((ref) => 11205);

// ─────────────────────────────────────────────────────────────
//  THEME CONSTANTS  (keep in sync with project theme)
// ─────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF4C3BCF); // deep indigo
const _kPrimaryLight = Color(0xFFEEEBFF);
const _kSurface = Color(0xFFFFFFFF);
const _kBackground = Color(0xFFF5F6FA);
const _kTextPrimary = Color(0xFF14142B);
const _kTextSecondary = Color(0xFF6E7191);
const _kBorder = Color(0xFFE4E4E7);

const _kEasyGreen = Color(0xFF00BA88);
const _kMediumOrange = Color(0xFFF4A261);
const _kHardRed = Color(0xFFEB5757);

// Subject chip colors
const Map<String, Color> _kSubjectColors = {
  'PHYSICS': Color(0xFFE8EAFF),
  'CHEMISTRY': Color(0xFFFFECE8),
  'BIOLOGY': Color(0xFFE6F9F1),
  'MATHS': Color(0xFFFFF3E0),
};

const Map<String, Color> _kSubjectTextColors = {
  'PHYSICS': Color(0xFF4C3BCF),
  'CHEMISTRY': Color(0xFFD94F3A),
  'BIOLOGY': Color(0xFF00875A),
  'MATHS': Color(0xFFBF7000),
};

// ─────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────

class QuestionBankScreen extends ConsumerStatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  ConsumerState<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends ConsumerState<QuestionBankScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_showSearch) _buildSearchBar(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildStatsRow()),
                SliverToBoxAdapter(child: _buildFilters()),
                SliverToBoxAdapter(child: _buildStatusChips()),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                _buildQuestionList(),
                // Bottom padding for FAB
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _kTextPrimary),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'Question Bank',
        style: TextStyle(
          color: _kTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: _kTextPrimary),
          onPressed: () => setState(() {
            _showSearch = !_showSearch;
            if (!_showSearch) {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).state = '';
            }
          }),
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: _kTextPrimary),
          onPressed: () => _showAdvancedFilterSheet(),
        ),
      ],
    );
  }

  // ── Search Bar ──────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
        decoration: InputDecoration(
          hintText: 'Search questions, chapters...',
          hintStyle: const TextStyle(color: _kTextSecondary, fontSize: 14),
          prefixIcon: const Icon(
            Icons.search,
            color: _kTextSecondary,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: _kTextSecondary,
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          filled: true,
          fillColor: _kBackground,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ── Stats Row ───────────────────────────────────────────────

  Widget _buildStatsRow() {
    final total = ref.watch(totalQuestionsProvider);
    final active = ref.watch(activeQuestionsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.library_books_outlined,
              iconBgColor: _kPrimaryLight,
              iconColor: _kPrimary,
              label: 'Total Questions',
              value: _formatNumber(total),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle_outline,
              iconBgColor: const Color(0xFFE6F9F1),
              iconColor: _kEasyGreen,
              label: 'Active Questions',
              value: _formatNumber(active),
              isGreen: true,
            ),
          ),
          // Partially visible third card hinting scroll
          const SizedBox(width: 12),
          SizedBox(
            width: 30,
            child: _StatCard(
              icon: Icons.pause_circle_outline,
              iconBgColor: const Color(0xFFFFF3E0),
              iconColor: _kMediumOrange,
              label: 'Inactive',
              value: _formatNumber(total - active),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filters Row ─────────────────────────────────────────────

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Expanded(child: _buildSubjectDropdown()),
          const SizedBox(width: 12),
          Expanded(child: _buildDifficultyDropdown()),
        ],
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    final current = ref.watch(subjectFilterProvider);
    return _DropdownFilter<SubjectFilter>(
      value: current,
      label: 'Subject',
      items: SubjectFilter.values,
      displayText: (v) => v == SubjectFilter.all
          ? 'All'
          : v.name[0].toUpperCase() + v.name.substring(1),
      onChanged: (v) => ref.read(subjectFilterProvider.notifier).state = v!,
    );
  }

  Widget _buildDifficultyDropdown() {
    final current = ref.watch(difficultyFilterProvider);
    return _DropdownFilter<DifficultyFilter>(
      value: current,
      label: 'Difficulty',
      items: DifficultyFilter.values,
      displayText: (v) => v == DifficultyFilter.all
          ? 'All'
          : v.name[0].toUpperCase() + v.name.substring(1),
      onChanged: (v) => ref.read(difficultyFilterProvider.notifier).state = v!,
    );
  }

  // ── Status Chips ────────────────────────────────────────────

  Widget _buildStatusChips() {
    final current = ref.watch(statusFilterProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: StatusFilter.values.map((f) {
          final isSelected = current == f;
          final label = f == StatusFilter.all
              ? 'All Status'
              : f.name[0].toUpperCase() + f.name.substring(1);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref.read(statusFilterProvider.notifier).state = f,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _kPrimary : _kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? _kPrimary : _kBorder),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _kTextSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Question List ───────────────────────────────────────────

  Widget _buildQuestionList() {
    final questions = ref.watch(filteredQuestionsProvider);

    if (questions.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 56,
                color: _kTextSecondary.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'No questions found',
                style: TextStyle(
                  color: _kTextSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _QuestionCard(
              question: questions[i],
              onEdit: () => _openEditQuestion(questions[i]),
              onDelete: () => _confirmDelete(questions[i]),
              onToggleStatus: () => _toggleStatus(questions[i]),
            ),
          ),
          childCount: questions.length,
        ),
      ),
    );
  }

  // ── FAB ─────────────────────────────────────────────────────

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _openAddQuestion,
      backgroundColor: _kPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  // ── Bottom Navigation ───────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _kPrimary,
        unselectedItemColor: _kTextSecondary,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline_rounded),
            label: 'Questions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Exams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          // TODO: wire up GoRouter navigation
        },
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────

  void _openAddQuestion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddEditQuestionSheet(),
    );
  }

  void _openEditQuestion(QuestionModel q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditQuestionSheet(existingQuestion: q),
    );
  }

  void _confirmDelete(QuestionModel q) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Question',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to delete this question? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _kTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kHardRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Question deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(QuestionModel q) {
    final msg = q.status == QuestionStatus.active
        ? 'Question marked as inactive'
        : 'Question marked as active';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showAdvancedFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AdvancedFilterSheet(),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  String _formatNumber(int n) {
    return NumberFormat('#,###').format(n);
  }
}

// ─────────────────────────────────────────────────────────────
//  STAT CARD WIDGET
// ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final String value;
  final bool isGreen;

  const _StatCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isGreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: _kTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: isGreen ? _kEasyGreen : _kTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DROPDOWN FILTER
// ─────────────────────────────────────────────────────────────

class _DropdownFilter<T> extends StatelessWidget {
  final T value;
  final String label;
  final List<T> items;
  final String Function(T) displayText;
  final ValueChanged<T?> onChanged;

  const _DropdownFilter({
    required this.value,
    required this.label,
    required this.items,
    required this.displayText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _kTextSecondary,
            size: 20,
          ),
          style: const TextStyle(
            color: _kTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    item == items.first
                        ? '$label: ${displayText(item)}'
                        : displayText(item),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  QUESTION CARD
// ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _QuestionCard({
    required this.question,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject + Chapter chips + overflow menu
          Row(
            children: [
              _SubjectChip(subject: question.subject),
              const SizedBox(width: 6),
              _ChapterChip(chapter: question.chapter),
              const Spacer(),
              _OverflowMenu(
                onEdit: onEdit,
                onDelete: onDelete,
                onToggleStatus: onToggleStatus,
                isActive: question.status == QuestionStatus.active,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Question body
          Text(
            question.body,
            style: const TextStyle(
              color: _kTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Difficulty + Status badges
          Row(
            children: [
              _DifficultyBadge(difficulty: question.difficulty),
              const SizedBox(width: 8),
              _StatusBadge(status: question.status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 10),
          // Footer: marks + date + avatar
          Row(
            children: [
              _MarksLabel(
                correct: question.marksCorrect,
                wrong: question.marksWrong,
              ),
              const SizedBox(width: 20),
              _DateLabel(date: question.createdAt),
              const Spacer(),
              // Creator avatar placeholder
              CircleAvatar(
                radius: 16,
                backgroundColor: _kPrimaryLight,
                child: Text(
                  'A',
                  style: TextStyle(
                    color: _kPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Subject chip ─────────────────────────────────────────────

class _SubjectChip extends StatelessWidget {
  final String subject;
  const _SubjectChip({required this.subject});

  @override
  Widget build(BuildContext context) {
    final bg = _kSubjectColors[subject] ?? _kPrimaryLight;
    final fg = _kSubjectTextColors[subject] ?? _kPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        subject,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Chapter chip ─────────────────────────────────────────────

class _ChapterChip extends StatelessWidget {
  final String chapter;
  const _ChapterChip({required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        chapter,
        style: const TextStyle(
          color: _kTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Overflow menu ────────────────────────────────────────────

class _OverflowMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final bool isActive;

  const _OverflowMenu({
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: _kTextSecondary, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit Question'),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: _MenuRow(
            icon: isActive
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            label: isActive ? 'Mark Inactive' : 'Mark Active',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: _MenuRow(
            icon: Icons.delete_outline,
            label: 'Delete',
            isDestructive: true,
          ),
        ),
      ],
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
        if (v == 'toggle') onToggleStatus();
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? _kHardRed : _kTextPrimary;
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Difficulty badge ─────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  final Difficulty difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (difficulty) {
      case Difficulty.easy:
        color = _kEasyGreen;
        icon = Icons.check;
        label = 'Easy';
        break;
      case Difficulty.medium:
        color = _kMediumOrange;
        icon = Icons.trending_up;
        label = 'Medium';
        break;
      case Difficulty.hard:
        color = _kHardRed;
        icon = Icons.bar_chart;
        label = 'Hard';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status badge ─────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final QuestionStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    String label;

    switch (status) {
      case QuestionStatus.active:
        dotColor = _kEasyGreen;
        label = 'Active';
        break;
      case QuestionStatus.inactive:
        dotColor = _kTextSecondary;
        label = 'Inactive';
        break;
      case QuestionStatus.draft:
        dotColor = _kMediumOrange;
        label = 'Draft';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: dotColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Marks label ──────────────────────────────────────────────

class _MarksLabel extends StatelessWidget {
  final double correct;
  final double wrong;

  const _MarksLabel({required this.correct, required this.wrong});

  @override
  Widget build(BuildContext context) {
    final wrongStr = wrong == 0
        ? '0'
        : wrong.toString().replaceAll(RegExp(r'\.0$'), '');
    final correctStr = correct.toString().replaceAll(RegExp(r'\.0$'), '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MARKS',
          style: TextStyle(
            color: _kTextSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '+$correctStr / $wrongStr',
          style: const TextStyle(
            color: _kTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Date label ───────────────────────────────────────────────

class _DateLabel extends StatelessWidget {
  final DateTime date;
  const _DateLabel({required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CREATED',
          style: TextStyle(
            color: _kTextSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('MMM dd, yyyy').format(date),
          style: const TextStyle(
            color: _kTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ADD / EDIT QUESTION BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _AddEditQuestionSheet extends ConsumerStatefulWidget {
  final QuestionModel? existingQuestion;
  const _AddEditQuestionSheet({this.existingQuestion});

  @override
  ConsumerState<_AddEditQuestionSheet> createState() =>
      _AddEditQuestionSheetState();
}

class _AddEditQuestionSheetState extends ConsumerState<_AddEditQuestionSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _bodyCtrl;
  late final TextEditingController _optionACtrl;
  late final TextEditingController _optionBCtrl;
  late final TextEditingController _optionCCtrl;
  late final TextEditingController _optionDCtrl;

  String _selectedSubject = 'physics';
  String _selectedChapter = '';
  String _correctOption = 'a';
  Difficulty _difficulty = Difficulty.medium;
  double _marksCorrect = 2.0;
  double _marksWrong = -0.5;
  bool _isLoading = false;

  final List<String> _subjects = ['physics', 'chemistry', 'maths', 'biology'];

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuestion;
    _bodyCtrl = TextEditingController(text: q?.body ?? '');
    _optionACtrl = TextEditingController();
    _optionBCtrl = TextEditingController();
    _optionCCtrl = TextEditingController();
    _optionDCtrl = TextEditingController();
    if (q != null) {
      _selectedSubject = q.subject.toLowerCase();
      _selectedChapter = q.chapter;
      _difficulty = q.difficulty;
      _marksCorrect = q.marksCorrect;
      _marksWrong = q.marksWrong;
    }
  }

  @override
  void dispose() {
    _bodyCtrl.dispose();
    _optionACtrl.dispose();
    _optionBCtrl.dispose();
    _optionCCtrl.dispose();
    _optionDCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingQuestion != null;
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Question' : 'Add Question',
                    style: const TextStyle(
                      color: _kTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: _kTextSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(color: _kBorder),
            // Form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject + Chapter row
                      Row(
                        children: [
                          Expanded(child: _buildSubjectPicker()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildChapterField()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Question body
                      _buildSectionLabel('Question'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _bodyCtrl,
                        maxLines: 4,
                        decoration: _inputDecor(
                          'Enter question text (LaTeX supported)',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      // Options
                      _buildSectionLabel('Options'),
                      const SizedBox(height: 8),
                      ...['a', 'b', 'c', 'd'].map((key) {
                        final ctrl = {
                          'a': _optionACtrl,
                          'b': _optionBCtrl,
                          'c': _optionCCtrl,
                          'd': _optionDCtrl,
                        }[key]!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _correctOption = key),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _correctOption == key
                                        ? _kPrimary
                                        : _kBackground,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _correctOption == key
                                          ? _kPrimary
                                          : _kBorder,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      key.toUpperCase(),
                                      style: TextStyle(
                                        color: _correctOption == key
                                            ? Colors.white
                                            : _kTextSecondary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: ctrl,
                                  decoration: _inputDecor(
                                    'Option ${key.toUpperCase()}',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      // Difficulty
                      _buildSectionLabel('Difficulty'),
                      const SizedBox(height: 8),
                      Row(
                        children: Difficulty.values.map((d) {
                          final isSelected = _difficulty == d;
                          Color color;
                          switch (d) {
                            case Difficulty.easy:
                              color = _kEasyGreen;
                              break;
                            case Difficulty.medium:
                              color = _kMediumOrange;
                              break;
                            case Difficulty.hard:
                              color = _kHardRed;
                              break;
                          }
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: d != Difficulty.hard ? 8 : 0,
                              ),
                              child: GestureDetector(
                                onTap: () => setState(() => _difficulty = d),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withOpacity(0.12)
                                        : _kBackground,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? color : _kBorder,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      d.name[0].toUpperCase() +
                                          d.name.substring(1),
                                      style: TextStyle(
                                        color: isSelected
                                            ? color
                                            : _kTextSecondary,
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Marks
                      _buildSectionLabel('Marking Scheme'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMarksField(
                              label: 'Correct (+)',
                              value: _marksCorrect,
                              onChanged: (v) =>
                                  setState(() => _marksCorrect = v),
                              isPositive: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMarksField(
                              label: 'Wrong (−)',
                              value: _marksWrong,
                              onChanged: (v) => setState(() => _marksWrong = v),
                              isPositive: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  isEdit ? 'Update Question' : 'Add Question',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Subject'),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _kBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSubject,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _kTextSecondary,
                size: 20,
              ),
              style: const TextStyle(color: _kTextPrimary, fontSize: 13),
              items: _subjects
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s[0].toUpperCase() + s.substring(1)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedSubject = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Chapter'),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _selectedChapter,
          decoration: _inputDecor('e.g. Rotation'),
          onChanged: (v) => _selectedChapter = v,
        ),
      ],
    );
  }

  Widget _buildMarksField({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required bool isPositive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _kTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value.toString(),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: _inputDecor(isPositive ? '+2.00' : '-0.50'),
          onChanged: (v) => onChanged(double.tryParse(v) ?? value),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _kTextPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
      filled: true,
      fillColor: _kBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kHardRed),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // TODO: replace with actual Supabase insert / update
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingQuestion != null
                ? 'Question updated successfully'
                : 'Question added successfully',
          ),
          backgroundColor: _kEasyGreen,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  ADVANCED FILTER SHEET
// ─────────────────────────────────────────────────────────────

class _AdvancedFilterSheet extends ConsumerWidget {
  const _AdvancedFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Filter Questions',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sort by',
            style: TextStyle(
              color: _kTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: ['Newest First', 'Oldest First', 'Difficulty']
                .map(
                  (label) => ChoiceChip(
                    label: Text(label),
                    selected: label == 'Newest First',
                    selectedColor: _kPrimaryLight,
                    labelStyle: TextStyle(
                      color: label == 'Newest First'
                          ? _kPrimary
                          : _kTextSecondary,
                      fontWeight: label == 'Newest First'
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: label == 'Newest First' ? _kPrimary : _kBorder,
                      ),
                    ),
                    onSelected: (_) {},
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(subjectFilterProvider.notifier).state =
                        SubjectFilter.all;
                    ref.read(difficultyFilterProvider.notifier).state =
                        DifficultyFilter.all;
                    ref.read(statusFilterProvider.notifier).state =
                        StatusFilter.all;
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: _kBorder),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: _kTextSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
