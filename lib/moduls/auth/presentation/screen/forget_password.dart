import 'package:flutter/material.dart';

import 'package:flutter_bighustle/core/constants/app_routes.dart';
import 'package:flutter_bighustle/core/notifiers/snackbar_notifier.dart';
import 'package:flutter_bighustle/moduls/auth/controller/forget_password_controller.dart';
import 'package:flutter_bighustle/moduls/auth/presentation/widget/auth_ui.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final _emailController = TextEditingController();
  late final ForgetPasswordController _controller;
  bool _initialized = false;
  bool _isLoading = false;

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
      _controller = ForgetPasswordController(SnackbarNotifier(context: context));
      _controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    if (_initialized) {
      _controller.removeListener(_onControllerUpdate);
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await _controller.sendForgetPasswordRequest(
      onSuccess: () {
        Navigator.pushNamed(
          context,
          AppRoutes.otpVerify,
          arguments: email,
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
                'Forgot Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (size.width * 0.075).clamp(22.0, 30.0),
                  fontWeight: FontWeight.w700,
                  color: AuthColors.textDark,
                ),
              ),
              SizedBox(height: size.height * 0.015),
              Text(
                'Enter your email to reset your password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (size.width * 0.045).clamp(14.0, 18.0),
                  color: AuthColors.textMuted,
                ),
              ),
              SizedBox(height: size.height * 0.04),
              AuthTextField(
                size: size,
                controller: _emailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onChanged: (value) => _controller.email = value,
              ),
              SizedBox(height: size.height * 0.04),
              AuthPrimaryButton(
                size: size,
                label: 'Continue',
                onPressed: _controller.canSend() && !_isLoading ? _submit : null,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
