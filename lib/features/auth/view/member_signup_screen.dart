import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/features/auth/controller/auth_controller.dart';
import 'package:health_connect/features/auth/repository/auth_repository.dart';
import 'package:health_connect/features/auth/view/auth_widgets.dart';
import 'package:routemaster/routemaster.dart';

class MemberSignupScreen extends ConsumerStatefulWidget {
  const MemberSignupScreen({super.key});

  @override
  ConsumerState<MemberSignupScreen> createState() => _MemberSignupScreenState();
}

class _MemberSignupScreenState extends ConsumerState<MemberSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isCodeVerified = false;
  bool _isVerifyingCode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code must be exactly 6 characters'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isVerifyingCode = true);
    try {
      final isValid = await ref
          .read(authRepositoryProvider)
          .validateFamilyCode(code);
      if (!mounted) return;

      if (isValid) {
        setState(() => _isCodeVerified = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Invalid code. Please check with your caretaker.',
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifyingCode = false);
    }
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authControllerProvider.notifier)
          .signUpFamilyMember(
            context: context,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            familyCode: _codeController.text.trim().toUpperCase(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF00897B),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              if (_isCodeVerified) {
                                setState(() => _isCodeVerified = false);
                              } else {
                                Routemaster.of(context).replace('/role-select');
                              }
                            },
                          ),
                        ),
                      ),

                      // Placeholder for Lottie
                      const SizedBox(
                        height: 150,
                        child: Center(
                          child: Icon(
                            Icons.family_restroom_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // White card
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(36),
                              topRight: Radius.circular(36),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 20,
                                offset: Offset(0, -4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isCodeVerified
                                ? _registrationForm(isLoading)
                                : _codeStep(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Step 1: Invite code ──────────────────────────────────────────────────

  Widget _codeStep() {
    return Column(
      key: const ValueKey('code'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Enter Invite Code 🔑',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ask your caretaker for the 6-character code to join their family.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        const SizedBox(height: 32),

        TextFormField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF1A1A2E),
          ),
          decoration: InputDecoration(
            hintText: '• • • • • •',
            hintStyle: TextStyle(
              letterSpacing: 8,
              color: Colors.grey.shade300,
              fontSize: 22,
            ),
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF00897B),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        authButton(
          label: 'Verify Code',
          isLoading: _isVerifyingCode,
          onPressed: _verifyCode,
        ),
      ],
    );
  }

  // ── Step 2: Registration form ────────────────────────────────────────────

  Widget _registrationForm(bool isLoading) {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Join as Family Member 👨‍👩‍👧',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),

        // Verified badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF00897B).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00897B),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Code: ${_codeController.text.trim().toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00897B),
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _isCodeVerified = false),
                child: Text(
                  'Change',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Form(
          key: _formKey,
          child: Column(
            children: [
              authField(
                controller: _nameController,
                label: 'Full name',
                icon: Icons.person_outline_rounded,
                capitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              authField(
                controller: _emailController,
                label: 'Email address',
                icon: Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              authField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                obscure: !_isPasswordVisible,
                suffix: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a password';
                  }
                  if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        authButton(
          label: 'Join Family',
          isLoading: isLoading,
          onPressed: _signup,
        ),
      ],
    );
  }
}
