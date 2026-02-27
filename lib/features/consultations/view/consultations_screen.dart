import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/features/caretaker/controller/caretaker_controller.dart';
import 'package:health_connect/features/consultations/controller/consultations_controller.dart';
import 'package:health_connect/features/consultations/view/add_visit_screen.dart';
import 'package:health_connect/models/doctor_visit_model.dart';
import 'package:health_connect/models/user_model.dart';
import 'package:health_connect/providers/user_provider.dart';
import 'package:health_connect/models/medicine_model.dart';
import 'package:intl/intl.dart';

const _kTeal = Color(0xFF00897B);
const _kDark = Color(0xFF1A1A2E);

class ConsultationsScreen extends ConsumerWidget {
  const ConsultationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(caretakerVisitsProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final currentUser = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(addVisitControllerProvider.notifier).reset();
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddVisitScreen()));
        },
        backgroundColor: _kTeal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Visit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: visitsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kTeal)),
        error: (e, _) => Center(
          child: Text(
            'Error loading visits',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
        data: (visits) {
          if (visits.isEmpty) return _emptyState();

          final members = membersAsync.value ?? [];
          final memberMap = {for (final m in members) m.uid: m};
          if (currentUser != null) {
            memberMap.putIfAbsent(currentUser.uid, () => currentUser);
          }

          // Grouping visits by memberId
          final groupedVisits = <String, List<DoctorVisitModel>>{};
          for (final v in visits) {
            groupedVisits.putIfAbsent(v.memberId, () => []).add(v);
          }

          // Sort members: Caretaker first, then family members by name
          final sortedMemberIds = groupedVisits.keys.toList()
            ..sort((a, b) {
              if (currentUser != null) {
                if (a == currentUser.uid) return -1;
                if (b == currentUser.uid) return 1;
              }
              final nameA = memberMap[a]?.name ?? '';
              final nameB = memberMap[b]?.name ?? '';
              return nameA.compareTo(nameB);
            });

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
            itemCount: sortedMemberIds.length,
            itemBuilder: (_, i) {
              final memberId = sortedMemberIds[i];
              final memberVisits = groupedVisits[memberId]!;
              final member = memberMap[memberId];
              final isSelf = currentUser != null && memberId == currentUser.uid;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      bottom: 12,
                      top: 16,
                    ),
                    child: Text(
                      isSelf
                          ? 'My Consultations'
                          : "${member?.name ?? 'Unknown'}'s consultations",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kDark,
                      ),
                    ),
                  ),
                  ...memberVisits.map(
                    (v) => _visitCard(context, v, memberMap, currentUser, ref),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _kTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.medical_information_outlined,
              size: 32,
              color: _kTeal.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No consultations yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to add a doctor visit',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _visitCard(
    BuildContext context,
    DoctorVisitModel visit,
    Map<String, UserModel> memberMap,
    UserModel? currentUser,
    WidgetRef ref,
  ) {
    final dateStr = DateFormat('dd MMM yyyy').format(visit.visitDate);
    final medicinesAsync = ref.watch(visitMedicinesProvider(visit.visitId));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6BC0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Color(0xFF5C6BC0),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${visit.doctorName}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (visit.notes != null && visit.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  visit.notes!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            medicinesAsync.when(
              loading: () => const LinearProgressIndicator(color: _kTeal),
              error: (_, __) => const Text('Error loading medicines'),
              data: (medicines) {
                if (medicines.isEmpty) {
                  return const Text(
                    'No medicines recorded',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  );
                }
                return Column(
                  children: medicines
                      .map((m) => _medicineTile(context, m, ref))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _medicineTile(BuildContext context, MedicineModel m, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: _kTeal,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
                Text(
                  '${m.dosage} • ${m.frequency.name} • ${m.note ?? "No description"}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
            onPressed: () => _showEditMedicineDialog(context, m, ref),
          ),
        ],
      ),
    );
  }

  void _showEditMedicineDialog(
    BuildContext context,
    MedicineModel m,
    WidgetRef ref,
  ) {
    final nameController = TextEditingController(text: m.name);
    final dosageController = TextEditingController(text: m.dosage);
    final noteController = TextEditingController(text: m.note ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Edit Medicine',
          style: TextStyle(color: _kDark, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameController, 'Medicine Name'),
              const SizedBox(height: 12),
              _dialogField(dosageController, 'Dosage'),
              const SizedBox(height: 12),
              _dialogField(noteController, 'Note / Description', maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final updated = m.copyWith(
                name: nameController.text.trim(),
                dosage: dosageController.text.trim(),
                note: noteController.text.trim(),
              );
              ref
                  .read(addVisitControllerProvider.notifier)
                  .updateMedicineInDb(updated);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kTeal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
