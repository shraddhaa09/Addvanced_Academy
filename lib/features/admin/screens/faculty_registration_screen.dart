import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────────────────────

final facultyRegistrationProvider =
    StateNotifierProvider.autoDispose<
      FacultyRegistrationNotifier,
      FacultyRegistrationState
    >((ref) => FacultyRegistrationNotifier());

// ─────────────────────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────────────────────

enum FacultyRegStatus { idle, loading, success, error }

class FacultyRegistrationState {
  final FacultyRegStatus status;
  final String? errorMessage;
  final bool isActive;
  final String? selectedSubject;

  const FacultyRegistrationState({
    this.status = FacultyRegStatus.idle,
    this.errorMessage,
    this.isActive = true,
    this.selectedSubject,
  });

  FacultyRegistrationState copyWith({
    FacultyRegStatus? status,
    String? errorMessage,
    bool? isActive,
    String? selectedSubject,
  }) {
    return FacultyRegistrationState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      isActive: isActive ?? this.isActive,
      selectedSubject: selectedSubject ?? this.selectedSubject,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────────────────────

class FacultyRegistrationNotifier
    extends StateNotifier<FacultyRegistrationState> {
  FacultyRegistrationNotifier() : super(const FacultyRegistrationState());

  void setActive(bool val) => state = state.copyWith(isActive: val);

  void setSubject(String? subject) =>
      state = state.copyWith(selectedSubject: subject);

  void clearError() => state = state.copyWith(status: FacultyRegStatus.idle);

  Future<void> register({
    required String email,
    required String name,
    required String mobile,
    required String qualification,
    required GlobalKey<FormState> formKey,
    required BuildContext context,
  }) async {
    if (!formKey.currentState!.validate()) return;
    if (state.selectedSubject == null) return;

    state = state.copyWith(
      status: FacultyRegStatus.loading,
      errorMessage: null,
    );

    try {
      final supabase = Supabase.instance.client;

      // 1. Create auth user with email as password
      final authResponse = await supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email.trim(),
          password: email.trim(),
          emailConfirm: true,
        ),
      );

      final authId = authResponse.user?.id;
      if (authId == null) throw Exception('Failed to create auth user');

      // 2. Insert into users table
      final userInsert = await supabase
          .from('users')
          .insert({
            'auth_id': authId,
            'email': email.trim().toLowerCase(),
            'role': 'faculty',
            'is_active': state.isActive,
          })
          .select('id')
          .single();

      final userId = userInsert['id'] as String;

      // 3. Insert into faculty table
      await supabase.from('faculty').insert({
        'id': userId,
        'name': name.trim(),
        'mobile': mobile.trim(),
        'subject': state.selectedSubject!.toLowerCase(),
        'qualification': qualification.trim().isEmpty
            ? null
            : qualification.trim(),
      });

      state = state.copyWith(status: FacultyRegStatus.success);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${name.trim()} registered successfully!'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        context.pop();
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: FacultyRegStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: FacultyRegStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────

class FacultyRegistrationScreen extends ConsumerStatefulWidget {
  const FacultyRegistrationScreen({super.key});

  @override
  ConsumerState<FacultyRegistrationScreen> createState() =>
      _FacultyRegistrationScreenState();
}

class _FacultyRegistrationScreenState
    extends ConsumerState<FacultyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _qualCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _qualFocus = FocusNode();

  static const _subjects = ['Physics', 'Chemistry', 'Maths', 'Biology'];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _qualCtrl.dispose();
    _emailFocus.dispose();
    _nameFocus.dispose();
    _mobileFocus.dispose();
    _qualFocus.dispose();
    super.dispose();
  }

  void _clearForm() {
    _emailCtrl.clear();
    _nameCtrl.clear();
    _mobileCtrl.clear();
    _qualCtrl.clear();
    _formKey.currentState?.reset();
    ref.read(facultyRegistrationProvider.notifier).setSubject(null);
    ref.read(facultyRegistrationProvider.notifier).setActive(true);
    _emailFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(facultyRegistrationProvider);
    final notifier = ref.read(facultyRegistrationProvider.notifier);
    final isLoading = state.status == FacultyRegStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F5FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4F46E5)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Faculty Registration',
          style: TextStyle(
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF4F46E5)),
            onPressed: () {},
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              // ── Hero Section ──────────────────────────────
              const SizedBox(height: 12),
              _HeroSection(),
              const SizedBox(height: 28),

              // ── Error Banner ──────────────────────────────
              if (state.status == FacultyRegStatus.error &&
                  state.errorMessage != null) ...[
                _ErrorBanner(
                  message: state.errorMessage!,
                  onDismiss: notifier.clearError,
                ),
                const SizedBox(height: 16),
              ],

              // ── Account Information Card ──────────────────
              _FormCard(
                icon: Icons.person_add_rounded,
                title: 'Account Information',
                children: [
                  // Email
                  _FieldLabel('Email Address'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailCtrl,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_nameFocus),
                    decoration: _inputDecoration('faculty.janesmith@'),
                    style: _inputTextStyle,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role (read-only)
                  _FieldLabel('Role'),
                  const SizedBox(height: 6),
                  _ReadOnlyField(
                    value: 'Faculty',
                    suffixIcon: Icons.lock_outline_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Account Status Toggle
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Status',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enable login access immediately',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: state.isActive,
                        onChanged: notifier.setActive,
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF4F46E5),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Faculty Details Card ──────────────────────
              _FormCard(
                icon: Icons.badge_rounded,
                title: 'Faculty Details',
                children: [
                  // Full Name
                  _FieldLabel('Full Name'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_mobileFocus),
                    decoration: _inputDecoration('Enter faculty full name'),
                    style: _inputTextStyle,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      if (v.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mobile Number
                  _FieldLabel('Mobile Number'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _mobileCtrl,
                    focusNode: _mobileFocus,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_qualFocus),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: _inputDecoration(
                      'Enter mobile number',
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+91',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 1,
                              height: 20,
                              color: Colors.grey.shade300,
                            ),
                          ],
                        ),
                      ),
                    ),
                    style: _inputTextStyle,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Mobile is required';
                      if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(v)) {
                        return 'Enter a valid 10-digit Indian mobile number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Subject Specialization
                  _FieldLabel('Subject Specialization'),
                  const SizedBox(height: 6),
                  _SubjectDropdown(
                    subjects: _subjects,
                    selected: state.selectedSubject,
                    onChanged: notifier.setSubject,
                  ),
                  const SizedBox(height: 16),

                  // Qualification (optional)
                  _FieldLabel('Qualification (Optional)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _qualCtrl,
                    focusNode: _qualFocus,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.words,
                    onFieldSubmitted: (_) => _qualFocus.unfocus(),
                    decoration: _inputDecoration(
                      'Enter qualification (e.g. M.Sc, PhD)',
                    ),
                    style: _inputTextStyle,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Register Button ───────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => notifier.register(
                          email: _emailCtrl.text,
                          name: _nameCtrl.text,
                          mobile: _mobileCtrl.text,
                          qualification: _qualCtrl.text,
                          formKey: _formKey,
                          context: context,
                        ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                  label: Text(
                    isLoading ? 'Registering...' : 'Register Faculty',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    disabledBackgroundColor: const Color(
                      0xFF4F46E5,
                    ).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Clear Form Button ─────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _clearForm,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  label: Text(
                    'Clear Form',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),

      // ── Bottom Nav (display only) ─────────────────────────
      bottomNavigationBar: _BottomNav(currentIndex: 1),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefix,
      contentPadding: EdgeInsets.symmetric(
        horizontal: prefix != null ? 0 : 16,
        vertical: 14,
      ),
      filled: true,
      fillColor: Colors.white,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
      errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 11.5),
      suffixIconColor: const Color(0xFFDC2626),
    );
  }

  TextStyle get _inputTextStyle => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF111827),
  );
}

// ─────────────────────────────────────────────────────────────
//  HERO SECTION
// ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Color(0xFF4F46E5),
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Register Faculty',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add a faculty member to the academy system',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FORM CARD
// ─────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _FormCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Card Header
          Row(
            children: [
              Icon(icon, color: const Color(0xFF4F46E5), size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FIELD LABEL
// ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade700,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  READ-ONLY FIELD
// ─────────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  final String value;
  final IconData suffixIcon;

  const _ReadOnlyField({required this.value, required this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Icon(suffixIcon, color: Colors.grey.shade400, size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SUBJECT DROPDOWN
// ─────────────────────────────────────────────────────────────

class _SubjectDropdown extends StatelessWidget {
  final List<String> subjects;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _SubjectDropdown({
    required this.subjects,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          hint: Text(
            'Select a subject',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF374151),
          ),
          items: subjects
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
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
//  ERROR BANNER
// ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFFDC2626),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOTTOM NAV
// ─────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.grid_view_rounded, label: 'Dashboard'),
      _NavItem(icon: Icons.school_rounded, label: 'Faculty'),
      _NavItem(icon: Icons.menu_book_rounded, label: 'Courses'),
      _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final isSelected = entry.key == currentIndex;
          return GestureDetector(
            onTap: () {
              if (entry.key == 0) context.go('/admin');
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  entry.value.icon,
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : Colors.grey.shade400,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.value.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
