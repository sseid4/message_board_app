import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    DateTime? dob,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;

    final userDoc = AppUser(
      uid: user.uid,
      firstName: firstName,
      lastName: lastName,
      role: role,
      registrationDatetime: DateTime.now().toUtc(),
      dob: dob,
    );

    await _db.collection('users').doc(user.uid).set(userDoc.toMap());

    // Update the Firebase Auth displayName so auth profile matches Firestore
    try {
      await user.updateDisplayName('$firstName $lastName');
      await user.reload();
    } catch (_) {}
    return cred;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null)
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No logged in user',
      );
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
