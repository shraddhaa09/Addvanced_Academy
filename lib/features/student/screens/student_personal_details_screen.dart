import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/student_providers.dart';
import '../../../core/widgets/shimmer_widgets.dart';

class StudentPersonalDetailsScreen extends ConsumerWidget {
  const StudentPersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Personal Details', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _DetailTile(label: 'Full Name', value: profile.name, icon: Icons.person_outline),
              _DetailTile(label: 'Mobile Number', value: profile.mobile, icon: Icons.phone_android_outlined),
              _DetailTile(label: 'Batch', value: profile.batch, icon: Icons.school_outlined),
              _DetailTile(label: 'Roll Number', value: profile.rollNo ?? 'Not Assigned', icon: Icons.badge_outlined),
              _DetailTile(label: 'Joined On', value: '${profile.createdAt.day}/${profile.createdAt.month}/${profile.createdAt.year}', icon: Icons.calendar_today_outlined),
              
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'To change your mobile number or batch, please contact the academy administration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.5),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF5B4FCF).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF5B4FCF), size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ],
          ),
        ],
      ),
    );
  }
}
