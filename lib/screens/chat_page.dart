import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class ChatPage extends StatefulWidget {
  final String boardId;
  final String boardName;

  const ChatPage({required this.boardId, required this.boardName, super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _txt = TextEditingController();
  final _db = FirebaseFirestore.instance;
  final Map<String, String> _nameCache = {};
  final Set<String> _loadingNames = {};

  @override
  void dispose() {
    _txt.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _txt.text.trim();
    if (text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    String displayName = 'anonymous';
    if (user != null) {
      // try to read user's profile from Firestore to get first/last name
      try {
        final doc = await _db.collection('users').doc(user.uid).get();
        final data = doc.data();
        if (data != null) {
          final first = (data['firstName'] ?? '').toString();
          final last = (data['lastName'] ?? '').toString();
          if (first.isNotEmpty || last.isNotEmpty) {
            displayName = '$first ${last}'.trim();
          } else {
            displayName = user.email ?? 'anonymous';
          }
        } else {
          displayName = user.email ?? 'anonymous';
        }
      } catch (_) {
        displayName = user.email ?? 'anonymous';
      }
    }
    await _db
        .collection('boards')
        .doc(widget.boardId)
        .collection('messages')
        .add({
          'text': text,
          'uid': user?.uid ?? 'anonymous',
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
        });
    _txt.clear();
  }

  void _ensureNameForUid(String uid) {
    if (uid.isEmpty || uid == 'anonymous') return;
    if (_nameCache.containsKey(uid) || _loadingNames.contains(uid)) return;
    _loadingNames.add(uid);
    _db
        .collection('users')
        .doc(uid)
        .get()
        .then((doc) {
          final data = doc.data();
          final name = (data?['firstName'] ?? '').toString().trim();
          final last = (data?['lastName'] ?? '').toString().trim();
          final display = (name.isNotEmpty || last.isNotEmpty)
              ? '$name ${last}'.trim()
              : (data?['email'] ?? uid);
          _nameCache[uid] = display;
        })
        .whenComplete(() {
          _loadingNames.remove(uid);
          if (mounted) setState(() {});
        });
  }

  @override
  Widget build(BuildContext context) {
    final msgsCol = _db
        .collection('boards')
        .doc(widget.boardId)
        .collection('messages')
        .orderBy('createdAt', descending: false);
    return Scaffold(
      appBar: AppBar(title: Text(widget.boardName)),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: msgsCol.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data() as Map<String, dynamic>;
                    final ts = d['createdAt'] as Timestamp?;
                    final dt = ts?.toDate();
                    final uid = d['uid'] as String? ?? '';
                    String nameToShow = d['displayName'] as String? ?? '';
                    if (nameToShow.isEmpty) {
                      nameToShow = _nameCache[uid] ?? '';
                      if (nameToShow.isEmpty) {
                        // kick off async load
                        _ensureNameForUid(uid);
                        nameToShow = '...';
                      }
                    }
                    return ListTile(
                      title: Text(nameToShow.isNotEmpty ? nameToShow : 'anon'),
                      subtitle: Text(d['text'] ?? ''),
                      trailing: Text(
                        dt != null
                            ? dt.toLocal().toString().split('.').first
                            : '',
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(controller: _txt),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
