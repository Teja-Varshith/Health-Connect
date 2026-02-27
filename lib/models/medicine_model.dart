import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Enum for medicine intake timing
enum MedicineTiming { morning, afternoon, evening, night }

extension MedicineTimingX on MedicineTiming {
  /// Default suggested time for each slot
  TimeOfDay get defaultTime {
    switch (this) {
      case MedicineTiming.morning:
        return const TimeOfDay(hour: 8, minute: 0);
      case MedicineTiming.afternoon:
        return const TimeOfDay(hour: 13, minute: 0);
      case MedicineTiming.evening:
        return const TimeOfDay(hour: 18, minute: 0);
      case MedicineTiming.night:
        return const TimeOfDay(hour: 21, minute: 0);
    }
  }

  String get label {
    switch (this) {
      case MedicineTiming.morning:
        return 'Morning';
      case MedicineTiming.afternoon:
        return 'Afternoon';
      case MedicineTiming.evening:
        return 'Evening';
      case MedicineTiming.night:
        return 'Night';
    }
  }

  String get emoji {
    switch (this) {
      case MedicineTiming.morning:
        return '🌅';
      case MedicineTiming.afternoon:
        return '☀️';
      case MedicineTiming.evening:
        return '🌇';
      case MedicineTiming.night:
        return '🌙';
    }
  }
}

/// Enum for frequency type
enum MedicineFrequency { once, twice, thrice, custom }

class MedicineModel {
  final String medicineId;
  final String memberId;
  final String visitId;
  final String name;
  final String dosage;
  final MedicineFrequency frequency;
  final List<MedicineTiming> timing;

  /// Maps each timing slot to a scheduled time (e.g. morning → 08:00)
  final Map<MedicineTiming, TimeOfDay>? scheduledTimes;
  final int? numberOfDays;
  final String? note;
  final bool isActive;
  final DateTime? createdAt;

  const MedicineModel({
    required this.medicineId,
    required this.memberId,
    required this.visitId,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.timing = const [],
    this.scheduledTimes,
    this.numberOfDays,
    this.note,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    // Serialize scheduledTimes as {"morning": "08:00", "evening": "20:00"}
    Map<String, String>? timesMap;
    if (scheduledTimes != null && scheduledTimes!.isNotEmpty) {
      timesMap = {
        for (final entry in scheduledTimes!.entries)
          describeEnum(entry.key): _timeToString(entry.value),
      };
    }

    return {
      'medicineId': medicineId,
      'memberId': memberId,
      'visitId': visitId,
      'name': name,
      'dosage': dosage,
      'frequency': describeEnum(frequency),
      'timing': timing.map((e) => describeEnum(e)).toList(),
      if (timesMap != null) 'scheduledTimes': timesMap,
      if (numberOfDays != null) 'numberOfDays': numberOfDays,
      if (note != null) 'note': note,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    // Parse scheduledTimes
    Map<MedicineTiming, TimeOfDay>? scheduledTimes;
    final rawTimes = map['scheduledTimes'] as Map<String, dynamic>?;
    if (rawTimes != null) {
      scheduledTimes = {};
      rawTimes.forEach((key, value) {
        final slot = MedicineTiming.values.firstWhere(
          (e) => describeEnum(e) == key,
          orElse: () => MedicineTiming.morning,
        );
        scheduledTimes![slot] = _parseTime(value as String);
      });
    }

    return MedicineModel(
      medicineId: map['medicineId'] as String,
      memberId: map['memberId'] as String,
      visitId: map['visitId'] as String,
      name: map['name'] as String,
      dosage: map['dosage'] as String? ?? '',
      frequency: MedicineFrequency.values.firstWhere(
        (e) => describeEnum(e) == (map['frequency'] ?? 'once'),
        orElse: () => MedicineFrequency.once,
      ),
      timing: (map['timing'] as List<dynamic>? ?? [])
          .map(
            (e) => MedicineTiming.values.firstWhere(
              (tim) => describeEnum(tim) == e,
              orElse: () => MedicineTiming.morning,
            ),
          )
          .toList(),
      scheduledTimes: scheduledTimes,
      numberOfDays: map['numberOfDays'] as int?,
      note: map['note'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory MedicineModel.fromDocument(DocumentSnapshot doc) =>
      MedicineModel.fromMap(doc.data() as Map<String, dynamic>);

  MedicineModel copyWith({
    String? medicineId,
    String? memberId,
    String? visitId,
    String? name,
    String? dosage,
    MedicineFrequency? frequency,
    List<MedicineTiming>? timing,
    Map<MedicineTiming, TimeOfDay>? scheduledTimes,
    int? numberOfDays,
    String? note,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return MedicineModel(
      medicineId: medicineId ?? this.medicineId,
      memberId: memberId ?? this.memberId,
      visitId: visitId ?? this.visitId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      timing: timing ?? this.timing,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _timeToString(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 8, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  /// Returns the scheduled TimeOfDay for a given timing slot (or default).
  TimeOfDay scheduledTimeFor(MedicineTiming slot) =>
      scheduledTimes?[slot] ?? slot.defaultTime;

  /// Human-readable scheduled time string (e.g. "8:00 AM")
  String scheduledTimeStringFor(MedicineTiming slot) {
    final t = scheduledTimeFor(slot);
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }
}
