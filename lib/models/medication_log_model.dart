import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:health_connect/models/medicine_model.dart';

enum MedicationStatus { taken, missed }

extension MedicationStatusX on MedicationStatus {
  String get value => this == MedicationStatus.taken ? 'taken' : 'missed';

  static MedicationStatus fromString(String? s) =>
      s == 'taken' ? MedicationStatus.taken : MedicationStatus.missed;
}

class MedicationLogModel {
  final String logId;
  final String medicineId;
  final DateTime date;
  final MedicationStatus status;

  /// Which timing slot this log is for (morning/afternoon/evening/night)
  final MedicineTiming? timingSlot;

  /// The actual moment the user marked the medicine as taken/missed
  final DateTime? takenAt;

  const MedicationLogModel({
    required this.logId,
    required this.medicineId,
    required this.date,
    required this.status,
    this.timingSlot,
    this.takenAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'medicineId': medicineId,
      'date': Timestamp.fromDate(date),
      'status': status.value,
      if (timingSlot != null) 'timingSlot': describeEnum(timingSlot!),
      'takenAt': takenAt != null
          ? Timestamp.fromDate(takenAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory MedicationLogModel.fromMap(Map<String, dynamic> map) {
    MedicineTiming? slot;
    final rawSlot = map['timingSlot'] as String?;
    if (rawSlot != null) {
      slot = MedicineTiming.values.firstWhere(
        (e) => describeEnum(e) == rawSlot,
        orElse: () => MedicineTiming.morning,
      );
    }

    return MedicationLogModel(
      logId: map['logId'] as String,
      medicineId: map['medicineId'] as String,
      date: (map['date'] as Timestamp).toDate(),
      status: MedicationStatusX.fromString(map['status'] as String?),
      timingSlot: slot,
      takenAt: (map['takenAt'] as Timestamp?)?.toDate(),
    );
  }

  factory MedicationLogModel.fromDocument(DocumentSnapshot doc) =>
      MedicationLogModel.fromMap(doc.data() as Map<String, dynamic>);

  MedicationLogModel copyWith({
    String? logId,
    String? medicineId,
    DateTime? date,
    MedicationStatus? status,
    MedicineTiming? timingSlot,
    DateTime? takenAt,
  }) {
    return MedicationLogModel(
      logId: logId ?? this.logId,
      medicineId: medicineId ?? this.medicineId,
      date: date ?? this.date,
      status: status ?? this.status,
      timingSlot: timingSlot ?? this.timingSlot,
      takenAt: takenAt ?? this.takenAt,
    );
  }

  /// Formats takenAt as a short human-readable string, e.g. "9:05 AM"
  String? get takenAtFormatted {
    if (takenAt == null) return null;
    final h = takenAt!.hour;
    final m = takenAt!.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:$m $period';
  }
}
