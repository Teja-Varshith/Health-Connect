import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:health_connect/features/auth/repository/auth_repository.dart';
import 'package:health_connect/models/user_model.dart';
import 'package:health_connect/providers/user_provider.dart';
import 'package:routemaster/routemaster.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authControllerProvider = StateNotifierProvider<AuthController, bool>((
  ref,
) {
  return AuthController(
    authRepository: ref.watch(authRepositoryProvider),
    ref: ref,
  );
});

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class AuthController extends StateNotifier<bool> {
  final AuthRepository _authRepository;
  final Ref _ref;

  // state = isLoading
  AuthController({required AuthRepository authRepository, required Ref ref})
    : _authRepository = authRepository,
      _ref = ref,
      super(false);

  // --- Sign in -------------------------------------------------------------

  Future<void> signIn({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    state = true;
    try {
      await _authRepository.signIn(email: email, password: password);

      // Sign-in succeeded (email is verified) → fetch user from Firestore
      final uid = _authRepository.currentUser!.uid;
      final userModel = await _authRepository.getUser(uid);
      _ref.read(userProvider.notifier).state = userModel;
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString();
      if (msg.contains('not-verified')) {
        _showVerificationError(context, email, password);
      } else {
        _showError(context, msg);
      }
    } finally {
      state = false;
    }
  }

  // --- Sign up as caretaker ------------------------------------------------

  Future<void> signUpCaretaker({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
  }) async {
    state = true;
    try {
      await _authRepository.signUp(
        email: email,
        password: password,
        name: name,
        role: UserRole.caretaker,
      );

      if (!context.mounted) return;
      Routemaster.of(context).replace('/login');
      _showSnack(
        context,
        title: 'Account Created! ✉️',
        message:
            'A verification link has been sent to your email. Please verify before signing in.',
        type: ContentType.success,
      );
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    } finally {
      state = false;
    }
  }

  // --- Sign up as family member --------------------------------------------

  Future<void> signUpFamilyMember({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
    required String familyCode,
  }) async {
    state = true;
    try {
      await _authRepository.signUp(
        email: email,
        password: password,
        name: name,
        role: UserRole.familyMember,
        familyCode: familyCode,
      );

      if (!context.mounted) return;
      Routemaster.of(context).replace('/login');
      _showSnack(
        context,
        title: 'Account Created! ✉️',
        message:
            'A verification link has been sent to your email. Please verify before signing in.',
        type: ContentType.success,
      );
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    } finally {
      state = false;
    }
  }

  // --- Complete profile ---------------------------------------------------

  Future<void> completeProfile({
    required BuildContext context,
    required int age,
    required Gender gender,
    required BloodGroup bloodGroup,
  }) async {
    state = true;
    try {
      final uid = _authRepository.currentUser!.uid;
      final updatedUser = await _authRepository.completeProfile(
        uid: uid,
        age: age,
        gender: gender,
        bloodGroup: bloodGroup,
      );

      // Update userProvider → main.dart reactively switches to dashboard routes
      _ref.read(userProvider.notifier).state = updatedUser;
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    } finally {
      state = false;
    }
  }

  // --- Sign out ------------------------------------------------------------

  Future<void> signOut() async {
    await _authRepository.signOut();
    _ref.read(userProvider.notifier).state = null;
  }

  // --- Snackbar helpers ----------------------------------------------------

  void _showSnack(
    BuildContext context, {
    required String title,
    required String message,
    required ContentType type,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          duration: const Duration(seconds: 5),
          content: AwesomeSnackbarContent(
            title: title,
            message: message,
            contentType: type,
          ),
        ),
      );
  }

  void _showError(BuildContext context, String message) {
    final clean = message.replaceAll(RegExp(r'\[.*?\]\s?'), '');
    _showSnack(
      context,
      title: 'Oops!',
      message: clean,
      type: ContentType.failure,
    );
  }

  void _showVerificationError(
    BuildContext context,
    String email,
    String password,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          duration: const Duration(seconds: 8),
          content: AwesomeSnackbarContent(
            title: 'Email Not Verified',
            message:
                'Please check your inbox (and spam folder). Tap Resend below if you need a new link.',
            contentType: ContentType.warning,
          ),
          action: SnackBarAction(
            label: 'RESEND',
            textColor: Colors.deepOrange,
            onPressed: () async {
              try {
                await _authRepository.resendVerificationEmail(
                  email: email,
                  password: password,
                );
                if (context.mounted) {
                  _showSnack(
                    context,
                    title: 'Sent!',
                    message: 'A new verification link has been sent to $email.',
                    type: ContentType.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  final isRateLimit =
                      e.toString().contains('unusual activity') ||
                      e.toString().contains('TOO_MANY_REQUESTS') ||
                      e.toString().contains('blocked');
                  _showSnack(
                    context,
                    title: isRateLimit ? 'Too Many Attempts' : 'Failed',
                    message: isRateLimit
                        ? 'Please wait a few minutes before trying again.'
                        : 'Could not resend email. Please try again later.',
                    type: ContentType.failure,
                  );
                }
              }
            },
          ),
        ),
      );
  }
}
