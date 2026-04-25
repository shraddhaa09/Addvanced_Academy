import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/faculty_upload_model.dart';

class RecentUploadTile extends StatelessWidget {
  final FacultyUploadModel upload;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RecentUploadTile({
    super.key,
    required this.upload,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = upload.contentType == 'video';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isVideo ? const Color(0xFF5B4FCF).withValues(alpha: 0.08) : const Color(0xFF1E8C6E).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isVideo ? Icons.play_circle_outline : Icons.picture_as_pdf,
            color: isVideo ? const Color(0xFF5B4FCF) : const Color(0xFF1E8C6E),
            size: 24,
          ),
        ),
        title: Text(
          upload.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    upload.subject,
                    style: const TextStyle(color: Color(0xFF5B4FCF), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.circle, size: 4, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text(
                    upload.uploadedAt != null 
                        ? timeago.format(upload.uploadedAt!) 
                        : 'Unknown date',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _StatusChip(
                    label: upload.isVisible ? 'Visible' : 'Hidden',
                    color: upload.isVisible ? const Color(0xFF1E8C6E) : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  _StatusChip(
                    label: isVideo ? 'Video' : 'Material',
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          onSelected: (val) {
            if (val == 'edit') {
              onEdit?.call();
            } else if (val == 'delete') {
              onDelete?.call();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit Metadata'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Upload', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
