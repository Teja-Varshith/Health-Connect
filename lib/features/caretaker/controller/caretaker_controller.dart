import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/features/caretaker/repository/caretaker_repository.dart';
import 'package:health_connect/models/user_model.dart';
import 'package:health_connect/models/medicine_model.dart';
import 'package:health_connect/models/medication_log_model.dart';
import 'package:health_connect/features/caretaker/repository/medication_repository.dart';
import 'package:health_connect/providers/user_provider.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Streams the list of family members for the currently logged-in caretaker.
final familyMembersProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(userProvider);
  if (user == null || user.familyCode == null) {
    return Stream.value([]);
  }
  return ref
      .watch(caretakerRepositoryProvider)
      .watchFamilyMembers(user.familyCode!);
});

/// Streams all active medicines for all family members + caretaker.
final familyMedicinesProvider = StreamProvider<List<MedicineModel>>((ref) {
  final members = ref.watch(familyMembersProvider).value ?? [];
  final user = ref.watch(userProvider);
  final ids = members.map((m) => m.uid).toList();
  if (user != null && !ids.contains(user.uid)) ids.add(user.uid);

  return ref.watch(medicationRepositoryProvider).watchAllMedicines(ids);
});

/// Streams today's medication logs for the active medicines.
final todayLogsProvider = StreamProvider<List<MedicationLogModel>>((ref) {
  final medicines = ref.watch(familyMedicinesProvider).value ?? [];
  final ids = medicines.map((m) => m.medicineId).toList();
  return ref.watch(medicationRepositoryProvider).watchTodayLogs(ids);
});

/// Computed: total count of family members.
final familyMemberCountProvider = Provider<int>((ref) {
  return ref.watch(familyMembersProvider).whenData((m) => m.length).value ?? 0;
});

/// Computed: real adherence score (0–100) across all family medicines today.
/// Returns 0 when there are no medicines.
final avgAdherenceProvider = Provider<int>((ref) {
  final medicines = ref.watch(familyMedicinesProvider).value ?? [];
  final logs = ref.watch(todayLogsProvider).value ?? [];

  if (medicines.isEmpty) return 0;

  final takenCount = logs
      .where((l) => l.status == MedicationStatus.taken)
      .length;
  return ((takenCount / medicines.length) * 100).round();
});

/// Computed: (takenToday, totalMeds) for the dashboard stat display.
final adherenceStatsProvider = Provider<(int, int)>((ref) {
  final medicines = ref.watch(familyMedicinesProvider).value ?? [];
  final logs = ref.watch(todayLogsProvider).value ?? [];
  final taken = logs.where((l) => l.status == MedicationStatus.taken).length;
  return (taken, medicines.length);
});

/// Computed: count of high-risk family members (placeholder).
final highRiskCountProvider = Provider<int>((ref) {
  return 0;
});
