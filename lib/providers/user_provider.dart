import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:health_connect/features/auth/repository/auth_repository.dart';
import 'package:health_connect/models/user_model.dart';

/// Holds the current user state. null = logged out.
/// Updated by AuthController on sign-in, sign-out, and profile completion.
final userProvider = StateProvider<UserModel?>((ref) => null);

/// Runs once on cold start — checks if there's already a signed-in,
/// verified user, and if so loads their Firestore doc into [userProvider].
final appInitProvider = FutureProvider<void>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && user.emailVerified) {
    final authRepo = ref.read(authRepositoryProvider);
    final userModel = await authRepo.getUser(user.uid);
    ref.read(userProvider.notifier).state = userModel;
  }
});
