import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'queue_provider.dart';

/// Provides a singleton AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Streams Firebase auth state changes (User? emitted on sign-in/out)
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provides the current user synchronously (may be null)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

/// Tracks the selected role for the current session
enum UserRole { student, professor }

final userRoleProvider = StateProvider<UserRole?>((ref) {
  return null;
});

/// Streams user profile from Firestore (persistent role)
final userProfileProvider =
    StreamProvider.family<UserModel?, String>((ref, uid) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamUserProfile(uid);
});

/// Gets the current user's profile
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  final db = ref.watch(databaseServiceProvider);
  return db.streamUserProfile(user.uid);
});
