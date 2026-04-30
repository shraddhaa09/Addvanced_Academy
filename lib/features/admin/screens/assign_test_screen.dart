import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────

class TestSummary {
  final String id;
  final String title;
  final String testType; // 'full_pcm' | 'full_pcb' | 'subject'
  final int durationMinutes;
  final int totalQuestions;

  const TestSummary({
    required this.id,
    required this.title,
    required this.testType,
    required this.durationMinutes,
    required this.totalQuestions,
  });

  factory TestSummary.fromJson(Map<String, dynamic> json) => TestSummary(
    id: json['id'] as String,
    title: json['title'] as String,
    testType: json['test_type'] as String,
    durationMinutes: json['duration_minutes'] as int,
    totalQuestions: json['total_questions'] as int,
  );

  String get typeLabel {
    switch (testType) {
      case 'full_pcm':
        return 'Full PCM';
      case 'full_pcb':
        return 'Full PCB';
      default:
        return 'Subject Test';
    }
  }

  int get totalMarks => totalQuestions * 2; // 2 marks per question (MHT-CET)
}

class StudentItem {
  final String id;
  final String name;
  final String email;
  final String batch;

  const StudentItem({
    required this.id,
    required this.name,
    required this.email,
    required this.batch,
  });

  factory StudentItem.fromJson(Map<String, dynamic> json) => StudentItem(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String? ?? '',
    batch: json['batch'] as String? ?? '',
  );
}

// ─────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────

final supabase = Supabase.instance.client;

// Fetch all published tests
final publishedTestsProvider = FutureProvider<List<TestSummary>>((ref) async {
  final res = await supabase
      .from('tests')
      .select('id, title, test_type, duration_minutes, total_questions')
      .eq('is_published', true)
      .order('created_at', ascending: false);
  return (res as List).map((e) => TestSummary.fromJson(e)).toList();
});

// Fetch all students
final allStudentsProvider = FutureProvider<List<StudentItem>>((ref) async {
  final res = await supabase
      .from('students')
      .select('id, name, batch, users!inner(email)')
      .order('name');
  return (res as List).map((e) {
    final userEmail = (e['users'] as Map?)?['email'] as String? ?? '';
    return StudentItem(
      id: e['id'] as String,
      name: e['name'] as String,
      email: userEmail,
      batch: e['batch'] as String? ?? '',
    );
  }).toList();
});

// Fetch distinct batches
final batchListProvider = FutureProvider<List<String>>((ref) async {
  final res = await supabase.from('students').select('batch');
  final batches =
      (res as List).map((e) => e['batch'] as String).toSet().toList()..sort();
  return batches;
});

// ─────────────────────────────────────────
//  STATE NOTIFIER
// ─────────────────────────────────────────

enum AssignmentMethod { individual, entireBatch }

class AssignTestState {
  final TestSummary? selectedTest;
  final AssignmentMethod method;
  final String? selectedBatch;
  final Set<String> selectedStudentIds;
  final DateTime? dueDate;
  final String searchQuery;
  final bool isAssigning;

  const AssignTestState({
    this.selectedTest,
    this.method = AssignmentMethod.individual,
    this.selectedBatch,
    this.selectedStudentIds = const {},
    this.dueDate,
    this.searchQuery = '',
    this.isAssigning = false,
  });

  AssignTestState copyWith({
    TestSummary? selectedTest,
    AssignmentMethod? method,
    String? selectedBatch,
    Set<String>? selectedStudentIds,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? searchQuery,
    bool? isAssigning,
  }) {
    return AssignTestState(
      selectedTest: selectedTest ?? this.selectedTest,
      method: method ?? this.method,
      selectedBatch: selectedBatch ?? this.selectedBatch,
      selectedStudentIds: selectedStudentIds ?? this.selectedStudentIds,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      searchQuery: searchQuery ?? this.searchQuery,
      isAssigning: isAssigning ?? this.isAssigning,
    );
  }
}

class AssignTestNotifier extends StateNotifier<AssignTestState> {
  AssignTestNotifier() : super(const AssignTestState());

  void selectTest(TestSummary test) {
    state = state.copyWith(selectedTest: test);
  }

  void setMethod(AssignmentMethod method) {
    state = state.copyWith(
      method: method,
      selectedStudentIds: {},
      selectedBatch: null,
    );
  }

  void selectBatch(String batch) {
    state = state.copyWith(selectedBatch: batch);
  }

  void toggleStudent(String studentId) {
    final current = Set<String>.from(state.selectedStudentIds);
    if (current.contains(studentId)) {
      current.remove(studentId);
    } else {
      current.add(studentId);
    }
    state = state.copyWith(selectedStudentIds: current);
  }

  void selectAllFiltered(List<StudentItem> students) {
    final ids = students.map((s) => s.id).toSet();
    state = state.copyWith(selectedStudentIds: ids);
  }

  void clearSelection() {
    state = state.copyWith(selectedStudentIds: {});
  }

  void setDueDate(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearDueDate: true);
    } else {
      state = state.copyWith(dueDate: date);
    }
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void reset() {
    state = const AssignTestState();
  }

  Future<void> assignTest({
    required List<StudentItem> allStudents,
    required String adminId,
    required VoidCallback onSuccess,
    required void Function(String) onError,
  }) async {
    if (state.selectedTest == null) {
      onError('Please select a test.');
      return;
    }

    List<String> targetIds;

    if (state.method == AssignmentMethod.entireBatch) {
      if (state.selectedBatch == null) {
        onError('Please select a batch.');
        return;
      }
      targetIds = allStudents
          .where((s) => s.batch == state.selectedBatch)
          .map((s) => s.id)
          .toList();
    } else {
      targetIds = state.selectedStudentIds.toList();
    }

    if (targetIds.isEmpty) {
      onError('No students selected.');
      return;
    }

    state = state.copyWith(isAssigning: true);

    try {
      if (state.method == AssignmentMethod.entireBatch &&
          state.selectedBatch != null) {
        // Use batch function
        await supabase.rpc(
          'assign_test_to_batch',
          params: {
            'p_test_id': state.selectedTest!.id,
            'p_batch': state.selectedBatch,
            'p_admin_id': adminId,
            'p_due_at': state.dueDate?.toIso8601String(),
          },
        );
      } else {
        // Individual inserts
        final rows = targetIds
            .map(
              (sid) => {
                'test_id': state.selectedTest!.id,
                'student_id': sid,
                'assigned_by': adminId,
                if (state.dueDate != null)
                  'due_at': state.dueDate!.toIso8601String(),
              },
            )
            .toList();

        await supabase
            .from('test_assignments')
            .upsert(rows, onConflict: 'test_id,student_id');
      }

      state = state.copyWith(isAssigning: false);
      onSuccess();
    } on PostgrestException catch (e) {
      state = state.copyWith(isAssigning: false);
      onError(e.message);
    } catch (e) {
      state = state.copyWith(isAssigning: false);
      onError(e.toString());
    }
  }
}


final assignTestProvider =
    StateNotifierProvider.autoDispose<AssignTestNotifier, AssignTestState>(
      (ref) => AssignTestNotifier(),
    );

// ─────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────

class AssignTestScreen extends ConsumerWidget {
  const AssignTestScreen({super.key, required this.testId});
  final String testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Assign Test',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Color(0xFF1A1A2E),
            ),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE8E8F0),
              child: const Icon(
                Icons.person,
                color: Color(0xFF5B5EA6),
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: const _AssignTestBody(),
    );
  }
}

class _AssignTestBody extends ConsumerWidget {
  const _AssignTestBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsync = ref.watch(publishedTestsProvider);
    final studentsAsync = ref.watch(allStudentsProvider);
    final batchesAsync = ref.watch(batchListProvider);
    final state = ref.watch(assignTestProvider);
    final notifier = ref.read(assignTestProvider.notifier);

    return testsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tests) => studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (students) => batchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (batches) {
            // Filtered students for individual selection
            final filtered = students.where((s) {
              final q = state.searchQuery.toLowerCase();
              return q.isEmpty ||
                  s.name.toLowerCase().contains(q) ||
                  s.email.toLowerCase().contains(q) ||
                  s.batch.toLowerCase().contains(q);
            }).toList();

            // Students in selected batch (for batch summary count)
            final batchStudents = state.selectedBatch != null
                ? students.where((s) => s.batch == state.selectedBatch).toList()
                : <StudentItem>[];

            final studentCount = state.method == AssignmentMethod.entireBatch
                ? batchStudents.length
                : state.selectedStudentIds.length;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Select Test ──────────────────────
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel('SELECT TEST'),
                              const SizedBox(height: 10),
                              _TestDropdown(
                                tests: tests,
                                selected: state.selectedTest,
                                onChanged: notifier.selectTest,
                              ),
                              if (state.selectedTest != null) ...[
                                const SizedBox(height: 12),
                                _TestDetailsCard(test: state.selectedTest!),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Assignment Method ─────────────────
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel('ASSIGNMENT METHOD'),
                              const SizedBox(height: 12),
                              _MethodToggle(
                                selected: state.method,
                                onChanged: notifier.setMethod,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Student Selection ─────────────────
                        if (state.method == AssignmentMethod.entireBatch)
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel('SELECT BATCH'),
                                const SizedBox(height: 12),
                                _BatchDropdown(
                                  batches: batches,
                                  selected: state.selectedBatch,
                                  onChanged: notifier.selectBatch,
                                ),
                                if (state.selectedBatch != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${batchStudents.length} students in this batch',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF5B5EA6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        else
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _SectionLabel('SELECT STUDENTS'),
                                    if (state.selectedStudentIds.isNotEmpty)
                                      Text(
                                        '${state.selectedStudentIds.length} Selected',
                                        style: const TextStyle(
                                          color: Color(0xFF5B5EA6),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _SearchBar(onChanged: notifier.setSearchQuery),
                                const SizedBox(height: 8),
                                // Select all / deselect all row
                                if (filtered.isNotEmpty)
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () => notifier
                                            .selectAllFiltered(filtered),
                                        child: const Text(
                                          'Select All',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF5B5EA6),
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        '·',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      TextButton(
                                        onPressed: notifier.clearSelection,
                                        child: const Text(
                                          'Deselect All',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ...filtered.map(
                                  (student) => _StudentTile(
                                    student: student,
                                    isSelected: state.selectedStudentIds
                                        .contains(student.id),
                                    onToggle: () =>
                                        notifier.toggleStudent(student.id),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 14),

                        // ── Due Date ──────────────────────────
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel('DUE DATE (OPTIONAL)'),
                              const SizedBox(height: 12),
                              _DueDatePicker(
                                selected: state.dueDate,
                                onChanged: notifier.setDueDate,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Summary Card ──────────────────────
                        _AssignmentSummaryCard(
                          test: state.selectedTest,
                          method: state.method,
                          selectedBatch: state.selectedBatch,
                          studentCount: studentCount,
                          dueDate: state.dueDate,
                        ),

                        const SizedBox(height: 80), // space for bottom bar
                      ],
                    ),
                  ),
                ),

                // ── Bottom Action Bar ─────────────────
                _BottomBar(
                  isAssigning: state.isAssigning,
                  onReset: notifier.reset,
                  onAssign: () async {
                    final adminId = supabase.auth.currentUser?.id ?? '';
                    await notifier.assignTest(
                      allStudents: students,
                      adminId: adminId,
                      onSuccess: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Test assigned to $studentCount student(s) successfully!',
                            ),
                            backgroundColor: const Color(0xFF4CAF50),
                          ),
                        );
                        notifier.reset();
                      },
                      onError: (msg) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8E8EA8),
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Test Dropdown ──────────────────────────────────────────────
class _TestDropdown extends StatelessWidget {
  final List<TestSummary> tests;
  final TestSummary? selected;
  final void Function(TestSummary) onChanged;

  const _TestDropdown({
    required this.tests,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E8)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TestSummary>(
          value: selected,
          isExpanded: true,
          hint: const Text(
            'Select a test...',
            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5B5EA6)),
          items: tests
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    t.title,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Test Details Card ──────────────────────────────────────────
class _TestDetailsCard extends StatelessWidget {
  final TestSummary test;
  const _TestDetailsCard({required this.test});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF5B5EA6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.quiz_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF5B5EA6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _TestChip(
                      icon: Icons.group_outlined,
                      label: test.typeLabel,
                    ),
                    const SizedBox(width: 8),
                    _TestChip(
                      icon: Icons.timer_outlined,
                      label: '${test.durationMinutes} Mins',
                    ),
                    const SizedBox(width: 8),
                    _TestChip(
                      icon: Icons.format_list_numbered,
                      label: '${test.totalQuestions} Qs',
                    ),
                    const SizedBox(width: 8),
                    _TestChip(
                      icon: Icons.star_border_outlined,
                      label: '${test.totalMarks} Marks',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TestChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TestChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF8E8EA8)),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B6B8A)),
        ),
      ],
    );
  }
}

// ── Method Toggle ──────────────────────────────────────────────
class _MethodToggle extends StatelessWidget {
  final AssignmentMethod selected;
  final void Function(AssignmentMethod) onChanged;
  const _MethodToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MethodButton(
            icon: Icons.person_outline,
            label: 'Individual',
            isSelected: selected == AssignmentMethod.individual,
            onTap: () => onChanged(AssignmentMethod.individual),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MethodButton(
            icon: Icons.groups_outlined,
            label: 'Entire Batch',
            isSelected: selected == AssignmentMethod.entireBatch,
            onTap: () => onChanged(AssignmentMethod.entireBatch),
          ),
        ),
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEEEFA) : const Color(0xFFF5F5F5),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5B5EA6)
                : const Color(0xFFE0E0E8),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF5B5EA6)
                  : const Color(0xFF9E9EB8),
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF5B5EA6)
                    : const Color(0xFF6B6B8A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Batch Dropdown ─────────────────────────────────────────────
class _BatchDropdown extends StatelessWidget {
  final List<String> batches;
  final String? selected;
  final void Function(String) onChanged;

  const _BatchDropdown({
    required this.batches,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E8)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          hint: const Text(
            'Select batch...',
            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5B5EA6)),
          items: batches
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final void Function(String) onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search students...',
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFFAAAAAA),
          size: 20,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ── Student Tile ───────────────────────────────────────────────
class _StudentTile extends StatelessWidget {
  final StudentItem student;
  final bool isSelected;
  final VoidCallback onToggle;

  const _StudentTile({
    required this.student,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F0FA) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5B5EA6).withOpacity(0.3)
                : const Color(0xFFEEEEEE),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF5B5EA6) : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5B5EA6)
                      : const Color(0xFFCCCCDD),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${student.email} • ${student.batch}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8EA8),
                    ),
                    overflow: TextOverflow.ellipsis,
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

// ── Due Date Picker ────────────────────────────────────────────
class _DueDatePicker extends StatelessWidget {
  final DateTime? selected;
  final void Function(DateTime?) onChanged;

  const _DueDatePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: selected ?? now.add(const Duration(days: 7)),
          firstDate: now,
          lastDate: now.add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF5B5EA6)),
            ),
            child: child!,
          ),
        );
        onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E8)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              selected == null
                  ? 'mm/dd/yyyy'
                  : '${selected!.day.toString().padLeft(2, '0')}/${selected!.month.toString().padLeft(2, '0')}/${selected!.year}',
              style: TextStyle(
                fontSize: 14,
                color: selected == null
                    ? const Color(0xFFAAAAAA)
                    : const Color(0xFF1A1A2E),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                if (selected != null)
                  GestureDetector(
                    onTap: () => onChanged(null),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFFAAAAAA),
                      size: 18,
                    ),
                  ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF8E8EA8),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assignment Summary ─────────────────────────────────────────
class _AssignmentSummaryCard extends StatelessWidget {
  final TestSummary? test;
  final AssignmentMethod method;
  final String? selectedBatch;
  final int studentCount;
  final DateTime? dueDate;

  const _AssignmentSummaryCard({
    required this.test,
    required this.method,
    required this.selectedBatch,
    required this.studentCount,
    required this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E8)),
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEFA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Color(0xFF5B5EA6),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Assignment Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF0F0F0), height: 1),
          const SizedBox(height: 14),
          _SummaryRow(
            label: 'Selected Test',
            value: test?.title ?? '—',
            valueColor: const Color(0xFF1A1A2E),
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Method',
            value: method == AssignmentMethod.individual
                ? 'Individual Selection'
                : 'Entire Batch${selectedBatch != null ? ' ($selectedBatch)' : ''}',
            valueColor: const Color(0xFF1A1A2E),
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Student Count',
            value: studentCount > 0 ? '$studentCount Students' : '—',
            valueColor: const Color(0xFF5B5EA6),
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Due Date',
            value: dueDate != null
                ? '${dueDate!.day} ${_monthName(dueDate!.month)} ${dueDate!.year}'
                : 'No deadline',
            valueColor: dueDate != null
                ? const Color(0xFFE65100)
                : const Color(0xFF8E8EA8),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF8E8EA8)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Bottom Bar ─────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final bool isAssigning;
  final VoidCallback onReset;
  final VoidCallback onAssign;

  const _BottomBar({
    required this.isAssigning,
    required this.onReset,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Reset button
          OutlinedButton(
            onPressed: isAssigning ? null : onReset,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              side: const BorderSide(color: Color(0xFFCCCCDD)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Reset\nSelection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B6B8A),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Assign button
          Expanded(
            child: ElevatedButton(
              onPressed: isAssigning ? null : onAssign,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5EA6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isAssigning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Assign Test',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
