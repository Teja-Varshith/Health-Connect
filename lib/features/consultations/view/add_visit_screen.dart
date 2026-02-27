import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/features/caretaker/controller/caretaker_controller.dart';
import 'package:health_connect/features/consultations/controller/consultations_controller.dart';
import 'package:health_connect/features/consultations/repository/gemini_service.dart';
import 'package:health_connect/models/user_model.dart';
import 'package:health_connect/models/medicine_model.dart';
import 'package:health_connect/providers/user_provider.dart';
import 'package:intl/intl.dart';

const _kTeal = Color(0xFF00897B);
const _kTealDark = Color(0xFF00695C);
const _kDark = Color(0xFF1A1A2E);

class AddVisitScreen extends ConsumerStatefulWidget {
  const AddVisitScreen({super.key});

  @override
  ConsumerState<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends ConsumerState<AddVisitScreen> {
  final _doctorNameController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _visitDate = DateTime.now();
  int _currentStep = 0; // 0 = details, 1 = extracting/editing, 2 = confirm
  bool _isForSelf = false; // caretaker toggle: for self vs family member

  @override
  void dispose() {
    _doctorNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visitState = ref.watch(addVisitControllerProvider);
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _kTeal,
        foregroundColor: Colors.white,
        title: const Text(
          'Add Consultation',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            _stepIndicator(),
            // Content
            Expanded(
              child: _currentStep == 0
                  ? _detailsStep(visitState, user)
                  : _currentStep == 1
                  ? _extractionStep(visitState)
                  : _confirmStep(visitState),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STEP INDICATOR
  // ════════════════════════════════════════════════════════════════════════════

  Widget _stepIndicator() {
    final labels = ['Details', 'Medicines', 'Confirm'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: Colors.white,
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isActive ? _kTeal : Colors.grey.shade200,
                    ),
                  ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive ? _kTeal : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STEP 1 — Details
  // ════════════════════════════════════════════════════════════════════════════

  Widget _detailsStep(AddVisitState visitState, UserModel? user) {
    final membersAsync = ref.watch(familyMembersProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Who is this consultation for? (caretaker only)
        if (user != null && user.isCaretaker) ...[
          const Text(
            'Consultation For',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 8),
          // Toggle: For Myself / For Family Member
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isForSelf = true);
                    ref
                        .read(addVisitControllerProvider.notifier)
                        .selectMember(user.uid);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isForSelf ? _kTeal : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'For Myself',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isForSelf
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isForSelf = false);
                    // Clear the caretaker's own uid from selectedMemberId
                    ref
                        .read(addVisitControllerProvider.notifier)
                        .selectMember('');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isForSelf ? _kTeal : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'For Family Member',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !_isForSelf
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Show member dropdown only when "For Family Member" is selected
          if (!_isForSelf)
            membersAsync.when(
              loading: () => const LinearProgressIndicator(color: _kTeal),
              error: (_, __) => const Text('Could not load members'),
              data: (members) => _memberDropdown(members, visitState),
            ),
          const SizedBox(height: 20),
        ],

        // Doctor name
        const Text(
          'Doctor Name',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 8),
        _inputField(
          controller: _doctorNameController,
          hint: 'e.g. Dr. Raghav Mehta',
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 20),

        // Visit date
        const Text(
          'Visit Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd MMM yyyy').format(_visitDate),
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Notes
        const Text(
          'Notes (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 8),
        _inputField(
          controller: _notesController,
          hint: 'Diagnosis, remarks...',
          icon: Icons.notes_rounded,
          maxLines: 3,
        ),
        const SizedBox(height: 24),

        // Prescription image
        const Text(
          'Prescription Image',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 8),
        _imagePickArea(visitState),

        const SizedBox(height: 32),

        // Next button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: visitState.isLoading ? null : _onDetailsNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: visitState.isUploading || visitState.isExtracting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Extract Medicines →',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _memberDropdown(List<UserModel> members, AddVisitState visitState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: members.any((m) => m.uid == visitState.selectedMemberId)
              ? visitState.selectedMemberId
              : null,
          hint: Text(
            'Select member',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          isExpanded: true,
          items: members
              .map((m) => DropdownMenuItem(value: m.uid, child: Text(m.name)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              ref.read(addVisitControllerProvider.notifier).selectMember(v);
            }
          },
        ),
      ),
    );
  }

  Widget _imagePickArea(AddVisitState visitState) {
    if (visitState.imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Image.memory(
              visitState.imageBytes!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () =>
                    ref.read(addVisitControllerProvider.notifier).reset(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showImagePickerSheet(),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 36,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to upload prescription',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerSheet() {
    print('🖼️ [_showImagePickerSheet] opening sheet...');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: _kTeal),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  print('🖼️ [Gallery] tapped');
                  Navigator.pop(context);
                  ref.read(addVisitControllerProvider.notifier).pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: _kTeal),
                title: const Text('Take a Photo'),
                onTap: () {
                  print('📷 [Camera] tapped');
                  Navigator.pop(context);
                  ref.read(addVisitControllerProvider.notifier).captureImage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _kTeal)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  void _onDetailsNext() {
    if (_doctorNameController.text.trim().isEmpty) {
      _showError('Please enter the doctor\'s name');
      return;
    }

    final state = ref.read(addVisitControllerProvider);
    final user = ref.read(userProvider);

    // If caretaker chose "For Myself", auto-assign their own uid
    if (user != null && user.isCaretaker) {
      if (_isForSelf) {
        ref.read(addVisitControllerProvider.notifier).selectMember(user.uid);
      } else if (state.selectedMemberId == null) {
        _showError('Please select a family member');
        return;
      }
    }

    if (state.imageBytes == null) {
      _showError('Please upload a prescription image');
      return;
    }

    // Upload + extract
    ref.read(addVisitControllerProvider.notifier).uploadAndExtract().then((_) {
      if (mounted) setState(() => _currentStep = 1);
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STEP 2 — Extraction / Editing
  // ════════════════════════════════════════════════════════════════════════════

  Widget _extractionStep(AddVisitState visitState) {
    if (visitState.isExtracting || visitState.isUploading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _kTeal),
            const SizedBox(height: 16),
            Text(
              visitState.isUploading
                  ? 'Uploading prescription...'
                  : 'Extracting medicines with AI...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final medicines = visitState.extractedMedicines;
    final controller = ref.read(addVisitControllerProvider.notifier);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  medicines.isEmpty
                      ? 'No medicines detected — add manually'
                      : '${medicines.length} medicines found',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => controller.addBlankMedicine(),
                icon: const Icon(Icons.add_rounded, size: 18, color: _kTeal),
                label: const Text(
                  'Add',
                  style: TextStyle(color: _kTeal, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        // Medicine cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: medicines.length,
            itemBuilder: (_, i) =>
                _editableMedicineCard(medicines[i], i, controller),
          ),
        ),

        // Bottom buttons
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep = 0),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kDark,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _currentStep = 2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Review →',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editableMedicineCard(
    ExtractedMedicine med,
    int index,
    AddVisitController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with delete
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: _kTeal,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Medicine ${index + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => controller.removeMedicine(index),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade400,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _miniField(
            'Name',
            med.name,
            (v) => controller.updateMedicine(index, med.copyWith(name: v)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _miniField(
                  'Dosage',
                  med.dosage,
                  (v) =>
                      controller.updateMedicine(index, med.copyWith(dosage: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _frequencyDropdown(med, index, controller)),
            ],
          ),
          const SizedBox(height: 10),
          // Timing chip selector
          _timingChipSelector(med, index, controller),
          const SizedBox(height: 8),
          _miniField(
            'Days (optional)',
            med.numberOfDays?.toString() ?? '',
            (v) => controller.updateMedicine(
              index,
              med.copyWith(numberOfDays: int.tryParse(v)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _frequencyDropdown(
    ExtractedMedicine med,
    int index,
    AddVisitController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MedicineFrequency>(
          value: med.frequency,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: MedicineFrequency.values
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(f.name[0].toUpperCase() + f.name.substring(1)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              controller.updateMedicine(index, med.copyWith(frequency: v));
            }
          },
        ),
      ),
    );
  }

  Widget _timingChipSelector(
    ExtractedMedicine med,
    int index,
    AddVisitController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timing & Schedule',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: MedicineTiming.values.map((slot) {
            final isSelected = med.timing.contains(slot);
            final scheduledTime = med.scheduledTimes?[slot];

            String timeLabel = '';
            if (scheduledTime != null) {
              final h = scheduledTime.hourOfPeriod == 0
                  ? 12
                  : scheduledTime.hourOfPeriod;
              final m = scheduledTime.minute.toString().padLeft(2, '0');
              final period = scheduledTime.period == DayPeriod.am ? 'AM' : 'PM';
              timeLabel = ' $h:$m $period';
            }

            return GestureDetector(
              onTap: () async {
                if (!isSelected) {
                  // Select this slot, open time picker
                  final newTiming = [...med.timing, slot];
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: slot.defaultTime,
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(primary: _kTeal),
                      ),
                      child: child!,
                    ),
                  );
                  final newTimes = Map<MedicineTiming, TimeOfDay>.from(
                    med.scheduledTimes ?? {},
                  );
                  if (picked != null) newTimes[slot] = picked;
                  controller.updateMedicine(
                    index,
                    med.copyWith(timing: newTiming, scheduledTimes: newTimes),
                  );
                } else {
                  // Deselect — remove from timing + scheduledTimes
                  final newTiming = med.timing.where((t) => t != slot).toList();
                  final newTimes = Map<MedicineTiming, TimeOfDay>.from(
                    med.scheduledTimes ?? {},
                  )..remove(slot);
                  controller.updateMedicine(
                    index,
                    med.copyWith(timing: newTiming, scheduledTimes: newTimes),
                  );
                }
              },
              onLongPress: isSelected
                  ? () async {
                      // Long press on selected chip → re-pick time
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: scheduledTime ?? slot.defaultTime,
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: _kTeal,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        final newTimes = Map<MedicineTiming, TimeOfDay>.from(
                          med.scheduledTimes ?? {},
                        )..[slot] = picked;
                        controller.updateMedicine(
                          index,
                          med.copyWith(scheduledTimes: newTimes),
                        );
                      }
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _kTeal : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _kTeal : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(slot.emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      slot.label + timeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (med.timing.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Long-press a selected chip to change time',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STEP 3 — Confirm
  // ════════════════════════════════════════════════════════════════════════════

  Widget _confirmStep(AddVisitState visitState) {
    final medicines = visitState.extractedMedicines;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryRow('Doctor', 'Dr. ${_doctorNameController.text}'),
                    _summaryRow(
                      'Date',
                      DateFormat('dd MMM yyyy').format(_visitDate),
                    ),
                    if (_notesController.text.isNotEmpty)
                      _summaryRow('Notes', _notesController.text),
                    _summaryRow('Medicines', '${medicines.length} items'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Medicine list
              ...medicines.asMap().entries.map((e) {
                final m = e.value;
                // final idx = e.key;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _kDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${m.dosage} • ${m.frequency.name}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            if (m.timing.isNotEmpty)
                              Text(
                                m.timing
                                    .map((t) {
                                      final st = m.scheduledTimes?[t];
                                      if (st != null) {
                                        final h = st.hourOfPeriod == 0
                                            ? 12
                                            : st.hourOfPeriod;
                                        final min = st.minute
                                            .toString()
                                            .padLeft(2, '0');
                                        final p = st.period == DayPeriod.am
                                            ? 'AM'
                                            : 'PM';
                                        return '${t.emoji} ${t.label} $h:$min $p';
                                      }
                                      return '${t.emoji} ${t.label}';
                                    })
                                    .join('  '),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            if (m.numberOfDays != null)
                              Text(
                                '📅 ${m.numberOfDays} days',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: _kTeal),
                        tooltip: 'Edit',
                        onPressed: () {
                          setState(() {
                            _currentStep = 1;
                          });
                          // Optionally, scroll to the medicine in the edit list
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        // Bottom buttons
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep = 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kDark,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: visitState.isSaving ? null : _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: visitState.isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Visit ✓',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    final success = await ref
        .read(addVisitControllerProvider.notifier)
        .saveVisit(
          doctorName: _doctorNameController.text.trim(),
          visitDate: _visitDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Visit saved successfully! ✓'),
          backgroundColor: _kTealDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }
}
