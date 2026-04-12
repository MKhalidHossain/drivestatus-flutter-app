import 'package:flutter/material.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../model/license_alert_model.dart';
import '../controller/license_info_controller.dart';
import '../widget/license_alert_item.dart';
import '../widget/license_info_card.dart';
import '../widget/license_status_card.dart';

class LicenseScreen extends StatefulWidget {
  final bool showBackButton;

  const LicenseScreen({super.key, this.showBackButton = false});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  late final SnackbarNotifier _snackbarNotifier;
  bool _isInitialized = false;

  bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final trimmedUrl = url.trim();
    return trimmedUrl.startsWith('http://') ||
        trimmedUrl.startsWith('https://');
  }

  @override
  void initState() {
    super.initState();
    _loadLicenseData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _snackbarNotifier = SnackbarNotifier(context: context);
    }
  }

  Future<void> _loadLicenseData() async {
    await LicenseInfoController.loadLicenseData(
      snackbarNotifier: _isInitialized ? _snackbarNotifier : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'License',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.editLicenseInfo);
            },
            icon: const Icon(Icons.edit_outlined, color: Colors.black87),
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: LicenseInfoController.isLoading,
        builder: (context, isLoading, _) {
          final hasLoaded = LicenseInfoController.hasLoaded.value;
          if (isLoading && !hasLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return ValueListenableBuilder<LicenseInfo>(
            valueListenable: LicenseInfoController.notifier,
            builder: (context, info, _) {
              return RefreshIndicator(
                onRefresh: _loadLicenseData,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    LicenseStatusCard(
                      status: info.status,
                      validity: info.validity,
                      expiryDate: info.expiryShort,
                    ),
                    const SizedBox(height: 12),
                    if (_isValidImageUrl(info.userPhoto))
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            info.userPhoto,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    if (_isValidImageUrl(info.userPhoto))
                      const SizedBox(height: 12),
                    if (_isValidImageUrl(info.licensePhoto))
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            info.licensePhoto,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.credit_card,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    if (_isValidImageUrl(info.licensePhoto))
                      const SizedBox(height: 12),
                    LicenseInfoCard(
                      name: info.name,
                      licenseNo: info.licenseNo,
                      state: info.state,
                      dateOfBirth: info.dateOfBirth,
                      expireDate: info.expireDate,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Alert & Information',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.licenseAlerts),
                                child: const Text(
                                  'View all',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LicenseAlertItem(
                            alert: LicenseAlertModel(
                              id: '',
                              userId: '',
                              type: 'license_status',
                              title: 'Unpaid Ticket',
                              message: 'Unpaid Ticket',
                              severity: 'warning',
                              isRead: false,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ),
                            showDivider: true,
                          ),
                          LicenseAlertItem(
                            alert: LicenseAlertModel(
                              id: '',
                              userId: '',
                              type: 'license_status',
                              title: 'Suspend..',
                              message: 'Suspend..',
                              severity: 'info',
                              isRead: false,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ),
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
