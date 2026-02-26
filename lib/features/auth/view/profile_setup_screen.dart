import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/features/auth/controller/auth_controller.dart';
import 'package:health_connect/models/user_model.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _ageController = TextEditingController();

  int _currentPage = 0;
  Gender? _selectedGender;
  BloodGroup? _selectedBloodGroup;

  late final List<_ProfilePage> _pages = [
    _ProfilePage(
      title: 'How old are you?',
      subtitle: 'Used to calculate your personalised health risk score.',
      icon: Icons.cake_outlined,
      builder: _buildAgePage,
    ),
    _ProfilePage(
      title: 'Your gender',
      subtitle: 'Helps us tailor health insights for you.',
      icon: Icons.person_outline_rounded,
      builder: _buildGenderPage,
    ),
    _ProfilePage(
      title: 'Blood group',
      subtitle: 'Critical info for emergency situations.',
      icon: Icons.water_drop_outlined,
      builder: _buildBloodGroupPage,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_validateCurrentPage()) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prev() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _formKey.currentState!.validate();
      case 1:
        if (_selectedGender == null) {
          _showHint('Please select your gender');
          return false;
        }
        return true;
      case 2:
        if (_selectedBloodGroup == null) {
          _showHint('Please select your blood group');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _submit() async {
    if (!_validateCurrentPage()) return;
    await ref
        .read(authControllerProvider.notifier)
        .completeProfile(
          context: context,
          age: int.parse(_ageController.text.trim()),
          gender: _selectedGender!,
          bloodGroup: _selectedBloodGroup!,
        );
  }

  void _showHint(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    final total = _pages.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Header
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Just $total quick questions to set up your health card.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Progress bar
              _ProgressBar(current: _currentPage, total: total),
              const SizedBox(height: 32),

              // Pages
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: _pages.map((p) => _buildPage(p)).toList(),
                  ),
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    if (_currentPage > 0) ...[
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _prev,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1A1A2E),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : (_currentPage == total - 1 ? _submit : _next),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00897B),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(
                              0xFF00897B,
                            ).withOpacity(0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading && _currentPage == total - 1
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _currentPage == total - 1
                                      ? "Let's Go!"
                                      : 'Continue',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_ProfilePage page) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + title row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  page.icon,
                  color: const Color(0xFF00897B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      page.subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          page.builder(),
        ],
      ),
    );
  }

  // ── Age ──────────────────────────────────────────────────────────────────

  Widget _buildAgePage() {
    return TextFormField(
      controller: _ageController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'e.g. 35',
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        suffixText: 'years',
        suffixStyle: TextStyle(color: Colors.grey.shade500),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Please enter your age';
        final age = int.tryParse(v.trim());
        if (age == null || age < 1 || age > 120) {
          return 'Please enter a valid age (1–120)';
        }
        return null;
      },
    );
  }

  // ── Gender ──────────────────────────────────────────────────────────────

  Widget _buildGenderPage() {
    final options = [
      (Gender.male, Icons.male_rounded, 'Male'),
      (Gender.female, Icons.female_rounded, 'Female'),
      (Gender.other, Icons.transgender_rounded, 'Other'),
    ];

    return Row(
      children: options.map((o) {
        final isSelected = _selectedGender == o.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: GestureDetector(
              onTap: () => setState(() => _selectedGender = o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00897B)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00897B)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      o.$2,
                      size: 32,
                      color: isSelected ? Colors.white : Colors.grey.shade500,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      o.$3,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1A1A2E),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Blood Group ──────────────────────────────────────────────────────────

  Widget _buildBloodGroupPage() {
    const groups = [
      (BloodGroup.aPosive, 'A+'),
      (BloodGroup.aNegative, 'A-'),
      (BloodGroup.bPositive, 'B+'),
      (BloodGroup.bNegative, 'B-'),
      (BloodGroup.abPositive, 'AB+'),
      (BloodGroup.abNegative, 'AB-'),
      (BloodGroup.oPositive, 'O+'),
      (BloodGroup.oNegative, 'O-'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final group = groups[i];
        final isSelected = _selectedBloodGroup == group.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedBloodGroup = group.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00897B) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00897B)
                    : Colors.grey.shade200,
              ),
            ),
            child: Center(
              child: Text(
                group.$2,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

class _ProfilePage {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;

  const _ProfilePage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });
}

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isActive = i <= current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF00897B) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
