import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_bighustle/core/constants/app_routes.dart';
import 'package:flutter_bighustle/core/di/external_service_di.dart';
import 'package:flutter_bighustle/core/di/internal_service_di.dart';
import 'package:flutter_bighustle/core/constants/stripe_config.dart';
import 'package:flutter_bighustle/moduls/auth/presentation/screen/forget_password.dart';
import 'package:flutter_bighustle/moduls/auth/presentation/screen/login_screen.dart';
import 'package:flutter_bighustle/moduls/auth/presentation/screen/otp_verify_screen.dart';
import 'package:flutter_bighustle/moduls/auth/presentation/screen/reset_password-screen.dart';
import 'package:flutter_bighustle/moduls/auth/presentation/screen/splash_screen.dart';
import 'package:flutter_bighustle/moduls/auth/presentation/screen/signup_screen.dart';
import 'package:flutter_bighustle/moduls/auth/presentation/widget/auth_ui.dart';
import 'package:flutter_bighustle/moduls/home/screen/bottom_nav_screen.dart';
import 'package:flutter_bighustle/moduls/home/screen/add_teen_driver_experience_screen.dart';
import 'package:flutter_bighustle/moduls/home/screen/learning_center_screen.dart';
import 'package:flutter_bighustle/moduls/home/screen/learning_video_screen.dart';
import 'package:flutter_bighustle/moduls/home/screen/teen_driver_posts_screen.dart';
import 'package:flutter_bighustle/moduls/home/screen/teen_drivers_screen.dart';
import 'package:flutter_bighustle/moduls/license/presentation/screen/edit_license_info_screen.dart';
import 'package:flutter_bighustle/moduls/license/presentation/screen/license_screen.dart';
import 'package:flutter_bighustle/moduls/license/presentation/screen/liscense_alearts_screen.dart';
import 'package:flutter_bighustle/moduls/ticket/presentation/screen/notification_screen.dart';
import 'package:flutter_bighustle/moduls/ticket/presentation/screen/plan_pricing_details_screen.dart';
import 'package:flutter_bighustle/moduls/ticket/presentation/screen/ticket_details_screen.dart';
import 'package:flutter_bighustle/moduls/ticket/presentation/screen/ticket_screen.dart';
import 'package:flutter_bighustle/moduls/notification/presentation/screen/notification_screen.dart';
import 'moduls/profile/presentation/screen/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = StripeConfig.publishableKey;
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();
  externalServiceDI();
  initServices();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Bighustle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AuthColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AuthColors.primary),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splash:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case AppRoutes.signup:
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case AppRoutes.forgetPassword:
            return MaterialPageRoute(builder: (_) => const ForgetPassword());
          case AppRoutes.otpVerify:
            final email = settings.arguments is String
                ? settings.arguments as String
                : '';
            return MaterialPageRoute(
              builder: (_) => OtpVerifyScreen(email: email),
            );
          // case AppRoutes.emailVerify:
          //   final email = settings.arguments is String
          //       ? settings.arguments as String
          //       : '';
          //   return MaterialPageRoute(
          //     // builder: (_) => EmailVerifyScreen(email: email),
          //   );
          case AppRoutes.resetPassword:
            String? email;
            String? otp;
            if (settings.arguments is Map) {
              final args = settings.arguments as Map;
              email = args['email'] as String?;
              otp = args['otp'] as String?;
            } else if (settings.arguments is String) {
              email = settings.arguments as String;
            }
            return MaterialPageRoute(
              builder: (_) => ResetPasswordscreen(email: email, otp: otp),
            );
          case AppRoutes.home:
            return MaterialPageRoute(builder: (_) => const BottomNavScreen());
          case AppRoutes.teenDrivers:
            return MaterialPageRoute(builder: (_) => const TeenDriversScreen());
          case AppRoutes.teenDriverPosts:
            return MaterialPageRoute(
              builder: (_) => const TeenDriverPostsScreen(),
            );
          case AppRoutes.teenDriverAddExperience:
            return MaterialPageRoute(
              builder: (_) => const AddTeenDriverExperienceScreen(),
            );
          case AppRoutes.learningCenter:
            return MaterialPageRoute(
              builder: (_) => const LearningCenterScreen(),
            );
          case AppRoutes.learningVideo:
            return MaterialPageRoute(
              builder: (_) => const LearningVideoScreen(),
            );
          case AppRoutes.license:
            final showBackButton = settings.arguments is bool
                ? settings.arguments as bool
                : true; // Default to true for route navigation
            return MaterialPageRoute(
              builder: (_) => LicenseScreen(showBackButton: showBackButton),
            );
          case AppRoutes.licenseAlerts:
            return MaterialPageRoute(
              builder: (_) => const LicenseAlertsScreen(),
            );
          case AppRoutes.editLicenseInfo:
            return MaterialPageRoute(
              builder: (_) => const EditLicenseInfoScreen(),
            );
          case AppRoutes.ticket:
            final showBackButton = settings.arguments is bool
                ? settings.arguments as bool
                : true; // Default to true for route navigation
            return MaterialPageRoute(
              builder: (_) => TicketScreen(showBackButton: showBackButton),
            );
          case AppRoutes.ticketDetails:
            final ticketId = settings.arguments is String
                ? settings.arguments as String
                : '';
            return MaterialPageRoute(
              builder: (_) => TicketDetailsScreen(ticketId: ticketId),
            );
          case AppRoutes.ticketNotifications:
            return MaterialPageRoute(
              builder: (_) => const TicketNotificationScreen(),
            );
          // case AppRoutes.planPricing:
          //   return MaterialPageRoute(builder: (_) => const PlanPricingScreen());
          case AppRoutes.planPricingDetails:
            return MaterialPageRoute(
              builder: (_) => const PlanPricingDetailsScreen(),
            );
          case AppRoutes.community:
            return MaterialPageRoute(
              builder: (_) => const TeenDriverPostsScreen(),
            );
          case AppRoutes.profile:
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case AppRoutes.notifications:
            return MaterialPageRoute(
              builder: (_) => const NotificationScreen(),
            );
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
