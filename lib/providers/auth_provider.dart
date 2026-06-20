import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

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
