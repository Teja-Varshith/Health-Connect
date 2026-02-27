import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorVisitModel {
  final String visitId;
  final String memberId;
  final String doctorName;
  final DateTime visitDate;
  final String? notes;
  final String? prescriptionImageUrl;
  final List<String> medicineIds;
  final DateTime? createdAt;

  const DoctorVisitModel({
    required this.visitId,
    required this.memberId,
    required this.doctorName,
    required this.visitDate,
    this.notes,
    this.prescriptionImageUrl,
    this.medicineIds = const [],
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'visitId': visitId,
      'memberId': memberId,
      'doctorName': doctorName,
      'visitDate': Timestamp.fromDate(visitDate),
      if (notes != null) 'notes': notes,
      if (prescriptionImageUrl != null)
        'prescriptionImageUrl': prescriptionImageUrl,
      'medicineIds': medicineIds,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory DoctorVisitModel.fromMap(Map<String, dynamic> map) {
    return DoctorVisitModel(
      visitId: map['visitId'] as String,
      memberId: map['memberId'] as String,
      doctorName: map['doctorName'] as String,
      visitDate: (map['visitDate'] as Timestamp).toDate(),
      notes: map['notes'] as String?,
      prescriptionImageUrl: map['prescriptionImageUrl'] as String?,
      medicineIds: List<String>.from(map['medicineIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory DoctorVisitModel.fromDocument(DocumentSnapshot doc) =>
      DoctorVisitModel.fromMap(doc.data() as Map<String, dynamic>);

  DoctorVisitModel copyWith({
    String? visitId,
    String? memberId,
    String? doctorName,
    DateTime? visitDate,
    String? notes,
    String? prescriptionImageUrl,
    List<String>? medicineIds,
    DateTime? createdAt,
  }) {
    return DoctorVisitModel(
      visitId: visitId ?? this.visitId,
      memberId: memberId ?? this.memberId,
      doctorName: doctorName ?? this.doctorName,
      visitDate: visitDate ?? this.visitDate,
      notes: notes ?? this.notes,
      prescriptionImageUrl: prescriptionImageUrl ?? this.prescriptionImageUrl,
      medicineIds: medicineIds ?? this.medicineIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
