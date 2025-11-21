# Message Board App

A simple Flutter message-board app with Firebase integration (Auth + Firestore).

**Features:**
- Email/password registration and login (Firebase Auth).
- User profiles stored in Firestore (uid, firstName, lastName, role, registrationDatetime, optional DOB).
- Message boards (per-board real-time chat via Firestore).
- Profile view/edit, change password, and logout.
- Optional local Firebase emulator support for development.

**Prerequisites:**
- Flutter SDK
- Firebase CLI (for running local emulators)

**Notes & important files:**
- Firebase config: `lib/firebase_options.dart` and platform files under `android/app/` and `ios/`.
- Main entry: `lib/main.dart` (contains emulator flag handling).
- Register / Profile logic: `lib/screens/register_page.dart`, `lib/screens/profile_page.dart`.
- Auth wrapper: `lib/services/auth_service.dart`.
