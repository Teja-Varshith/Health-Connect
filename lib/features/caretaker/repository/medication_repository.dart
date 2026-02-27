import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/models/medication_log_model.dart';
import 'package:health_connect/models/medicine_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(firestore: FirebaseFirestore.instance);
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class MedicationRepository {
  final FirebaseFirestore _firestore;

  MedicationRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _medicines =>
      _firestore.collection('medicines');

  CollectionReference<Map<String, dynamic>> get _logs =>
      _firestore.collection('medication_logs');

  /// Deterministic log document ID = medicineId + date (YYYY-MM-DD)
  /// This ensures one log per medicine per day (or per slot if slot is provided).
  String _logDocId(String medicineId, DateTime date, [MedicineTiming? slot]) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (slot != null) return '${medicineId}_${dateStr}_${slot.name}';
    return '${medicineId}_$dateStr';
  }

  /// Stream all active medicines for multiple members.
  Stream<List<MedicineModel>> watchAllMedicines(List<String> memberIds) {
    if (memberIds.isEmpty) return Stream.value([]);
    return _medicines
        .where('memberId', whereIn: memberIds)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MedicineModel.fromDocument(d)).toList(),
        );
  }

  /// Log a medication intake status.
  /// Uses a deterministic logId based on medicineId+date+slot so toggling
  /// the same medicine overwrites the previous log for that day.
  Future<void> logMedication(MedicationLogModel log) async {
    await _logs.doc(log.logId).set(log.toMap());
  }

  /// Delete a medication log (used for untoggling).
  Future<void> deleteMedicationLog(String logId) async {
    await _logs.doc(logId).delete();
  }

  /// Stream today's logs for a set of medicines.
  Stream<List<MedicationLogModel>> watchTodayLogs(List<String> medicineIds) {
    if (medicineIds.isEmpty) return Stream.value([]);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _logs
        .where('medicineId', whereIn: medicineIds)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MedicationLogModel.fromDocument(d)).toList(),
        );
  }

  /// Helper: compute a deterministic log doc ID for use in the UI layer.
  String computeLogId(
    String medicineId,
    DateTime date, [
    MedicineTiming? slot,
  ]) {
    return _logDocId(medicineId, date, slot);
  }
}
