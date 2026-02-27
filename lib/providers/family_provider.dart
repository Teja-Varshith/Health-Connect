import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/models/user_model.dart';

/// Streams all family members whose `familyCode` matches the caretaker's code.
/// Returns an empty list when there are no members yet.
final familyMembersProvider = StreamProvider.family<List<UserModel>, String>((
  ref,
  familyCode,
) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('familyCode', isEqualTo: familyCode)
      .where('role', isEqualTo: 'family_member')
      .snapshots()
      .map((snap) => snap.docs.map((d) => UserModel.fromDocument(d)).toList());
});
