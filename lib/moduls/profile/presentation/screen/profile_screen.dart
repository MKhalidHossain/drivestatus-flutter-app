import 'package:flutter/material.dart';
import '../widget/logout_dialog.dart';
import '../widget/profile_menu_item.dart';
import 'add_license_info_screen.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';
import 'notification_screen.dart';
import 'personal_info_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_condition_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  static const Color _background = Color(0xFFF2F2F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          ProfileMenuItem(
            icon: Icons.person_outline,
            title: 'Personal Info',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
              );
            },
          ),
          ProfileMenuItem(
            icon: Icons.person_outline,
            title: ' Add Your License Info',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddLicenseInfoScreen()),
              );
            },
          ),
          ProfileMenuItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          ProfileMenuItem(
            icon: Icons.notifications_none,
            title: 'Notification',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          ProfileMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          ProfileMenuItem(
            icon: Icons.gavel_outlined,
            title: 'Terms & Condition',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsConditionScreen()),
              );
            },
          ),
          ProfileMenuItem(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
              );
            },
            showChevron: false,
          ),
          ProfileMenuItem(
            icon: Icons.logout,
            title: 'Log Out',
            onTap: () => showLogoutDialog(context),
            showChevron: false,
          ),
        ],
      ),
    );
  }
}
