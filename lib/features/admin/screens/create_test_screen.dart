import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class Subject {
  final String id;
  final String name;
  final String label;
  Subject({required this.id, required this.name, required this.label});
  factory Subject.fromMap(Map<String, dynamic> m) =>
      Subject(id: m['id'], name: m['name'], label: m['label']);
}

class Chapter {
  final String id;
  final String name;
  final int chapterNo;
  Chapter({required this.id, required this.name, required this.chapterNo});
  factory Chapter.fromMap(Map<String, dynamic> m) =>
      Chapter(id: m['id'], name: m['name'], chapterNo: m['chapter_no']);
}

class Topic {
  final String id;
  final String name;
  Topic({required this.id, required this.name});
  factory Topic.fromMap(Map<String, dynamic> m) =>
      Topic(id: m['id'], name: m['name']);
}

class QuestionItem {
  final String id;
  final String body;
  final String difficulty; // 'easy','medium','hard'
  final int difficultyNum;
  final String chapterName;
  final String topicName;
  final int questionNo; // display number

  QuestionItem({
    required this.id,
    required this.body,
    required this.difficulty,
    required this.difficultyNum,
    required this.chapterName,
    required this.topicName,
    required this.questionNo,
  });

  factory QuestionItem.fromMap(Map<String, dynamic> m) {
    final diff = m['difficulty'] as int? ?? 3;
    String diffLabel;
    if (diff <= 2) {
      diffLabel = 'easy';
    } else if (diff <= 3) {
      diffLabel = 'medium';
    } else {
      diffLabel = 'hard';
    }
    final topic = m['topics'] as Map<String, dynamic>?;
    final chapter = topic?['chapters'] as Map<String, dynamic>?;
    return QuestionItem(
      id: m['id'],
      body: m['body'],
      difficulty: diffLabel,
      difficultyNum: diff,
      chapterName: chapter?['name'] ?? '',
      topicName: topic?['name'] ?? '',
      questionNo: 0,
    );
  }
}

// ─── Enums ────────────────────────────────────────────────────────────────────

enum TestTypeOption { subject, fullPcm, fullPcb }

extension TestTypeOptionX on TestTypeOption {
  String get label {
    switch (this) {
      case TestTypeOption.subject:
        return 'Subject Test';
      case TestTypeOption.fullPcm:
        return 'Full PCM';
      case TestTypeOption.fullPcb:
        return 'Full PCB';
    }
  }

  int get durationMinutes {
    return this == TestTypeOption.subject ? 60 : 180;
  }

  int get totalQuestions {
    return this == TestTypeOption.subject ? 30 : 90;
  }

  bool get needsSubject => this == TestTypeOption.subject;
}

// ─── Providers ────────────────────────────────────────────────────────────────

final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final data = await Supabase.instance.client
      .from('subjects')
      .select('id, name, label')
      .order('label');
  return (data as List).map((e) => Subject.fromMap(e)).toList();
});

final chaptersProvider = FutureProvider.family<List<Chapter>, String>((
  ref,
  subjectId,
) async {
  final data = await Supabase.instance.client
      .from('chapters')
      .select('id, name, chapter_no')
      .eq('subject_id', subjectId)
      .order('chapter_no');
  return (data as List).map((e) => Chapter.fromMap(e)).toList();
});

final topicsProvider = FutureProvider.family<List<Topic>, String>((
  ref,
  chapterId,
) async {
  final data = await Supabase.instance.client
      .from('topics')
      .select('id, name')
      .eq('chapter_id', chapterId)
      .order('topic_no');
  return (data as List).map((e) => Topic.fromMap(e)).toList();
});

// Question pool provider — filtered by subject + optional chapter/topic/difficulty/search
class QuestionPoolParams {
  final String? subjectId;
  final String? chapterId;
  final String? topicId;
  final int? difficulty; // null = all
  final String search;
  final int limit;

  const QuestionPoolParams({
    this.subjectId,
    this.chapterId,
    this.topicId,
    this.difficulty,
    this.search = '',
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      other is QuestionPoolParams &&
      other.subjectId == subjectId &&
      other.chapterId == chapterId &&
      other.topicId == topicId &&
      other.difficulty == difficulty &&
      other.search == search &&
      other.limit == limit;

  @override
  int get hashCode =>
      Object.hash(subjectId, chapterId, topicId, difficulty, search, limit);
}

final questionPoolProvider =
    FutureProvider.family<List<QuestionItem>, QuestionPoolParams>((
      ref,
      params,
    ) async {
      var query = Supabase.instance.client
          .from('questions')
          .select(
            'id, body, difficulty, topics(id, name, chapters(id, name, subject_id))',
          )
          .eq('is_active', true);

      if (params.subjectId != null) {
        // Filter by subject via topics→chapters→subject_id
        // Use a subquery-style filter via topics.chapters.subject_id
        // Supabase doesn't support deep filter directly; filter client-side after fetch
      }
      if (params.difficulty != null) {
        // map label back to range
        if (params.difficulty == 1) {
          query = query.lte('difficulty', 2);
        } else if (params.difficulty == 2) {
          query = query.eq('difficulty', 3);
        } else {
          query = query.gte('difficulty', 4);
        }
      }
      if (params.search.isNotEmpty) {
        query = query.ilike('body', '%${params.search}%');
      }

      final data = await query.order('created_at', ascending: false).limit(50);
      var items = (data as List).map((e) => QuestionItem.fromMap(e)).toList();

      // Client-side subject filter
      if (params.subjectId != null) {
        items = items.where((q) {
          final topic =
              (data.firstWhere(
                    (d) => d['id'] == q.id,
                    orElse: () => <String, dynamic>{},
                  )
                  as Map<String, dynamic>);
          final chapterMap =
              (topic['topics'] as Map<String, dynamic>?)?['chapters']
                  as Map<String, dynamic>?;
          return chapterMap?['subject_id'] == params.subjectId;
        }).toList();
      }

      // Add display numbers
      return items
          .take(params.limit)
          .toList()
          .asMap()
          .entries
          .map(
            (e) => QuestionItem(
              id: e.value.id,
              body: e.value.body,
              difficulty: e.value.difficulty,
              difficultyNum: e.value.difficultyNum,
              chapterName: e.value.chapterName,
              topicName: e.value.topicName,
              questionNo: 1000 + e.key + 1,
            ),
          )
          .toList();
    });

// ─── Form State ───────────────────────────────────────────────────────────────

class NewTestFormState {
  final String title;
  final TestTypeOption testType;
  final Subject? selectedSubject;
  final String instructions;
  final String search;
  final int? filterDifficulty; // 1=easy,2=medium,3=hard
  final String? filterChapterId;
  final String? filterTopicId;
  final List<QuestionItem> selectedQuestions;
  final bool publishImmediately;
  final bool isSaving;

  const NewTestFormState({
    this.title = '',
    this.testType = TestTypeOption.subject,
    this.selectedSubject,
    this.instructions = '',
    this.search = '',
    this.filterDifficulty,
    this.filterChapterId,
    this.filterTopicId,
    this.selectedQuestions = const [],
    this.publishImmediately = true,
    this.isSaving = false,
  });

  int get maxQuestions => testType.totalQuestions;
  bool get isFull => selectedQuestions.length >= maxQuestions;

  bool isSelected(String questionId) =>
      selectedQuestions.any((q) => q.id == questionId);

  NewTestFormState copyWith({
    String? title,
    TestTypeOption? testType,
    Subject? selectedSubject,
    bool clearSubject = false,
    String? instructions,
    String? search,
    int? filterDifficulty,
    bool clearDifficulty = false,
    String? filterChapterId,
    bool clearChapter = false,
    String? filterTopicId,
    bool clearTopic = false,
    List<QuestionItem>? selectedQuestions,
    bool? publishImmediately,
    bool? isSaving,
  }) {
    return NewTestFormState(
      title: title ?? this.title,
      testType: testType ?? this.testType,
      selectedSubject: clearSubject
          ? null
          : (selectedSubject ?? this.selectedSubject),
      instructions: instructions ?? this.instructions,
      search: search ?? this.search,
      filterDifficulty: clearDifficulty
          ? null
          : (filterDifficulty ?? this.filterDifficulty),
      filterChapterId: clearChapter
          ? null
          : (filterChapterId ?? this.filterChapterId),
      filterTopicId: clearTopic ? null : (filterTopicId ?? this.filterTopicId),
      selectedQuestions: selectedQuestions ?? this.selectedQuestions,
      publishImmediately: publishImmediately ?? this.publishImmediately,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class NewTestNotifier extends StateNotifier<NewTestFormState> {
  NewTestNotifier() : super(const NewTestFormState());

  void setTitle(String v) => state = state.copyWith(title: v);

  void setTestType(TestTypeOption t) =>
      state = state.copyWith(testType: t, clearSubject: true);

  void setSubject(Subject? s) =>
      state = state.copyWith(selectedSubject: s, clearSubject: s == null);

  void setInstructions(String v) => state = state.copyWith(instructions: v);

  void setSearch(String v) => state = state.copyWith(search: v);

  void setFilterDifficulty(int? v) => state = v == null
      ? state.copyWith(clearDifficulty: true)
      : state.copyWith(filterDifficulty: v);

  void setFilterChapter(String? v) => state = v == null
      ? state.copyWith(clearChapter: true)
      : state.copyWith(filterChapterId: v);

  void toggleQuestion(QuestionItem q) {
    final current = List<QuestionItem>.from(state.selectedQuestions);
    if (current.any((s) => s.id == q.id)) {
      current.removeWhere((s) => s.id == q.id);
    } else {
      if (current.length < state.maxQuestions) {
        current.add(q);
      }
    }
    state = state.copyWith(selectedQuestions: current);
  }

  void removeQuestion(String id) {
    final current = List<QuestionItem>.from(state.selectedQuestions)
      ..removeWhere((q) => q.id == id);
    state = state.copyWith(selectedQuestions: current);
  }

  void setPublish(bool v) => state = state.copyWith(publishImmediately: v);

  Future<void> createTest(BuildContext context, String adminUserId) async {
    final s = state;
    if (s.isSaving) return;
    state = state.copyWith(isSaving: true);

    try {
      final testTypeStr = s.testType == TestTypeOption.subject
          ? 'subject'
          : s.testType == TestTypeOption.fullPcm
          ? 'full_pcm'
          : 'full_pcb';

      // Insert test
      final testResult = await Supabase.instance.client
          .from('tests')
          .insert({
            'title': s.title.trim(),
            'test_type': testTypeStr,
            'subject_id': s.testType.needsSubject
                ? s.selectedSubject?.id
                : null,
            'duration_minutes': s.testType.durationMinutes,
            'total_questions': s.testType.totalQuestions,
            'instructions': s.instructions.trim().isEmpty
                ? null
                : s.instructions.trim(),
            'is_published': s.publishImmediately,
            'created_by': adminUserId,
          })
          .select('id')
          .single();

      final testId = testResult['id'] as String;

      // Insert test_questions
      final questionRows = s.selectedQuestions
          .asMap()
          .entries
          .map(
            (e) => {
              'test_id': testId,
              'question_id': e.value.id,
              'position': e.key + 1,
            },
          )
          .toList();

      if (questionRows.isNotEmpty) {
        await Supabase.instance.client
            .from('test_questions')
            .insert(questionRows);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test created successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context, testId);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final newTestProvider =
    StateNotifierProvider.autoDispose<NewTestNotifier, NewTestFormState>(
      (ref) => NewTestNotifier(),
    );

// ─── Screen ───────────────────────────────────────────────────────────────────

class NewTestScreen extends ConsumerStatefulWidget {
  const NewTestScreen({super.key});

  @override
  ConsumerState<NewTestScreen> createState() => _NewTestScreenState();
}

class _NewTestScreenState extends ConsumerState<NewTestScreen> {
  final _titleCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String get _adminUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instructionsCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _validate(NewTestFormState s) {
    if (s.title.trim().isEmpty) {
      _showError('Please enter a test title');
      return false;
    }
    if (s.testType.needsSubject && s.selectedSubject == null) {
      _showError('Please select a subject for this test type');
      return false;
    }
    if (s.selectedQuestions.isEmpty) {
      _showError('Please add at least one question');
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(newTestProvider);
    final notifier = ref.read(newTestProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Academic Test',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded, color: Color(0xFF4F46E5)),
            onPressed: formState.isSaving
                ? null
                : () {
                    if (_validate(formState)) {
                      notifier.createTest(context, _adminUserId);
                    }
                  },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TestInfoCard(
            formState: formState,
            notifier: notifier,
            titleCtrl: _titleCtrl,
            instructionsCtrl: _instructionsCtrl,
          ),
          const SizedBox(height: 12),
          _SchemaConstraintsBanner(formState: formState),
          const SizedBox(height: 16),
          _PickQuestionsCard(
            formState: formState,
            notifier: notifier,
            searchCtrl: _searchCtrl,
          ),
          const SizedBox(height: 16),
          _SelectedQuestionsCard(formState: formState, notifier: notifier),
          const SizedBox(height: 16),
          _PublishToggleCard(formState: formState, notifier: notifier),
          const SizedBox(height: 24),
          _CreateTestButton(
            isSaving: formState.isSaving,
            onTap: () {
              if (_validate(formState)) {
                notifier.createTest(context, _adminUserId);
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Test Info Card ───────────────────────────────────────────────────────────

class _TestInfoCard extends ConsumerWidget {
  final NewTestFormState formState;
  final NewTestNotifier notifier;
  final TextEditingController titleCtrl;
  final TextEditingController instructionsCtrl;

  const _TestInfoCard({
    required this.formState,
    required this.notifier,
    required this.titleCtrl,
    required this.instructionsCtrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return _SectionCard(
      icon: Icons.description_rounded,
      iconColor: const Color(0xFF4F46E5),
      title: 'Test Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _FieldLabel('TEST TITLE'),
          const SizedBox(height: 6),
          _StyledTextField(
            controller: titleCtrl,
            hint: 'e.g. Mid-term Physics Assessment',
            onChanged: notifier.setTitle,
          ),
          const SizedBox(height: 14),

          // Test Type + Subject row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('TEST TYPE'),
                    const SizedBox(height: 6),
                    _StyledDropdown<TestTypeOption>(
                      hint: 'Select',
                      value: formState.testType,
                      items: TestTypeOption.values,
                      itemLabel: (t) => t.label,
                      onChanged: (t) {
                        if (t != null) notifier.setTestType(t);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('SUBJECT'),
                    const SizedBox(height: 6),
                    if (!formState.testType.needsSubject)
                      _DisabledField(
                        label: formState.testType == TestTypeOption.fullPcm
                            ? 'PCM'
                            : 'PCB',
                      )
                    else
                      subjectsAsync.when(
                        data: (subjects) => _StyledDropdown<Subject>(
                          hint: 'Subject',
                          value: formState.selectedSubject,
                          items: subjects,
                          itemLabel: (s) => s.label,
                          onChanged: (s) => notifier.setSubject(s),
                        ),
                        loading: () => const _LoadingField(),
                        error: (_, __) => const _DisabledField(label: 'Error'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Duration + Questions row (read-only derived)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('DURATION'),
                    const SizedBox(height: 6),
                    _InfoChip(
                      icon: Icons.timer_rounded,
                      label: '${formState.testType.durationMinutes} Mins',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('TOTAL QUESTIONS'),
                    const SizedBox(height: 6),
                    _InfoChip(
                      icon: Icons.quiz_rounded,
                      label: '${formState.testType.totalQuestions} Qs',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Instructions
          _FieldLabel('INSTRUCTIONS'),
          const SizedBox(height: 6),
          TextField(
            controller: instructionsCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              hintText: 'Add specific guidelines for students...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            onChanged: notifier.setInstructions,
          ),
        ],
      ),
    );
  }
}

// ─── Schema Constraints Banner ────────────────────────────────────────────────

class _SchemaConstraintsBanner extends StatelessWidget {
  final NewTestFormState formState;
  const _SchemaConstraintsBanner({required this.formState});

  @override
  Widget build(BuildContext context) {
    String msg;
    switch (formState.testType) {
      case TestTypeOption.subject:
        msg =
            'Subject tests are limited to 30 questions. All questions must be from the same selected subject.';
        break;
      case TestTypeOption.fullPcm:
        msg =
            'Full PCM tests require exactly 90 questions — 30 each from Physics, Chemistry, and Mathematics.';
        break;
      case TestTypeOption.fullPcb:
        msg =
            'Full PCB tests require exactly 90 questions — 30 each from Physics, Chemistry, and Biology.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFCBFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, color: Color(0xFF4F46E5), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schema Constraints Applied',
                  style: TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  msg,
                  style: const TextStyle(
                    color: Color(0xFF5555AA),
                    fontSize: 12,
                    height: 1.4,
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

// ─── Pick Questions Card ──────────────────────────────────────────────────────

class _PickQuestionsCard extends ConsumerStatefulWidget {
  final NewTestFormState formState;
  final NewTestNotifier notifier;
  final TextEditingController searchCtrl;

  const _PickQuestionsCard({
    required this.formState,
    required this.notifier,
    required this.searchCtrl,
  });

  @override
  ConsumerState<_PickQuestionsCard> createState() => _PickQuestionsCardState();
}

class _PickQuestionsCardState extends ConsumerState<_PickQuestionsCard> {
  int _visibleLimit = 5;

  @override
  Widget build(BuildContext context) {
    final params = QuestionPoolParams(
      subjectId: widget.formState.selectedSubject?.id,
      difficulty: widget.formState.filterDifficulty,
      search: widget.formState.search,
      limit: _visibleLimit,
    );
    final questionsAsync = ref.watch(questionPoolProvider(params));

    // Chapter filter list
    final chaptersAsync = widget.formState.selectedSubject != null
        ? ref.watch(chaptersProvider(widget.formState.selectedSubject!.id))
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.library_add_rounded,
                  color: Color(0xFFE67E22),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Pick Questions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              questionsAsync.when(
                data: (questions) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'POOL: ${questions.length}+',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF555580),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: widget.searchCtrl,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                hintText: 'Search by topic or keywords...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: widget.notifier.setSearch,
            ),
          ),
          const SizedBox(height: 10),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Difficulty',
                  options: const ['Easy', 'Medium', 'Hard'],
                  selectedIndex: widget.formState.filterDifficulty != null
                      ? widget.formState.filterDifficulty! - 1
                      : null,
                  onSelected: (i) => widget.notifier.setFilterDifficulty(
                    i == null ? null : i + 1,
                  ),
                ),
                const SizedBox(width: 8),
                if (chaptersAsync != null)
                  chaptersAsync.when(
                    data: (chapters) => _FilterChip(
                      label: 'Chapter',
                      options: chapters
                          .map((c) => 'Ch ${c.chapterNo}: ${c.name}')
                          .toList(),
                      selectedIndex: widget.formState.filterChapterId != null
                          ? chapters.indexWhere(
                              (c) => c.id == widget.formState.filterChapterId,
                            )
                          : null,
                      onSelected: (i) => widget.notifier.setFilterChapter(
                        i == null ? null : chapters[i].id,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  )
                else
                  _FilterChip(
                    label: 'Chapter',
                    options: const [],
                    selectedIndex: null,
                    onSelected: (_) {},
                  ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Topic',
                  options: const [],
                  selectedIndex: null,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Question list
          questionsAsync.when(
            data: (questions) {
              if (questions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No questions found.\nTry adjusting your filters.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  ...questions.map(
                    (q) => _QuestionPoolItem(
                      question: q,
                      isSelected: widget.formState.isSelected(q.id),
                      isFull:
                          widget.formState.isFull &&
                          !widget.formState.isSelected(q.id),
                      onTap: () => widget.notifier.toggleQuestion(q),
                    ),
                  ),
                  if (questions.length >= _visibleLimit)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _visibleLimit += 10),
                        child: const Text(
                          'View More Questions',
                          style: TextStyle(
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Error loading questions: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Question Pool Item ───────────────────────────────────────────────────────

class _QuestionPoolItem extends StatelessWidget {
  final QuestionItem question;
  final bool isSelected;
  final bool isFull;
  final VoidCallback onTap;

  const _QuestionPoolItem({
    required this.question,
    required this.isSelected,
    required this.isFull,
    required this.onTap,
  });

  Color get _diffColor {
    switch (question.difficulty) {
      case 'easy':
        return const Color(0xFF27AE60);
      case 'medium':
        return const Color(0xFFE67E22);
      default:
        return const Color(0xFFE53935);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF4F46E5).withOpacity(0.4)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _diffColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        question.difficulty.toUpperCase(),
                        style: TextStyle(
                          color: _diffColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '#${question.questionNo} • ${question.topicName.isNotEmpty ? question.topicName : question.chapterName}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  question.body.length > 70
                      ? '${question.body.substring(0, 70)}...'
                      : question.body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A2E),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isFull ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF27AE60)
                    : isFull
                    ? Colors.grey.shade300
                    : const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.add_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Selected Questions Card ──────────────────────────────────────────────────

class _SelectedQuestionsCard extends StatelessWidget {
  final NewTestFormState formState;
  final NewTestNotifier notifier;

  const _SelectedQuestionsCard({
    required this.formState,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final count = formState.selectedQuestions.length;
    final max = formState.maxQuestions;
    final progress = max > 0 ? count / max : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.format_list_numbered_rounded,
                  color: Color(0xFF4F46E5),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Selected Questions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$count',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: count >= max
                            ? const Color(0xFF27AE60)
                            : const Color(0xFF4F46E5),
                      ),
                    ),
                    TextSpan(
                      text: ' / $max',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9090A0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE8E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                count >= max
                    ? const Color(0xFF27AE60)
                    : const Color(0xFF4F46E5),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),

          if (formState.selectedQuestions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No questions selected yet.\nAdd from the pool above.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: formState.selectedQuestions.length,
              onReorder: (oldIndex, newIndex) {
                final current = List<QuestionItem>.from(
                  formState.selectedQuestions,
                );
                if (newIndex > oldIndex) newIndex--;
                final item = current.removeAt(oldIndex);
                current.insert(newIndex, item);
                notifier.state = notifier.state.copyWith(
                  selectedQuestions: current,
                );
              },
              itemBuilder: (context, index) {
                final q = formState.selectedQuestions[index];
                return _SelectedQuestionItem(
                  key: ValueKey(q.id),
                  index: index,
                  question: q,
                  onRemove: () => notifier.removeQuestion(q.id),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SelectedQuestionItem extends StatelessWidget {
  final int index;
  final QuestionItem question;
  final VoidCallback onRemove;

  const _SelectedQuestionItem({
    super.key,
    required this.index,
    required this.question,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.drag_indicator_rounded,
            color: Color(0xFFBBBBCC),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.body.length > 55
                      ? '${question.body.substring(0, 55)}...'
                      : question.body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A2E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_capitalize(question.difficulty)} • ${question.topicName.isNotEmpty ? question.topicName : question.chapterName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFFE53935),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Publish Toggle Card ──────────────────────────────────────────────────────

class _PublishToggleCard extends StatelessWidget {
  final NewTestFormState formState;
  final NewTestNotifier notifier;

  const _PublishToggleCard({required this.formState, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.upload_rounded,
              color: Color(0xFF4F46E5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Publish Immediately',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Make visible to all assigned students',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Switch(
            value: formState.publishImmediately,
            onChanged: notifier.setPublish,
            activeColor: const Color(0xFF4F46E5),
          ),
        ],
      ),
    );
  }
}

// ─── Create Test Button ───────────────────────────────────────────────────────

class _CreateTestButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onTap;

  const _CreateTestButton({required this.isSaving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isSaving ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Create Test',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Filter Chip Widget ───────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final List<String> options;
  final int? selectedIndex;
  final void Function(int?) onSelected;

  const _FilterChip({
    required this.label,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selectedIndex != null;

    return GestureDetector(
      onTap: () {
        if (options.isEmpty) return;
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _FilterSheet(
            label: label,
            options: options,
            selectedIndex: selectedIndex,
            onSelected: (i) {
              Navigator.pop(context);
              onSelected(i);
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4F46E5).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF4F46E5) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isActive &&
                      selectedIndex != null &&
                      selectedIndex! < options.length
                  ? options[selectedIndex!]
                  : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF555580),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF9090A0),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final String label;
  final List<String> options;
  final int? selectedIndex;
  final void Function(int?) onSelected;

  const _FilterSheet({
    required this.label,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filter by $label',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (selectedIndex != null)
                TextButton(
                  onPressed: () => onSelected(null),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Color(0xFF4F46E5)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...options.asMap().entries.map(
            (e) => ListTile(
              title: Text(e.value),
              trailing: selectedIndex == e.key
                  ? const Icon(Icons.check_rounded, color: Color(0xFF4F46E5))
                  : null,
              onTap: () => onSelected(e.key),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final void Function(String) onChanged;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;

  const _StyledDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(
        hint,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),
      items: items
          .map(
            (i) => DropdownMenuItem<T>(
              value: i,
              child: Text(
                itemLabel(i),
                style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF9090A0),
      ),
      dropdownColor: Colors.white,
      isExpanded: true,
    );
  }
}

class _DisabledField extends StatelessWidget {
  final String label;
  const _DisabledField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      ),
    );
  }
}

class _LoadingField extends StatelessWidget {
  const _LoadingField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4F46E5),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Loading...',
            style: TextStyle(fontSize: 13, color: Color(0xFF9090A0)),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}
