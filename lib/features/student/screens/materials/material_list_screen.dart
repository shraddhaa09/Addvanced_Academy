import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../providers/student_providers.dart';
import '../../../../providers/faculty_providers.dart';
import '../../../../models/study_material_model.dart';
import '../../../../core/widgets/hero_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_widgets.dart';

class MaterialListScreen extends ConsumerWidget {
  const MaterialListScreen({
    super.key,
    required this.subjectId,
    required this.chapterId,
  });

  final String subjectId;
  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(studentMaterialsProvider(chapterId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Resources',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: HeroBanner(
              title: 'Chapter Resources',
              subtitle: 'Access study notes and reference materials',
              tag: 'Study Material',
              gradientColors: const [Color(0xFF2BB5A0), Color(0xFF4DD0E1)],
              backgroundIcon: Icons.menu_book_rounded,
            ),
          ),
          Expanded(
            child: materialsAsync.when(
              data: (materials) {
                if (materials.isEmpty) {
                  return const Center(
                    child: AppEmptyState(
                      title: 'No resources found',
                      message: 'Check back later for study notes and PDFs.',
                      icon: Icons.folder_open_rounded,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: materials.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return _MaterialCard(material: material);
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerBox(width: double.infinity, height: 80, borderRadius: 14),
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialCard extends ConsumerWidget {
  final StudyMaterialModel material;
  const _MaterialCard({required this.material});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () async {
          final service = ref.read(materialServiceProvider);
          final url = await service.getPublicUrl(material.storagePath);
          
          if (!context.mounted) return;
          
          // In a real app, use url_launcher or a PDF viewer
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening: ${material.title}'),
              action: SnackBarAction(label: 'Copy URL', onPressed: () {}),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E8C6E).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Color(0xFF1E8C6E), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      material.description ?? 'Study document',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeago.format(material.uploadedAt, locale: 'en_short'),
                style: const TextStyle(fontSize: 11, color: Color(0xFFD1D5DB)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

