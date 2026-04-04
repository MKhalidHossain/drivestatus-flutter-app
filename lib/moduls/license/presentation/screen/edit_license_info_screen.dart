import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/helpers/subscription_access.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../../../core/services/app_pigeon/app_pigeon.dart';
import '../../interface/license_interface.dart';
import '../../model/license_create_request_model.dart';
import '../controller/license_info_controller.dart';
import '../widget/license_edit_field.dart';
import '../widget/license_status_card.dart';

class EditLicenseInfoScreen extends StatefulWidget {
  const EditLicenseInfoScreen({super.key});

  @override
  State<EditLicenseInfoScreen> createState() => _EditLicenseInfoScreenState();
}

class _EditLicenseInfoScreenState extends State<EditLicenseInfoScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _licenseNoController;
  late final TextEditingController _stateController;
  late final TextEditingController _dobController;
  late final TextEditingController _expireController;
  late final SnackbarNotifier _snackbarNotifier;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _selectedUserPhotoPath;
  String? _selectedLicensePhotoPath;
  DateTime? _selectedDateOfBirth;
  DateTime? _selectedExpireDate;

  Future<bool> _ensureSubscribed(String featureName) async {
    return SubscriptionAccess.ensureSubscribedAction(
      context: context,
      featureName: featureName,
    );
  }

  DateTime? _parseFormattedDateToDateTime(String formattedDate) {
    if (formattedDate.isEmpty || formattedDate == 'N/A') {
      return null;
    }

    try {
      // Parse format like "19th July, 1990" or "1st January, 2000"
      final parts = formattedDate.split(',');
      if (parts.length != 2) return null;

      final year = int.tryParse(parts[1].trim());
      if (year == null) return null;

      final datePart = parts[0].trim();
      final dayMatch = RegExp(r'^\d+').firstMatch(datePart);
      if (dayMatch == null) return null;

      final day = int.tryParse(dayMatch.group(0)!);
      if (day == null) return null;

      final monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      int? month;
      for (int i = 0; i < monthNames.length; i++) {
        if (datePart.contains(monthNames[i])) {
          month = i + 1;
          break;
        }
      }

      if (month == null) return null;

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  String _formatDateForDisplay(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;

    String suffix = 'th';
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }

    return '$day$suffix $month, $year';
  }

  @override
  void initState() {
    super.initState();
    final info = LicenseInfoController.notifier.value;
    _nameController = TextEditingController(
      text: info.name == 'N/A' ? '' : info.name,
    );
    _licenseNoController = TextEditingController(text: info.licenseNo);
    _stateController = TextEditingController(text: info.state);

    // Parse dates from formatted strings
    _selectedDateOfBirth = _parseFormattedDateToDateTime(info.dateOfBirth);
    _selectedExpireDate = _parseFormattedDateToDateTime(info.expireDate);

    _dobController = TextEditingController(
      text: _selectedDateOfBirth != null
          ? _formatDateForDisplay(_selectedDateOfBirth!)
          : '',
    );
    _expireController = TextEditingController(
      text: _selectedExpireDate != null
          ? _formatDateForDisplay(_selectedExpireDate!)
          : '',
    );
  }

  Future<void> _pickUserPhoto() async {
    final canProceed = await _ensureSubscribed('License photo upload');
    if (!canProceed || !mounted) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedUserPhotoPath = pickedFile.path;
        });
      }
    } catch (e) {
      _snackbarNotifier.notifyError(
        message: 'Failed to pick image: ${e.toString()}',
      );
    }
  }

  Future<void> _pickLicensePhoto() async {
    final canProceed = await _ensureSubscribed('License photo upload');
    if (!canProceed || !mounted) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedLicensePhotoPath = pickedFile.path;
        });
      }
    } catch (e) {
      _snackbarNotifier.notifyError(
        message: 'Failed to pick image: ${e.toString()}',
      );
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976F3),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text = _formatDateForDisplay(picked);
      });
    }
  }

  Future<void> _selectExpireDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedExpireDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: 'Select Expire Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976F3),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedExpireDate) {
      setState(() {
        _selectedExpireDate = picked;
        _expireController.text = _formatDateForDisplay(picked);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _snackbarNotifier = SnackbarNotifier(context: context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _licenseNoController.dispose();
    _stateController.dispose();
    _dobController.dispose();
    _expireController.dispose();
    super.dispose();
  }

  Future<String?> _getUserId() async {
    try {
      final appPigeon = Get.find<AppPigeon>();
      final authStatus = await appPigeon.currentAuth();
      if (authStatus is Authenticated) {
        final auth = authStatus.auth;
        // Try to get userId from data
        final userId =
            auth.data['_id'] ??
            auth.data['userId'] ??
            auth.data['user']?['_id'] ??
            auth.data['user']?['id'];
        if (userId != null) {
          return userId.toString();
        }
      }
    } catch (e) {
      // Silently fail
    }
    return null;
  }

  Future<void> _saveAndClose() async {
    if (_isLoading) return;
    final canProceed = await _ensureSubscribed('License information update');
    if (!canProceed || !mounted) return;

    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      _snackbarNotifier.notifyError(message: 'Name is required');
      return;
    }
    if (_licenseNoController.text.trim().isEmpty) {
      _snackbarNotifier.notifyError(message: 'License number is required');
      return;
    }
    if (_stateController.text.trim().isEmpty) {
      _snackbarNotifier.notifyError(message: 'State is required');
      return;
    }

    // Get user ID
    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) {
      _snackbarNotifier.notifyError(
        message: 'Unable to get user information. Please login again.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final info = LicenseInfoController.notifier.value;

      // Use selected dates or fall back to existing
      String dateOfBirthISO =
          _selectedDateOfBirth?.toIso8601String() ?? info.rawDateOfBirth;
      String expireDateISO =
          _selectedExpireDate?.toIso8601String() ?? info.rawExpireDate;

      // Use selected images if available, otherwise keep existing
      final userPhotoPath = _selectedUserPhotoPath ?? info.userPhoto;
      final licensePhotoPath = _selectedLicensePhotoPath ?? info.licensePhoto;

      // Create update request model
      final updateRequest = LicenseCreateRequestModel(
        fullName: _nameController.text.trim(),
        licenseNumber: _licenseNoController.text.trim(),
        state: _stateController.text.trim(),
        dateOfBirth: dateOfBirthISO,
        expiryDate: expireDateISO,
        licenseClass: info.licenseClass,
        userPhoto: userPhotoPath,
        licensePhoto: licensePhotoPath,
      );

      final licenseInterface = Get.find<LicenseInterface>();
      final result = await licenseInterface.updateLicense(
        userId: userId,
        param: updateRequest,
      );

      result.fold(
        (failure) {
          _snackbarNotifier.notifyError(
            message: failure.uiMessage.isNotEmpty
                ? failure.uiMessage
                : 'Failed to update license information',
          );
        },
        (success) {
          _snackbarNotifier.notifySuccess(
            message: success.message.isNotEmpty
                ? success.message
                : 'License updated successfully',
          );
          // Reload license data
          LicenseInfoController.loadLicenseData(
            snackbarNotifier: _snackbarNotifier,
          );
          Navigator.of(context).pop();
        },
      );
    } catch (e) {
      _snackbarNotifier.notifyError(
        message: 'An error occurred while updating license information',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7A7A7A),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'Select $label' : controller.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: controller.text.isEmpty
                          ? const Color(0xFF9E9E9E)
                          : Colors.black87,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Color(0xFF7A7A7A),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildPhotoSection({
    required String title,
    String? imagePath,
    required String existingImageUrl,
    required VoidCallback onPickImage,
  }) {
    final bool hasValidImage =
        imagePath != null ||
        (existingImageUrl.isNotEmpty &&
            (existingImageUrl.startsWith('http://') ||
                existingImageUrl.startsWith('https://')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            SizedBox(
              height: 30,
              child: OutlinedButton(
                onPressed: onPickImage,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFEDEDED),
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Color(0xFF2F2F2F)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Upload photo +',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imagePath != null
                ? Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  )
                : hasValidImage
                ? Image.network(
                    existingImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 50,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No image selected',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = LicenseInfoController.notifier.value;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit License Info',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          LicenseStatusCard(
            status: info.status,
            validity: info.validity,
            expiryDate: info.expiryShort,
          ),
          const SizedBox(height: 10),
          // User Photo Section
          _buildPhotoSection(
            title: 'User Photo',
            imagePath: _selectedUserPhotoPath,
            existingImageUrl: info.userPhoto,
            onPickImage: _pickUserPhoto,
          ),
          const SizedBox(height: 12),
          // License Photo Section
          _buildPhotoSection(
            title: 'License Photo',
            imagePath: _selectedLicensePhotoPath,
            existingImageUrl: info.licensePhoto,
            onPickImage: _pickLicensePhoto,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'License Information',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                LicenseEditField(label: 'Name', controller: _nameController),
                LicenseEditField(
                  label: 'License No',
                  controller: _licenseNoController,
                ),
                LicenseEditField(label: 'State', controller: _stateController),
                _buildDateField(
                  label: 'Date of birth',
                  controller: _dobController,
                  onTap: _selectDateOfBirth,
                ),
                _buildDateField(
                  label: 'Expire Date',
                  controller: _expireController,
                  onTap: _selectExpireDate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAndClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
