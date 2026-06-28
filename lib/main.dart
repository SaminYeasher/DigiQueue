import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/role_select_screen.dart';
import 'screens/student/queue_list_screen.dart';
import 'screens/professor/queue_control_screen.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: DigiQueueApp()));
}

class DigiQueueApp extends ConsumerWidget {
  const DigiQueueApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'DigiQueue',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _AuthGate(),
    );
  }
}

/// Routes user based on auth state and role selection.
/// Now loads role from Firestore for persistence across sessions.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final sessionRole = ref.watch(userRoleProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to connect',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$error',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        // If session role is already set, use it
        if (sessionRole != null) {
          return sessionRole == UserRole.student
              ? const QueueListScreen()
              : const QueueControlScreen();
        }

        // Otherwise, try loading role from Firestore
        final profileAsync = ref.watch(currentUserProfileProvider);
        return profileAsync.when(
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => const RoleSelectScreen(),
          data: (profile) {
            if (profile == null || profile.role.isEmpty) {
              return const RoleSelectScreen();
            }

            // Set session role from Firestore and navigate
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final role = profile.isStudent
                  ? UserRole.student
                  : UserRole.professor;
              ref.read(userRoleProvider.notifier).state = role;
            });

            return profile.isStudent
                ? const QueueListScreen()
                : const QueueControlScreen();
          },
        );
      },
    );
  }
}
