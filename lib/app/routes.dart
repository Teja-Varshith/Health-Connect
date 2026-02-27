import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/features/auth/controller/auth_controller.dart';
import 'package:health_connect/features/auth/view/caretaker_signup_screen.dart';
import 'package:health_connect/features/auth/view/login_screen.dart';
import 'package:health_connect/features/auth/view/member_signup_screen.dart';
import 'package:health_connect/features/auth/view/profile_setup_screen.dart';
import 'package:health_connect/features/auth/view/role_select_screen.dart';
import 'package:health_connect/features/caretaker/view/caretaker_homescreen.dart';
import 'package:routemaster/routemaster.dart';

// Placeholder — replace when building dashboards
class _PlaceholderScreen extends ConsumerWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          ElevatedButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    ),
  );
}

// ─── 1. Logged-out (unauthenticated) ─────────────────────────────────────────

final loggedOutRoutes = RouteMap(
  routes: {
    '/': (_) => const Redirect('/login'),
    '/login': (_) => const MaterialPage(child: LoginScreen()),
    '/role-select': (_) => const MaterialPage(child: RoleSelectScreen()),
    '/signup/caretaker': (_) =>
        const MaterialPage(child: CaretakerSignupScreen()),
    '/signup/member': (_) => const MaterialPage(child: MemberSignupScreen()),
  },
);

// ─── 2. Logged-in but profile incomplete ─────────────────────────────────────

final profileSetupRoutes = RouteMap(
  routes: {
    '/': (_) => const Redirect('/profile-setup'),
    '/profile-setup': (_) => const MaterialPage(child: ProfileSetupScreen()),
  },
);

// ─── 3a. Caretaker dashboard ──────────────────────────────────────────────────

final caretakerRoutes = RouteMap(
  routes: {
    '/': (_) => const Redirect('/caretaker/dashboard'),
    '/caretaker/dashboard': (_) =>
        const MaterialPage(child: CaretakerHomeScreen()),
  },
);

// ─── 3b. Family member dashboard ─────────────────────────────────────────────

final memberRoutes = RouteMap(
  routes: {
    '/': (_) => const Redirect('/member/dashboard'),
    '/member/dashboard': (_) => const MaterialPage(
      child: _PlaceholderScreen(title: 'Family Member Dashboard'),
    ),
  },
);
