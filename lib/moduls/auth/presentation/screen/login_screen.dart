import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:flutter_bighustle/core/constants/app_routes.dart';
import 'package:flutter_bighustle/core/notifiers/snackbar_notifier.dart';
import 'package:flutter_bighustle/moduls/auth/controller/login_controller.dart';
import 'package:flutter_bighustle/moduls/auth/presentation/widget/auth_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final LoginsScreenController _controller;
  bool _initialized = false;
  bool _isLoading = false;
  bool _isAppleLoading = false;
  String? _emailError;
  String? _passwordError;

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[A-Za-z]{2,}$');
    return regex.hasMatch(email);
  }

  bool get _supportsAppleSignIn =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _controller = LoginsScreenController(SnackbarNotifier(context: context));
      _controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    if (_initialized) {
      _controller.removeListener(_onControllerUpdate);
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    String? emailError;
    String? passwordError;
    if (!_isValidEmail(email)) {
      emailError = 'Mail is incorrect';
    }
    if (password.isEmpty) {
      passwordError = 'Entered password incorrect';
    }
    if (emailError != null || passwordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
      });
      return;
    }

    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });
    final success = await _controller.login(
      needVerification: () {
        Navigator.pushNamed(
          context,
          AppRoutes.emailVerify,
          arguments: email,
        );
      },
    );
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);
    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (ModalRoute.of(context)?.isCurrent ?? true) {
      setState(() {
        _passwordError = 'Entered password incorrect';
      });
    }
  }

  Future<void> _submitAppleSignIn() async {
    if (_isAppleLoading) return;

    setState(() => _isAppleLoading = true);
    final success = await _controller.signInWithApple();
    if (!mounted) {
      return;
    }
    setState(() => _isAppleLoading = false);
    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
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
              SizedBox(height: size.height * 0.06),
              Center(
                child: AuthLogo(),
              ),
              SizedBox(height: size.height * 0.05),
              Text(
                'Welcome',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (size.width * 0.08).clamp(24.0, 34.0),
                  fontWeight: FontWeight.w700,
                  color: AuthColors.textDark,
                ),
              ),
              SizedBox(height: size.height * 0.01),
              Text(
                'Please sign in to continue',
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
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: (value) {
                  _controller.email = value;
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
              ),
              SizedBox(height: size.height * 0.02),
              AuthTextField(
                size: size,
                controller: _passwordController,
                hintText: 'Password',
                errorText: _passwordError,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onChanged: (value) {
                  _controller.password = value;
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.forgetPassword);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AuthColors.primary,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: (size.width * 0.04).clamp(12.0, 16.0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.02),
              AuthPrimaryButton(
                size: size,
                label: 'Login',
                onPressed: _controller.canSubmit && !_isLoading ? _submit : null,
                isLoading: _isLoading,
              ),
              if (_supportsAppleSignIn) ...[
                SizedBox(height: size.height * 0.02),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: TextStyle(
                          fontSize: (size.width * 0.04).clamp(12.0, 16.0),
                          color: AuthColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                SizedBox(height: size.height * 0.02),
                SizedBox(
                  height: (size.height * 0.075).clamp(48.0, 60.0),
                  child: SignInWithAppleButton(
                    onPressed: _isAppleLoading ? null : _submitAppleSignIn,
                    style: SignInWithAppleButtonStyle.black,
                    text: 'Sign in with Apple',
                  ),
                ),
              ],
              SizedBox(height: size.height * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      fontSize: (size.width * 0.04).clamp(12.0, 16.0),
                      color: AuthColors.textMuted,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.signup);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AuthColors.primary,
                    ),
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                        fontSize: (size.width * 0.04).clamp(12.0, 16.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
