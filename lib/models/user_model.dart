import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum UserRole { caretaker, familyMember }

extension UserRoleX on UserRole {
  String get value =>
      this == UserRole.caretaker ? 'caretaker' : 'family_member';

  static UserRole fromString(String? s) =>
      s == 'caretaker' ? UserRole.caretaker : UserRole.familyMember;
}

enum Gender { male, female, other }

extension GenderX on Gender {
  String get value {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }

  static Gender fromString(String? s) {
    switch (s) {
      case 'Male':
        return Gender.male;
      case 'Female':
        return Gender.female;
      default:
        return Gender.other;
    }
  }
}

enum BloodGroup {
  aPosive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
}

extension BloodGroupX on BloodGroup {
  String get value {
    switch (this) {
      case BloodGroup.aPosive:
        return 'A+';
      case BloodGroup.aNegative:
        return 'A-';
      case BloodGroup.bPositive:
        return 'B+';
      case BloodGroup.bNegative:
        return 'B-';
      case BloodGroup.abPositive:
        return 'AB+';
      case BloodGroup.abNegative:
        return 'AB-';
      case BloodGroup.oPositive:
        return 'O+';
      case BloodGroup.oNegative:
        return 'O-';
    }
  }

  static BloodGroup fromString(String? s) {
    switch (s) {
      case 'A+':
        return BloodGroup.aPosive;
      case 'A-':
        return BloodGroup.aNegative;
      case 'B+':
        return BloodGroup.bPositive;
      case 'B-':
        return BloodGroup.bNegative;
      case 'AB+':
        return BloodGroup.abPositive;
      case 'AB-':
        return BloodGroup.abNegative;
      case 'O+':
        return BloodGroup.oPositive;
      case 'O-':
        return BloodGroup.oNegative;
      default:
        return BloodGroup.oPositive;
    }
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? phoneNumber;

  final String? familyCode;

  final String? caretakerId;

  final int? age;
  final Gender? gender;
  final BloodGroup? bloodGroup;

  final bool isProfileComplete;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.phoneNumber,
    this.familyCode,
    this.caretakerId,
    this.age,
    this.gender,
    this.bloodGroup,
    this.isProfileComplete = false,
    this.createdAt,
  });

  // ─── Firestore serialisation ──────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.value,
      'phoneNumber': phoneNumber,
      if (familyCode != null) 'familyCode': familyCode,
      if (caretakerId != null) 'caretakerId': caretakerId,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender!.value,
      if (bloodGroup != null) 'bloodGroup': bloodGroup!.value,
      'isProfileComplete': isProfileComplete,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      role: UserRoleX.fromString(map['role'] as String?),
      familyCode: map['familyCode'] as String?,
      caretakerId: map['caretakerId'] as String?,
      age: map['age'] as int?,
      gender: map['gender'] != null
          ? GenderX.fromString(map['gender'] as String)
          : null,
      bloodGroup: map['bloodGroup'] != null
          ? BloodGroupX.fromString(map['bloodGroup'] as String)
          : null,
      isProfileComplete: map['isProfileComplete'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) =>
      UserModel.fromMap(doc.data() as Map<String, dynamic>);

  // ─── Convenience ─────────────────────────────────────────────────────────

  bool get isCaretaker => role == UserRole.caretaker;
  bool get isFamilyMember => role == UserRole.familyMember;

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    String? phoneNumber,
    String? familyCode,
    String? caretakerId,
    int? age,
    Gender? gender,
    BloodGroup? bloodGroup,
    bool? isProfileComplete,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      familyCode: familyCode ?? this.familyCode,
      caretakerId: caretakerId ?? this.caretakerId,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, name: $name, role: ${role.value}, profileComplete: $isProfileComplete)';
}
