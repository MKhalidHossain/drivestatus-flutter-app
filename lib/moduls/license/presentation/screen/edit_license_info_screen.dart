import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/helpers/subscription_access.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../../../core/services/app_pigeon/app_pigeon.dart';
import '../../interface/license_interface.dart';
import '../../model/license_create_request_model.dart';
import '../../../profile/interface/profile_interface.dart';
import '../../../profile/model/profile_data.dart';
import '../controller/license_info_controller.dart';
import '../widget/license_edit_field.dart';
import '../widget/license_status_card.dart';

class EditLicenseInfoScreen extends StatefulWidget {
  const EditLicenseInfoScreen({super.key});

  @override
  State<EditLicenseInfoScreen> createState() => _EditLicenseInfoScreenState();
}

class _EditLicenseInfoScreenState extends State<EditLicenseInfoScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _licenseNoController;
  late final TextEditingController _stateController;
  late final TextEditingController _dobController;
  late final TextEditingController _expireController;
  late final SnackbarNotifier _snackbarNotifier;
  bool _isLoading = false;
  bool _isInitialized = false;
  DateTime? _selectedDateOfBirth;
  DateTime? _selectedExpireDate;

  Future<bool> _ensureSubscribed(String featureName) async {
    return SubscriptionAccess.ensureSubscribedAction(
      context: context,
      featureName: featureName,
    );
  }

  DateTime? _parseFormattedDateToDateTime(String formattedDate) {
    if (formattedDate.isEmpty || formattedDate == 'N/A') {
      return null;
    }

    try {
      // Parse format like "19th July, 1990" or "1st January, 2000"
      final parts = formattedDate.split(',');
      if (parts.length != 2) return null;

      final year = int.tryParse(parts[1].trim());
      if (year == null) return null;

      final datePart = parts[0].trim();
      final dayMatch = RegExp(r'^\d+').firstMatch(datePart);
      if (dayMatch == null) return null;

      final day = int.tryParse(dayMatch.group(0)!);
      if (day == null) return null;

      final monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      int? month;
      for (int i = 0; i < monthNames.length; i++) {
        if (datePart.contains(monthNames[i])) {
          month = i + 1;
          break;
        }
      }

      if (month == null) return null;

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  String _formatDateForDisplay(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;

    String suffix = 'th';
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }

    return '$day$suffix $month, $year';
  }

  @override
  void initState() {
    super.initState();
    final info = LicenseInfoController.notifier.value;
    final nameParts = _splitName(info.name);
    _firstNameController = TextEditingController(text: nameParts.$1);
    _lastNameController = TextEditingController(text: nameParts.$2);
    _licenseNoController = TextEditingController(text: info.licenseNo);
    _stateController = TextEditingController(text: info.state);

    // Parse dates from formatted strings
    _selectedDateOfBirth = _parseFormattedDateToDateTime(info.dateOfBirth);
    _selectedExpireDate = _parseFormattedDateToDateTime(info.expireDate);

    _dobController = TextEditingController(
      text: _selectedDateOfBirth != null
          ? _formatDateForDisplay(_selectedDateOfBirth!)
          : '',
    );
    _expireController = TextEditingController(
      text: _selectedExpireDate != null
          ? _formatDateForDisplay(_selectedExpireDate!)
          : '',
    );
  }

  (String, String) _splitName(String name) {
    final normalized = name == 'N/A' ? '' : name.trim();
    if (normalized.isEmpty) {
      return ('', '');
    }

    final parts = normalized.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return (parts.first, '');
    }

    return (parts.first, parts.sublist(1).join(' '));
  }

  bool _isValidStoredEmail(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed != 'N/A' &&
        trimmed.contains('@') &&
        trimmed.contains('.');
  }

  String _readEmailFromMap(Map<dynamic, dynamic> source) {
    for (final key in ['email', 'userEmail']) {
      final value = source[key]?.toString().trim() ?? '';
      if (_isValidStoredEmail(value)) {
        return value;
      }
    }

    for (final key in ['user', 'data', 'profile']) {
      final nested = source[key];
      if (nested is Map) {
        final value = _readEmailFromMap(nested);
        if (_isValidStoredEmail(value)) {
          return value;
        }
      }
    }

    return '';
  }

  Future<String> _getUserEmail() async {
    final profileEmail = ProfileData.instance.email.trim();
    if (_isValidStoredEmail(profileEmail)) {
      return profileEmail;
    }

    try {
      final authStatus = await Get.find<AppPigeon>().currentAuth();
      if (authStatus is Authenticated) {
        final authEmail = _readEmailFromMap(authStatus.auth.data);
        if (_isValidStoredEmail(authEmail)) {
          return authEmail;
        }
      }
    } catch (_) {
      // Fall through to the profile API below.
    }

    if (!Get.isRegistered<ProfileInterface>()) {
      return '';
    }

    try {
      final result = await Get.find<ProfileInterface>().getProfile();
      return result.fold((_) => '', (success) {
        final profile = success.data;
        if (profile == null) {
          return '';
        }
        ProfileData.instance.updateFromProfile(profile);
        return _isValidStoredEmail(profile.email) ? profile.email.trim() : '';
      });
    } catch (_) {
      return '';
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976F3),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text = _formatDateForDisplay(picked);
      });
    }
  }

  Future<void> _selectExpireDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedExpireDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: 'Select Expire Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976F3),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedExpireDate) {
      setState(() {
        _selectedExpireDate = picked;
        _expireController.text = _formatDateForDisplay(picked);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _snackbarNotifier = SnackbarNotifier(context: context);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _licenseNoController.dispose();
    _stateController.dispose();
    _dobController.dispose();
    _expireController.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    if (_isLoading) return;
    final canProceed = await _ensureSubscribed(
      'License verification submission',
    );
    if (!canProceed || !mounted) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (firstName.isEmpty) {
      _snackbarNotifier.notifyError(message: 'First name is required');
      return;
    }
    if (lastName.isEmpty) {
      _snackbarNotifier.notifyError(message: 'Last name is required');
      return;
    }
    if (_licenseNoController.text.trim().isEmpty) {
      _snackbarNotifier.notifyError(message: 'License number is required');
      return;
    }
    if (_stateController.text.trim().isEmpty) {
      _snackbarNotifier.notifyError(message: 'State is required');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final info = LicenseInfoController.notifier.value;
      final email = await _getUserEmail();
      if (!_isValidStoredEmail(email)) {
        _snackbarNotifier.notifyError(
          message: 'Email is required. Please update your profile email.',
        );
        return;
      }

      final dateOfBirthISO =
          _selectedDateOfBirth?.toIso8601String() ?? info.rawDateOfBirth;
      final expireDateISO =
          _selectedExpireDate?.toIso8601String() ?? info.rawExpireDate;
      final fullName = '$firstName $lastName';

      final createRequest = LicenseCreateRequestModel(
        fullName: fullName,
        firstName: firstName,
        lastName: lastName,
        email: email,
        licenseNumber: _licenseNoController.text.trim(),
        state: _stateController.text.trim(),
        dateOfBirth: dateOfBirthISO,
        expiryDate: expireDateISO,
        licenseClass: info.licenseClass,
        userPhoto: '',
        licensePhoto: '',
      );

      final licenseInterface = Get.find<LicenseInterface>();
      final result = await licenseInterface.createLicense(param: createRequest);

      await result.fold(
        (failure) {
          _snackbarNotifier.notifyError(
            message: failure.uiMessage.isNotEmpty
                ? failure.uiMessage
                : 'Failed to submit license information',
          );
        },
        (success) async {
          final invitationUrl = success.data ?? '';
          final invitationUri = Uri.tryParse(invitationUrl);
          if (invitationUri == null ||
              !(invitationUri.scheme == 'http' ||
                  invitationUri.scheme == 'https')) {
            _snackbarNotifier.notifyError(
              message: 'Invitation link was not found. Please try again.',
            );
            return;
          }

          final completed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  LicenseInvitationWebViewScreen(invitationUrl: invitationUrl),
            ),
          );

          if (!mounted) return;
          await LicenseInfoController.loadLicenseData(
            snackbarNotifier: _snackbarNotifier,
          );
          if (completed == true) {
            await _showThanksDialog();
          }
        },
      );
    } catch (e) {
      _snackbarNotifier.notifyError(
        message: 'An error occurred while submitting license information',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showThanksDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thanks for submitting'),
          content: const Text('Your license information has been submitted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7A7A7A),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'Select $label' : controller.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: controller.text.isEmpty
                          ? const Color(0xFF9E9E9E)
                          : Colors.black87,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Color(0xFF7A7A7A),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = LicenseInfoController.notifier.value;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit License Info',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          LicenseStatusCard(
            status: info.status,
            validity: info.validity,
            expiryDate: info.expiryShort,
          ),
          const SizedBox(height: 10),
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
                const Text(
                  'License Information',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                LicenseEditField(
                  label: 'First Name',
                  controller: _firstNameController,
                ),
                LicenseEditField(
                  label: 'Last Name',
                  controller: _lastNameController,
                ),
                LicenseEditField(
                  label: 'License No',
                  controller: _licenseNoController,
                ),
                LicenseEditField(label: 'State', controller: _stateController),
                _buildDateField(
                  label: 'Date of birth',
                  controller: _dobController,
                  onTap: _selectDateOfBirth,
                ),
                _buildDateField(
                  label: 'Expire Date',
                  controller: _expireController,
                  onTap: _selectExpireDate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _proceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Proceed',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class LicenseInvitationWebViewScreen extends StatefulWidget {
  const LicenseInvitationWebViewScreen({
    super.key,
    required this.invitationUrl,
  });

  final String invitationUrl;

  @override
  State<LicenseInvitationWebViewScreen> createState() =>
      _LicenseInvitationWebViewScreenState();
}

class _LicenseInvitationWebViewScreenState
    extends State<LicenseInvitationWebViewScreen> {
  WebViewController? _controller;
  Timer? _completionPollTimer;
  int _progress = 0;
  bool _completed = false;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    _completionPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeWebView() async {
    final invitationUrl = widget.invitationUrl.trim();
    final uri = Uri.tryParse(invitationUrl);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      _setWebViewError('Invalid invitation link.');
      return;
    }

    debugPrint('Opening Checkr invitation URL: $invitationUrl');

    try {
      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _progress = progress);
            }
          },
          onPageStarted: (url) {
            debugPrint('Checkr WebView page started: $url');
          },
          onNavigationRequest: (request) {
            if (_isCompletionUrl(request.url)) {
              _finishCompleted();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) {
            debugPrint('Checkr WebView page finished: $url');
            _checkPageCompletion(url);
          },
          onWebResourceError: (error) {
            debugPrint(
              'Checkr WebView resource error: '
              '${error.errorCode} ${error.description}',
            );
            if (error.isForMainFrame == true) {
              _setWebViewError(
                'Unable to load the Checkr form. Please try again.',
              );
            }
          },
        ),
      );

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
      await controller.loadRequest(uri);
      _startCompletionPolling();
    } catch (error) {
      debugPrint('Checkr WebView initialization failed: $error');
      _setWebViewError(
        'Unable to open the Checkr form. Please rebuild the app.',
      );
    }
  }

  void _setWebViewError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isInitializing = false;
    });
  }

  void _startCompletionPolling() {
    _completionPollTimer?.cancel();
    _completionPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkCurrentPageCompletion();
    });
  }

  bool _isCompletionUrl(String url) {
    final uri = Uri.tryParse(url.toLowerCase());
    if (uri == null) return false;

    final path = uri.path;
    final status = uri.queryParameters['status'] ?? '';
    final result = uri.queryParameters['result'] ?? '';
    final invitationStatus = uri.queryParameters['invitation_status'] ?? '';
    return path.contains('/complete') ||
        path.contains('/completed') ||
        path.contains('/confirmation') ||
        path.contains('/confirmed') ||
        path.contains('/finish') ||
        path.contains('/finished') ||
        path.contains('/success') ||
        path.contains('/submitted') ||
        path.contains('/thank-you') ||
        path.contains('/thank_you') ||
        status == 'complete' ||
        status == 'completed' ||
        status == 'success' ||
        result == 'success' ||
        invitationStatus == 'completed';
  }

  bool _hasCompletionText(String value) {
    final lower = value.toLowerCase();
    return lower.contains('review your information') ||
        lower.contains("review the information you've provided") ||
        lower.contains('review the information you have provided') ||
        lower.contains('please review your information') ||
        lower.contains('thanks for submitting') ||
        lower.contains('thank you for submitting') ||
        lower.contains('thank you') && lower.contains('submitted') ||
        lower.contains('thanks') && lower.contains('submitted') ||
        lower.contains('submitted successfully') ||
        lower.contains('successfully submitted') ||
        lower.contains('your information has been submitted') ||
        lower.contains('background check has been submitted') ||
        lower.contains('submission complete') ||
        lower.contains('invitation completed') ||
        lower.contains("you're all set") ||
        lower.contains('you are all set') ||
        lower.contains('all set');
  }

  Future<void> _checkCurrentPageCompletion() async {
    if (_completed) return;

    final controller = _controller;
    if (controller == null) return;

    try {
      final url = await controller.currentUrl();
      if (url != null && _isCompletionUrl(url)) {
        _finishCompleted();
        return;
      }
      await _checkPageCompletion(url ?? '');
    } catch (error) {
      debugPrint('Checkr WebView completion polling skipped: $error');
    }
  }

  Future<void> _checkPageCompletion(String url) async {
    if (_completed || _isCompletionUrl(url)) {
      _finishCompleted();
      return;
    }

    final controller = _controller;
    if (controller == null) return;

    try {
      final title = await controller.getTitle();
      if (title != null && _hasCompletionText(title)) {
        _finishCompleted();
        return;
      }

      final bodyText = await controller.runJavaScriptReturningResult(r'''
        (() => {
          const bodyText = document.body ? document.body.innerText : '';
          const documentText = document.documentElement ? document.documentElement.innerText : '';
          return `${document.title || ''}\\n${bodyText}\\n${documentText}`;
        })()
        ''');
      if (_hasCompletionText(bodyText.toString())) {
        _finishCompleted();
      }
    } catch (_) {
      // Some pages block JavaScript inspection; URL detection still handles
      // normal completion redirects.
    }
  }

  void _finishCompleted() {
    if (_completed || !mounted) return;
    _completionPollTimer?.cancel();
    _completed = true;
    debugPrint('Checkr WebView completed. Returning to app.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('License Verification'),
        actions: [
          TextButton(onPressed: _finishCompleted, child: const Text('Done')),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
            )
          else if (_isInitializing || controller == null)
            const Center(child: CircularProgressIndicator())
          else
            WebViewWidget(controller: controller),
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress == 0 ? null : _progress / 100,
            ),
        ],
      ),
    );
  }
}
