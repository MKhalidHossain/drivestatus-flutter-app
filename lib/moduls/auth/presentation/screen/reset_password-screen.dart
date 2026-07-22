import 'package:flutter/material.dart';

import 'package:flutter_bighustle/core/constants/app_routes.dart';
import 'package:flutter_bighustle/core/notifiers/snackbar_notifier.dart';
import 'package:flutter_bighustle/moduls/auth/controller/reset_password_controller.dart';
import 'package:flutter_bighustle/moduls/auth/presentation/widget/auth_ui.dart';

class ResetPasswordscreen extends StatefulWidget {
  final String? email;
  final String? otp;

  const ResetPasswordscreen({
    super.key,
    this.email,
    this.otp,
  });

  @override
  State<ResetPasswordscreen> createState() => _ResetPasswordscreenState();
}

class _ResetPasswordscreenState extends State<ResetPasswordscreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late final ResetPasswordController _controller;
  bool _initialized = false;
  bool _isLoading = false;

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    if (_initialized) {
      _controller.removeListener(_onControllerUpdate);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _controller = ResetPasswordController(SnackbarNotifier(context: context))
        ..email = widget.email ?? ''
        ..otp = widget.otp ?? '';
      _controller.addListener(_onControllerUpdate);
    }
  }

  Future<void> _submit() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your new password.')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await _controller.resetPassword(
      onSuccess: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      },
    );
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AuthColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.08,
            vertical: size.height * 0.04,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: size.height * 0.04),
              Center(
                child: AuthLogo(),
              ),
              SizedBox(height: size.height * 0.04),
              Text(
                'Create New Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (size.width * 0.075).clamp(22.0, 30.0),
                  fontWeight: FontWeight.w700,
                  color: AuthColors.textDark,
                ),
              ),
              SizedBox(height: size.height * 0.015),
              Text(
                'Set a new password for your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (size.width * 0.045).clamp(14.0, 18.0),
                  color: AuthColors.textMuted,
                ),
              ),
              SizedBox(height: size.height * 0.04),
              AuthTextField(
                size: size,
                controller: _passwordController,
                hintText: 'New Password',
                isPassword: true,
                textInputAction: TextInputAction.next,
                onChanged: (value) => _controller.password = value,
              ),
              SizedBox(height: size.height * 0.02),
              AuthTextField(
                size: size,
                controller: _confirmController,
                hintText: 'Confirm Password',
                isPassword: true,
                textInputAction: TextInputAction.done,
                onChanged: (value) => _controller.confirmPassword = value,
              ),
              SizedBox(height: size.height * 0.04),
              AuthPrimaryButton(
                size: size,
                label: 'Reset Password',
                onPressed: _controller.canReset() && !_isLoading ? _submit : null,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
