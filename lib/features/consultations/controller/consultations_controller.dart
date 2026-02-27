import 'package:health_connect/models/medicine_model.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:health_connect/features/consultations/repository/doctor_repository.dart';
import 'package:health_connect/features/consultations/repository/gemini_service.dart';
import 'package:health_connect/models/doctor_visit_model.dart';
import 'package:health_connect/providers/user_provider.dart';
import 'package:health_connect/features/caretaker/controller/caretaker_controller.dart';
import 'package:health_connect/utils/storage_methods.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Streams doctor visits across all family members + the caretaker themselves.
final caretakerVisitsProvider = StreamProvider<List<DoctorVisitModel>>((ref) {
  final membersAsync = ref.watch(familyMembersProvider);
  final repo = ref.watch(doctorRepositoryProvider);
  final user = ref.watch(userProvider);

  return membersAsync.when(
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
    data: (members) {
      final ids = members.map((m) => m.uid).toList();
      // Include caretaker's own uid so self-visits also show
      if (user != null && !ids.contains(user.uid)) {
        ids.add(user.uid);
      }
      if (ids.isEmpty) return Stream.value([]);
      return repo.watchAllFamilyVisits(ids);
    },
  );
});

/// Controller for the add-visit flow.
final addVisitControllerProvider =
    StateNotifierProvider<AddVisitController, AddVisitState>((ref) {
      return AddVisitController(ref: ref);
    });

/// Provider to watch medicines for a specific visit.
final visitMedicinesProvider =
    StreamProvider.family<List<MedicineModel>, String>((ref, visitId) {
      return ref
          .watch(doctorRepositoryProvider)
          .getMedicinesForVisit(visitId)
          .asStream();
    });

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AddVisitState {
  final bool isUploading;
  final bool isExtracting;
  final bool isSaving;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final List<ExtractedMedicine> extractedMedicines;
  final String? selectedMemberId;
  final String? errorMessage;

  const AddVisitState({
    this.isUploading = false,
    this.isExtracting = false,
    this.isSaving = false,
    this.imageBytes,
    this.imageUrl,
    this.extractedMedicines = const [],
    this.selectedMemberId,
    this.errorMessage,
  });

  AddVisitState copyWith({
    bool? isUploading,
    bool? isExtracting,
    bool? isSaving,
    Uint8List? imageBytes,
    String? imageUrl,
    List<ExtractedMedicine>? extractedMedicines,
    String? selectedMemberId,
    String? errorMessage,
  }) {
    return AddVisitState(
      isUploading: isUploading ?? this.isUploading,
      isExtracting: isExtracting ?? this.isExtracting,
      isSaving: isSaving ?? this.isSaving,
      imageBytes: imageBytes ?? this.imageBytes,
      imageUrl: imageUrl ?? this.imageUrl,
      extractedMedicines: extractedMedicines ?? this.extractedMedicines,
      selectedMemberId: selectedMemberId ?? this.selectedMemberId,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => isUploading || isExtracting || isSaving;
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class AddVisitController extends StateNotifier<AddVisitState> {
  final Ref _ref;
  final _uuid = const Uuid();

  AddVisitController({required Ref ref})
    : _ref = ref,
      super(const AddVisitState());

  /// Pick image from gallery.
  Future<void> pickImage() async {
    print('📸 [pickImage] called');
    try {
      final picker = ImagePicker();
      print('📸 [pickImage] ImagePicker created, opening gallery...');
      final picked = await picker.pickImage(source: ImageSource.gallery);
      print(
        '📸 [pickImage] picker returned: ${picked?.path ?? "null (user cancelled)"}',
      );
      if (picked == null) return;
      final file = File(picked.path);
      print(
        '📸 [pickImage] File exists: ${file.existsSync()}, size: ${file.lengthSync()} bytes',
      );
      final bytes = await file.readAsBytes();
      print('📸 [pickImage] Read ${bytes.length} bytes, updating state...');
      state = state.copyWith(imageBytes: bytes);
      print(
        '📸 [pickImage] ✅ State updated, imageBytes length: ${state.imageBytes?.length}',
      );
    } catch (e, stackTrace) {
      print('📸 [pickImage] ❌ ERROR: $e');
      print('📸 [pickImage] StackTrace: $stackTrace');
      state = state.copyWith(errorMessage: 'Failed to pick image: $e');
    }
  }

  /// Pick image from camera.
  Future<void> captureImage() async {
    print('📷 [captureImage] called');
    try {
      final picker = ImagePicker();
      print('📷 [captureImage] ImagePicker created, opening camera...');
      final picked = await picker.pickImage(source: ImageSource.camera);
      print(
        '📷 [captureImage] picker returned: ${picked?.path ?? "null (user cancelled)"}',
      );
      if (picked == null) return;
      final file = File(picked.path);
      print(
        '📷 [captureImage] File exists: ${file.existsSync()}, size: ${file.lengthSync()} bytes',
      );
      final bytes = await file.readAsBytes();
      print('📷 [captureImage] Read ${bytes.length} bytes, updating state...');
      state = state.copyWith(imageBytes: bytes);
      print(
        '📷 [captureImage] ✅ State updated, imageBytes length: ${state.imageBytes?.length}',
      );
    } catch (e, stackTrace) {
      print('📷 [captureImage] ❌ ERROR: $e');
      print('📷 [captureImage] StackTrace: $stackTrace');
      state = state.copyWith(errorMessage: 'Failed to capture image: $e');
    }
  }

  /// Upload image to Supabase and extract medicines via Gemini.
  Future<void> uploadAndExtract() async {
    if (state.imageBytes == null) return;

    // Step 1: Upload to Supabase
    state = state.copyWith(isUploading: true, errorMessage: null);
    final url = await StorageMethods().uploadPrescriptionImage(
      state.imageBytes!,
    );
    if (url == null) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Image upload failed. Please try again.',
      );
      return;
    }
    state = state.copyWith(isUploading: false, imageUrl: url);

    // Step 2: Extract medicines via Gemini
    state = state.copyWith(isExtracting: true);
    final gemini = _ref.read(geminiServiceProvider);
    final medicines = await gemini.extractMedicines(state.imageBytes!);
    print(
      medicines.isEmpty
          ? '⚠️ No medicines extracted from Gemini.'
          : '✅ Extracted ${medicines.length} medicines from Gemini.',
    );
    state = state.copyWith(isExtracting: false, extractedMedicines: medicines);
  }

  /// Set selected family member (caretaker picking for whom).
  void selectMember(String memberId) {
    state = state.copyWith(selectedMemberId: memberId);
  }

  /// Update an extracted medicine at a given index.
  void updateMedicine(int index, ExtractedMedicine updated) {
    final list = [...state.extractedMedicines];
    list[index] = updated;
    state = state.copyWith(extractedMedicines: list);
  }

  /// Remove an extracted medicine at a given index.
  void removeMedicine(int index) {
    final list = [...state.extractedMedicines];
    list.removeAt(index);
    state = state.copyWith(extractedMedicines: list);
  }

  /// Manually update a medicine in Firestore (for edits).
  Future<void> updateMedicineInDb(MedicineModel medicine) async {
    await _ref.read(doctorRepositoryProvider).updateMedicine(medicine);
  }

  /// Add a new blank medicine for manual entry.
  void addBlankMedicine() {
    final list = [
      ...state.extractedMedicines,
      const ExtractedMedicine(
        name: '',
        dosage: '',
        frequency: MedicineFrequency.once,
      ),
    ];
    state = state.copyWith(extractedMedicines: list);
  }

  /// Save visit + medicines to Firestore.
  Future<bool> saveVisit({
    required String doctorName,
    required DateTime visitDate,
    String? notes,
  }) async {
    final user = _ref.read(userProvider);
    if (user == null) return false;

    // Determine which member these medicines belong to.
    // Caretaker must select; family member auto-assigns to self.
    final memberId = user.isCaretaker ? state.selectedMemberId : user.uid;

    if (memberId == null) {
      state = state.copyWith(errorMessage: 'Please select a family member.');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final repo = _ref.read(doctorRepositoryProvider);
      final visitId = _uuid.v4();

      // Convert extracted medicines to MedicineModels
      final medicineModels = state.extractedMedicines.map((em) {
        return em.toMedicineModel(
          medicineId: _uuid.v4(),
          memberId: memberId,
          visitId: visitId,
        );
      }).toList();

      // Create visit
      final visit = DoctorVisitModel(
        visitId: visitId,
        memberId: memberId,
        doctorName: doctorName,
        visitDate: visitDate,
        notes: notes,
        prescriptionImageUrl: state.imageUrl,
        medicineIds: medicineModels.map((m) => m.medicineId).toList(),
      );

      await repo.addVisit(visit);
      if (medicineModels.isNotEmpty) {
        await repo.saveMedicines(medicineModels);
      }

      state = const AddVisitState(); // reset
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save: $e',
      );
      return false;
    }
  }

  /// Reset the controller state.
  void reset() {
    state = const AddVisitState();
  }
}
