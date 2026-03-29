import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import '../../../core/constants/stripe_config.dart';
import '../../../core/helpers/validation.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../../../core/services/app_pigeon/app_pigeon.dart';
import '../../profile/interface/profile_interface.dart';
import '../../profile/model/profile_data.dart';
import '../implement/plan_interface_impl.dart';
import '../interface/plan_interface.dart';
import '../model/payment_response_model.dart';
import '../model/plan_model.dart';

class SubscribePaymentController extends ChangeNotifier {
  SubscribePaymentController();

  final List<PlanModel> _plans = [];
  PlanModel? _currentPlan;
  PlanModel? _selectedPlan;
  bool _isLoadingPlans = false;
  bool _isSubmitting = false;
  bool _initialized = false;

  List<PlanModel> get plans => List.unmodifiable(_plans);
  PlanModel? get currentPlan => _currentPlan;
  PlanModel? get selectedPlan => _selectedPlan;
  bool get isLoadingPlans => _isLoadingPlans;
  bool get isSubmitting => _isSubmitting;

  bool get hasPlans => _plans.isNotEmpty;
  bool get hasSelection => _selectedPlan != null;
  bool get isCurrentSelection =>
      _selectedPlan != null && _selectedPlan?.id == _currentPlan?.id;

  PlanInterface get _planInterface => _ensurePlanInterface();

  void init() {
    if (_initialized) return;
    _initialized = true;
  }

  PlanInterface _ensurePlanInterface() {
    if (!Get.isRegistered<PlanInterface>()) {
      Get.put<PlanInterface>(
        PlanInterfaceImpl(appPigeon: Get.find<AppPigeon>()),
      );
    }
    return Get.find<PlanInterface>();
  }

  Future<void> loadPlans({SnackbarNotifier? snackbarNotifier}) async {
    _setLoadingPlans(true);
    try {
      final result = await _planInterface.getPlans();
      result.fold(
        (failure) => _handlePlanLoadFailure(failure, snackbarNotifier),
        (success) => _handlePlanLoadSuccess(success),
      );
    } catch (_) {
      snackbarNotifier?.notifyError(
        message: 'An error occurred while loading plans',
      );
    } finally {
      _setLoadingPlans(false);
    }
  }

  void selectPlan(PlanModel plan) {
    if (plan.id == _currentPlan?.id) return;
    _selectedPlan = plan;
    notifyListeners();
  }

  Future<bool> submitSubscription({
    required SnackbarNotifier snackbarNotifier,
  }) async {
    if (!_canSubmit(snackbarNotifier)) return false;

    var success = false;
    _setSubmitting(true);
    try {
      debugPrint(
        'Stripe: submit start planId=${_selectedPlan?.id} price=${_selectedPlan?.price} currency=${_selectedPlan?.currency}',
      );
      debugPrint('Stripe: resolve billing info');
      final billingInfo = await _requireBillingInfo(snackbarNotifier);
      debugPrint(
        'Stripe: billing info email=${billingInfo.email.isNotEmpty} name=${billingInfo.name.isNotEmpty}',
      );
      debugPrint('Stripe: create payment intent');
      final paymentData = await _createPayment(billingInfo, snackbarNotifier);
      if (paymentData == null) return false;

      print('Stripe: init payment sheet');
      await _presentPaymentSheet(billingInfo, paymentData);
      print('Stripe: payment sheet completed');
      success = await _confirmPayment(paymentData, snackbarNotifier);
    } on TimeoutException {
      snackbarNotifier.notifyError(
        message: 'Payment timed out. Please try again.',
      );
    } on StripeException catch (e) {
      debugPrint(
        'StripeException: ${e.error.code} ${e.error.localizedMessage ?? e.error.message}',
      );
      snackbarNotifier.notifyError(
        message:
            e.error.localizedMessage ??
            e.error.message ??
            'Stripe payment cancelled',
      );
    } catch (_) {
      debugPrint('Stripe: unknown error');
      snackbarNotifier.notifyError(message: 'Stripe payment failed');
    } finally {
      _setSubmitting(false);
    }
    return success;
  }

  bool _canSubmit(SnackbarNotifier snackbarNotifier) {
    if (!hasSelection) {
      snackbarNotifier.notifyError(message: 'Please select a plan.');
      return false;
    }
    if (isCurrentSelection) {
      snackbarNotifier.notify(message: 'You are already on this plan.');
      return false;
    }
    if (StripeConfig.publishableKey.isEmpty ||
        StripeConfig.publishableKey.contains('replace_with_your_key')) {
      snackbarNotifier.notifyError(
        message: 'Stripe publishable key is not set.',
      );
      return false;
    }
    return true;
  }

  void _handlePlanLoadFailure(failure, SnackbarNotifier? snackbarNotifier) {
    snackbarNotifier?.notifyError(
      message: failure.uiMessage.isNotEmpty
          ? failure.uiMessage
          : 'Failed to load plans',
    );
    _plans.clear();
    _currentPlan = null;
    _selectedPlan = null;
    notifyListeners();
  }

  void _handlePlanLoadSuccess(success) {
    final fetchedPlans = success.data ?? <PlanModel>[];
    _plans
      ..clear()
      ..addAll(fetchedPlans);

    _currentPlan = _resolveCurrentPlan(fetchedPlans);
    _selectedPlan = _resolveSelectedPlan(fetchedPlans, _currentPlan);
    notifyListeners();
  }

  PlanModel? _resolveCurrentPlan(List<PlanModel> plans) {
    for (final plan in plans) {
      if (plan.price == 0) return plan;
    }
    return plans.isNotEmpty ? plans.first : null;
  }

  PlanModel? _resolveSelectedPlan(List<PlanModel> plans, PlanModel? current) {
    if (plans.isEmpty) return null;
    return plans.firstWhere(
      (plan) => plan.id != current?.id && plan.price > 0,
      orElse: () => current ?? plans.first,
    );
  }

  void _setLoadingPlans(bool value) {
    if (_isLoadingPlans == value) return;
    _isLoadingPlans = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    if (_isSubmitting == value) return;
    _isSubmitting = value;
    notifyListeners();
  }

  bool _isValidEmail(String value) => value.isNotEmpty && isEmail(value);

  bool _isValidName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final normalized = trimmed.toLowerCase();
    return normalized != 'n/a' && normalized != 'profile name';
  }

  String _readString(dynamic value) => value?.toString().trim() ?? '';

  String _readNameFromMap(Map data) {
    final direct = _readString(data['name']);
    if (_isValidName(direct)) return direct;
    final fullName = _readString(data['fullName'] ?? data['fullname']);
    if (_isValidName(fullName)) return fullName;
    final firstName = _readString(data['firstName'] ?? data['firstname']);
    final lastName = _readString(data['lastName'] ?? data['lastname']);
    final combined = [firstName, lastName].where((v) => v.isNotEmpty).join(' ');
    if (_isValidName(combined)) return combined;
    return '';
  }

  String _readEmailFromMap(Map data) {
    final direct = _readString(data['email']);
    if (_isValidEmail(direct)) return direct;
    final alt = _readString(data['emailAddress'] ?? data['mail']);
    if (_isValidEmail(alt)) return alt;
    return '';
  }

  _BillingInfo _readBillingFromProfileData() {
    return _BillingInfo(
      email: _readString(ProfileData.instance.email),
      name: _readString(ProfileData.instance.name),
    );
  }

  _BillingInfo _mergeBilling(_BillingInfo current, _BillingInfo next) {
    final email = _isValidEmail(current.email) ? current.email : next.email;
    final name = _isValidName(current.name) ? current.name : next.name;
    return _BillingInfo(email: email, name: name);
  }

  _BillingInfo _readBillingFromMap(Map data) {
    return _BillingInfo(
      email: _readEmailFromMap(data),
      name: _readNameFromMap(data),
    );
  }

  Future<_BillingInfo> _readBillingFromAuth() async {
    final status = await Get.find<AppPigeon>().currentAuth();
    if (status is! Authenticated) return const _BillingInfo.empty();

    final authData = status.auth.data;
    if (authData is! Map) return const _BillingInfo.empty();

    var billing = _readBillingFromMap(authData);
    final userData = authData['user'];
    if (userData is Map) {
      billing = _mergeBilling(billing, _readBillingFromMap(userData));
    }
    return billing;
  }

  Future<_BillingInfo> _readBillingFromProfileApi() async {
    if (!Get.isRegistered<ProfileInterface>()) {
      return const _BillingInfo.empty();
    }

    final result = await Get.find<ProfileInterface>().getProfile();
    return result.fold((_) => const _BillingInfo.empty(), (success) {
      final profile = success.data;
      if (profile == null) return const _BillingInfo.empty();
      ProfileData.instance.updateFromProfile(profile);
      return _BillingInfo(
        email: _readString(profile.email),
        name: _readString(profile.name),
      );
    });
  }

  Future<_BillingInfo> _resolveBillingInfo() async {
    var billing = _readBillingFromProfileData();
    if (!billing.isComplete) {
      billing = _mergeBilling(billing, await _readBillingFromAuth());
    }
    if (!billing.isComplete) {
      billing = _mergeBilling(billing, await _readBillingFromProfileApi());
    }
    return _BillingInfo(
      email: _isValidEmail(billing.email) ? billing.email : '',
      name: _isValidName(billing.name) ? billing.name : '',
    );
  }

  Future<_BillingInfo> _requireBillingInfo(
    SnackbarNotifier snackbarNotifier,
  ) async {
    final billingInfo = await _resolveBillingInfo();
    if (!billingInfo.isComplete) {
      snackbarNotifier.notify(
        message:
            'Name/email missing. You can still continue, but please update your profile later.',
      );
    }
    return billingInfo;
  }

  Future<PlanPaymentCreateResponse?> _createPayment(
    _BillingInfo billingInfo,
    SnackbarNotifier snackbarNotifier,
  ) async {
    debugPrint('Stripe: createPayment start');
    print('Stripe: createPlanPayment planId=${_selectedPlan?.id} email=${billingInfo.email} name=${billingInfo.name}');
    final createResult = await _planInterface
        .createPlanPayment(
          planId: _selectedPlan!.id,
          // provider: 'stripe',
          email: billingInfo.email,
          name: billingInfo.name,
        )
        .timeout(const Duration(seconds: 25));

    final paymentData = createResult.fold((failure) {
      debugPrint('Stripe: createPayment failed ${failure.fullError}');
      snackbarNotifier.notifyError(
        message: failure.uiMessage.isNotEmpty
            ? failure.uiMessage
            : 'Failed to create payment',
      );
      return null;
    }, (success) => success.data);

    if (paymentData == null ||
        paymentData.clientSecret == null ||
        paymentData.clientSecret!.isEmpty) {
      debugPrint(
        'Stripe: createPayment missing clientSecret paymentId=${paymentData?.paymentId} providerPaymentId=${paymentData?.providerPaymentId}',
      );
      snackbarNotifier.notifyError(
        message: 'Stripe client secret missing from backend response.',
      );
      return null;
    }

    debugPrint(
      'Stripe: createPayment ok paymentId=${paymentData.paymentId} '
      'providerPaymentId=${paymentData.providerPaymentId} '
      'clientSecretLen=${paymentData.clientSecret?.length}',
    );
    return paymentData;
  }

  Future<void> presentPaymentSheetFromClientSecret({
    required String clientSecret,
    String? email,
    String? name,
  }) async {
    final billingInfo = _BillingInfo(
      email: email?.trim() ?? '',
      name: name?.trim() ?? '',
    );
    await _presentPaymentSheetWithClientSecret(clientSecret, billingInfo);
  }

  Future<void> _presentPaymentSheet(
    _BillingInfo billingInfo,
    PlanPaymentCreateResponse paymentData,
  ) async {
    final clientSecret = paymentData.clientSecret ?? '';
    await _presentPaymentSheetWithClientSecret(clientSecret, billingInfo);
  }

  Future<void> _presentPaymentSheetWithClientSecret(
    String clientSecret,
    _BillingInfo billingInfo,
  ) async {
    if (clientSecret.isEmpty) {
      throw StateError('Stripe client secret missing.');
    }

    final billingDetails = BillingDetails(
      email: billingInfo.email.isNotEmpty ? billingInfo.email : null,
      name: billingInfo.name.isNotEmpty ? billingInfo.name : null,
    );

    print('Stripe: initPaymentSheet start');
    await Stripe.instance
        .initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: StripeConfig.merchantName,
            style: ThemeMode.light,
            returnURL: 'flutterstripe://stripe-redirect',
            billingDetails: billingDetails,
          ),
        )
        .timeout(const Duration(seconds: 25));

    print('Stripe: initPaymentSheet done');
    print('Stripe: presentPaymentSheet start');
    await Stripe.instance.presentPaymentSheet().timeout(
      const Duration(seconds: 60),
    );
    print('Stripe: presentPaymentSheet done');
  }

  Future<bool> _confirmPayment(
    PlanPaymentCreateResponse paymentData,
    SnackbarNotifier snackbarNotifier,
  ) async {
    const maxAttempts = 4;
    for (var attempt = 0; attempt < maxAttempts; attempt += 1) {
      print('Stripe: confirm attempt ${attempt + 1}/$maxAttempts');
      final confirmResult = await _planInterface
          .confirmPlanPayment(
            paymentId: paymentData.paymentId,
            providerPaymentId: paymentData.providerPaymentId,
          )
          .timeout(const Duration(seconds: 25));

      final outcome = confirmResult.fold(
        (failure) {
          debugPrint('Stripe: confirm failed ${failure.fullError}');
          snackbarNotifier.notifyError(
            message: failure.uiMessage.isNotEmpty
                ? failure.uiMessage
                : 'Payment confirmation failed',
          );
          return _ConfirmOutcome.failure();
        },
        (success) {
          debugPrint(
            'Stripe: confirm response status=${success.data?.status} message=${success.message}',
          );
          return _ConfirmOutcome.success(
            payment: success.data,
            message: success.message,
          );
        },
      );

      if (!outcome.ok) return false;

      final payment = outcome.payment;
      if (payment == null) {
        snackbarNotifier.notifyError(
          message: 'Payment confirmation data missing.',
        );
        return false;
      }

      final status = payment.status.toLowerCase();
      if (status == 'paid') {
        snackbarNotifier.notifySuccess(message: outcome.message);
        _currentPlan = _selectedPlan;
        notifyListeners();
        return true;
      }

      if (status == 'processing' && attempt < maxAttempts - 1) {
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }

      snackbarNotifier.notify(
        message:
            'Payment is still processing. Please wait a moment and try again.',
      );
      return false;
    }

    snackbarNotifier.notify(
      message: 'Payment is still processing. Please try again shortly.',
    );
    return false;
  }
}

class _ConfirmOutcome {
  final bool ok;
  final PlanPaymentModel? payment;
  final String message;

  const _ConfirmOutcome._({
    required this.ok,
    required this.payment,
    required this.message,
  });

  factory _ConfirmOutcome.failure() =>
      const _ConfirmOutcome._(ok: false, payment: null, message: '');

  factory _ConfirmOutcome.success({
    required PlanPaymentModel? payment,
    required String message,
  }) =>
      _ConfirmOutcome._(ok: true, payment: payment, message: message);
}

class _BillingInfo {
  final String email;
  final String name;

  const _BillingInfo({required this.email, required this.name});

  const _BillingInfo.empty() : email = '', name = '';

  bool get isComplete => email.isNotEmpty && name.isNotEmpty;
}
