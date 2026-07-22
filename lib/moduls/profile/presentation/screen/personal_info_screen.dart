import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../../../core/services/app_pigeon/app_pigeon.dart';
import '../../controller/profile_info_controller.dart';
import '../../../license/implement/license_interface_impl.dart';
import '../../../license/interface/license_interface.dart';
import '../../../license/model/license_alert_model.dart';
import '../../../ticket/interface/ticket_interface.dart';
import '../../../license/model/license_response_model.dart';
import '../../../ticket/model/ticket_model.dart';
import '../../model/profile_data.dart';
import '../../../license/presentation/widget/license_alert_item.dart';
import '../widget/driving_license_card.dart';
import '../widget/ticket_table.dart';
import 'personal_info_edit_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  static const Color _background = Color(0xFFF2F2F2);
  static const String _drivingLicenseAsset =
      'assets/images/drivingLicence.png';

  late final SnackbarNotifier _snackbarNotifier;
  bool _isInitialized = false;
  bool _isLicenseLoading = false;
  bool _isTicketsLoading = false;
  bool _isAlertsLoading = false;
  LicenseResponseModel? _license;
  List<TicketModel> _tickets = [];
  List<LicenseAlertModel> _alerts = const [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _snackbarNotifier = SnackbarNotifier(context: context);
    }
  }

  Future<void> _loadProfile() async {
    await ProfileInfoController.loadProfile(
      snackbarNotifier: _isInitialized ? _snackbarNotifier : null,
    );
  }

  Future<void> _loadLicense() async {
    setState(() => _isLicenseLoading = true);
    final licenseInterface = Get.find<LicenseInterface>();
    final result = await licenseInterface.getLicense();

    result.fold(
      (failure) {
        _license = null;
        if (_isInitialized) {
          _snackbarNotifier.notifyError(
            message: failure.uiMessage.isNotEmpty
                ? failure.uiMessage
                : 'Failed to load license',
          );
        }
      },
      (success) {
        final licenses = success.data ?? <LicenseResponseModel>[];
        _license = licenses.isNotEmpty ? licenses.first : null;
      },
    );

    if (mounted) {
      setState(() => _isLicenseLoading = false);
    }
  }

  Future<void> _loadTickets() async {
    setState(() => _isTicketsLoading = true);
    final ticketInterface = Get.find<TicketInterface>();
    final result = await ticketInterface.getMyTickets();

    result.fold(
      (failure) {
        _tickets = [];
        if (_isInitialized) {
          _snackbarNotifier.notifyError(
            message: failure.uiMessage.isNotEmpty
                ? failure.uiMessage
                : 'Failed to load tickets',
          );
        }
      },
      (success) {
        _tickets = success.data?.tickets ?? [];
      },
    );

    if (mounted) {
      setState(() => _isTicketsLoading = false);
    }
  }

  Future<void> _loadAll() async {
    _ensureLicenseInterfaceRegistered();
    await _loadProfile();
    await Future.wait([
      _loadLicense(),
      _loadTickets(),
      _loadAlerts(),
    ]);
  }

  void _ensureLicenseInterfaceRegistered() {
    if (Get.isRegistered<LicenseInterface>()) return;
    Get.put<LicenseInterface>(
      LicenseInterfaceImpl(appPigeon: Get.find<AppPigeon>()),
    );
  }

  Future<void> _loadAlerts() async {
    if (mounted) {
      setState(() => _isAlertsLoading = true);
    }
    try {
      _ensureLicenseInterfaceRegistered();
      final licenseInterface = Get.find<LicenseInterface>();
      final result = await licenseInterface.getAlerts();
      if (!mounted) return;

      result.fold(
        (failure) {
          _alerts = [];
          if (_isInitialized) {
            _snackbarNotifier.notifyError(
              message: failure.uiMessage.isNotEmpty
                  ? failure.uiMessage
                  : 'Failed to load alerts',
            );
          }
        },
        (success) {
          _alerts = success.data ?? [];
        },
      );
    } catch (_) {
      if (!mounted) return;
      _alerts = [];
      if (_isInitialized) {
        _snackbarNotifier.notifyError(
          message: 'An error occurred while loading alerts',
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _isAlertsLoading = false);
    }
  }

  List<LicenseAlertModel> _topAlerts() {
    if (_alerts.length <= 3) return _alerts;
    return _alerts.take(3).toList();
  }

  Widget _buildAlertPreviewSection() {
    if (_isAlertsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    final topAlerts = _topAlerts();
    if (topAlerts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'No alerts available',
          style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
        ),
      );
    }

    return Column(
      children: List.generate(topAlerts.length, (index) {
        return LicenseAlertItem(
          alert: topAlerts[index],
          showDivider: index != topAlerts.length - 1,
        );
      }),
    );
  }

  Future<void> _openLicenseAlerts() async {
    await Navigator.of(context).pushNamed(AppRoutes.licenseAlerts);
    if (!mounted) return;
    await _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final profileData = ProfileData.instance;
    final ticketsToShow = _tickets.take(5).toList();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersonalInfoEditScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: ProfileInfoController.isLoading,
        builder: (context, isLoading, _) {
          if (isLoading && !profileData.hasLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _loadAll,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                AnimatedBuilder(
                  animation: profileData,
                  builder: (context, _) {
                    final userId = profileData.userId;
                    final trimmedUserId =
                        userId.length > 8 ? userId.substring(0, 8) : userId;
                    return Column(
                      children: [
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: const Color(0xFFE1E1E1),
                                foregroundImage: profileData.avatarImageProvider,
                                onForegroundImageError:
                                    profileData.avatarImageProvider == null
                                    ? null
                                    : (_, __) {},
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.black45,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        Text(
                          profileData.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'User ID: $trimmedUserId',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${profileData.email}\n${profileData.phone}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Alert & Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _openLicenseAlerts,
                                    child: const Text(
                                      'View all',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildAlertPreviewSection(),
                            ],
                          ),
                        ),
                // if (_isLicenseLoading)
                //   const SizedBox(
                //     height: 150,
                //     child: Center(child: CircularProgressIndicator()),
                //   )
                // else
                //   DrivingLicenseCard(
                //     imageUrl: _license?.licensePhoto ?? '',
                //     imageAssetPath:
                //         _license?.licensePhoto.isNotEmpty == true
                //             ? ''
                //             : _drivingLicenseAsset,
                //   ),
                // const SizedBox(height: 16),
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 12,
                //     vertical: 12,
                //   ),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(10),
                //     border: Border.all(color: const Color(0xFFE5E5E5)),
                //   ),
                //   child: Column(
                //     children: [
                //       const TicketHeader(),
                //       const Divider(height: 16),
                //       if (_isTicketsLoading)
                //         const Padding(
                //           padding: EdgeInsets.symmetric(vertical: 12),
                //           child: CircularProgressIndicator(),
                //         )
                //       else if (ticketsToShow.isEmpty)
                //         const Padding(
                //           padding: EdgeInsets.symmetric(vertical: 12),
                //           child: Text(
                //             'No tickets found',
                //             style: TextStyle(fontSize: 12, color: Colors.black54),
                //           ),
                //         )
                //       else
                //         ...ticketsToShow.map((ticket) {
                //           final isPaid = ticket.isPaid;
                //           return TicketRow(
                //             status: isPaid ? 'Paid' : 'Unpaid',
                //             statusColor: isPaid
                //                 ? const Color(0xFF1DB954)
                //                 : const Color(0xFFE53935),
                //             ticketId: ticket.ticketNo.isNotEmpty
                //                 ? ticket.ticketNo
                //                 : ticket.id,
                //             location:
                //                 ticket.city.isNotEmpty ? ticket.city : 'N/A',
                //             fee: '\$${ticket.amount.toStringAsFixed(2)}',
                //           );
                //         }),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
