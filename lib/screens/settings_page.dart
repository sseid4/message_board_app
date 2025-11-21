import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_drawer.dart';
import 'login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Log out'),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // Show dialog to change password
                final current = TextEditingController();
                final next = TextEditingController();
                final formKey = GlobalKey<FormState>();
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Change Password'),
                    content: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: current,
                            decoration: const InputDecoration(
                              labelText: 'Current password',
                            ),
                            obscureText: true,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: next,
                            decoration: const InputDecoration(
                              labelText: 'New password',
                            ),
                            obscureText: true,
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Min 6 chars'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.of(ctx).pop(true);
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  try {
                    await auth.changePassword(
                      currentPassword: current.text.trim(),
                      newPassword: next.text.trim(),
                    );
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password changed')),
                      );
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Change failed: $e')),
                      );
                  }
                }
              },
              child: const Text('Change password'),
            ),
            const SizedBox(height: 12),
            const Text('Personal info (like DOB) can be edited in Profile.'),
          ],
        ),
      ),
    );
  }
}
