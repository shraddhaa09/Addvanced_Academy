import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/faculty_providers.dart';

// --- Domain Models & Extensions ---

/// Extension to handle subject-specific UI logic outside the build method.
extension SubjectStyleX on String? {
  Color get toSubjectColor {
    switch (this?.toLowerCase()) {
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

  String get toInitials {
    if (this == null || this!.trim().isEmpty) return '?';
    final parts = this!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// --- Main Screen ---

class FacultyProfileScreen extends ConsumerWidget {
  const FacultyProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _LogoutDialog(),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // FIX: Remove 'final success =' because signOut returns void
      await ref.read(authProvider.notifier).signOut();

      if (context.mounted) {
        // Since signOut is void, we assume success if no error was thrown
        context.go(RouteConstants.login);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'An unexpected error occurred during logout.');
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
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
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(context, profileAsync),
              const SizedBox(height: 32),
              _buildProfileCard(context, profileAsync),
              const SizedBox(height: 20),
              _buildStatsRow(statsAsync),
              const SizedBox(height: 28),
              _buildMenuSection(),
              const SizedBox(height: 28),
              _LogoutButton(
                isLoading: authState.isLoading,
                onPressed: () => _handleLogout(context, ref),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<dynamic> profileAsync) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Profile',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        profileAsync.maybeWhen(
          data: (profile) => _IconActionButton(
            icon: Icons.edit_outlined,
            onTap: () => _openEditProfile(context, profile),
          ),
          orElse: () => const SizedBox(width: 40),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, AsyncValue<dynamic> profileAsync) {
    return profileAsync.when(
      data: (profile) {
        final Color color = (profile?.subject as String?).toSubjectColor;
        return _FacultyHeroCard(
          profile: profile,
          accentColor: color,
          onEdit: () => _openEditProfile(context, profile),
        );
      },
      loading: () => const _ProfileCardShimmer(),
      error: (_, __) => const _ErrorCard(message: 'Could not load profile'),
    );
  }

  Widget _buildStatsRow(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) => Row(
        children: [
          _ExpandedStat(label: 'Videos', value: '${stats['videos']}', icon: Icons.play_circle_outline, color: const Color(0xFF5B4FCF)),
          const SizedBox(width: 12),
          _ExpandedStat(label: 'Materials', value: '${stats['materials']}', icon: Icons.description_outlined, color: const Color(0xFF1E8C6E)),
          const SizedBox(width: 12),
          _ExpandedStat(label: 'Total', value: '${stats['total_uploads']}', icon: Icons.cloud_done_outlined, color: const Color(0xFFE65100)),
        ],
      ),
      loading: () => const _StatsShimmer(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
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
      ],
    );
  }
}

// --- Sub-Widgets (Private) ---

class _FacultyHeroCard extends StatelessWidget {
  final dynamic profile;
  final Color accentColor;
  final VoidCallback onEdit;

  const _FacultyHeroCard({required this.profile, required this.accentColor, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final lightColor = Color.lerp(accentColor, Colors.white, 0.35) ?? accentColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: accentColor.withAlpha(40), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accentColor, lightColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                children: [
                  _AvatarStack(initials: (profile?.name as String?).toInitials, accentColor: accentColor, onEdit: onEdit),
                  const SizedBox(height: 14),
                  Text(
                    profile?.name ?? 'Professor',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  if ((profile?.mobile ?? '').isNotEmpty)
                    Text(profile!.mobile, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _Badge(label: profile?.subject ?? 'Faculty', color: Colors.white.withAlpha(40), textColor: Colors.white),
                      if (profile?.qualification != null)
                        _Badge(label: profile!.qualification!, color: Colors.white.withAlpha(25), textColor: Colors.white70),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor.withAlpha(80)),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final String initials;
  final Color accentColor;
  final VoidCallback onEdit;

  const _AvatarStack({required this.initials, required this.accentColor, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
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
              child: Text(initials, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.edit_rounded, color: accentColor, size: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ExpandedStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LogoutButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
            : const Icon(Icons.logout, size: 18),
        label: Text(isLoading ? 'Logging Out...' : 'Log Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.withAlpha(60)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// --- Dialogs & Sheets ---

class _LogoutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Log Out?', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
      content: const Text('You will be signed out of your account on this device.', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Log Out'),
        ),
      ],
    );
  }
}

// --- Reusable Private UI Helpers ---

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Badge({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color iconColor;
  final String route;

  const _MenuTile({required this.icon, required this.label, this.subtitle, required this.iconColor, required this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFF0F0F0))),
      child: ListTile(
        onTap: () => context.push(route),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(backgroundColor: Colors.white),
    );
  }
}

// --- Shimmers & Errors ---

class _ProfileCardShimmer extends StatelessWidget {
  const _ProfileCardShimmer();
  @override
  Widget build(BuildContext context) {
    return Container(height: 240, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)));
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();
  @override
  Widget build(BuildContext context) {
    return Row(children: List.generate(3, (_) => Expanded(child: Container(height: 80, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))))));
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, style: const TextStyle(color: Colors.red)));
  }
}

// --- Implementation of Edit Profile Sheet ---
class _EditProfileSheet extends ConsumerStatefulWidget {
  final dynamic profile;
  const _EditProfileSheet({required this.profile});

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
    _qualController = TextEditingController(text: widget.profile?.qualification ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qualController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      await ref.read(facultyServiceProvider).updateProfile(name: name, qualification: _qualController.text.trim());
      ref.invalidate(facultyProfileProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      // Handle error
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = (widget.profile?.subject as String?).toSubjectColor;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person, color: color))),
            const SizedBox(height: 16),
            TextField(controller: _qualController, decoration: InputDecoration(labelText: 'Qualification', prefixIcon: Icon(Icons.school, color: color))),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: color, minimumSize: const Size(double.infinity, 50)),
              child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}