import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/models/doctor_visit_model.dart';
import 'package:health_connect/models/medicine_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(firestore: FirebaseFirestore.instance);
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class DoctorRepository {
  final FirebaseFirestore _firestore;

  DoctorRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _visits =>
      _firestore.collection('doctor_visits');

  CollectionReference<Map<String, dynamic>> get _medicines =>
      _firestore.collection('medicines');

  // ── Doctor Visits ─────────────────────────────────────────────────────────

  /// Stream all visits for a specific family member, ordered by date desc.
  Stream<List<DoctorVisitModel>> watchVisits(String memberId) {
    return _visits
        .where('memberId', isEqualTo: memberId)
        .orderBy('visitDate', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => DoctorVisitModel.fromDocument(d)).toList(),
        );
  }

  /// Stream ALL visits across all members with a given familyCode.
  /// Useful for caretaker view — fetches visits for all family members.
  Stream<List<DoctorVisitModel>> watchAllFamilyVisits(List<String> memberIds) {
    if (memberIds.isEmpty) return Stream.value([]);
    return _visits
        .where('memberId', whereIn: memberIds)
        .orderBy('visitDate', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => DoctorVisitModel.fromDocument(d)).toList(),
        );
  }

  /// Save a new doctor visit and return the created model.
  Future<DoctorVisitModel> addVisit(DoctorVisitModel visit) async {
    await _visits.doc(visit.visitId).set(visit.toMap());
    return visit;
  }

  // ── Medicines ─────────────────────────────────────────────────────────────

  /// Batch-write a list of medicines for a visit.
  Future<void> saveMedicines(List<MedicineModel> medicines) async {
    final batch = _firestore.batch();
    for (final med in medicines) {
      batch.set(_medicines.doc(med.medicineId), med.toMap());
    }
    await batch.commit();
  }

  /// Get all active medicines for a member.
  Stream<List<MedicineModel>> watchMedicines(String memberId) {
    return _medicines
        .where('memberId', isEqualTo: memberId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MedicineModel.fromDocument(d)).toList(),
        );
  }

  /// Get medicines for a specific visit.
  Future<List<MedicineModel>> getMedicinesForVisit(String visitId) async {
    final snap = await _medicines.where('visitId', isEqualTo: visitId).get();
    return snap.docs.map((d) => MedicineModel.fromDocument(d)).toList();
  }

  /// Update an existing medicine's details.
  Future<void> updateMedicine(MedicineModel medicine) async {
    await _medicines.doc(medicine.medicineId).update(medicine.toMap());
  }
}
