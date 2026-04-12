import 'package:flutter/material.dart';
import 'package:flutter_bighustle/core/common/common/app_logo.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../../../core/services/app_pigeon/app_pigeon.dart';
import '../controller/home_controller.dart';
import '../implement/home_interface_impl.dart';
import '../interface/home_interface.dart';
import '../model/home_response_model.dart';
import '../../profile/controller/profile_info_controller.dart';
import '../../profile/model/profile_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeController? _controller;
  SnackbarNotifier? _snackbarNotifier;
  bool _initialized = false;

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      _controller!.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    if (!Get.isRegistered<HomeInterface>()) {
      Get.put<HomeInterface>(
        HomeInterfaceImpl(appPigeon: Get.find<AppPigeon>()),
      );
    }

    _snackbarNotifier = SnackbarNotifier(context: context);
    _controller = HomeController(snackbarNotifier: _snackbarNotifier!);
    _controller!.addListener(_onControllerUpdate);
    _controller!.loadHomeData();

    if (!ProfileData.instance.hasLoaded &&
        !ProfileInfoController.isLoading.value) {
      ProfileInfoController.loadProfile(snackbarNotifier: _snackbarNotifier);
    }
  }

  String _displayName(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isNotEmpty ? trimmed : 'Driver';
  }

  String _formatStatus(String? status) {
    final normalized = status?.trim();
    if (normalized == null || normalized.isEmpty) return 'Unknown';
    final lower = normalized.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  String _formatActivityTitle(HomeActivityModel activity) {
    if (activity.title.trim().isNotEmpty) {
      return activity.title.trim();
    }
    if (activity.type.trim().isNotEmpty) {
      return activity.type.replaceAll('_', ' ');
    }
    return 'Activity';
  }

  String _formatActivitySubtitle(HomeActivityModel activity) {
    final message = activity.message.trim();
    final timeAgo = _timeAgo(activity.createdAt);
    if (message.isEmpty) return timeAgo;
    if (timeAgo.isEmpty) return message;
    return '$message - $timeAgo';
  }

  void _openFeature(String route) {
    Navigator.pushNamed(context, route);
  }

  int _licenseAlertsCount(List<HomeActivityModel> activities) {
    var count = 0;
    for (final activity in activities) {
      final type = activity.type.toLowerCase();
      if (type.contains('license')) {
        count += 1;
      }
    }
    return count;
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  _IndicatorStyle _licenseStatusStyle(String? status) {
    final normalized = status?.toLowerCase().trim() ?? '';
    if (normalized == 'active' ||
        normalized == 'verified' ||
        normalized == 'valid') {
      return const _IndicatorStyle(
        color: Color(0xFF1B8E3E),
        background: Color(0xFFE8F7ED),
        icon: Icons.shield_outlined,
      );
    }
    if (normalized == 'pending' ||
        normalized == 'processing' ||
        normalized == 'in_review') {
      return const _IndicatorStyle(
        color: Color(0xFFC08A0A),
        background: Color(0xFFFFF4DB),
        icon: Icons.shield_outlined,
      );
    }
    if (normalized == 'expired' ||
        normalized == 'rejected' ||
        normalized == 'inactive' ||
        normalized == 'suspended') {
      return const _IndicatorStyle(
        color: Color(0xFFD64545),
        background: Color(0xFFFBEFE8),
        icon: Icons.shield_outlined,
      );
    }
    return const _IndicatorStyle(
      color: Color(0xFF5C6BF2),
      background: Color(0xFFEFF2FF),
      icon: Icons.shield_outlined,
    );
  }

  _ActivityStyle _activityStyle(HomeActivityModel activity) {
    final severity = activity.severity.toLowerCase().trim();
    if (severity == 'success') {
      return const _ActivityStyle(
        icon: Icons.check_circle_outline,
        iconColor: Color(0xFF1B8E3E),
        iconBackground: Color(0xFFE8F7ED),
      );
    }
    if (severity == 'warning') {
      return const _ActivityStyle(
        icon: Icons.warning_amber_rounded,
        iconColor: Color(0xFFD58A19),
        iconBackground: Color(0xFFFFF4DB),
      );
    }
    if (severity == 'error' || severity == 'critical') {
      return const _ActivityStyle(
        icon: Icons.error_outline,
        iconColor: Color(0xFFD64545),
        iconBackground: Color(0xFFFBEFE8),
      );
    }
    if (severity == 'info') {
      return const _ActivityStyle(
        icon: Icons.info_outline,
        iconColor: Color(0xFF3F76F6),
        iconBackground: Color(0xFFEFF2FF),
      );
    }
    final type = activity.type.toLowerCase();
    if (type.contains('license')) {
      return const _ActivityStyle(
        icon: Icons.shield_outlined,
        iconColor: Color(0xFF5C6BF2),
        iconBackground: Color(0xFFEFF2FF),
      );
    }
    return const _ActivityStyle(
      icon: Icons.notifications_none,
      iconColor: Color(0xFF777777),
      iconBackground: Color(0xFFEDEDED),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final controller = _controller;
    final homeData = controller?.homeData ?? HomeResponseModel.empty();
    final isLoading = controller?.isLoading ?? true;
    final hasLoaded = controller?.hasLoaded ?? false;
    final licenseState = homeData.licenseState;
    final licenseStatusStyle = _licenseStatusStyle(licenseState?.licenseStatus);
    final displayName = _displayName(licenseState?.fullName);
    final licenseStatus = _formatStatus(licenseState?.licenseStatus);
    final licenseAlerts = _licenseAlertsCount(homeData.recentActivity);
    final ticketAlerts = homeData.ticketAlerts;
    homeData.recentActivity.where((activity) => !activity.isRead).length;
    final profileData = ProfileData.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06,
            vertical: size.height * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ---------------- HEADER ----------------
              Row(
                children: [
                 SizedBox(
                  height: size.width * 0.2,
                    width: size.width * 0.2,
                  child: AppLogo()),
                 
                  // Text(
                  //   'Logo',
                  //   style: TextStyle(
                  //     color: const Color(0xFF3F76F6),
                  //     fontWeight: FontWeight.w700,
                  //     fontSize: (size.width * 0.03).clamp(18.0, 28.0),
                  //   ),
                  // ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                    child: Stack(
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: (size.width * 0.07).clamp(20.0, 28.0),
                        ),
                        const Positioned(
                          right: 4,
                          top: 4,
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: Color(0xFFE65151),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.profile),
                    child: AnimatedBuilder(
                      animation: profileData,
                      builder: (context, _) {
                        final avatarProvider = profileData.avatarImageProvider;
                        return CircleAvatar(
                          radius: (size.width * 0.045).clamp(14.0, 20.0),
                          backgroundColor: const Color(0xFFE0E0E0),
                          backgroundImage: avatarProvider,
                          child: avatarProvider == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.02),

              /// ---------------- GREETING ----------------
              Text(
                'Good Morning, $displayName! \u{1F44B}',
                style: TextStyle(
                  fontSize: (size.width * 0.02).clamp(18.0, 26.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's your dashboard",
                style: TextStyle(
                  fontSize: (size.width * 0.045).clamp(14.0, 18.0),
                  color: const Color(0xFF444444),
                ),
              ),

              SizedBox(height: size.height * 0.03),

              /// ---------------- STATUS CARDS ----------------
              _StatusCard(
                size: size,
                title: 'Licence Status',
                value: licenseStatus,
                valueColor: licenseStatusStyle.color,
                icon: Icon(
                  licenseStatusStyle.icon,
                  color: licenseStatusStyle.color,
                  size: size.width * 0.08,
                ),
                iconBackground: licenseStatusStyle.background,
              ),

              SizedBox(height: size.height * 0.015),

              _StatusCard(
                size: size,
                title: 'Licence Alerts',
                value: licenseAlerts.toString(),
                valueColor: const Color(0xFFD64545),
                icon: Icon(
                  Icons.warning_amber_rounded,
                  color: const Color(0xFFD64545),
                  size: size.width * 0.08,
                ),
                iconBackground: const Color(0xFFFBEFE8),
              ),

              SizedBox(height: size.height * 0.015),

              _StatusCard(
                size: size,
                title: 'Open Tickets',
                value: ticketAlerts.toString(),
                valueColor: const Color(0xFF5C6BF2),
                icon: Image.asset(
                  'assets/images/mynaui_shield.png',
                  width: size.width * 0.09,
                  height: size.width * 0.09,
                  color: const Color(0xFF5C6BF2),
                ),
                iconBackground: const Color(0xFFEFF2FF),
              ),

              SizedBox(height: size.height * 0.03),

              /// ---------------- QUICK ACCESS ----------------
              Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: (size.width * 0.055).clamp(16.0, 22.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: size.height * 0.02),

              Wrap(
                spacing: size.width * 0.04,
                runSpacing: size.height * 0.02,
                children: [
                  _QuickAccessCard(
                    size: size,
                    label: 'Licence Status',
                    icon: Icon(
                      Icons.shield_outlined,
                      size: size.width * 0.07,
                      color: const Color(0xFF1B8E3E),
                    ),
                    iconBackground: const Color(0xFFE8F7ED),
                    onTap: () => _openFeature(AppRoutes.license),
                  ),

                  _QuickAccessCard(
                    size: size,
                    label: 'Ticket Assistance',
                    icon: Image.asset(
                      'assets/images/mynaui_shield.png',
                      width: size.width * 0.09,
                      height: size.width * 0.09,
                      color: const Color(0xFF5C6BF2),
                    ),
                    iconBackground: const Color(0xFFEFF2FF),
                    onTap: () => _openFeature(AppRoutes.ticket),
                  ),

                  _QuickAccessCard(
                    size: size,
                    label: 'Community',
                    icon: Icon(
                      Icons.group_outlined,
                      size: size.width * 0.07,
                      color: const Color(0xFFC08A0A),
                    ),
                    iconBackground: const Color(0xFFFFF4DB),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.community);
                    },
                  ),

                  _QuickAccessCard(
                    size: size,
                    label: 'Teen Driver posts',
                    icon: Icon(
                      Icons.school_outlined,
                      size: size.width * 0.07,
                      color: const Color(0xFFB54A4A),
                    ),
                    iconBackground: const Color(0xFFFCEAEA),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.teenDrivers);
                    },
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.03),

              /// ---------------- RECENT ACTIVITY ----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: (size.width * 0.055).clamp(16.0, 22.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigator.pushNamed(context, AppRoutes.teenDrivers);
                    },
                    child: Text(
                      'See more',
                      style: TextStyle(
                        fontSize: (size.width * 0.042).clamp(12.0, 16.0),
                        color: const Color(0xFF3F76F6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.02),

              if (isLoading && !hasLoaded && homeData.recentActivity.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (homeData.recentActivity.isEmpty)
                const Center(
                  child: Text(
                    'No recent activity',
                    style: TextStyle(fontSize: 14, color: Color(0xFF777777)),
                  ),
                )
              else
                Column(
                  children: List.generate(homeData.recentActivity.length, (
                    index,
                  ) {
                    final activity = homeData.recentActivity[index];
                    final style = _activityStyle(activity);
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == homeData.recentActivity.length - 1
                            ? 0
                            : size.height * 0.015,
                      ),
                      child: _ActivityTile(
                        size: size,
                        title: _formatActivityTitle(activity),
                        subtitle: _formatActivitySubtitle(activity),
                        icon: style.icon,
                        iconColor: style.iconColor,
                        iconBackground: style.iconBackground,
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicatorStyle {
  final Color color;
  final Color background;
  final IconData icon;

  const _IndicatorStyle({
    required this.color,
    required this.background,
    required this.icon,
  });
}

class _ActivityStyle {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _ActivityStyle({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });
}

/// ================= STATUS CARD =================
class _StatusCard extends StatelessWidget {
  final Size size;
  final String title;
  final String value;
  final Color valueColor;
  final Widget icon;
  final Color iconBackground;

  const _StatusCard({
    required this.size,
    required this.title,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: size.height * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: (size.width * 0.045).clamp(14.0, 18.0),
                  ),
                ),
                SizedBox(height: size.height * 0.008),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: (size.width * 0.065).clamp(20.0, 30.0),
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: size.width * 0.16,
            height: size.width * 0.16,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Center(child: icon),
          ),
        ],
      ),
    );
  }
}

/// ================= QUICK ACCESS CARD =================
class _QuickAccessCard extends StatelessWidget {
  final Size size;
  final String label;
  final Widget icon;
  final Color iconBackground;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.size,
    required this.label,
    required this.icon,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = (size.width - size.width * 0.16) / 2;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: cardWidth,
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.025,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Container(
              width: size.width * 0.14,
              height: size.width * 0.14,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Center(child: icon),
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (size.width * 0.042).clamp(12.0, 16.0),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= ACTIVITY TILE =================
class _ActivityTile extends StatelessWidget {
  final Size size;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _ActivityTile({
    required this.size,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.018,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: size.width * 0.14,
            height: size.width * 0.14,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: size.width * 0.07),
          ),
          SizedBox(width: size.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: (size.width * 0.045).clamp(14.0, 18.0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: size.height * 0.006),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: (size.width * 0.038).clamp(12.0, 16.0),
                    color: const Color(0xFF777777),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
