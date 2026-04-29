import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/announcement_model.dart';
import '../../../providers/announcement_providers.dart';
import '../../../providers/faculty_providers.dart';

class FacultyAnnouncementScreen extends ConsumerStatefulWidget {
  const FacultyAnnouncementScreen({super.key});

  @override
  ConsumerState<FacultyAnnouncementScreen> createState() => _FacultyAnnouncementScreenState();
}

class _FacultyAnnouncementScreenState extends ConsumerState<FacultyAnnouncementScreen> {
  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(facultyAnnouncementsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Announcements',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1A1A2E)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAnnouncementForm(context),
        backgroundColor: const Color(0xFF5B4FCF),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('CREATE NOTICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
      body: announcementsAsync.when(
        data: (announcements) {
          if (announcements.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(facultyAnnouncementsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return _AnnouncementCard(
                  announcement: announcement,
                  onEdit: () => _showAnnouncementForm(context, announcement: announcement),
                  onDelete: () => _confirmDelete(context, announcement.id),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF5B4FCF))),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20),
              ],
            ),
            child: const Icon(Icons.campaign_outlined, size: 64, color: Color(0xFF5B4FCF)),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Notices Published',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your announcements will appear here.\nTap the button below to publish your first one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), height: 1.5, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementForm(BuildContext context, {AnnouncementModel? announcement}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AnnouncementForm(announcement: announcement),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Announcement?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This action cannot be undone. Students will no longer see this notice.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(announcementServiceProvider).deleteAnnouncement(id);
      ref.invalidate(facultyAnnouncementsProvider);
    }
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = announcement.expiresAt != null && DateTime.now().isAfter(announcement.expiresAt!);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: announcement.subject != null ? const Color(0xFF5B4FCF) : Colors.amber.shade400,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                          ),
                        ),
                        PopupMenuButton(
                          icon: const Icon(Icons.more_horiz_rounded, size: 20, color: Color(0xFF9CA3AF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                          ],
                          onSelected: (val) {
                            if (val == 'edit') onEdit();
                            if (val == 'delete') onDelete();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.message,
                      style: const TextStyle(color: Color(0xFF4B5563), height: 1.5, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _Tag(label: announcement.targetBatch, color: const Color(0xFF1E8C6E)),
                        if (announcement.subject != null) ...[
                          const SizedBox(width: 8),
                          _Tag(label: announcement.subject!, color: const Color(0xFF5B4FCF)),
                        ],
                        const Spacer(),
                        if (isExpired)
                          const Text(
                            'EXPIRED',
                            style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          )
                        else
                          Text(
                            timeago.format(announcement.createdAt),
                            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
    );
  }
}

class _AnnouncementForm extends ConsumerStatefulWidget {
  final AnnouncementModel? announcement;

  const _AnnouncementForm({this.announcement});

  @override
  ConsumerState<_AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends ConsumerState<_AnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  late TextEditingController _batchController;
  late TextEditingController _subjectController;
  DateTime? _expiresAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement?.title);
    _messageController = TextEditingController(text: widget.announcement?.message);
    _batchController = TextEditingController(text: widget.announcement?.targetBatch ?? 'MHT-CET 2025');
    _subjectController = TextEditingController(text: widget.announcement?.subject);
    _expiresAt = widget.announcement?.expiresAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _batchController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final facultyId = ref.read(currentFacultyIdProvider);
      if (facultyId == null) throw Exception('Faculty profile not found');

      if (widget.announcement == null) {
        await ref.read(announcementServiceProvider).createAnnouncement(
              facultyId: facultyId,
              title: _titleController.text.trim(),
              message: _messageController.text.trim(),
              targetBatch: _batchController.text.trim(),
              subject: _subjectController.text.isNotEmpty ? _subjectController.text.trim() : null,
              expiresAt: _expiresAt,
            );
      } else {
        await ref.read(announcementServiceProvider).updateAnnouncement(
              widget.announcement!.id,
              {
                'title': _titleController.text.trim(),
                'message': _messageController.text.trim(),
                'target_batch': _batchController.text.trim(),
                'subject': _subjectController.text.isNotEmpty ? _subjectController.text.trim() : null,
                'expires_at': _expiresAt?.toIso8601String(),
              },
            );
      }

      ref.invalidate(facultyAnnouncementsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.announcement == null ? 'New Notice' : 'Edit Notice',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Title', Icons.short_text_rounded),
                style: const TextStyle(fontWeight: FontWeight.w600),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: _inputDecoration('Notice Message', Icons.notes_rounded),
                maxLines: 4,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _batchController,
                decoration: _inputDecoration('Target Batch', Icons.group_outlined),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: _inputDecoration('Subject (Optional)', Icons.auto_awesome_mosaic_outlined),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 20, color: Color(0xFF5B4FCF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Expiry Date', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          Text(
                            _expiresAt == null ? 'No Expiry (Always Active)' : '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => _expiresAt = date);
                      },
                      child: Text(_expiresAt == null ? 'SET' : 'CHANGE'),
                    ),
                  ],
                ),
              ),
              if (_expiresAt != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _expiresAt = null),
                    child: const Text('REMOVE EXPIRY', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4FCF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('PUBLISH ANNOUNCEMENT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF5B4FCF).withOpacity(0.7)),
      labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5B4FCF), width: 2)),
    );
  }
}
