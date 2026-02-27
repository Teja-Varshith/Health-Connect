import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/features/auth/controller/auth_controller.dart';
import 'package:health_connect/features/caretaker/controller/caretaker_controller.dart';
import 'package:health_connect/features/caretaker/repository/medication_repository.dart';
import 'package:health_connect/features/caretaker/view/family_member_dashboard.dart';
import 'package:health_connect/features/community/view/community_screen.dart';
import 'package:health_connect/features/consultations/view/consultations_screen.dart';
import 'package:health_connect/features/profile/view/profile_screen.dart';
import 'package:health_connect/models/medication_log_model.dart';
import 'package:health_connect/models/medicine_model.dart';
import 'package:health_connect/models/user_model.dart';
import 'package:health_connect/providers/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// ─── Design tokens ──────────────────────────────────────────────────────────
const _kTeal = Color(0xFF00897B);
const _kTealDark = Color(0xFF00695C);
const _kDark = Color(0xFF1A1A2E);
const _kPurple = Color(0xFF5C6BC0);

class CaretakerHomeScreen extends ConsumerStatefulWidget {
  const CaretakerHomeScreen({super.key});

  @override
  ConsumerState<CaretakerHomeScreen> createState() =>
      _CaretakerHomeScreenState();
}

class _CaretakerHomeScreenState extends ConsumerState<CaretakerHomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _homeTab(user),
                  const ConsultationsScreen(),
                  const CommunityScreen(),
                  const ProfileScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ══════════════════════════════════════════════════════════
  // APP BAR
  // ══════════════════════════════════════════════════════════

  Widget _appBar(UserModel user) {
    final firstName = user.name.split(' ').first;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, d MMM').format(now);
    final timeStr = DateFormat('h:mm a').format(now);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF00BFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greeting column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting() + ', $firstName 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Date + time chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$dateStr • $timeStr',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Mental health icon
          GestureDetector(
            onTap: _showMentalHealthDialog,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.self_improvement_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar → opens profile sheet
          GestureDetector(
            onTap: () => _showProfileSheet(user),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showProfileSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00695C), Color(0xFF00897B)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _kDark,
              ),
            ),
            Text(
              user.email,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(authControllerProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.red.shade100),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showMentalHealthDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.self_improvement_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mental Health Assistant',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get personalised mental health tips and check-ins for you and your family. Available soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.notifications_outlined),
                label: const Text('Notify Me When Available'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // HOME TAB
  // ══════════════════════════════════════════════════════════

  Widget _homeTab(UserModel user) {
    final membersAsync = ref.watch(familyMembersProvider);
    final medicinesAsync = ref.watch(familyMedicinesProvider);
    final logsAsync = ref.watch(todayLogsProvider);

    return membersAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _kTeal)),
      error: (e, _) => Center(
        child: Text(
          'Error loading data',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ),
      data: (members) {
        final medicines = medicinesAsync.value ?? [];
        final logs = logsAsync.value ?? [];
        final takenCount = logs
            .where((l) => l.status == MedicationStatus.taken)
            .length;
        final activeRx = medicines.length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            _appBar(user),
            _dashboard(members, takenCount, medicines.length, activeRx),
            const SizedBox(height: 20),
            _mentalHealthBanner(),
            const SizedBox(height: 20),
            _todayMedicationSection(members, medicines, logs),
            const SizedBox(height: 24),
            _familyMembersSection(members),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  // MENTAL HEALTH BANNER
  // ══════════════════════════════════════════════════════════

  Widget _mentalHealthBanner() {
    return GestureDetector(
      onTap: _showMentalHealthDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B1FA2).withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.self_improvement_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mental Health Assistant',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Personalised check-ins for your family',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Explore',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // DASHBOARD
  // ══════════════════════════════════════════════════════════

  Widget _dashboard(
    List<UserModel> members,
    int takenToday,
    int totalMeds,
    int activeRx,
  ) {
    final adherencePct = totalMeds > 0
        ? '${((takenToday / totalMeds) * 100).round()}%'
        : '—';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _metric(
              icon: Icons.people_rounded,
              value: '${members.length}',
              label: 'Members',
              color: _kPurple,
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _metric(
              icon: Icons.check_circle_rounded,
              value: adherencePct,
              label: 'Adherence',
              color: const Color(0xFF43A047),
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _metric(
              icon: Icons.medication_rounded,
              value: '$activeRx',
              label: 'Active Rx',
              color: const Color(0xFFFF9800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.grey.shade200,
    );
  }

  // ══════════════════════════════════════════════════════════
  // TODAY'S MEDICATION
  // ══════════════════════════════════════════════════════════

  Widget _todayMedicationSection(
    List<UserModel> members,
    List<MedicineModel> medicines,
    List<MedicationLogModel> logs,
  ) {
    if (medicines.isEmpty) return const SizedBox.shrink();

    final currentUser = ref.watch(userProvider);
    final memberMap = {for (final m in members) m.uid: m};
    if (currentUser != null) memberMap[currentUser.uid] = currentUser;

    // Sort: untaken/missed first, taken at bottom
    final sorted = [...medicines];
    sorted.sort((a, b) {
      final aLog = logs.where((l) => l.medicineId == a.medicineId).firstOrNull;
      final bLog = logs.where((l) => l.medicineId == b.medicineId).firstOrNull;
      final aTaken = aLog?.status == MedicationStatus.taken ? 1 : 0;
      final bTaken = bLog?.status == MedicationStatus.taken ? 1 : 0;
      return aTaken.compareTo(bTaken);
    });

    final takenCount = logs
        .where((l) => l.status == MedicationStatus.taken)
        .length;
    final totalCount = medicines.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Today's Medication",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: takenCount == totalCount && totalCount > 0
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$takenCount/$totalCount done',
                style: TextStyle(
                  fontSize: 12,
                  color: takenCount == totalCount && totalCount > 0
                      ? Colors.green.shade700
                      : Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sorted.map((m) {
          final log = logs
              .where((l) => l.medicineId == m.medicineId)
              .firstOrNull;
          final member = memberMap[m.memberId];
          return _medicationAdherenceTile(m, member, log);
        }),
      ],
    );
  }

  Widget _medicationAdherenceTile(
    MedicineModel medicine,
    UserModel? member,
    MedicationLogModel? log,
  ) {
    final isTaken = log?.status == MedicationStatus.taken;
    final isMissed = log?.status == MedicationStatus.missed;

    // Build timing + scheduled time subtitle
    String timingStr = '';
    if (medicine.timing.isNotEmpty) {
      timingStr = medicine.timing
          .map(
            (t) =>
                '${t.emoji} ${t.label} ${medicine.scheduledTimeStringFor(t)}',
          )
          .join('  ');
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTaken
            ? Colors.green.shade50
            : isMissed
            ? Colors.red.shade50
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTaken
              ? Colors.green.shade200
              : isMissed
              ? Colors.red.shade200
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isTaken
                  ? Colors.green.withOpacity(0.15)
                  : isMissed
                  ? Colors.red.withOpacity(0.12)
                  : _kTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isTaken
                  ? Icons.check_circle_rounded
                  : isMissed
                  ? Icons.cancel_rounded
                  : Icons.medication_rounded,
              color: isTaken
                  ? Colors.green.shade600
                  : isMissed
                  ? Colors.red.shade400
                  : _kTeal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isTaken ? Colors.grey.shade500 : _kDark,
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${member?.name ?? "Unknown"} • ${medicine.dosage}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (timingStr.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    timingStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: isTaken
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
                // Show "Taken at HH:MM" if taken
                if (isTaken && log?.takenAtFormatted != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: Colors.green.shade500,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Taken at ${log!.takenAtFormatted}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action buttons
          Column(
            children: [
              _adherenceBtn(
                icon: Icons.close_rounded,
                color: Colors.red,
                isActive: isMissed,
                onTap: () => _toggleAdherence(
                  medicine.medicineId,
                  log,
                  MedicationStatus.missed,
                ),
              ),
              const SizedBox(height: 6),
              _adherenceBtn(
                icon: Icons.check_rounded,
                color: Colors.green,
                isActive: isTaken,
                onTap: () => _toggleAdherence(
                  medicine.medicineId,
                  log,
                  MedicationStatus.taken,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adherenceBtn({
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : color.withOpacity(0.7),
          size: 17,
        ),
      ),
    );
  }

  void _toggleAdherence(
    String medicineId,
    MedicationLogModel? existingLog,
    MedicationStatus status,
  ) {
    final repo = ref.read(medicationRepositoryProvider);

    // If same status is tapped again → untoggle (delete the log)
    if (existingLog?.status == status) {
      repo.deleteMedicationLog(existingLog!.logId);
      return;
    }

    final now = DateTime.now();
    // Use a deterministic log ID so toggling rewrites the same document
    final logId = repo.computeLogId(medicineId, now);

    final log = MedicationLogModel(
      logId: existingLog?.logId ?? logId,
      medicineId: medicineId,
      date: now,
      status: status,
      takenAt: status == MedicationStatus.taken ? now : null,
    );
    repo.logMedication(log);
  }

  // ══════════════════════════════════════════════════════════
  // FAMILY MEMBERS
  // ══════════════════════════════════════════════════════════

  Widget _familyMembersSection(List<UserModel> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Family Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
            const Spacer(),
            Text(
              '${members.length} members',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (members.isEmpty)
          _emptyMembersState()
        else
          ...members.map(_memberTile),
      ],
    );
  }

  Widget _emptyMembersState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 28,
              color: _kTeal.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No family members yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Share your invite code so\nfamily members can join.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberTile(UserModel member) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FamilyMemberDashboard(member: member),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _memberAvatar(member.name),
            const SizedBox(width: 14),
            Expanded(child: _memberInfo(member)),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: _kTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberAvatar(String name) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kTeal.withOpacity(0.7), _kTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _memberInfo(UserModel member) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          member.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (member.age != null)
              _chip(Icons.cake_outlined, '${member.age} yrs'),
            if (member.bloodGroup != null)
              _chip(Icons.water_drop_outlined, member.bloodGroup!.value),
            if (member.gender != null)
              _chip(Icons.person_outline_rounded, member.gender!.value),
          ],
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade400),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // BOTTOM NAV
  // ══════════════════════════════════════════════════════════

  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentTab,
      onTap: (i) => setState(() => _currentTab = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _kTeal,
      unselectedItemColor: Colors.grey.shade400,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      backgroundColor: Colors.white,
      elevation: 12,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_services_rounded),
          label: 'Consultations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_rounded),
          label: 'Community',
        ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.people_rounded),
        //   label: 'Family',
        // ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_rounded),
          label: 'Profile',
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // PLACEHOLDER TABS
  // ══════════════════════════════════════════════════════════

  Widget _placeholderTab(String title) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            '$title — Coming Soon',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
