import 'package:flutter/material.dart';
import 'chat_page.dart';
// imports for navigation are handled by the drawer routes
import '../widgets/app_drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final List<Map<String, dynamic>> boards = [
    {
      'id': 'classes',
      'name': 'Classes',
      'color': Colors.indigo,
      'icon': Icons.school,
      'subtitle': 'Course discussions & resources',
    },
    {
      'id': 'clubs',
      'name': 'Clubs',
      'color': Colors.green,
      'icon': Icons.groups,
      'subtitle': 'Student clubs and organizations',
    },
    {
      'id': 'announcements',
      'name': 'Announcements',
      'color': Colors.orange,
      'icon': Icons.campaign,
      'subtitle': 'Campus news & alerts',
    },
    {
      'id': 'study_hall',
      'name': 'Study Hall',
      'color': Colors.deepPurple,
      'icon': Icons.menu_book,
      'subtitle': 'Peer help and study groups',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select A Room')),
      drawer: const AppDrawer(),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        itemCount: boards.length,
        itemBuilder: (context, index) {
          final b = boards[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ChatPage(boardId: b['id'], boardName: b['name']),
              ),
            ),
            child: Container(
              height: 220,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (b['color'] as Color).withOpacity(0.9),
                    (b['color'] as Color).withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Large decorative icon
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Opacity(
                      opacity: 0.18,
                      child: Icon(
                        b['icon'] as IconData,
                        size: 220,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          b['subtitle'] ?? 'Join the conversation',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
