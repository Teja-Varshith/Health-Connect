import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:health_connect/models/medicine_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class GeminiService {
  // TODO: Move API key to environment variable / secure storage
  static const String _apiKey = 'AIzaSyBhweQq9NBUEzAnpx4XW4XUmu7NDj8PSao';

  /// Sends a prescription image to Gemini and returns extracted medicines.
  /// Returns an empty list if extraction fails (fallback to manual entry).
  Future<List<ExtractedMedicine>> extractMedicines(Uint8List imageBytes) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: _apiKey,
      );

      final prompt = TextPart('''
Analyze this prescription image and extract all medicines prescribed.
Return ONLY a valid JSON object with this exact structure, no markdown:
{
  "medicines": [
    {
      "name": "medicine name",
      "dosage": "dosage amount, e.g. 500mg",
      "frequency": "how often, e.g. twice",
      "timing": ["morning", "night"],
      "scheduledTimes": {"morning": "08:00", "night": "21:00"},
      "numberOfDays": 5,
      "note": "short description of why this medicine is prescribed"
    }
  ]
}
frequency must be one of: once, twice, thrice, custom.
timing values must be from: morning, afternoon, evening, night.
scheduledTimes keys must match the timing list. Use 24-hour HH:mm format.
If you cannot read the prescription clearly, return: {"medicines": []}
''');

      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) return [];

      print(text);

      return _parseResponse(text);
    } catch (e) {
      print('Gemini extraction error: $e');
      return [];
    }
  }

  /// Parse raw Gemini response text into ExtractedMedicine objects.
  List<ExtractedMedicine> _parseResponse(String rawText) {
    try {
      // Strip markdown code fences if present
      String cleaned = rawText.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```json?\s*'), '')
            .replaceFirst(RegExp(r'```\s*$'), '')
            .trim();
      }

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final medicines = json['medicines'] as List<dynamic>? ?? [];

      return medicines.map((m) {
        final map = m as Map<String, dynamic>;

        // Parse timing list
        final timingList = (map['timing'] as List<dynamic>? ?? [])
            .map(
              (e) => MedicineTiming.values.firstWhere(
                (tim) => tim.name == e,
                orElse: () => MedicineTiming.morning,
              ),
            )
            .toList();

        // Parse scheduledTimes map
        Map<MedicineTiming, TimeOfDay>? scheduledTimes;
        final rawTimes = map['scheduledTimes'] as Map<String, dynamic>?;
        if (rawTimes != null) {
          scheduledTimes = {};
          rawTimes.forEach((key, value) {
            final slot = MedicineTiming.values.firstWhere(
              (e) => e.name == key,
              orElse: () => MedicineTiming.morning,
            );
            scheduledTimes![slot] = _parseTimeString(value as String);
          });
        }

        return ExtractedMedicine(
          name: map['name'] as String? ?? '',
          dosage: map['dosage'] as String? ?? '',
          frequency: MedicineFrequency.values.firstWhere(
            (e) => e.name == (map['frequency'] ?? 'once'),
            orElse: () => MedicineFrequency.once,
          ),
          timing: timingList,
          scheduledTimes: scheduledTimes,
          numberOfDays: map['numberOfDays'] as int?,
          note: map['note'] as String?,
        );
      }).toList();
    } catch (e) {
      print('Failed to parse Gemini response: $e');
      return [];
    }
  }

  static TimeOfDay _parseTimeString(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 8, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Intermediate model — before assigning memberId / visitId
// ---------------------------------------------------------------------------

class ExtractedMedicine {
  final String name;
  final String dosage;
  final MedicineFrequency frequency;
  final List<MedicineTiming> timing;
  final Map<MedicineTiming, TimeOfDay>? scheduledTimes;
  final int? numberOfDays;
  final String? note;

  const ExtractedMedicine({
    required this.name,
    required this.dosage,
    required this.frequency,
    this.timing = const [],
    this.scheduledTimes,
    this.numberOfDays,
    this.note,
  });

  /// Convert to a full MedicineModel with assigned IDs.
  MedicineModel toMedicineModel({
    required String medicineId,
    required String memberId,
    required String visitId,
  }) {
    return MedicineModel(
      medicineId: medicineId,
      memberId: memberId,
      visitId: visitId,
      name: name,
      dosage: dosage,
      frequency: frequency,
      timing: timing,
      scheduledTimes: scheduledTimes,
      numberOfDays: numberOfDays,
      note: note,
    );
  }

  ExtractedMedicine copyWith({
    String? name,
    String? dosage,
    MedicineFrequency? frequency,
    List<MedicineTiming>? timing,
    Map<MedicineTiming, TimeOfDay>? scheduledTimes,
    int? numberOfDays,
    String? note,
  }) {
    return ExtractedMedicine(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      timing: timing ?? this.timing,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      note: note ?? this.note,
    );
  }
}
