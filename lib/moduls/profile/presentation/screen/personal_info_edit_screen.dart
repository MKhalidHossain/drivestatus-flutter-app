import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../model/profile_data.dart';
import '../../interface/profile_interface.dart';
import '../../model/update_profile_request_model.dart';
import '../widget/info_field.dart';

class PersonalInfoEditScreen extends StatefulWidget {
  const PersonalInfoEditScreen({super.key});

  @override
  State<PersonalInfoEditScreen> createState() => _PersonalInfoEditScreenState();
}

class _PersonalInfoEditScreenState extends State<PersonalInfoEditScreen> {
  static const Color _background = Color(0xFFF2F2F2);
  static const Color _primaryBlue = Color(0xFF2D6BFF);

  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dobController;
  late ProfileData _profileData;
  late final SnackbarNotifier _snackbarNotifier;
  bool _isSaving = false;
  bool _initialized = false;
  String? _selectedAvatarPath;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile == null) {
      return;
    }
    _selectedAvatarPath = pickedFile.path;
    _profileData.updateAvatar(pickedFile.path);
  }

  @override
  void initState() {
    super.initState();
    _profileData = ProfileData.instance;
    _nameController = TextEditingController(text: _profileData.name);
    _phoneController = TextEditingController(text: _profileData.phone);
    _dobController = TextEditingController(text: _profileData.dateOfBirth);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _snackbarNotifier = SnackbarNotifier(context: context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final dob = _dobController.text.trim();
    final avatarPath = _selectedAvatarPath ?? _profileData.avatarPath;

    print("Avatar path _selectedAvatarPath : from Personal Info Edit Screen : $_selectedAvatarPath");
    print("Avatar path : from Personal Info Edit Screen : $avatarPath");

    setState(() => _isSaving = true);
    final profileInterface = Get.find<ProfileInterface>();
    final result = await profileInterface.updateProfile(
      param: UpdateProfileRequestModel(
        name: name,
        phone: phone,
        dob: dob,
        avatarPath: avatarPath,
      ),
    );

    result.fold(
      (failure) {
        _snackbarNotifier.notifyError(
          message:
              failure.uiMessage.isNotEmpty ? failure.uiMessage : 'Update failed',
        );
      },
      (success) {
        if (success.data != null) {
          _profileData.updateFromProfile(success.data!);
        }
        _selectedAvatarPath = null;
        _snackbarNotifier.notifySuccess(message: success.message);
        Navigator.pop(context);
      },
    );

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          SizedBox()
          // TextButton(
          //   onPressed: () => Navigator.pop(context),
          //   child: const Text(
          //     'Done',
          //     style: TextStyle(color: _primaryBlue),
          //   ),
          // ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Center(
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(40),
                    child: Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _profileData,
                          builder: (context, _) {
                            return CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(0xFFE1E1E1),
                              backgroundImage:
                                  _profileData.avatarImageProvider,
                              child: _profileData.avatarImageProvider == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.black45,
                                      size: 36,
                                    )
                                  : null,
                            );
                          },
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: _primaryBlue,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Personal Information',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 12),
                _EditableInfoField(
                  label: 'Name',
                  controller: _nameController,
                ),
                const SizedBox(height: 10),
                _EditableInfoField(
                  label: 'Phone',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                _EditableInfoField(
                  label: 'Date of birth',
                  controller: _dobController,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Update'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableInfoField extends StatelessWidget {
  const _EditableInfoField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return InfoField(
      label: label,
      value: controller.text,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(fontSize: 13, color: Colors.black54),
      ),
    );
  }
}
