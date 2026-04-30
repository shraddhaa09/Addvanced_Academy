import 'package:flutter/material.dart';

class AdminTimetableScreen extends StatelessWidget {
  const AdminTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Management'),
      ),
      body: const Center(
        child: Text('Timetable Management Content Here'),
      ),
    );
  }
}
