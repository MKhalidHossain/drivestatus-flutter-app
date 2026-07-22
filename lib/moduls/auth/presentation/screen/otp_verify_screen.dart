import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bighustle/core/constants/app_routes.dart';
import 'package:flutter_bighustle/core/notifiers/snackbar_notifier.dart';
import 'package:flutter_bighustle/moduls/auth/controller/verify_email_controller.dart';
import 'package:flutter_bighustle/moduls/auth/presentation/widget/auth_ui.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;

  const OtpVerifyScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  Timer? _timer;
  int _resendTime = 45;
  String _otp = '';
  bool _showOtpError = false;
  late final VerifyEmailController _controller;
  bool _initialized = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _controller = VerifyEmailController(SnackbarNotifier(context: context))
        ..email = widget.email
        ..purpose = 'reset_password';
    }
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_initialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _resendTime = 45;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTime == 0) {
        timer.cancel();
      } else {
        setState(() => _resendTime--);
      }
    });
  }

  bool _isOtpValid() => _otp.length >= 6;

  Future<void> _submit() async {
    if (!_isOtpValid()) {
      setState(() => _showOtpError = true);
      await showAuthStatusDialog(
        context,
        success: false,
        message: 'Account not Verified!',
      );
      return;
    }

    setState(() => _showOtpError = false);

    _controller.otp = _otp;
    setState(() => _isLoading = true);
    await _controller.verifyEmail(
      onSuccess: () {
        Navigator.pushNamed(
          context,
          AppRoutes.resetPassword,
          arguments: {
            'email': widget.email,
            'otp': _otp,
          },
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
              SizedBox(height: size.height * 0.05),
              Text(
                'Enter OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (size.width * 0.075).clamp(22.0, 30.0),
                  fontWeight: FontWeight.w700,
                  color: AuthColors.textDark,
                ),
              ),
              SizedBox(height: size.height * 0.015),
              Text(
                'We have shared a code to your registered email address\n${widget.email}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (size.width * 0.045).clamp(14.0, 18.0),
                  color: AuthColors.textMuted,
                  height: 1.4,
                ),
              ),
              SizedBox(height: size.height * 0.04),
              AuthOtpFields(
                size: size,
                onChanged: (value) => _otp = value,
              ),
              if (_showOtpError) ...[
                SizedBox(height: size.height * 0.015),
                Text(
                  'Enter the 6-digit code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AuthColors.dialogError,
                    fontSize: (size.width * 0.04).clamp(12.0, 16.0),
                  ),
                ),
              ],
              SizedBox(height: size.height * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't get a code?",
                    style: TextStyle(
                      color: AuthColors.textMuted,
                      fontSize: (size.width * 0.04).clamp(12.0, 16.0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: _resendTime == 0 ? _startTimer : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AuthColors.primary,
                    ),
                    child: Text(
                      _resendTime == 0
                          ? 'Resend'
                          : 'Resend in ${_resendTime}s',
                      style: TextStyle(
                        fontSize: (size.width * 0.04).clamp(12.0, 16.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.08),
              AuthPrimaryButton(
                size: size,
                label: 'Verify',
                onPressed: !_isLoading ? _submit : null,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
