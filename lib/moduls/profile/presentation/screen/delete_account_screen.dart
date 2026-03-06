import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../../../core/services/app_pigeon/app_pigeon.dart';
import '../../../auth/presentation/screen/login_screen.dart';
import '../../interface/profile_interface.dart';
import '../../model/delete_account_request_model.dart';
import '../../model/profile_data.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  static const Color _background = Color(0xFFF2F2F2);
  static const Color _primaryBlue = Color(0xFF2D6BFF);

  late final TextEditingController _emailController;
  late final TextEditingController _reasonController;
  late SnackbarNotifier _snackbarNotifier;
  bool _isInitialized = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _reasonController = TextEditingController();
    _prefillEmail();
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
    _emailController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _prefillEmail() async {
    final profileEmail = ProfileData.instance.email.trim();
    if (_isValidEmail(profileEmail)) {
      _emailController.text = profileEmail;
      return;
    }

    final status = await Get.find<AppPigeon>().currentAuth();
    if (status is Authenticated) {
      final authEmail = status.auth.data['email']?.toString().trim() ?? '';
      if (_isValidEmail(authEmail)) {
        _emailController.text = authEmail;
        return;
      }
    }

    final result = await Get.find<ProfileInterface>().getProfile();
    result.fold((_) {}, (success) {
      final profile = success.data;
      if (profile != null) {
        ProfileData.instance.updateFromProfile(profile);
        if (_isValidEmail(profile.email)) {
          _emailController.text = profile.email;
        }
      }
    });
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDADADA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDADADA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryBlue),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: maxLines > 1
          ? TextInputAction.done
          : TextInputAction.next,
      decoration: _inputDecoration(hintText: hintText),
    );
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Are you sure want to Delete Account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text(
                            'No',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(
                              color: Colors.red.withValues(alpha: 0.28),
                            ),
                            backgroundColor: const Color(0xFFFFFBFB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text(
                            'Yes',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return shouldDelete ?? false;
  }

  Future<void> _submit() async {
    if (_isDeleting) {
      return;
    }

    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final reason = _reasonController.text.trim();

    if (!_isValidEmail(email)) {
      _snackbarNotifier.notifyError(message: 'Please enter a valid email');
      return;
    }

    if (reason.isEmpty) {
      _snackbarNotifier.notifyError(
        message: 'Please enter a reason for deleting your account',
      );
      return;
    }

    final shouldDelete = await _showDeleteConfirmationDialog();
    if (!shouldDelete) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final result = await Get.find<ProfileInterface>().deleteAccount(
      param: DeleteAccountRequestModel(email: email),
    );

    if (!mounted) {
      return;
    }

    await result.fold<Future<void>>(
      (failure) async {
        _snackbarNotifier.notifyError(message: failure.uiMessage);
        if (!mounted) {
          return;
        }
        setState(() {
          _isDeleting = false;
        });
      },
      (success) async {
        _snackbarNotifier.notifySuccess(message: success.message);
        await Get.find<AppPigeon>().logOut();
        if (!mounted) {
          return;
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
    );
  }

  bool _isValidEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'N/A') {
      return false;
    }
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
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
          'Delete Account',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildSectionLabel('Email'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hintText: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildSectionLabel('Reason'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _reasonController,
                hintText: 'Write your reason',
                minLines: 4,
                maxLines: 6,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isDeleting ? null : _submit,
                  child: const Text('Delete Account'),
                ),
              ),
            ],
          ),
          if (_isDeleting)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
