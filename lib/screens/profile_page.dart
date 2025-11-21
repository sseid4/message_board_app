import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _db = FirebaseFirestore.instance;
  final _first = TextEditingController();
  final _last = TextEditingController();
  DateTime? _dob;
  String? _email;
  String? _role;
  DateTime? _registrationDatetime;
  bool _editing = false;
  static const bool _useEmulator = bool.fromEnvironment(
    'USE_FIRESTORE_EMULATOR',
    defaultValue: false,
  );
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      _first.text = data['firstName'] ?? '';
      _last.text = data['lastName'] ?? '';
      if (data['dob'] != null) {
        _dob = DateTime.tryParse(data['dob']);
      }
      _email = user.email;
      _role = data['role'] ?? '';
      if (data['registrationDatetime'] != null) {
        _registrationDatetime = DateTime.tryParse(data['registrationDatetime']);
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to load profile: $e';
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final docRef = _db.collection('users').doc(user.uid);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        await docRef.update({
          'firstName': _first.text.trim(),
          'lastName': _last.text.trim(),
          if (_dob != null) 'dob': _dob!.toUtc().toIso8601String(),
        });
      } else {
        // Create the document if it doesn't exist (registration likely occurred when Firestore was unavailable)
        await docRef.set({
          'uid': user.uid,
          'firstName': _first.text.trim(),
          'lastName': _last.text.trim(),
          'role': _role ?? 'user',
          'registrationDatetime': DateTime.now().toUtc().toIso8601String(),
          if (_dob != null) 'dob': _dob!.toUtc().toIso8601String(),
        });
      }
      // refresh values from DB
      await _load();
      // update Auth displayName to keep Auth profile in sync
      try {
        final current = FirebaseAuth.instance.currentUser;
        if (current != null) {
          final display = '${_first.text.trim()} ${_last.text.trim()}';
          await current.updateDisplayName(display);
          await current.reload();
        }
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      _error = 'Failed to save profile: $e';
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_error!)));
    } finally {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        _load();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_email != null)
                    Text(
                      'Email: $_email',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  if (_role != null) Text('Role: $_role'),
                  if (_registrationDatetime != null)
                    Text(
                      'Registered: ${_registrationDatetime!.toLocal().toString().split(' ')[0]}',
                    ),
                  const SizedBox(height: 12),
                  if (_useEmulator)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.developer_mode,
                            size: 18,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Running with local Firebase emulators',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // View mode
                  if (!_editing) ...[
                    ListTile(
                      title: const Text('First name'),
                      subtitle: Text(_first.text),
                    ),
                    ListTile(
                      title: const Text('Last name'),
                      subtitle: Text(_last.text),
                    ),
                    ListTile(
                      title: const Text('Date of birth'),
                      subtitle: Text(
                        _dob == null
                            ? 'not set'
                            : _dob!.toLocal().toString().split(' ')[0],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() => _editing = true),
                      child: const Text('Edit'),
                    ),
                  ] else ...[
                    // Edit mode
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _first,
                            decoration: const InputDecoration(
                              labelText: 'First name',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'First name required'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _last,
                            decoration: const InputDecoration(
                              labelText: 'Last name',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Last name required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dob == null
                                ? 'Date of birth: not set'
                                : 'DOB: ${_dob!.toLocal().toString().split(' ')[0]}',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dob ?? DateTime(2000, 1, 1),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => _dob = picked);
                          },
                          child: const Text('Pick DOB'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving
                                ? null
                                : () async {
                                    if (!(_formKey.currentState?.validate() ??
                                        false))
                                      return;
                                    await _save();
                                    if (mounted)
                                      setState(() => _editing = false);
                                  },
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () {
                                    // discard changes by reloading the saved values
                                    setState(() {
                                      _loading = true;
                                      _error = null;
                                    });
                                    _load().then((_) {
                                      if (mounted)
                                        setState(() => _editing = false);
                                    });
                                  },
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
