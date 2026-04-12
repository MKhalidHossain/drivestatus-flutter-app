import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_bighustle/core/constants/app_routes.dart';
import 'package:flutter_bighustle/core/services/app_pigeon/app_pigeon.dart';
import 'package:flutter_bighustle/moduls/auth/presentation/widget/auth_ui.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  Future<void> _checkAuth() async {
    if (_navigated) {
      return;
    }
    final status = await Get.find<AppPigeon>().currentAuth();
    if (!mounted || _navigated) {
      return;
    }
    _navigated = true;
    if (status is Authenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AuthColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.08,
            vertical: size.height * 0.04,
          ),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.18),
              Center(
                child: AuthLogo(fontSize: size.width * 0.2),
              ),
              SizedBox(height: size.height * 0.02),
              Text(
                'Tagline goes here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (size.width * 0.05).clamp(16.0, 22.0),
                  fontWeight: FontWeight.w500,
                  color: AuthColors.textDark,
                ),
              ),
              const Spacer(),
              const CircularProgressIndicator(),
              SizedBox(height: size.height * 0.04),
              Text(
                'Checking your session...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (size.width * 0.04).clamp(12.0, 16.0),
                  color: AuthColors.textMuted,
                ),
              ),
              SizedBox(height: size.height * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
