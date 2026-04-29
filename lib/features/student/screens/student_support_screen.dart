import 'package:flutter/material.dart';

class StudentSupportScreen extends StatelessWidget {
  const StudentSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a contact method below to reach our support team.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            _SupportTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'WhatsApp Support',
              subtitle: 'Chat with us for quick queries',
              onTap: () {},
              color: const Color(0xFF25D366),
            ),
            const SizedBox(height: 12),
            _SupportTile(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'Send us an email for technical issues',
              onTap: () {},
              color: const Color(0xFF5B4FCF),
            ),
            const SizedBox(height: 12),
            _SupportTile(
              icon: Icons.phone_in_talk_outlined,
              title: 'Call Support',
              subtitle: 'Available 10 AM - 6 PM',
              onTap: () {},
              color: const Color(0xFF1E8C6E),
            ),
            
            const SizedBox(height: 40),
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const _FAQItem(
              question: 'How do I take a mock test?',
              answer: 'Go to Dashboard > Assigned Tests and select an active test to begin.',
            ),
            const _FAQItem(
              question: 'Where can I find study notes?',
              answer: 'Study materials are available under the "Materials" tab in the bottom navigation bar.',
            ),
            const _FAQItem(
              question: 'Can I watch lectures offline?',
              answer: 'Currently, video lectures require an active internet connection to stream.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
