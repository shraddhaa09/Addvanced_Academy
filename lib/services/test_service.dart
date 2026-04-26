// lib/features/tests/services/test_service.dart

import '../models/test_model.dart';

class TestService {
  /// ─────────────────────────────────────────────────────────
  /// FETCH ASSIGNED TESTS (MOCK / API READY)
  /// ─────────────────────────────────────────────────────────
  Future<List<TestModel>> fetchAssignedTests({
    String status = 'pending', // pending | completed
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return List.generate(4, (index) {
      final isCompleted = status == 'completed';

      return TestModel(
        id: 'assigned_$index',
        testType: index % 2 == 0 ? 'full_pcm' : 'subject',
        title: isCompleted
            ? 'Completed Test ${index + 1}'
            : 'Pending Test ${index + 1}',
        description: 'Assigned by academy',
        totalQuestions: index % 2 == 0 ? 90 : 30,
        durationMinutes: index % 2 == 0 ? 180 : 60,
        totalMarks: index % 2 == 0 ? 90 : 30,
        subject: index % 2 == 0 ? null : 'Physics',
        chapter: index % 2 == 0 ? null : 'Thermodynamics',
        isAssigned: true,
        isCompleted: isCompleted,
      );
    });
  }

  /// ─────────────────────────────────────────────────────────
  /// FETCH CUSTOM TEST OPTIONS
  /// ─────────────────────────────────────────────────────────
  Future<List<TestModel>> fetchCustomTests() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      TestModel.fullPCM(id: 'custom_pcm'),
      TestModel.fullPCB(id: 'custom_pcb'),
      TestModel.subjective(
        id: 'custom_subject',
        subject: 'Physics',
        chapter: 'Oscillations',
      ),
    ];
  }

  /// ─────────────────────────────────────────────────────────
  /// CREATE TEST (SCHEMA BASED)
  /// ─────────────────────────────────────────────────────────
  Future<TestModel> createTest({
    required String type, // full | subjective
    String? subject,
    String? chapter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (type == 'full') {
      return TestModel.fullPCM(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    }

    return TestModel.subjective(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: subject ?? 'Physics',
      chapter: chapter ?? 'General',
    );
  }

  /// ─────────────────────────────────────────────────────────
  /// GET TEST BY ID
  /// ─────────────────────────────────────────────────────────
  Future<TestModel?> getTestById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // mock lookup
    final tests = await fetchCustomTests();
    try {
      return tests.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}