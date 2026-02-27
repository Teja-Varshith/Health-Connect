import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/features/caretaker/repository/medication_repository.dart';
import 'package:health_connect/features/consultations/repository/doctor_repository.dart';
import 'package:health_connect/models/doctor_visit_model.dart';
import 'package:health_connect/models/medicine_model.dart';
import 'package:health_connect/models/medication_log_model.dart';
import 'package:health_connect/models/user_model.dart';
import 'package:intl/intl.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────
const _kTeal = Color(0xFF00897B);
const _kTealDark = Color(0xFF00695C);
const _kDark = Color(0xFF1A1A2E);
const _kPurple = Color(0xFF5C6BC0);

// ─── Providers ─────────────────────────────────────────────────────────────

final _memberVisitsProvider =
    StreamProvider.family<List<DoctorVisitModel>, String>((ref, memberId) {
      return ref.watch(doctorRepositoryProvider).watchVisits(memberId);
    });

final _memberMedicinesProvider =
    StreamProvider.family<List<MedicineModel>, String>((ref, memberId) {
      return ref.watch(doctorRepositoryProvider).watchMedicines(memberId);
    });

final _memberTodayLogsProvider =
    StreamProvider.family<List<MedicationLogModel>, List<String>>((
      ref,
      medicineIds,
    ) {
      return ref
          .watch(medicationRepositoryProvider)
          .watchTodayLogs(medicineIds);
    });

// ─── Screen ─────────────────────────────────────────────────────────────────

class FamilyMemberDashboard extends ConsumerWidget {
  final UserModel member;

  const FamilyMemberDashboard({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(_memberVisitsProvider(member.uid));
    final medicinesAsync = ref.watch(_memberMedicinesProvider(member.uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, member),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _HealthStatsCard(member: member),
                const SizedBox(height: 20),
                medicinesAsync.when(
                  loading: () => const LinearProgressIndicator(color: _kTeal),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (medicines) => _TodayMedCard(
                    member: member,
                    medicines: medicines,
                    ref: ref,
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionHeader(
                  title: 'Active Prescriptions',
                  icon: Icons.medication_rounded,
                  color: _kTeal,
                ),
                const SizedBox(height: 12),
                medicinesAsync.when(
                  loading: () => const LinearProgressIndicator(color: _kTeal),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (medicines) {
                    final active = medicines.where((m) => m.isActive).toList();
                    if (active.isEmpty) {
                      return _emptyBox('No active prescriptions');
                    }
                    return Column(
                      children: active
                          .map((m) => _MedicineTile(med: m))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const _SectionHeader(
                  title: 'Consultation History',
                  icon: Icons.medical_services_rounded,
                  color: _kPurple,
                ),
                const SizedBox(height: 12),
                visitsAsync.when(
                  loading: () => const LinearProgressIndicator(color: _kTeal),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (visits) {
                    if (visits.isEmpty)
                      return _emptyBox('No consultations yet');
                    return Column(
                      children: visits
                          .take(5)
                          .map((v) => _VisitTile(visit: v))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Center(
        child: Text(
          msg,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, UserModel member) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _kTeal,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kTealDark, _kTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (member.age != null || member.gender != null)
                          Text(
                            [
                              if (member.age != null) '${member.age} yrs',
                              if (member.gender != null) member.gender!.value,
                            ].join(' • '),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        if (member.bloodGroup != null)
                          Text(
                            'Blood: ${member.bloodGroup!.value}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          member.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Health Stats Card ──────────────────────────────────────────────────────

class _HealthStatsCard extends StatelessWidget {
  final UserModel member;

  const _HealthStatsCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _stat(
            'Age',
            member.age != null ? '${member.age} yrs' : '—',
            Icons.cake_outlined,
            const Color(0xFFFF9800),
          ),
          _divider(),
          _stat(
            'Blood',
            member.bloodGroup?.value ?? '—',
            Icons.water_drop_outlined,
            const Color(0xFFE53935),
          ),
          _divider(),
          _stat(
            'Gender',
            member.gender?.value ?? '—',
            Icons.person_outline_rounded,
            _kPurple,
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 50, color: Colors.grey.shade100);
  }
}

// ─── Today's Medication Card ────────────────────────────────────────────────

class _TodayMedCard extends ConsumerWidget {
  final UserModel member;
  final List<MedicineModel> medicines;
  final WidgetRef ref;

  const _TodayMedCard({
    required this.member,
    required this.medicines,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = medicines.where((m) => m.isActive).toList();
    if (active.isEmpty) return const SizedBox.shrink();

    final ids = active.map((m) => m.medicineId).toList();
    final logsAsync = ref.watch(_memberTodayLogsProvider(ids));
    final logs = logsAsync.value ?? [];

    final takenCount = logs
        .where((l) => l.status == MedicationStatus.taken)
        .length;
    final totalCount = active.length;
    final pct = totalCount > 0 ? takenCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF00BFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kTeal.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Today's Adherence",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '$takenCount/$totalCount taken',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct >= 1.0
                ? '🎉 All medications taken today!'
                : pct >= 0.5
                ? '👍 More than half done!'
                : 'Keep it up!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Medicine Tile ───────────────────────────────────────────────────────────

class _MedicineTile extends StatelessWidget {
  final MedicineModel med;

  const _MedicineTile({required this.med});

  @override
  Widget build(BuildContext context) {
    // Build scheduled time info per timing slot
    final timingInfo = med.timing.isNotEmpty
        ? med.timing
              .map(
                (t) =>
                    '${t.emoji} ${t.label} at ${med.scheduledTimeStringFor(t)}',
              )
              .join('  ')
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: _kTeal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${med.dosage} • ${med.frequency.name}${med.numberOfDays != null ? ' • ${med.numberOfDays} days' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (timingInfo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    timingInfo,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
                if (med.note != null && med.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    med.note!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Active',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Visit Tile ──────────────────────────────────────────────────────────────

class _VisitTile extends StatelessWidget {
  final DoctorVisitModel visit;

  const _VisitTile({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: _kPurple,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${visit.doctorName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(visit.visitDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (visit.notes != null && visit.notes!.isNotEmpty)
                  Text(
                    visit.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _kPurple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${visit.medicineIds.length} 💊',
              style: TextStyle(
                fontSize: 11,
                color: _kPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kDark,
          ),
        ),
      ],
    );
  }
}
