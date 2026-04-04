import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

import 'package:flutter_bighustle/core/helpers/subscription_access.dart';
import 'package:flutter_bighustle/core/notifiers/snackbar_notifier.dart';
import 'package:flutter_bighustle/core/services/app_pigeon/app_pigeon.dart';
import 'package:flutter_bighustle/moduls/license/controller/license_create_controller.dart';
import 'package:flutter_bighustle/moduls/license/implement/license_interface_impl.dart';
import 'package:flutter_bighustle/moduls/license/interface/license_interface.dart';
import '../../model/profile_data.dart';

const Color _fieldBorderColor = Color(0xFFBDBDBD);
const Color _fieldHintColor = Color(0xFF9A9A9A);
const Color _fieldLabelColor = Color(0xFF222222);
const Color _primaryBlue = Color(0xFF1976F3);

class AddLicenseInfoScreen extends StatefulWidget {
  const AddLicenseInfoScreen({super.key});

  @override
  State<AddLicenseInfoScreen> createState() => _AddLicenseInfoScreenState();
}

class _AddLicenseInfoScreenState extends State<AddLicenseInfoScreen> {
  final ImagePicker _picker = ImagePicker();
  final _fullNameController = TextEditingController();
  final _userPhotoController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _licensePhotoController = TextEditingController();
  late final LicenseCreateController _controller;
  bool _initialized = false;
  bool _isSubmitting = false;
  String? _selectedState;
  String? _selectedLicenseClass;

  static const List<String> _stateAndCountryOptions = [
    'Alabama (US)',
    'Alaska (US)',
    'Arizona (US)',
    'California (US)',
    'Colorado (US)',
    'Florida (US)',
    'Georgia (US)',
    'Illinois (US)',
    'New York (US)',
    'Texas (US)',
    'Washington (US)',
    'Canada',
    'Mexico',
    'United Kingdom',
    'Australia',
    'India',
    'Philippines',
    'Nigeria',
    'Other',
  ];

  static const List<String> _licenseClassOptions = [
    'Class A',
    'Class B',
    'Class C',
    'Class D',
    'Class E',
    'Class M',
    'CDL',
  ];

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (!Get.isRegistered<LicenseInterface>()) {
        Get.put<LicenseInterface>(
          LicenseInterfaceImpl(appPigeon: Get.find<AppPigeon>()),
        );
      }
      _controller = LicenseCreateController(SnackbarNotifier(context: context));
      _controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _userPhotoController.dispose();
    _licenseNumberController.dispose();
    _dateOfBirthController.dispose();
    _expiryDateController.dispose();
    _licensePhotoController.dispose();
    if (_initialized) {
      _controller.removeListener(_onControllerUpdate);
      _controller.dispose();
    }
    super.dispose();
  }

  Future<bool> _ensureSubscribed(String featureName) async {
    return SubscriptionAccess.ensureSubscribedAction(
      context: context,
      featureName: featureName,
    );
  }

  Future<void> _pickImage({required bool isUserPhoto}) async {
    final canProceed = await _ensureSubscribed('License upload');
    if (!canProceed || !mounted) return;

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile == null) {
      return;
    }
    final fileName = pickedFile.name.isNotEmpty
        ? pickedFile.name
        : pickedFile.path.split('/').last;
    if (isUserPhoto) {
      _userPhotoController.text = fileName;
      _controller.userPhoto = pickedFile.path;
    } else {
      _licensePhotoController.text = fileName;
      _controller.licensePhoto = pickedFile.path;
    }
  }

  Future<void> _submit() async {
    final canProceed = await _ensureSubscribed(
      'License verification submission',
    );
    if (!canProceed || !mounted) return;

    setState(() => _isSubmitting = true);
    final success = await _controller.submit();
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
    if (success) {
      // keep inputs intact for now
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$month/$day/$year';
  }

  DateTime? _tryParseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (month == null || day == null || year == null) return null;
    return DateTime(year, month, day);
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    required bool isDob,
  }) async {
    final now = DateTime.now();
    final existing = _tryParseDate(controller.text);
    final initialDate = existing ?? (isDob ? DateTime(1990, 1, 1) : now);
    final firstDate = DateTime(1900);
    final lastDate = isDob ? now : DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;

    final formatted = _formatDate(picked);
    controller.text = formatted;
    if (isDob) {
      _controller.dateOfBirth = formatted;
    } else {
      _controller.expiryDate = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubscribed = ProfileData.instance.subscribed;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Add Your License Info',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            if (!isSubscribed) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4DB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Uploading license for verification requires subscription.',
                  style: TextStyle(
                    color: Color(0xFF8A5B00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              'Personal Info',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            _LabeledInput(
              label: 'Name',
              hintText: 'Write here',
              controller: _fullNameController,
              onChanged: (value) => _controller.fullName = value,
            ),
            const SizedBox(height: 14),
            _LabeledInput(
              label: 'User Photo',
              hintText: 'Select a file (jpg/png)',
              controller: _userPhotoController,
              readOnly: true,
              onTap: () => _pickImage(isUserPhoto: true),
              suffixIcon: const Icon(
                Icons.attach_file,
                color: Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 14),
            _LabeledInput(
              label: 'License Number',
              hintText: 'Write here',
              controller: _licenseNumberController,
              onChanged: (value) => _controller.licenseNumber = value,
            ),
            const SizedBox(height: 14),
            _LabeledDropdown(
              label: 'State / Country',
              hintText: 'Select State or Country',
              value: _selectedState,
              items: _stateAndCountryOptions,
              onChanged: (value) {
                setState(() => _selectedState = value);
                if (value != null) {
                  _controller.state = value;
                }
              },
            ),
            const SizedBox(height: 14),
            _LabeledInput(
              label: 'Date of Birth',
              hintText: 'MM/DD/YYYY',
              controller: _dateOfBirthController,
              readOnly: true,
              onTap: () =>
                  _pickDate(controller: _dateOfBirthController, isDob: true),
              suffixIcon: const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 14),
            _LabeledInput(
              label: 'Expiration Date',
              hintText: 'MM/DD/YYYY',
              controller: _expiryDateController,
              readOnly: true,
              onTap: () =>
                  _pickDate(controller: _expiryDateController, isDob: false),
              suffixIcon: const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 14),
            _LabeledDropdown(
              label: 'License Class',
              hintText: 'Select Class',
              value: _selectedLicenseClass,
              items: _licenseClassOptions,
              onChanged: (value) {
                setState(() => _selectedLicenseClass = value);
                if (value != null) {
                  _controller.licenseClass = value;
                }
              },
            ),
            const SizedBox(height: 14),
            _LabeledInput(
              label: 'Upload License Photo',
              hintText: 'Select a file (jpg/png)',
              controller: _licensePhotoController,
              readOnly: true,
              onTap: () => _pickImage(isUserPhoto: false),
              suffixIcon: const Icon(
                Icons.attach_file,
                color: Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _controller.canSubmit && !_isSubmitting
                    ? _submit
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.hintText,
    this.readOnly = false,
    this.suffixIcon,
    this.keyboardType,
    this.controller,
    this.onChanged,
    this.onTap,
  });

  final String label;
  final String hintText;
  final bool readOnly;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _fieldLabelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: _fieldHintColor),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _fieldBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _fieldBorderColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.hintText,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String hintText;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _fieldLabelColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF4A4A4A),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: _fieldHintColor),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _fieldBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _fieldBorderColor),
            ),
          ),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
