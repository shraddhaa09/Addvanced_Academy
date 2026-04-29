import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/faculty_providers.dart';

Color _subjectColor(String? subject) {
  switch (subject?.toLowerCase()) {
    case 'physics':
      return const Color(0xFF1565C0);
    case 'chemistry':
      return const Color(0xFF2E7D32);
    case 'maths':
      return const Color(0xFFE65100);
    case 'biology':
      return const Color(0xFF6A1B9A);
    default:
      return const Color(0xFF5B4FCF);
  }
}

String _initials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

class FacultyProfileScreen extends ConsumerWidget {
  const FacultyProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.logout, color: Colors.red, size: 32),
        title: const Text(
          'Log Out?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You will be signed out of your Addvanced Academy account on this device.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final success = await ref.read(authProvider.notifier).signOut();
      
      if (!context.mounted) return;

      if (success) {
        // Force navigation to login screen immediately
        context.go(RouteConstants.login);
      } else {
        final errorMessage = ref.read(authProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Could not log out. Please try again.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred during logout.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _openEditProfile(BuildContext context, dynamic profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(facultyProfileProvider);
    final statsAsync = ref.watch(facultyStatsProvider);
    final authState = ref.watch(authProvider); // ✅ Watch authState

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  profileAsync.maybeWhen(
                    data: (profile) => _IconActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit profile',
                      onTap: () => _openEditProfile(context, profile),
                    ),
                    orElse: () => const SizedBox(width: 40),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              profileAsync.when(
                data: (profile) {
                  final color = _subjectColor(profile?.subject as String?);
                  final lightColor = Color.lerp(color, Colors.white, 0.35) ?? color;
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(40),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Column(
                        children: [
                          // ── Gradient banner ──────────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, lightColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () => _openEditProfile(context, profile),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 96,
                                        height: 96,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withAlpha(30),
                                          border: Border.all(color: Colors.white.withAlpha(80), width: 2.5),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _initials(profile?.name),
                                            style: const TextStyle(
                                              fontSize: 34,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: color.withAlpha(60),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: Icon(Icons.edit_rounded, color: color, size: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  profile?.name ?? 'Professor',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                if ((profile?.mobile ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    profile!.mobile,
                                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    _Badge(
                                      label: profile?.subject ?? 'Faculty',
                                      color: Colors.white.withAlpha(40),
                                      textColor: Colors.white,
                                    ),
                                    if (profile?.qualification != null)
                                      _Badge(
                                        label: profile!.qualification!,
                                        color: Colors.white.withAlpha(25),
                                        textColor: Colors.white70,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // ── White bottom strip with edit button ──────────
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _openEditProfile(context, profile),
                                icon: const Icon(Icons.edit_outlined, size: 15),
                                label: const Text('Edit Profile'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: color,
                                  side: BorderSide(color: color.withAlpha(80)),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const _ProfileCardShimmer(),
                error: (_, __) => const _ErrorCard(message: 'Could not load profile'),
              ),
              const SizedBox(height: 20),
              statsAsync.when(
                data: (stats) => Row(
                  children: [
                    Expanded(
                      child: _StatBadge(
                        label: 'Videos',
                        value: stats['videos'].toString(),
                        icon: Icons.play_circle_outline,
                        color: const Color(0xFF5B4FCF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBadge(
                        label: 'Materials',
                        value: stats['materials'].toString(),
                        icon: Icons.description_outlined,
                        color: const Color(0xFF1E8C6E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBadge(
                        label: 'Total',
                        value: stats['total_uploads'].toString(),
                        icon: Icons.cloud_done_outlined,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
                loading: () => Row(
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
                        child: const _ShimmerBox(
                          width: double.infinity,
                          height: 80,
                          borderRadius: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 28),
              _MenuTile(
                icon: Icons.person_outline,
                label: 'Personal Details',
                subtitle: 'View your name, mobile & more',
                iconColor: const Color(0xFF5B4FCF),
                route: '${RouteConstants.facultyProfile}/${RouteConstants.personalDetails}',
              ),
              _MenuTile(
                icon: Icons.menu_book_outlined,
                label: 'My Subjects',
                subtitle: 'Subjects assigned to you',
                iconColor: const Color(0xFF1E8C6E),
                route: '${RouteConstants.facultyProfile}/${RouteConstants.mySubjects}',
              ),
              _MenuTile(
                icon: Icons.history_rounded,
                label: 'Upload History',
                subtitle: 'All your past content uploads',
                iconColor: const Color(0xFF1565C0),
                route: '${RouteConstants.facultyProfile}/${RouteConstants.uploadHistory}',
              ),
              _MenuTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                subtitle: 'Get help or report an issue',
                iconColor: const Color(0xFFE65100),
                route: '${RouteConstants.facultyProfile}/${RouteConstants.helpSupport}',
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: authState.isLoading ? null : () => _handleLogout(context, ref), // ✅ Handle loading
                  icon: authState.isLoading 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                    : const Icon(Icons.logout, size: 18),
                  label: Text(
                    authState.isLoading ? 'Logging Out...' : 'Log Out', // ✅ Update text
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withAlpha(60)),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.profile});

  final dynamic profile;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _qualController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    _qualController =
        TextEditingController(text: widget.profile?.qualification ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qualController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final qualification = _qualController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(facultyServiceProvider).updateProfile(
        name: name,
        qualification: qualification,
      );
      ref.invalidate(facultyProfileProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Profile updated successfully.'),
              ],
            ),
            backgroundColor: const Color(0xFF1E8C6E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not save changes. Please try again.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final subjectColor = _subjectColor(widget.profile?.subject as String?);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F6FA),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SheetTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'e.g. Dr. Priya Sharma',
            icon: Icons.person_outline,
            accentColor: subjectColor,
          ),
          const SizedBox(height: 16),
          _SheetTextField(
            controller: _qualController,
            label: 'Qualification (optional)',
            hint: 'e.g. M.Sc Physics, PhD',
            icon: Icons.school_outlined,
            accentColor: subjectColor,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mobile and subject can only be changed by your Admin.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: subjectColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.onTap,
    this.tooltip = '',
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, color: Colors.black87, size: 20),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Small pill badge used in the hero gradient area.
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.textColor});
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.route,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color iconColor;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: iconColor.withAlpha(15),
          highlightColor: iconColor.withAlpha(8),
          onTap: () => context.push(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accentColor,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: accentColor),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileCardShimmer extends StatelessWidget {
  const _ProfileCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const _ShimmerBox(width: 100, height: 100, borderRadius: 50),
          const SizedBox(height: 16),
          const _ShimmerBox(width: 160, height: 18, borderRadius: 8),
          const SizedBox(height: 8),
          const _ShimmerBox(width: 100, height: 14, borderRadius: 8),
          const SizedBox(height: 16),
          const _ShimmerBox(width: 80, height: 28, borderRadius: 14),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
      ),
    );
  }
}