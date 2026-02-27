import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/models/user_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

// Streams the current Firebase user — null when logged out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // --- Validate invite code (read-only) ------------------------------------

  Future<bool> validateFamilyCode(String code) async {
    final snapshot = await _users
        .where('familyCode', isEqualTo: code)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // --- Sign up -------------------------------------------------------------

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? familyCode,
  }) async {
    // ── For family members: validate invite code BEFORE creating account ────
    QueryDocumentSnapshot? caretakerDoc;

    if (role == UserRole.familyMember) {
      if (familyCode == null || familyCode.isEmpty) {
        throw Exception('Family code is required for family members.');
      }

      final caretakerSnapshot = await _users
          .where('familyCode', isEqualTo: familyCode)
          .limit(1)
          .get();

      if (caretakerSnapshot.docs.isEmpty) {
        throw Exception(
          'Invalid family code. Please check with your caretaker.',
        );
      }

      caretakerDoc = caretakerSnapshot.docs.first;
    }

    // ── Now safe to create the Firebase Auth account ────────────────────────
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user!.updateDisplayName(name);
    final uid = credential.user!.uid;

    late UserModel userModel;

    if (role == UserRole.caretaker) {
      final code = _generateFamilyCode(uid);
      userModel = UserModel(
        uid: uid,
        name: name,
        email: email,
        phoneNumber: null,
        role: UserRole.caretaker,
        familyCode: code,
      );
    } else {
      userModel = UserModel(
        uid: uid,
        name: name,
        email: email,
        phoneNumber: null,
        role: UserRole.familyMember,
        familyCode: familyCode,
        caretakerId: caretakerDoc!.id,
      );
    }

    await _users.doc(uid).set(userModel.toMap());

    // Send verification email then IMMEDIATELY sign out so the app
    // stays on loggedOutRoutes until the user verifies and signs in manually.
    await credential.user!.sendEmailVerification();
    await _auth.signOut();

    return userModel;
  }

  // --- Sign in -------------------------------------------------------------

  Future<void> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (!credential.user!.emailVerified) {
      // Auto-resend verification email on every unverified login attempt
      // (mirrors proven pattern — user gets email immediately without clicking Resend)
      try {
        await credential.user!.sendEmailVerification();
      } catch (_) {
        // Rate-limited — swallow silently, the throw below still informs the user
      }
      await _auth.signOut();
      throw Exception('not-verified');
    }
  }

  // --- Resend verification email -------------------------------------------

  Future<void> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    // Sign in temporarily to get the user object, then send verification
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (!credential.user!.emailVerified) {
      await credential.user!.sendEmailVerification();
    }
    await _auth.signOut();
  }

  // --- Complete health profile --------------------------------------------

  Future<UserModel> completeProfile({
    required String uid,
    required int age,
    required Gender gender,
    required BloodGroup bloodGroup,
    String? phoneNumber,
  }) async {
    final updates = <String, dynamic>{
      'age': age,
      'gender': gender.value,
      'bloodGroup': bloodGroup.value,
      'isProfileComplete': true,
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phoneNumber': phoneNumber,
    };
    return updateUser(uid, updates);
  }

  /// Update any user field.
  Future<UserModel> updateUser(String uid, Map<String, dynamic> updates) async {
    await _users.doc(uid).update(updates);
    final doc = await _users.doc(uid).get();
    return UserModel.fromDocument(doc);
  }

  // --- Sign out ------------------------------------------------------------

  Future<void> signOut() async => _auth.signOut();

  // --- Fetch UserModel for the current (or any) user ----------------------

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDocument(doc);
  }

  /// Real-time stream of the user document. Used by [userProvider] so that
  /// completing the profile automatically triggers re-routing in main.dart.
  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDocument(doc);
    });
  }

  // --- Helpers -------------------------------------------------------------

  String _generateFamilyCode(String uid) => uid.substring(0, 6).toUpperCase();
}
