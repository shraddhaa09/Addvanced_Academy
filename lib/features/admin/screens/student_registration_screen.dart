import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Supabase client shorthand ────────────────────────────────────────────────
final _supabase = Supabase.instance.client;

// ─── Available batches provider (fetched from existing student batches) ────────
final batchesProvider = FutureProvider<List<String>>((ref) async {
  final res = await _supabase.from('students').select('batch').order('batch');

  final raw = (res as List).map((e) => e['batch'] as String).toSet().toList()
    ..sort();

  // Always offer some default batches if none exist yet
  if (raw.isEmpty) {
    return ['PCM-2025-A', 'PCM-2025-B', 'PCB-2025-A', 'PCB-2025-B'];
  }
  return raw;
});

// ─── Registration state ───────────────────────────────────────────────────────
class _RegistrationState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const _RegistrationState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  _RegistrationState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) => _RegistrationState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    isSuccess: isSuccess ?? this.isSuccess,
  );
}

class _RegistrationNotifier extends StateNotifier<_RegistrationState> {
  _RegistrationNotifier() : super(const _RegistrationState());

  Future<void> registerStudent({
    required String name,
    required String email,
    required String mobile,
    required String parentMobile,
    required String parentEmail,
    required String batch,
    DateTime? dateOfBirth,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. Create Supabase Auth user (email = password per SRS FR-AUTH-03)
      final authRes = await _supabase.auth.signUp(
        email: email,
        password: email, // email used as password
      );

      if (authRes.user == null) {
        throw Exception('Failed to create auth account.');
      }

      final authId = authRes.user!.id;

      // 2. Insert into academy.users
      final userInsert = await _supabase
          .from('users')
          .insert({'auth_id': authId, 'email': email, 'role': 'student'})
          .select('id')
          .single();

      final userId = userInsert['id'] as String;

      // 3. Insert into academy.students
      await _supabase.from('students').insert({
        'id': userId,
        'name': name.trim(),
        'mobile': mobile.trim(),
        'parent_mobile': parentMobile.trim(),
        'parent_email': parentEmail.trim().toLowerCase(),
        'batch': batch,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'address': address?.trim().isEmpty == true ? null : address?.trim(),
      });

      state = state.copyWith(isLoading: false, isSuccess: true);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() => state = const _RegistrationState();
}

final _registrationProvider =
    StateNotifierProvider.autoDispose<
      _RegistrationNotifier,
      _RegistrationState
    >((_) => _RegistrationNotifier());

// ─── Main Screen ──────────────────────────────────────────────────────────────
class StudentRegistrationScreen extends ConsumerStatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  ConsumerState<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends ConsumerState<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _parentMobileCtrl = TextEditingController();
  final _parentEmailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? _selectedBatch;
  DateTime? _selectedDob;

  // Section expand/collapse state (all expanded by default)
  final Map<String, bool> _expanded = {
    'student': true,
    'parent': true,
    'academic': true,
    'optional': true,
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _parentMobileCtrl.dispose();
    _parentEmailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ─── Validators ──────────────────────────────────────────────────────────
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email address is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(v.trim())) return 'Invalid email format';
    return null;
  }

  String? _validateMobile(String? v) {
    if (v == null || v.trim().isEmpty) return 'Mobile number is required';
    final mobileRegex = RegExp(r'^[6-9][0-9]{9}$');
    if (!mobileRegex.hasMatch(v.trim())) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  String? _validateParentEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Parent email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(v.trim())) return 'Invalid email format';
    return null;
  }

  // ─── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBatch == null) {
      _showSnack('Please select a batch', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    await ref
        .read(_registrationProvider.notifier)
        .registerStudent(
          name: _nameCtrl.text,
          email: _emailCtrl.text.trim(),
          mobile: _mobileCtrl.text.trim(),
          parentMobile: _parentMobileCtrl.text.trim(),
          parentEmail: _parentEmailCtrl.text.trim(),
          batch: _selectedBatch!,
          dateOfBirth: _selectedDob,
          address: _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
        );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _emailCtrl.clear();
    _mobileCtrl.clear();
    _parentMobileCtrl.clear();
    _parentEmailCtrl.clear();
    _addressCtrl.clear();
    setState(() {
      _selectedBatch = null;
      _selectedDob = null;
    });
    ref.read(_registrationProvider.notifier).reset();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFE53E3E)
            : const Color(0xFF38A169),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 17, now.month, now.day),
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year - 10),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3D52D5),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(_registrationProvider);

    // Listen for success
    ref.listen(_registrationProvider, (prev, next) {
      if (next.isSuccess && !(prev?.isSuccess ?? false)) {
        _showSnack('Student registered successfully!');
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
      if (next.errorMessage != null && prev?.errorMessage == null) {
        _showSnack(next.errorMessage!, isError: true);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _buildStudentInfoSection(),
            const SizedBox(height: 16),
            _buildParentInfoSection(),
            const SizedBox(height: 16),
            _buildAcademicInfoSection(),
            const SizedBox(height: 16),
            _buildOptionalDetailsSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(regState),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    shadowColor: Colors.black12,
    surfaceTintColor: Colors.transparent,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 20,
        color: Color(0xFF1A1D2E),
      ),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Student Registration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1D2E),
            letterSpacing: -0.3,
          ),
        ),
        Text(
          'Create New Student Profile',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF8896AB),
          ),
        ),
      ],
    ),
    titleSpacing: 0,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: const Color(0xFFE8ECF4)),
    ),
  );

  // ─── Section Card Builder ─────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String key,
    required Widget icon,
    required String title,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D2E),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          const Divider(height: 1, color: Color(0xFFF0F2F8), thickness: 1),
          // Fields
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Student Information Section ─────────────────────────────────────────
  Widget _buildStudentInfoSection() => _buildSectionCard(
    key: 'student',
    icon: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        color: Color(0xFF3D52D5),
        size: 20,
      ),
    ),
    title: 'Student Information',
    children: [
      _buildFieldLabel('FULL NAME'),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _nameCtrl,
        hint: 'e.g. John Doe',
        validator: _validateName,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
        ],
      ),
      const SizedBox(height: 16),
      _buildFieldLabel('EMAIL ADDRESS', required: true),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _emailCtrl,
        hint: 'john.doe@example.com',
        validator: _validateEmail,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 16),
      _buildFieldLabel('MOBILE NUMBER'),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _mobileCtrl,
        hint: '10-digit number',
        validator: _validateMobile,
        keyboardType: TextInputType.phone,
        prefixText: '+91  ',
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
      ),
    ],
  );

  // ─── Parent Information Section ───────────────────────────────────────────
  Widget _buildParentInfoSection() => _buildSectionCard(
    key: 'parent',
    icon: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.people_outline_rounded,
        color: Color(0xFFE67E22),
        size: 20,
      ),
    ),
    title: 'Parent Information',
    children: [
      _buildFieldLabel('PARENT MOBILE NUMBER'),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _parentMobileCtrl,
        hint: 'Enter mobile number',
        validator: _validateMobile,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
      ),
      const SizedBox(height: 16),
      _buildFieldLabel('PARENT EMAIL ADDRESS'),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _parentEmailCtrl,
        hint: 'parent.email@example.com',
        validator: _validateParentEmail,
        keyboardType: TextInputType.emailAddress,
      ),
    ],
  );

  // ─── Academic Information Section ────────────────────────────────────────
  Widget _buildAcademicInfoSection() {
    final batchesAsync = ref.watch(batchesProvider);

    return _buildSectionCard(
      key: 'academic',
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.school_outlined,
          color: Color(0xFF2E7D32),
          size: 20,
        ),
      ),
      title: 'Academic Information',
      children: [
        _buildFieldLabel('BATCH'),
        const SizedBox(height: 6),
        batchesAsync.when(
          data: (batches) => _buildBatchDropdown(batches),
          loading: () => _buildBatchDropdown([]),
          error: (_, __) => _buildBatchDropdown([
            'PCM-2025-A',
            'PCM-2025-B',
            'PCB-2025-A',
            'PCB-2025-B',
          ]),
        ),
      ],
    );
  }

  Widget _buildBatchDropdown(List<String> batches) {
    // Allow manual entry too via a custom text field approach
    final allBatches = [
      ...batches,
      if (!batches.contains(_selectedBatch) && _selectedBatch != null)
        _selectedBatch!,
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedBatch == null
              ? const Color(0xFFDDE1ED)
              : const Color(0xFF3D52D5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFFAFBFD),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBatch,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'Select assigned batch',
              style: TextStyle(color: Color(0xFFADB5C7), fontSize: 14),
            ),
          ),
          isExpanded: true,
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF8896AB),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1D2E),
            fontWeight: FontWeight.w500,
          ),
          items: allBatches.map((b) {
            return DropdownMenuItem(value: b, child: Text(b));
          }).toList(),
          onChanged: (v) => setState(() => _selectedBatch = v),
        ),
      ),
    );
  }

  // ─── Optional Details Section ─────────────────────────────────────────────
  Widget _buildOptionalDetailsSection() => _buildSectionCard(
    key: 'optional',
    icon: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.more_horiz_rounded,
        color: Color(0xFF6B7280),
        size: 20,
      ),
    ),
    title: 'Optional Details',
    children: [
      _buildFieldLabel('DATE OF BIRTH'),
      const SizedBox(height: 6),
      _buildDobPicker(),
      const SizedBox(height: 16),
      _buildFieldLabel('ADDRESS'),
      const SizedBox(height: 6),
      _buildTextField(
        controller: _addressCtrl,
        hint: 'Residential address...',
        keyboardType: TextInputType.streetAddress,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
      ),
    ],
  );

  Widget _buildDobPicker() => GestureDetector(
    onTap: _pickDob,
    child: Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedDob != null
              ? const Color(0xFF3D52D5)
              : const Color(0xFFDDE1ED),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFFAFBFD),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedDob == null
                  ? 'mm/dd/yyyy'
                  : '${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.year}',
              style: TextStyle(
                fontSize: 14,
                color: _selectedDob == null
                    ? const Color(0xFFADB5C7)
                    : const Color(0xFF1A1D2E),
                fontWeight: _selectedDob != null
                    ? FontWeight.w500
                    : FontWeight.w400,
              ),
            ),
          ),
          const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: Color(0xFF8896AB),
          ),
        ],
      ),
    ),
  );

  // ─── Shared Widgets ───────────────────────────────────────────────────────
  Widget _buildFieldLabel(String label, {bool required = false}) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8896AB),
          letterSpacing: 0.8,
        ),
      ),
      if (required) ...[
        const SizedBox(width: 4),
        const Text(
          '*',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFE53E3E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ],
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? prefixText,
  }) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    inputFormatters: inputFormatters,
    maxLines: maxLines,
    style: const TextStyle(
      fontSize: 14,
      color: Color(0xFF1A1D2E),
      fontWeight: FontWeight.w500,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFADB5C7),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Color(0xFF8896AB), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFFAFBFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE1ED), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE1ED), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF3D52D5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
      ),
      errorStyle: const TextStyle(
        fontSize: 11,
        color: Color(0xFFE53E3E),
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  // ─── Bottom Action Bar ────────────────────────────────────────────────────
  Widget _buildBottomBar(_RegistrationState state) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 16,
          offset: Offset(0, -4),
        ),
      ],
    ),
    padding: EdgeInsets.fromLTRB(
      16,
      12,
      16,
      12 + MediaQuery.of(context).padding.bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Save button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: state.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D52D5),
              disabledBackgroundColor: const Color(0xFF3D52D5).withOpacity(0.6),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: state.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.save_outlined, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Save Student',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        // Reset button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: state.isLoading ? null : _resetForm,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8896AB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Reset Form',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
  );
}
