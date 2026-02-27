import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/models/user_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final caretakerRepositoryProvider = Provider<CaretakerRepository>((ref) {
  return CaretakerRepository(firestore: FirebaseFirestore.instance);
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class CaretakerRepository {
  final FirebaseFirestore _firestore;

  CaretakerRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Real-time stream of family members who share the same [familyCode].
  /// Only returns users with role == 'family_member'.
  Stream<List<UserModel>> watchFamilyMembers(String familyCode) {
    return _users
        .where('familyCode', isEqualTo: familyCode)
        .where('role', isEqualTo: 'family_member')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => UserModel.fromDocument(doc)).toList(),
        );
  }

  /// One-shot fetch of family members (useful for refresh).
  Future<List<UserModel>> getFamilyMembers(String familyCode) async {
    final snap = await _users
        .where('familyCode', isEqualTo: familyCode)
        .where('role', isEqualTo: 'family_member')
        .get();
    return snap.docs.map((doc) => UserModel.fromDocument(doc)).toList();
  }

  /// Removes a user from the family by clearing their familyCode.
  Future<void> removeFamilyMember(String uid) async {
    await _users.doc(uid).update({'familyCode': FieldValue.delete()});
  }
}
